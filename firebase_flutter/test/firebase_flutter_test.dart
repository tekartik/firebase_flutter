library;

import 'package:firebase_core/firebase_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

void main() {
  group('firebase_flutter', () {
    test('isLocal', () {
      expect(firebaseFlutter.isLocal, isFalse);
    });
    test('api', () {
      // ignore: unnecessary_statements
      firebaseFlutter;
      // ignore: unnecessary_statements
      firebaseFlutterAsync;
      // ignore: unnecessary_statements
      FirebaseFlutter;
    });
    test('app_options', () {
      // ignore: omit_local_variable_types
      FirebaseAppOptions options = firebaseFlutter.wrapOptions(
          const core.FirebaseOptions(
              projectId: 'test',
              apiKey: 'api',
              appId: 'app',
              messagingSenderId: 'sender'));
      expect(options.projectId, 'test');
      expect(options.apiKey, 'api');
      expect(options.appId, 'app');
      expect(options.messagingSenderId, 'sender');
    });
  });
}
