// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'
    as firebase_flutter;

import 'import.dart' as common;

class AuthServiceFlutterImpl
    with AuthServiceMixin
    implements AuthServiceFlutter {
  @override
  Auth auth(common.App app) {
    return getInstance(app, () {
      assert(app is firebase_flutter.AppFlutter, 'invalid firebase app type');
      final appFlutter = app as firebase_flutter.AppFlutter;
      return AuthFlutterImpl(
          native.FirebaseAuth.instanceFor(app: appFlutter.nativeInstance!));
    });
  }

  @override
  bool get supportsListUsers => false;

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceFlutter? _firebaseAuthServiceFlutter;

AuthServiceFlutter get authService =>
    _firebaseAuthServiceFlutter ??= AuthServiceFlutterImpl();

UserFlutterImpl? wrapUser(native.User? nativeUser) =>
    nativeUser != null ? UserFlutterImpl(nativeUser) : null;

class UserFlutterImpl implements User, UserInfoWithIdToken {
  final native.User nativeInstance;

  UserFlutterImpl(this.nativeInstance);

  @override
  String? get displayName => nativeInstance.displayName;

  @override
  String? get email => nativeInstance.email;

  @override
  bool get emailVerified => nativeInstance.emailVerified;

  @override
  bool get isAnonymous => nativeInstance.isAnonymous;

  @override
  String? get phoneNumber => nativeInstance.phoneNumber;

  @override
  String? get photoURL => nativeInstance.photoURL;

  @override
  String? get providerId =>
      null; // no longer supported - nativeInstance.providerId;

  @override
  String get uid => nativeInstance.uid;

  @override
  String toString() => '$displayName ($email)';

  @override
  Future<String> getIdToken({bool? forceRefresh}) async =>
      await nativeInstance.getIdToken(forceRefresh ?? false);
}

class AuthFlutterImpl with AuthMixin implements AuthFlutter {
  final native.FirebaseAuth nativeAuth;

  StreamSubscription? onAuthStateChangedSubscription;

  void _listenToCurrentUser() {
    onAuthStateChangedSubscription?.cancel();
    onAuthStateChangedSubscription =
        nativeAuth.authStateChanges().listen((user) {
      currentUserAdd(wrapUser(user));
    });
  }

  AuthFlutterImpl(this.nativeAuth) {
    _listenToCurrentUser();
  }

  @override
  Future<User?> reloadCurrentUser() async {
    await (nativeAuth.currentUser)?.reload();
    _listenToCurrentUser();
    return wrapUser((nativeAuth.currentUser));
  }

  @override
  Future close(common.App? app) async {
    await super.close(app);
    await onAuthStateChangedSubscription?.cancel();
  }

  google_sign_in.GoogleSignIn? _googleSignIn;

  /// Google only...
  @override
  Future<User?> googleSignIn() async {
    if (!kIsWeb) {
      late native.AuthCredential credential;
      _googleSignIn ??= google_sign_in.GoogleSignIn();
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        return null;
      }
      final googleAuth = await googleUser.authentication;

      credential = native.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final nativeUser =
          (await nativeAuth.signInWithCredential(credential)).user;
      return wrapUser(nativeUser);
    } else {
      var userCredentials = await webSignInWithGoogle();
      final nativeUser = userCredentials.user;
      return wrapUser(nativeUser);
    }
  }

  Future<native.UserCredential> webSignInWithGoogle() async {
    // Create a new provider
    var googleProvider = native.GoogleAuthProvider();

    //googleProvider
    //    .addScope('https://www.googleapis.com/auth/contacts.readonly');
    //googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    // Once signed in, return the UserCredential
    return await native.FirebaseAuth.instance.signInWithPopup(googleProvider);

    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
  }

  @override
  Future signOut() async {
    await nativeAuth.signOut();
  }

  @override
  String toString() => 'AuthFlutter(${nativeAuth.app.name})';
}
