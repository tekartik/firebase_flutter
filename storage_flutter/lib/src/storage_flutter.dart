import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart' as native;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage/src/common/storage_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/utils/content_type.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';

import 'import.dart';

class StorageServiceFlutter
    with FirebaseProductServiceMixin<FirebaseStorage>, StorageServiceMixin
    implements StorageService {
  StorageServiceFlutter();

  @override
  Storage storage(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppFlutter, 'invalid firebase app type');
      var appFlutter = app as FirebaseAppFlutter;
      // The default instance for the default app.
      return StorageFlutter(
        this,
        appFlutter,
        native.FirebaseStorage.instanceFor(app: appFlutter.nativeInstance),
      );
    });
  }
}

StorageServiceFlutter? _storageServiceFlutter;

StorageServiceFlutter get storageServiceFlutter =>
    _storageServiceFlutter ??= StorageServiceFlutter();

class FileMetadataFlutter with FileMetadataMixin implements FileMetadata {
  final native.FullMetadata _full;

  FileMetadataFlutter(this._full);

  @override
  DateTime get dateUpdated => _full.updated!;

  @override
  String get md5Hash => _full.md5Hash!;

  @override
  int get size => _full.size!;

  /// Content type of the file
  @override
  String? get contentType => _full.contentType;

  /// Cache control of the file
  @override
  String? get cacheControl => _full.cacheControl;
}

class FileFlutter with FileMixin implements File {
  @override
  final BucketFlutter bucket;
  final String path;
  native.Reference? _ref;

  FileFlutter(this.bucket, this.path);

  FileFlutter.ref(this.bucket, this._ref) : path = _ref!.fullPath;

  /// init and assign, to use: `_ref ??= await _initRef();`
  Future<native.Reference> _initRef() async {
    return _ref ??= await bucket.getReferenceFromName(path);
  }

  @override
  Future<void> writeAsBytes(Uint8List bytes) async {
    await upload(bytes);
  }

  @override
  Future<void> upload(
    Uint8List bytes, {
    StorageUploadFileOptions? options,
  }) async {
    var contentType =
        options?.contentType ??
        firebaseStorageContentTypeFromFilename(url.basename(path));
    _ref ??= await _initRef();
    await _ref!.putData(
      bytes,
      native.SettableMetadata(
        contentType: contentType,
        cacheControl: options?.cacheControl,
      ),
    );
  }

  // To deprecated
  @override
  Future save(content) {
    late Uint8List data;
    if (content is Uint8List) {
      data = content;
    } else if (content is List<int>) {
      data = Uint8List.fromList(content);
    } else if (content is String) {
      data = Uint8List.fromList(utf8.encode(content));
    } else {
      throw ArgumentError.value(
        content,
        'content',
        'Uint8List, List<int> or String expected',
      );
    }
    return writeAsBytes(data);
  }

  @override
  Future<Uint8List> readAsBytes() async {
    _ref ??= await _initRef();
    var metaData = await _ref!.getMetadata();
    var size = metaData.size!;
    // getData asserts a positive max size.
    if (size == 0) {
      return Uint8List(0);
    }
    return (await _ref!.getData(size))!;
  }

  @override
  Future<Uint8List> download() => readAsBytes();

  /// Not supported on flutter
  @override
  FileMetadata? get metadata => null;

  /// Get file meta data
  @override
  Future<FileMetadata> getMetadata() async {
    _ref ??= await _initRef();
    var fullMetadata = await _ref!.getMetadata();
    return FileMetadataFlutter(fullMetadata);
  }

