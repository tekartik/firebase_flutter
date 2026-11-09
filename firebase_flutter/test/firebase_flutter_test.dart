library;

import 'package:firebase_core/firebase_core.dart' as core;
import 'package:firebase_core_platform_interface/test.dart';
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
          messagingSenderId: 'sender',
        ),
      );
      expect(options.projectId, 'test');
      expect(options.apiKey, 'api');
      expect(options.appId, 'app');
      expect(options.messagingSenderId, 'sender');
    });
    test('toDebugMap does not leak the api key', () {
      var apiKey = 'AIzaSyThisIsNotARealKey0123456789';
      var options = firebaseFlutter.wrapOptions(
        core.FirebaseOptions(
          projectId: 'test',
          apiKey: apiKey,
          appId: '1:123:android:abc',
          messagingSenderId: '123',
          androidClientId: 'client.apps.googleusercontent.com',
        ),
      );
      var debugMap = options.toDebugMap();
      expect(debugMap['projectId'], 'test');
      expect(debugMap.values, isNot(contains(apiKey)));
      expect(debugMap.toString(), isNot(contains('googleusercontent')));
    });
  });

  group('app', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      setupFirebaseCoreMocks();
    });

    test('the same app for the same native app', () async {
      var app = await firebaseFlutter.initializeAppAsync();
      // Its products and services (registered on it) are found again.
      expect(firebaseFlutter.app(), same(app));
      expect(firebaseFlutter.initializeApp(), same(app));
      expect(await firebaseFlutter.appAsync(), same(app));
      expect(FirebaseApp.instance, same(app));
      expect(Firebase.apps.where((other) => other.name == app.name), [app]);
    });
  });
}
