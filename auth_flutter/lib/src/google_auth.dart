import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_flutter/src/auth_flutter.dart';

import 'import.dart';

var _debug = false; // devWarning(true);

/// Google auth provider.
abstract class GoogleAuthProvider extends AuthProvider {
  /// Default constructor
  factory GoogleAuthProvider() => GoogleAuthProviderImpl();

  /// Native instance
  native.GoogleAuthProvider get nativeAuthProvider;

  /// Adds additional OAuth 2.0 scopes that you want to request (typically email)
  void addScope(String scope);
}

/// Google auth provider implementation.
class GoogleAuthProviderImpl implements GoogleAuthProvider {
  /// Default constructor
  GoogleAuthProviderImpl() {
    nativeAuthProvider = native.GoogleAuthProvider();
  }

  /// The native instance
  @override
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

/// Google auth extension.
extension AuthFlutterImplGoogle on Auth {
  /// Firebase native auth
  native.FirebaseAuth get firebaseNativeAuth =>
      (this as AuthFlutterImpl).nativeAuth;

  /// Native google sign in
  Future<AuthSignInResult> nativeGoogleSignIn(
    GoogleAuthProvider provider,
  ) async {
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
    final credentials = (await firebaseNativeAuth.signInWithCredential(
      credential,
    ));
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

  /// Web google sign in
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
      var credentials = await firebaseNativeAuth.signInWithPopup(
        googleProvider,
      );
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
    // return await FirebaseAuth.ins.instance.signInWithRedirect(googleProvider);
  }
}
