library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart';

class PathReferenceFlutterMock with PathReferenceFlutterMixin {
  @override
  final String path;

  PathReferenceFlutterMock(this.path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firestore_flutter_mock', () {
    test('PathReferenceFlutterMixin', () {
      var ref1 = PathReferenceFlutterMock('path1');
      var ref2 = PathReferenceFlutterMock('path1');
      expect(ref1, ref2);
      expect(ref1.hashCode, ref2.hashCode);
      ref2 = PathReferenceFlutterMock('path2');
      expect(ref1, isNot(ref2));
    });
  });
}
