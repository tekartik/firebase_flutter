import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_flutter/src/auth_flutter.dart';

import 'import.dart';

var _debug = false; // devWarning(true);

abstract class GoogleAuthProvider extends AuthProvider {
  factory GoogleAuthProvider() => GoogleAuthProviderImpl();

  void addScope(String scope);
}

class GoogleAuthProviderImpl implements GoogleAuthProvider {
  GoogleAuthProviderImpl() {
    nativeAuthProvider = native.GoogleAuthProvider();
  }

  late native.GoogleAuthProvider nativeAuthProvider;

  /// Adds additional OAuth 2.0 scopes that you want to request from the
  /// authentication provider.
  @override
  void addScope(String scope) {
    nativeAuthProvider = nativeAuthProvider.addScope(scope);
  }

  @override
  String get providerId => nativeAuthProvider.providerId;
}

google_sign_in.GoogleSignIn? _googleSignIn;

extension AuthFlutterImplGoogle on Auth {
  native.FirebaseAuth get firebaseNativeAuth =>
      (this as AuthFlutterImpl).nativeAuth;
  Future<AuthSignInResult> nativeGoogleSignIn(
      GoogleAuthProvider provider) async {
    late native.AuthCredential credential;
    if (_debug) {
      if (kDebugMode) {
        print('Google sign in');
      }
    }
    _googleSignIn ??= google_sign_in.GoogleSignIn();
    final googleUser = await _googleSignIn!.signIn();
    if (_debug) {
      if (kDebugMode) {
        print('Google signed in $googleUser');
      }
    }
    if (googleUser == null) {
      throw StateError('Sign-in failed');
    }
    final googleAuth = await googleUser.authentication;

    credential = native.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final credentials =
        (await firebaseNativeAuth.signInWithCredential(credential));
    return AuthSignInResultFlutter(credentials);
  }

  /// Google only...
  Future<AuthSignInResult> googleSignIn(GoogleAuthProvider provider) async {
    if (!kIsWeb) {
      return nativeGoogleSignIn(provider);
      /*
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
          (await firebaseNativeAuth.signInWithCredential(credential)).user;
      return wrapUser(nativeUser);

       */
    } else {
      return await webGoogleSignIn(provider);
    }
  }

  Future<AuthSignInResult> webGoogleSignIn(GoogleAuthProvider provider) async {
    // Create a new provider
    var googleProvider = native.GoogleAuthProvider();

    //googleProvider
    //    .addScope('https://www.googleapis.com/auth/contacts.readonly');
    //googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    if (_debug) {
      if (kDebugMode) {
        print('Google signing in web');
      }
    }
    try {
      // Once signed in, return the UserCredential
      var credentials =
          await native.FirebaseAuth.instance.signInWithPopup(googleProvider);
      if (_debug) {
        if (kDebugMode) {
          print('Google signed in $credentials');
        }
      }
      return AuthSignInResultFlutter(credentials);
    } catch (e) {
      if (kDebugMode) {
        print('sign in failed $e');
      }
      rethrow;
    }
    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
  }
}
