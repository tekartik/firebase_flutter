library;

import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_firestore_flutter/firestore_flutter.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

void main() {
  group('firestore_flutter', () {
    test('api', () {
      firestoreServiceFlutter;
    });
    test('supports', () {
      expect(firestoreServiceFlutter.supportsBlobs, isTrue);
    });
    test('service is a single instance', () {
      expect(firestoreServiceFlutter, same(firestoreServiceFlutter));
    });
  });

  group('app', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      setupFirebaseCoreMocks();
    });

    test('one firestore per app', () async {
      var app = await firebaseFlutter.initializeAppAsync();
      var firestore = firestoreServiceFlutter.firestore(app);
      expect(firestoreServiceFlutter.firestore(app), same(firestore));
      expect(firestore.service, same(firestoreServiceFlutter));
      expect(app.getProduct<Firestore>(), same(firestore));
    });
  });
}
