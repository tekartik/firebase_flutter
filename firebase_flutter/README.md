# tekartik_firebase_flutter

The Flutter backend of [tekartik_firebase](https://github.com/tekartik/firebase.dart/tree/master/firebase),
on top of `firebase_core` (FlutterFire): it gives the `FirebaseApp` that the
Flutter product services (firestore, storage, auth, functions call, vertex ai)
attach to, so the shared code only depends on the platform neutral packages.

Runs on the FlutterFire platforms: Android, iOS, macOS, web (and the other
platforms supported by your FlutterFire plugins).

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: firebase_flutter
```

Configure the native project first (`flutterfire configure`: it generates
`firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`
and the web config). Then initialize once, before `runApp`:

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The native configuration; or pass
  // options: firebaseFlutter.wrapOptions(DefaultFirebaseOptions.currentPlatform)
  var app = await firebaseFlutter.initializeAppAsync();
  debugPrint('${app.name} ${app.projectId}');
  runApp(const Placeholder());
}
```

Then get the products from the Flutter services, with this app:

| Product | Package (path in this repo) | Service |
|---|---|---|
| Firestore | `tekartik_firebase_firestore_flutter` (`firestore_flutter`) | `firestoreServiceFlutter.firestore(app)` |
| Storage | `tekartik_firebase_storage_flutter` (`storage_flutter`) | `storageServiceFlutter.storage(app)` |
| Auth | `tekartik_firebase_auth_flutter` (`auth_flutter`) | `firebaseAuthServiceFlutter.auth(app)` |
| Functions call | `tekartik_firebase_functions_call_flutter` (`functions_call_flutter`) | `firebaseFunctionsCallServiceFlutter.functionsCall(app, options: ...)` |

## When to use what

* `firebaseFlutter` (a `FirebaseFlutter`, also a `FirebaseAsync`): type your
  shared entry points as `FirebaseAsync` and use `initializeAppAsync` /
  `appAsync`, Flutter initializes asynchronously.
* `firebaseFlutter.app()` and `initializeApp()` (sync) work once
  `firebase_core` is initialized, for the default app only. They, and
  `appAsync()`, return the same `FirebaseApp` (with its products) each time.
* `firebaseFlutter.wrapOptions(FirebaseOptions)`: the only way to pass
  explicit options.
* `app.nativeInstance`: the `firebase_core` app, for a FlutterFire plugin
  without tekartik wrapper.

## Common pitfalls

* Call `WidgetsFlutterBinding.ensureInitialized()` before
  `initializeAppAsync`.
* A hand built `FirebaseAppOptions` with a project id throws
  (`UnsupportedError`): wrap the FlutterFire options.
* Only the default app: `app(name: ...)` throws.
* `options.toDebugMap()` keeps only the project id and an obfuscated api key:
  log that, never the native options.
* In a `flutter test`, call `setupFirebaseCoreMocks()`
  (`package:firebase_core_platform_interface/test.dart`) before
  `initializeAppAsync()`; use the memory backends (`tekartik_firebase_local`)
  to test your data code.

The [tekartik-firebase-flutter-setup skill](skills/tekartik-firebase-flutter-setup/SKILL.md)
has more examples.
