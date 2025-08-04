library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';

void main() async {
  group('flutter', () {
    test('factory', () async {
      expect(firebaseAuthServiceFlutter.supportsListUsers, isFalse);
      expect(firebaseAuthServiceFlutter.supportsCurrentUser, isTrue);
      AuthFlutter? authFlutter;
      // ignore: dead_code
      await authFlutter?.webSetIndexedDbPersistence();
    });
  });
}