  @override
  Future<bool> exists() async {
    _ref ??= await _initRef();

    try {
      await _ref!.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future delete() async {
    _ref ??= await _initRef();
    await _ref!.delete();
  }

  @override
  String get name => path;

  @override
  String toString() => 'FileFlutter($path)';

  @override
  bool operator ==(Object other) {
    if (other is FileFlutter) {
      return other.bucket == bucket && other.path == path;
    }
    return false;
  }

  @override
  int get hashCode => path.hashCode;
}

class BucketFlutter with BucketMixin implements Bucket {
  final StorageFlutter storage;
  @override
  final String name;

  BucketFlutter(this.storage, String? name)
    : name = name ?? storage.firebaseStorage.bucket;

  Future<native.Reference> getReferenceFromName(String name) async {
    var ref = storage.firebaseStorage
        .refFromURL(StorageFileRef(this.name, '').toLink().toString())
        .child(name);
    return ref;
  }

  /// The files of [options] whose name starts with its prefix (a plain
  /// string prefix, like Cloud Storage and storage_fs): the deepest folder
  /// the prefix names is listed recursively, only the sub folders that can
  /// hold matching files are listed. One native list call per folder page.
  ///
  /// With autoPaginate (the default), every page is fetched and maxResults
  /// caps the total; otherwise one page of maxResults files is returned with
  /// the query of the next ones.
  Future<GetFilesResponse> _getNextFiles(_GetFileOptionsFlutter options) async {
    var prefix = options.prefix ?? '';
    if (prefix.startsWith('/')) {
      prefix = prefix.substring(1);
    }
    var maxResults = options.maxResults;
    var autoPaginate = options.autoPaginate;
    var files = <FileFlutter>[];
    var buffer = options._nextFiles?.toList() ?? <FileFlutter>[];
    List<FileFlutter> folders;
    String? folder;
    String? pageToken;
    if (options._nextPrefixes == null) {
      // First call: the deepest folder named by the prefix.
      var lastSlashIndex = prefix.lastIndexOf('/');
      folder = lastSlashIndex < 0 ? '' : prefix.substring(0, lastSlashIndex);
      pageToken = options.pageToken;
      folders = <FileFlutter>[];
    } else {
      folders = options._nextPrefixes.toList();
      folder = options._nextPrefix;
      pageToken = folder == null ? null : options.pageToken;
    }

    /// True if [folderPath] can hold a file starting with [prefix].
    bool mayHoldMatches(String folderPath) {
      var folderPrefix = '$folderPath/';
      return folderPrefix.startsWith(prefix) || prefix.startsWith(folderPrefix);
    }

    var pageSize = min(maxResults ?? 1000, 1000);
    while (true) {
      while (buffer.isNotEmpty &&
          (maxResults == null || files.length < maxResults)) {
        files.add(buffer.removeAt(0));
      }
      if (maxResults != null && files.length >= maxResults) {
        break;
      }
      if (folder == null) {
        if (folders.isEmpty) {
          break;
        }
        folder = folders.removeAt(0).path;
        pageToken = null;
      }
      var ref = await getReferenceFromName(folder);
      var nativeResponse = await ref.list(
        native.ListOptions(maxResults: pageSize, pageToken: pageToken),
      );
      for (var item in nativeResponse.items) {
        if (item.fullPath.startsWith(prefix)) {
          buffer.add(FileFlutter(this, item.fullPath));
        }
      }
      for (var subFolder in nativeResponse.prefixes) {
        if (mayHoldMatches(subFolder.fullPath)) {
          folders.add(FileFlutter(this, subFolder.fullPath));
        }
      }
      pageToken = nativeResponse.nextPageToken;
      if (pageToken == null) {
        folder = null;
      }
    }
    var hasMore = buffer.isNotEmpty || folder != null || folders.isNotEmpty;
    if (autoPaginate || !hasMore) {
      return GetFilesResponse(files: files, nextQuery: null);
    }
    var nextQuery = options._copyWith(
      nextFiles: buffer,
      nextPrefixes: folders,
      nextPrefix: folder,
      nullNextPrefix: folder == null,
      pageToken: pageToken,
      nullPageToken: pageToken == null,
    );
    return GetFilesResponse(files: files, nextQuery: nextQuery);
  }

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) {
    var optionsFlutter = options?.asOrToFlutter() ?? _GetFileOptionsFlutter();
    return _getNextFiles(optionsFlutter);
  }

  @override
  File file(String path) => FileFlutter(this, path);

  @override
  Future<bool> exists() async {
    /*
    Getting meta data might fail with permission error
    try {
      var metadata = await storage.firebaseStorage.ref(name).getMetadata();
      print('metadata $name: $metadata');
    } catch (e) {
      devPrint('error getting bucket metada $name: $e');
      error getting bucket metada xxxxx.appspot.com: [firebase_storage/unauthorized] User is not authorized to perform the desired action.
      // return false;
    }*/
    // Simply check that the storage matches
    if (name == storage.firebaseStorage.bucket) {
      return true;
    }
    return false;
  }
}

String nameToUrl(String name) => 'gs://$name';

class ReferenceFlutter with ReferenceMixin implements Reference {
  final native.Reference nativeInstance;

