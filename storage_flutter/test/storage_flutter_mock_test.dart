library tekartik_firebase_storage_flutter.test.storage_flutter_mock_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_storage/storage.dart';

class BucketMock implements Bucket {
  @override
  final String name;

  BucketMock(this.name);
  @override
  Future<bool> exists() {
    // TODO: implement exists
    throw UnimplementedError();
  }

  @override
  File file(String path) {
    // TODO: implement file
    throw UnimplementedError();
  }

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) {
    // TODO: implement getFiles
    throw UnimplementedError();
  }
}

class StorageFlutterMock implements Storage {
  StorageFlutterMock();

  @override
  Bucket bucket([String? name]) {
    return BucketMock(name!);
  }

  @override
  Reference ref([String? path]) {
    // TODO: implement ref
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firestore_flutter_mock', () {
    test('ref', () {
      var storage = StorageFlutterMock();
      var bucket = storage.bucket('test');
      expect(bucket.name, 'test');
    });
  });
}
