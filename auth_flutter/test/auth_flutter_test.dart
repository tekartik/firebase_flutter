library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';

void main() async {
  group('flutter', () {
    test('factory', () async {
      expect(authServiceFlutter.supportsListUsers, isFalse);
      expect(authServiceFlutter.supportsCurrentUser, isTrue);
      AuthFlutter? authFlutter;
      // ignore: dead_code
      await authFlutter?.webSetIndexedDbPersistence();
    });
  });
}