  ReferenceFlutter(this.nativeInstance);

  @override
  Future<String> getDownloadUrl() => nativeInstance.getDownloadURL();

  @override
  String toString() => nativeInstance.toString();
}

class StorageFlutter
    with FirebaseAppProductMixin<FirebaseStorage>
    implements Storage {
  final FirebaseAppFlutter appFlutter;
  final StorageServiceFlutter serviceFlutter;
  final native.FirebaseStorage firebaseStorage;

  StorageFlutter(this.serviceFlutter, this.appFlutter, this.firebaseStorage);

  @override
  Bucket bucket([String? name]) {
    return BucketFlutter(this, name ?? firebaseStorage.bucket);
  }

  @override
  Reference ref([String? path]) {
    path ??= '/';
    path = path.isEmpty ? '/' : path;
    if (path.startsWith('gs://')) {
      return ReferenceFlutter(firebaseStorage.refFromURL(path));
    } else {
      return ReferenceFlutter(firebaseStorage.ref(path));
    }
  }

  @override
  FirebaseApp get app => appFlutter;

  @override
  FirebaseStorageService get service => serviceFlutter;
}

class _GetFileOptionsFlutter implements GetFilesOptions {
  final String? _nextPrefix;
  final List<FileFlutter>? _nextPrefixes;
  final List<FileFlutter>? _nextFiles;
  @override
  final int? maxResults;
  @override
  final String? prefix;
  @override
  final bool autoPaginate;
  @override
  final String? pageToken;

  _GetFileOptionsFlutter({
    this.maxResults,
    this.prefix,
    this.pageToken,
    this.autoPaginate = true,
    this._nextPrefixes,
    this._nextPrefix,
    this._nextFiles,
  });

  @override
  String toString() => {
    if (maxResults != null) 'maxResults': maxResults,
    if (prefix != null) 'prefix': prefix,
    if (_nextPrefix != null) 'nextPrefix': _nextPrefix,
    if (_nextPrefixes != null) 'nextPrefixes': _nextPrefixes,
    if (_nextFiles != null) 'nextFiles': _nextFiles,
    'autoPaginate': autoPaginate,
    if (pageToken != null) 'pageToken': pageToken,
  }.toString();

  // Copy options

  GetFilesOptions _copyWith({
    int? maxResults,
    String? prefix,
    bool? autoPaginate,
    String? pageToken,
    bool? nullPageToken,
    List<FileFlutter>? nextPrefixes,
    List<FileFlutter>? nextFiles,
    String? nextPrefix,
    bool? nullNextPrefix,
  }) {
    return _GetFileOptionsFlutter(
      maxResults: maxResults ?? this.maxResults,
      prefix: prefix ?? this.prefix,
      autoPaginate: autoPaginate ?? this.autoPaginate,
      nextFiles: nextFiles ?? _nextFiles,
      pageToken: (nullPageToken ?? false)
          ? null
          : (pageToken ?? this.pageToken),
      nextPrefixes: nextPrefixes ?? _nextPrefixes,
      nextPrefix: (nullNextPrefix ?? false) ? null : nextPrefix ?? _nextPrefix,
    );
  }

  @override
  GetFilesOptions copyWith({
    int? maxResults,
    String? prefix,
    bool? autoPaginate,
    String? pageToken,
  }) => _copyWith(
    maxResults: maxResults,
    prefix: prefix,
    autoPaginate: autoPaginate,
    pageToken: pageToken,
  );
}

extension _GetFilesOptionsExt on GetFilesOptions {
  _GetFileOptionsFlutter asOrToFlutter() {
    if (this is _GetFileOptionsFlutter) {
      return this as _GetFileOptionsFlutter;
    }
    return _GetFileOptionsFlutter(
      maxResults: maxResults,
      prefix: prefix,
      pageToken: pageToken,
      autoPaginate: autoPaginate,
    );
  }
}
