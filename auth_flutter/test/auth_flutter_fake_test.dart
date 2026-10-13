// Checks with fakes of the plugin classes (no device).
// ignore_for_file: depend_on_referenced_packages, subtype_of_sealed_class
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_auth_flutter/src/auth_flutter.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

class _FakeApp implements FirebaseAppFlutter {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUser implements native.User {
  @override
  final String uid;

  _FakeUser(this.uid);

  @override
  bool get isAnonymous => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUserCredential implements native.UserCredential {
  @override
  final native.User? user;

  _FakeUserCredential(this.user);

  @override
  native.AuthCredential? get credential => null;

  @override
  native.AdditionalUserInfo? get additionalUserInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Like MethodChannelFirebaseAuth: the native current user changes right
/// away, the authStateChanges event comes later.
class _FakeAuth implements native.FirebaseAuth {
  final controller = StreamController<native.User?>.broadcast();
  @override
  native.User? currentUser = _FakeUser('u1');

  void _later(native.User? user) =>
      Timer(const Duration(milliseconds: 10), () => controller.add(user));

  @override
  Stream<native.User?> authStateChanges() => controller.stream;

  @override
  Future<void> signOut() async {
    currentUser = null;
    _later(null);
  }

  @override
  Future<native.UserCredential> signInAnonymously() async {
    var user = currentUser = _FakeUser('u2');
    _later(user);
    return _FakeUserCredential(user);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('auth_flutter_fake', () {
    test('currentUser right after sign out and sign in', () async {
      var nativeAuth = _FakeAuth();
      var auth = AuthFlutterImpl(
        AuthServiceFlutterImpl(),
        _FakeApp(),
        nativeAuth,
      );
      nativeAuth.controller.add(nativeAuth.currentUser);
      await Future<void>.delayed(Duration.zero);
      expect(auth.currentUser?.uid, 'u1');
      await auth.signOut();
      expect(auth.currentUser, isNull);
      // Let the later native sign out event arrive.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(auth.currentUser, isNull);
      var credential = await auth.signInAnonymously();
      expect(auth.currentUser?.uid, 'u2');
      expect(credential.user.uid, 'u2');
      // No credential from the plugin.
      expect(credential.credential.providerId, 'anonymous');
      expect(auth.currentUser?.providerId, 'firebase');
      var events = <String?>[];
      var subscription = auth.onCurrentUser.listen(
        (user) => events.add(user?.uid),
      );
      // The later native events do not add the same user again.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(auth.currentUser?.uid, 'u2');
      expect(events, ['u2']);
      await subscription.cancel();
    });
  });
}
