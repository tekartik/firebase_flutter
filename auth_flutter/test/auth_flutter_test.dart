library tekartik_firebase_auth_flutter.auth_flutter_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';

void main() async {
  group('flutter', () {
    test('factory', () {
      expect(authServiceFlutter.supportsListUsers, isFalse);
      expect(authServiceFlutter.supportsCurrentUser, isTrue);
    });
  });
}
