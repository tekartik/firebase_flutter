# tekartik_firebase_auth_flutter

The Flutter backend of [tekartik_firebase_auth](https://github.com/tekartik/firebase_auth.dart/tree/master/auth),
on top of the FlutterFire `firebase_auth` plugin: shared code uses
`FirebaseAuth`, `User` and `onCurrentUser`, the app plugs this implementation
in.

Platforms of `firebase_auth`: Android, iOS, macOS and web. On Linux and
Windows use `tekartik_firebase_auth_rest` behind the same `FirebaseAuth`; in
tests a local backend (`tekartik_firebase_auth_sdb`, `tekartik_firebase_auth_local`).

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: auth_flutter
```

Initialize the app with [tekartik_firebase_flutter](../firebase_flutter/README.md),
then get the auth once and keep it:

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

late FirebaseAuth auth;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await firebaseFlutter.initializeAppAsync();
  auth = firebaseAuthServiceFlutter.auth(app);
  // Keep the session across page reloads on the web (no-op elsewhere).
  await auth.webSetIndexedDbPersistence();

  auth.onCurrentUser.listen((user) {
    debugPrint('current user: ${user?.uid}');
  });
  runApp(const Placeholder());
}

Future<void> signIn(String email, String password) async {
  var credential = await auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  // currentUser is already the signed in user.
  debugPrint('${credential.user.uid} ${auth.currentUser?.email}');
}
```

## What is supported

* Email/password (`createUserWithEmailAndPassword`,
  `signInWithEmailAndPassword`, `sendPasswordResetEmail`,
  `sendEmailVerification`), anonymous (`signInAnonymously`), `signOut`,
  `reloadCurrentUser`, `currentUser` and `onCurrentUser`, `User.delete()`,
  `User.linkWithCredential` (a `FirebaseAuthEmailPasswordCredential`)
  and the id token (`(user as UserInfoWithIdToken).getIdToken()`).
* Federated providers (Google, Apple...): `signIn(provider)` throws
  `UnsupportedError`; sign in through the native instance
  (`(auth as FirebaseAuthFlutter).nativeInstance.signInWithCredential(...)`),
  `currentUser` follows.
* Admin calls (`listUsers`, `getUser`, `getUserByEmail`, `verifyIdToken`)
  throw `UnsupportedError`: they belong to a server (admin sdk).

## Common pitfalls

* The app must be a Flutter app (`firebaseFlutter`): other apps fail an
  assert.
* Emulator: `await (auth as FirebaseAuthFlutter).useAuthEmulator('localhost', 9099)`
  right after creating the auth, before any sign in (`localhost` is mapped to
  `10.0.2.2` on the Android emulator). The `useFirestoreEmulator` extension
  on `FirebaseAuth` also targets the auth emulator, despite its name.
* Web: without `webSetIndexedDbPersistence()` the session may not survive a
  page reload.

The [tekartik-firebase-auth-flutter-setup skill](skills/tekartik-firebase-auth-flutter-setup/SKILL.md)
has more examples.
