// ignore_for_file: implementation_imports
import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:flutter/foundation.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';

import 'package:tekartik_firebase_flutter/firebase_flutter.dart'
    as firebase_flutter;

import 'import.dart' as common;
import 'import.dart';

/// Flutter impl
class AuthServiceFlutterImpl
    with common.FirebaseProductServiceMixin<FirebaseAuth>, AuthServiceMixin
    implements AuthServiceFlutter {
  @override
  FirebaseAuthFlutter auth(common.App app) {
    return getInstance(app, () {
      assert(
        app is firebase_flutter.FirebaseAppFlutter,
        'invalid firebase app type',
      );
      final appFlutter = app as firebase_flutter.FirebaseAppFlutter;
      return AuthFlutterImpl(
        this,
        appFlutter,
        native.FirebaseAuth.instanceFor(app: appFlutter.nativeInstance!),
      );
    });
  }

  @override
  bool get supportsListUsers => false;

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceFlutter? _firebaseAuthServiceFlutter;

/// The flutter auth service
AuthServiceFlutter get authService =>
    _firebaseAuthServiceFlutter ??= AuthServiceFlutterImpl();

/// Wearp native user.
User? wrapUser(native.User? nativeUser) =>
    nativeUser != null ? _UserFlutterImpl(nativeUser) : null;

/// Flutter impl
class AuthCredentialFlutter implements AuthCredential {
  /// The native instance
  final native.AuthCredential nativeInstance;

  /// Constructor
  AuthCredentialFlutter(this.nativeInstance);

  @override
  String get providerId => nativeInstance.providerId;
}

/// Flutter impl
class UserCredentialFlutter implements UserCredential {
  /// The native instance
  final native.UserCredential nativeInstance;
  User? _user;

  /// Constructor
  UserCredentialFlutter(this.nativeInstance);

  @override
  AuthCredential get credential =>
      AuthCredentialFlutter(nativeInstance.credential!);

  @override
  User get user => _user ??= wrapUser(nativeInstance.user)!;

  @override
  String toString() => 'UserCredentialFlutter($user)';
}

class _UserFlutterImpl implements User, UserInfoWithIdToken {
  final native.User nativeInstance;

  _UserFlutterImpl(this.nativeInstance);

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
  String? get providerId => null; // no longer supported - nativeInstance.providerId;

  @override
  String get uid => nativeInstance.uid;

  @override
  String toString() =>
      '$uid${displayName != null ? ' $displayName' : ''} ($email)';

  @override
  Future<String> getIdToken({bool? forceRefresh}) async =>
      (await nativeInstance.getIdToken(forceRefresh ?? false))!;
}

/// Flutter impl
class AuthFlutterImpl
    with FirebaseAppProductMixin<FirebaseAuth>, FirebaseAuthMixin
    implements FirebaseAuthFlutter {
  /// The service
  final AuthServiceFlutter serviceFlutter;

  /// The native instance
  /// Prefer using nativeInstance
  final native.FirebaseAuth nativeAuth;

  StreamSubscription? _onAuthStateChangedSubscription;

  void _listenToCurrentUser() {
    _onAuthStateChangedSubscription?.cancel();
    _onAuthStateChangedSubscription = nativeAuth.authStateChanges().listen((
      user,
    ) {
      currentUserAdd(wrapUser(user));
    });
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    var userCredential = await nativeAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserCredentialFlutter(userCredential);
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    var userCredential = await nativeAuth.signInAnonymously();
    return UserCredentialFlutter(userCredential);
  }

  /// App
  final firebase_flutter.FirebaseAppFlutter appFlutter;

  /// Constructor
  AuthFlutterImpl(this.serviceFlutter, this.appFlutter, this.nativeAuth) {
    _listenToCurrentUser();
  }

  @override
  Future<User?> reloadCurrentUser() async {
    await (nativeAuth.currentUser)?.reload();
    _listenToCurrentUser();
    return wrapUser((nativeAuth.currentUser));
  }

  @override
  void dispose() {
    _onAuthStateChangedSubscription?.cancel();
    super.dispose();
  }

  @override
  Future signOut() async {
    await nativeAuth.signOut();
  }

  @override
  Future<AuthSignInResult> signIn(
    AuthProvider authProvider, {
    AuthSignInOptions? options,
  }) async {
    throw UnsupportedError('Unsupported provider ${authProvider.providerId}');
  }

  @override
  String toString() => 'AuthFlutter(${nativeAuth.app.name})';

  @override
  common.FirebaseApp get app => appFlutter;

  @override
  FirebaseAuthService get service => serviceFlutter;

  /// Prefer nativeInstance
  @override
  native.FirebaseAuth get nativeInstance => nativeAuth;
}

/// Flutter impl
class AuthSignInResultFlutter implements AuthSignInResult {
  /// The native instance
  final native.UserCredential nativeUserCredentials;

  /// Constructor
  AuthSignInResultFlutter(this.nativeUserCredentials);

  @override
  UserCredential? get credential =>
      UserCredentialFlutter(nativeUserCredentials);

  @override
  bool get hasInfo => true;
}

/// Helpers
extension FirebaseAuthFlutterExtension on Auth {
  /// Native instance
  native.FirebaseAuth get nativeInstance =>
      (this as AuthFlutterImpl).nativeAuth;

  /// Web only
  Future<void> webSetIndexedDbPersistence() async {
    if (kIsWeb && this is AuthFlutterImpl) {
      await (this as AuthFlutterImpl).nativeAuth.setPersistence(
        native.Persistence.LOCAL,
      ); // indexedDB
    }
  }

  /// Auth flutter
  AuthFlutter get flutter => this as AuthFlutter;
}
