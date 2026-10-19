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
    implements FirebaseAuthServiceFlutter {
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

/// The credential of a sign in without one from the plugin (FlutterFire
/// gives none for email/password or anonymous sign in).
class _AuthCredentialNoneFlutter implements AuthCredential {
  @override
  final String providerId;

  _AuthCredentialNoneFlutter(this.providerId);
}

/// Flutter impl
class UserCredentialFlutter implements UserCredential {
  /// The native instance
  final native.UserCredential nativeInstance;
  User? _user;

  /// The auth that signed in, to keep its current user up to date.
  AuthFlutterImpl? _auth;

  /// Constructor
  UserCredentialFlutter(this.nativeInstance);

  @override
  AuthCredential get credential {
    var nativeCredential = nativeInstance.credential;
    if (nativeCredential != null) {
      return AuthCredentialFlutter(nativeCredential);
    }
    return _AuthCredentialNoneFlutter(
      nativeInstance.additionalUserInfo?.providerId ??
          (nativeInstance.user?.isAnonymous ?? false
              ? 'anonymous'
              : 'password'),
    );
  }

  @override
  User get user =>
      _user ??= _UserFlutterImpl(nativeInstance.user!).._auth = _auth;

  @override
  String toString() => 'UserCredentialFlutter($user)';
}

class _UserFlutterImpl
    with FirebaseUserMixin
    implements User, UserInfoWithIdToken {
  final native.User nativeInstance;

  /// The auth of the user, to update its current user on delete.
  AuthFlutterImpl? _auth;

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

  /// 'firebase', as the native user gave before firebase_auth dropped it.
  @override
  String? get providerId => 'firebase';

  @override
  String get uid => nativeInstance.uid;

  @override
  String toString() =>
      '$uid${displayName != null ? ' $displayName' : ''} ($email)';

  @override
  Future<String> getIdToken({bool? forceRefresh}) async =>
      (await nativeInstance.getIdToken(forceRefresh ?? false))!;

  @override
  common.Future<void> delete() async {
    await nativeInstance.delete();
    _auth?._addNativeCurrentUser();
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    var userCredential = await nativeInstance.linkWithCredential(
      _nativeCredential(credential),
    );
    // Same uid: authStateChanges does not fire, the linked user is added
    // again.
    var auth = _auth;
    auth?._addCurrentUser(auth.nativeAuth.currentUser, force: true);
    return UserCredentialFlutter(userCredential).._auth = auth;
  }
}

/// The native credential of [credential], a flutter or an email and password
/// one.
native.AuthCredential _nativeCredential(AuthCredential credential) {
  if (credential is AuthCredentialFlutter) {
    return credential.nativeInstance;
  }
  if (credential is FirebaseAuthEmailPasswordCredential) {
    return native.EmailAuthProvider.credential(
      email: credential.email,
      password: credential.password,
    );
  }
  throw ArgumentError.value(
    credential,
    'credential',
    'Unsupported ${credential.providerId} credential',
  );
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

  /// Use emulator
  Future<void> nativeUseEmulator(String host, int port) {
    /*
    nativeAuth.settings = const Settings(
      host: 'localhost:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );*/

    return nativeAuth.useAuthEmulator(host, port, automaticHostMapping: true);
  }

  void _listenToCurrentUser() {
    _onAuthStateChangedSubscription?.cancel();
    _onAuthStateChangedSubscription = nativeAuth.authStateChanges().listen((
      user,
    ) {
      _addCurrentUser(user);
    });
  }

  /// True once a current user (or null) has been added.
  var _currentUserAdded = false;

  /// The uid of the last current user added.
  String? _currentUserUid;

  /// Adds [user] as the current user, unless it is the one already added
  /// ([force] to add it again, for a reload).
  void _addCurrentUser(native.User? user, {bool force = false}) {
    if (!force && _currentUserAdded && _currentUserUid == user?.uid) {
      return;
    }
    _currentUserAdded = true;
    _currentUserUid = user?.uid;
    currentUserAdd(
      user == null ? null : (_UserFlutterImpl(user).._auth = this),
    );
  }

  /// The native current user added right away: the native state changes on
  /// sign in, sign out or delete, the authStateChanges event comes later.
  void _addNativeCurrentUser() => _addCurrentUser(nativeAuth.currentUser);

  UserCredentialFlutter _signedIn(native.UserCredential userCredential) {
    _addNativeCurrentUser();
    return UserCredentialFlutter(userCredential).._auth = this;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    var userCredential = await nativeAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return _signedIn(userCredential);
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

    return _signedIn(userCredential);
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    var userCredential = await nativeAuth.signInAnonymously();

    return _signedIn(userCredential);
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
    // The reloaded user (same uid, new info).
    _addCurrentUser(nativeAuth.currentUser, force: true);
    return currentUser;
  }

  @override
  Future<void> sendEmailVerification() async {
    await nativeAuth.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await nativeAuth.sendPasswordResetEmail(email: email);
  }

  @override
  void dispose() {
    _onAuthStateChangedSubscription?.cancel();
    super.dispose();
  }

  @override
  Future signOut() async {
    await nativeAuth.signOut();
    _addNativeCurrentUser();
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

  AuthFlutterImpl get _impl => (this as AuthFlutterImpl);

  /// Use firestore emulator
  Future<void> useFirestoreEmulator(String host, int port) {
    return _impl.nativeUseEmulator(host, port);
  }

  /// Auth flutter
  AuthFlutter get flutter => this as AuthFlutter;
}

/// Helpers
extension FirebaseAuthFlutterImplExtension on FirebaseAuthFlutter {
  AuthFlutterImpl get _impl => (this as AuthFlutterImpl);

  /// Use firestore emulator
  Future<void> useAuthEmulator(String host, int port) {
    return _impl.useFirestoreEmulator(host, port);
  }
}
