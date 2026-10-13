// Checks with fakes of the plugin classes (no device).
// ignore_for_file: depend_on_referenced_packages, subtype_of_sealed_class
library;

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart' as native;
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_flutter/src/storage_flutter.dart';

class _FakeApp implements FirebaseAppFlutter {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeListResult implements native.ListResult {
  @override
  final List<native.Reference> items;
  @override
  final List<native.Reference> prefixes;
  @override
  String? get nextPageToken => null;

  _FakeListResult(this.items, this.prefixes);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Files of the fake bucket: top.txt, dir/a.txt, dir/sub/b.txt, dirx/c.txt,
/// empty.txt (0 bytes).
const _files = ['top.txt', 'dir/a.txt', 'dir/sub/b.txt', 'dirx/c.txt'];

class _FakeRef implements native.Reference {
  @override
  final String fullPath;

  _FakeRef(this.fullPath);

  @override
  native.Reference child(String path) =>
      _FakeRef([fullPath, path].where((e) => e.isNotEmpty).join('/'));

  @override
  Future<native.ListResult> list([native.ListOptions? options]) async {
    var folderPrefix = fullPath.isEmpty ? '' : '$fullPath/';
    var items = <native.Reference>[];
    var prefixes = <String>{};
    for (var file in _files) {
      if (file.startsWith(folderPrefix)) {
        var rest = file.substring(folderPrefix.length);
        var slash = rest.indexOf('/');
        if (slash < 0) {
          items.add(_FakeRef(file));
        } else {
          prefixes.add('$folderPrefix${rest.substring(0, slash)}');
        }
      }
    }
    return _FakeListResult(items, prefixes.map(_FakeRef.new).toList());
  }

  @override
  Future<native.FullMetadata> getMetadata() async =>
      native.FullMetadata({'fullPath': fullPath, 'size': 0});

  @override
  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    // Like firebase_storage
    assert(maxSize > 0);
    return Uint8List(maxSize);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorage implements native.FirebaseStorage {
  @override
  String get bucket => 'bucket';

  @override
  native.Reference refFromURL(String url) => _FakeRef('');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  var storage = StorageFlutter(
    StorageServiceFlutter(),
    _FakeApp(),
    _FakeStorage(),
  );
  var bucket = storage.bucket();

  Future<List<String>> names(GetFilesOptions options) async =>
      (await bucket.getFiles(options)).files.map((file) => file.name).toList()
        ..sort();

  group('storage_flutter_fake', () {
    test('getMetadata on a new file object', () async {
      var metadata = await bucket.file('dir/a.txt').getMetadata();
      expect(metadata.size, 0);
    });

    test('read an empty file', () async {
      expect(await bucket.file('dir/a.txt').readAsBytes(), isEmpty);
    });

    test('save an unsupported type', () async {
      expect(
        // ignore: deprecated_member_use
        () => bucket.file('x').save(1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getFiles plain string prefix, every page', () async {
      expect(await names(GetFilesOptions(prefix: 'dir')), [
        'dir/a.txt',
        'dir/sub/b.txt',
        'dirx/c.txt',
      ]);
      expect(await names(GetFilesOptions(prefix: 'dir/')), [
        'dir/a.txt',
        'dir/sub/b.txt',
      ]);
      expect(await names(GetFilesOptions(prefix: 'dir/a')), ['dir/a.txt']);
      expect(await names(GetFilesOptions()), [
        'dir/a.txt',
        'dir/sub/b.txt',
        'dirx/c.txt',
        'top.txt',
      ]);
      var response = await bucket.getFiles(GetFilesOptions(prefix: 'dir'));
      expect(response.nextQuery, isNull);
    });

    test('getFiles pages', () async {
      var query = GetFilesOptions(
        prefix: 'dir/',
        maxResults: 1,
        autoPaginate: false,
      );
      var all = <String>[];
      GetFilesOptions? next = query;
      var pages = 0;
      while (next != null) {
        var response = await bucket.getFiles(next);
        expect(response.files.length, lessThanOrEqualTo(1));
        all.addAll(response.files.map((file) => file.name));
        next = response.nextQuery;
        pages++;
      }
      expect(all..sort(), ['dir/a.txt', 'dir/sub/b.txt']);
      expect(pages, 2);
    });
  });
}
