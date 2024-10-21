import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart' as native;
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage/src/common/storage_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage/storage.dart';
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
      if (appFlutter.isDefault!) {
        return StorageFlutter(
            this, appFlutter, native.FirebaseStorage.instance);
      } else {
        return StorageFlutter(this, appFlutter,
            native.FirebaseStorage.instanceFor(app: appFlutter.nativeInstance));
      }
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
    _ref ??= await _initRef();
    await _ref!.putData(bytes);
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
    }
    return writeAsBytes(data);
  }

  @override
  Future<Uint8List> readAsBytes() async {
    _ref ??= await _initRef();
    var metaData = await _ref!.getMetadata();
    return (await _ref!.getData(metaData.size!))!;
  }

  @override
  Future<Uint8List> download() => readAsBytes();

  /// Not supported on flutter
  @override
  FileMetadata? get metadata => null;

  /// Get file meta data
  @override
  Future<FileMetadata> getMetadata() async {
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

  Future<GetFilesResponse> _getNextFiles(
      _GetFileOptionsFlutter optionsFlutter) async {
    var maxResultsDefault = optionsFlutter.maxResults ?? 100;

    var allFiles = optionsFlutter._nextFiles?.toList() ?? <FileFlutter>[];
    var allPrefixes = optionsFlutter._nextPrefixes?.toList() ?? <FileFlutter>[];

    if (allFiles.isNotEmpty) {
      var taken = min(allFiles.length, maxResultsDefault);
      var files = allFiles.sublist(0, taken);

      // devPrint('getFiles nextFiles: ${allFiles.map((file) => file.path)}');
      var nextQuery = optionsFlutter._copyWith(
          maxResults: maxResultsDefault - taken,
          nextFiles: allFiles.sublist(taken));
      return GetFilesResponse(files: files, nextQuery: nextQuery);
    }
    var listOptions = native.ListOptions(
        maxResults: optionsFlutter.maxResults,
        pageToken: optionsFlutter.pageToken);

    var queryPrefix = optionsFlutter._nextPrefix ?? optionsFlutter.prefix ?? '';
    var ref = await getReferenceFromName(queryPrefix);
    // devPrint('options: $options, ref: ${ref.bucket}//${ref.fullPath}');
    var nativeResponse = await ref.list(listOptions);
    // devPrint(          'nativeResponse items: ${nativeResponse.items.map((ref) => '${ref.bucket} ${ref.fullPath}')}, prefixes ${nativeResponse.prefixes.map((ref) => '${ref.name} ${ref.fullPath}')} ${nativeResponse.nextPageToken}');
    // nativeResponse
    // items: (file1.txt test/zq4ThOPZSu4QEHYxCplk/test/list_files/yes/file1.txt),
    // prefixes (other_sub test/zq4ThOPZSu4QEHYxCplk/test/list_files/yes/other_sub)
    // dGVzdC96cTRUaE9QWlN1NFFFSFl4Q3Bsay90ZXN0L2xpc3RfZmlsZXMveWVzL290aGVyX3N1Yi8=
    var files = nativeResponse.items
        .map((nativeReference) => FileFlutter(this, nativeReference.fullPath))
        .toList();
    var prefixes = nativeResponse.prefixes
        .map((nativeReference) => FileFlutter(this, nativeReference.fullPath))
        .toList();
    allPrefixes.addAll(prefixes);
    if (nativeResponse.nextPageToken != null) {
      // devPrint('nextPageToken ${nativeResponse.nextPageToken}');
      var nextQuery = optionsFlutter._copyWith(
          pageToken: nativeResponse.nextPageToken, nextPrefixes: allPrefixes);
      return GetFilesResponse(files: files, nextQuery: nextQuery);
    }
    if (allPrefixes.isNotEmpty) {
      var prefix = allPrefixes.removeAt(0);
      var nextQuery = optionsFlutter._copyWith(
          nextPrefix: prefix.path,
          nextPrefixes: allPrefixes,
          nullPageToken: true);
      return GetFilesResponse(files: files, nextQuery: nextQuery);
    }
    return GetFilesResponse(files: files, nextQuery: null);
  }

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) async {
    var optionsFlutter = options?.asOrToFlutter() ?? _GetFileOptionsFlutter();

    while (true) {
      return _getNextFiles(optionsFlutter);
    }
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

  _GetFileOptionsFlutter(
      {this.maxResults,
      this.prefix,
      this.pageToken,
      this.autoPaginate = true,
      List<FileFlutter>? nextPrefixes,
      String? nextPrefix,
      List<FileFlutter>? nextFiles})
      : _nextFiles = nextFiles,
        _nextPrefixes = nextPrefixes,
        _nextPrefix = nextPrefix;

  @override
  String toString() => {
        if (maxResults != null) 'maxResults': maxResults,
        if (prefix != null) 'prefix': prefix,
        if (_nextPrefix != null) 'nextPrefix': _nextPrefix,
        if (_nextPrefixes != null) 'nextPrefixes': _nextPrefixes,
        if (_nextFiles != null) 'nextFiles': _nextFiles,
        'autoPaginate': autoPaginate,
        if (pageToken != null) 'pageToken': pageToken
      }.toString();

  // Copy options

  GetFilesOptions _copyWith(
      {int? maxResults,
      String? prefix,
      bool? autoPaginate,
      String? pageToken,
      bool? nullPageToken,
      List<FileFlutter>? nextPrefixes,
      List<FileFlutter>? nextFiles,
      String? nextPrefix,
      bool? nullNextPrefix}) {
    return _GetFileOptionsFlutter(
      maxResults: maxResults ?? this.maxResults,
      prefix: prefix ?? this.prefix,
      autoPaginate: autoPaginate ?? this.autoPaginate,
      nextFiles: nextFiles ?? _nextFiles,
      pageToken:
          (nullPageToken ?? false) ? null : (pageToken ?? this.pageToken),
      nextPrefixes: nextPrefixes ?? _nextPrefixes,
      nextPrefix: (nullNextPrefix ?? false) ? null : nextPrefix ?? _nextPrefix,
    );
  }

  @override
  GetFilesOptions copyWith(
          {int? maxResults,
          String? prefix,
          bool? autoPaginate,
          String? pageToken}) =>
      _copyWith(
          maxResults: maxResults,
          prefix: prefix,
          autoPaginate: autoPaginate,
          pageToken: pageToken);
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
        autoPaginate: autoPaginate);
  }
}
