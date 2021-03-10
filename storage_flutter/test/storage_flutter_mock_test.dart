library tekartik_firebase_storage_flutter.test.storage_flutter_mock_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_storage_flutter/src/storage_flutter.dart';

class StorageFlutterMock extends StorageFlutter {
  StorageFlutterMock() : super(null);
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
