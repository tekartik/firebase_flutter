// ignore_for_file: implementation_imports
import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';
import 'package:tekartik_firebase_auth_flutter/src/google_auth.dart';
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'
    as firebase_flutter;

import 'import.dart' as common;
import 'import.dart';

class AuthServiceFlutterImpl
    with AuthServiceMixin
    implements AuthServiceFlutter {
  @override
  Auth auth(common.App app) {
    return getInstance(app, () {
      assert(app is firebase_flutter.FirebaseAppFlutter,
          'invalid firebase app type');
      final appFlutter = app as firebase_flutter.FirebaseAppFlutter;
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

/// Flutter impl
class AuthCredentialFlutter implements AuthCredential {
  final native.AuthCredential nativeInstance;

  AuthCredentialFlutter(this.nativeInstance);
  @override
  String get providerId => nativeInstance.providerId;
}

/// Flutter impl
class UserCredentialFlutter implements UserCredential {
  final native.UserCredential nativeInstance;
  User? _user;

  UserCredentialFlutter(this.nativeInstance);
  @override
  AuthCredential get credential =>
      AuthCredentialFlutter(nativeInstance.credential!);

  @override
  User get user => _user ??= wrapUser(nativeInstance.user)!;
}

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
      (await nativeInstance.getIdToken(forceRefresh ?? false))!;
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

  Future<AuthSignInResult?> nativeGoogleSignIn() async {
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
    final credentials = (await nativeAuth.signInWithCredential(credential));
    return AuthSignInResultFlutter(credentials);
  }

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
  Future<AuthSignInResult> signIn(AuthProvider authProvider,
      {AuthSignInOptions? options}) async {
    //devPrint('signIn($authProvider, $options)');
    if (authProvider is GoogleAuthProvider) {
      //devPrint('google');
      var nativeAuthProvider =
          (authProvider as GoogleAuthProviderImpl).nativeAuthProvider;

      if (options is AuthSignInOptionsWeb) {
        if (options.isPopup) {
          //devPrint('popup');
          var credentials =
              await nativeAuth.signInWithPopup(nativeAuthProvider);
          //devPrint('popup done');
          return AuthSignInResultFlutter(credentials);
        } else {
          //devPrint('redirect');
          await nativeAuth.signInWithRedirect(nativeAuthProvider);
          //devPrint('redirect done');
          throw StateError('Sign in result sent later');
          //return AuthSignInResultFlutter(credentials);
        }
      } else {
        var credentials =
            await nativeAuth.signInWithProvider(nativeAuthProvider);
        return AuthSignInResultFlutter(credentials);
      }
    }
    throw UnsupportedError('Unsupported provider ${authProvider.providerId}');
  }

  @override
  String toString() => 'AuthFlutter(${nativeAuth.app.name})';
}

class AuthSignInResultFlutter implements AuthSignInResult {
  final native.UserCredential nativeUserCredentials;

  AuthSignInResultFlutter(this.nativeUserCredentials);

  @override
  UserCredential? get credential =>
      UserCredentialFlutter(nativeUserCredentials);

  @override
  bool get hasInfo => true;
}
