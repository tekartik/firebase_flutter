library tekartik_firebase_storage_flutter.test.storage_flutter_mock_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_storage/storage.dart';

class BucketMock implements Bucket {
  @override
  final String name;

  BucketMock(this.name);
  @override
  Future<bool> exists() {
    throw UnimplementedError();
  }

  @override
  File file(String path) {
    throw UnimplementedError();
  }

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) {
    throw UnimplementedError();
  }
}

class ReferenceMock with ReferenceMixin {
  final String? path;

  ReferenceMock(this.path);
}

class StorageFlutterMock implements Storage {
  StorageFlutterMock();

  @override
  Bucket bucket([String? name]) {
    return BucketMock(name!);
  }

  @override
  ReferenceMock ref([String? path]) {
    return ReferenceMock(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firestore_flutter_mock', () {
    test('ref', () {
      var storage = StorageFlutterMock();
      var bucket = storage.bucket('test');
      expect(bucket.name, 'test');
      var ref = storage.ref();
      expect(ref.path, isNull);
      ref = storage.ref('dummy');
      expect(ref.path, 'dummy');
    });
  });
}
