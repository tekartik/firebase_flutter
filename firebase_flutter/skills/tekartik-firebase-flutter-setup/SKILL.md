---
name: tekartik-firebase-flutter-setup
description: >-
  Use when running tekartik_firebase code inside a Flutter app (android, ios,
  web, macos, linux desktop via firebase_core) with tekartik_firebase_flutter:
  the firebaseFlutter / firebaseFlutterAsync getters, FirebaseFlutter,
  initializeAppAsync, appAsync, FirebaseFlutterExtension.wrapOptions to convert
  a firebase_core FirebaseOptions (DefaultFirebaseOptions.currentPlatform) into
  FirebaseAppOptions, FirebaseAppFlutter / FirebaseAppFlutterExtension
  nativeInstance, the package:tekartik_firebase_flutter/firebase_flutter.dart
  import, and wiring the flutter product services (firestore, storage, auth,
  functions call, vertex ai) on top of the app.
---

# tekartik_firebase_flutter: the Flutter implementation

`tekartik_firebase_flutter` implements the `tekartik_firebase` abstraction on
top of `package:firebase_core` (the FlutterFire plugin). It is the single entry
point of a Flutter app: get the `FirebaseApp` here, then hand it to the
`*_flutter` product packages (firestore, storage, auth, functions call,
vertex ai) so all shared code keeps depending on the abstractions only.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_flutter:
      git:
        url: https://github.com/tekartik/firebase_flutter
        path: firebase_flutter
      version: '>=0.7.2'
  ```
  It brings `tekartik_firebase` (repo `firebase.dart`, `path: firebase`) and
  `firebase_core`; declare either explicitly when you import it directly.
* Single import: `package:tekartik_firebase_flutter/firebase_flutter.dart`. It
  re-exports `package:tekartik_firebase/firebase.dart` (`Firebase`,
  `FirebaseAsync`, `FirebaseApp`/`App`, `FirebaseAppOptions`/`AppOptions`,
  `firebaseAppNameDefault`) and adds `firebaseFlutter`, `firebaseFlutterAsync`,
  `FirebaseFlutter`, `FirebaseAppFlutter`, `FirebaseFlutterExtension` and
  `FirebaseAppFlutterExtension`. Never import
  `package:tekartik_firebase_flutter/src/...`.
* `firebaseFlutter` is a lazily created singleton of type `FirebaseFlutter`
  (`implements FirebaseAsync, Firebase`). Never construct it: the constructor
  is private. `firebaseFlutterAsync` is a compatibility alias returning the
  very same object; prefer `firebaseFlutter` in new code.
* Native setup first: run `flutterfire configure` (generates
  `firebase_options.dart`, `google-services.json`,
  `GoogleService-Info.plist`, and the web config). Nothing in this package
  registers a project by itself.
* Initialize once, asynchronously, before `runApp`:
  `WidgetsFlutterBinding.ensureInitialized();` then
  `await firebaseFlutter.initializeAppAsync()`. With no `options` it calls
  `Firebase.initializeApp()` of `firebase_core`, i.e. uses the native platform
  configuration; the returned `FirebaseApp.options` is the *native* options
  wrapped back.
* To pass explicit options, always wrap the FlutterFire ones:
  `firebaseFlutter.initializeAppAsync(options: firebaseFlutter.wrapOptions(DefaultFirebaseOptions.currentPlatform))`.
  `wrapOptions` (extension `FirebaseFlutterExtension` on `Firebase`) is the
  only supported way: a hand-built `FirebaseAppOptions` with a non-null
  `projectId` currently throws `'not supported yet'`, and one with a null
  `projectId` is ignored (falls back to the platform configuration).
* `initializeApp()` (sync) only works when `firebase_core` is already
  initialized and only for the default app (it wraps
  `firebase_core.Firebase.app()`); anything with `options` or `name` throws.
  In shared code type the entry point as `FirebaseAsync` and use
  `initializeAppAsync` / `appAsync`.
* Only the default app is supported: `app(name: ...)` with a non-null name
  throws `UnsupportedError`, and `appAsync(name:)` just re-initializes the
  default app. Do not design around multiple named apps on Flutter.
* `firebaseFlutter.isLocal` is `false` and `app.hasAdminCredentials` is
  `false`: never expect admin/service-account behaviour here, and use
  `tekartik_firebase_local` + the memory product services for unit tests.
* Escape hatch to FlutterFire: `app.nativeInstance` (extension
  `FirebaseAppFlutterExtension` on `FirebaseApp`) returns the
  `firebase_core.FirebaseApp`, for plugins that have no tekartik wrapper.
  `FirebaseAppFlutter` is the interface behind it (`nativeInstance`,
  `isDefault`); cast only when you must.
* `await app.delete()` closes the registered tekartik services then deletes
  the native app. Deleting the default app is rejected by `firebase_core`, so
  in practice never delete the app of a running Flutter app.
* Products are obtained from the flutter service of each product package and
  never from the app: `firestoreServiceFlutter.firestore(app)`
  (`tekartik_firebase_firestore_flutter`), `storageServiceFlutter.storage(app)`
  (`tekartik_firebase_storage_flutter`), `authServiceFlutter.auth(app)`
  (`tekartik_firebase_auth_flutter`),
  `firebaseFunctionsCallServiceFlutter.functionsCall(app)`
  (`tekartik_firebase_functions_call_flutter`).
* Tests: `flutter test` runs without a native binding, so
  `initializeAppAsync()` fails there. Unit-test only the pure parts
  (`wrapOptions`, `isLocal`); test real initialization in an
  `integration_test` on a device or emulator.
* `AppFlutter` is a deprecated typedef of `FirebaseAppFlutter` and is not
  exported by the public library: use `FirebaseAppFlutter`.

## Examples

### Application startup

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Uses google-services.json / GoogleService-Info.plist / web config.
  var app = await firebaseFlutter.initializeAppAsync();
  print('firebase app ${app.name} project ${app.projectId}');
  runApp(const Placeholder());
}
```

### Explicit options generated by `flutterfire configure`

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

/// [nativeOptions] is typically `DefaultFirebaseOptions.currentPlatform`
/// from the generated `firebase_options.dart`.
Future<FirebaseApp> initApp(FirebaseOptions nativeOptions) async {
  WidgetsFlutterBinding.ensureInitialized();
  var options = firebaseFlutter.wrapOptions(nativeOptions);
  return await firebaseFlutter.initializeAppAsync(options: options);
}
```

### Shared code takes the abstraction, main picks flutter

```dart
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

/// Shared code: no flutter, no backend dependency.
Future<String> readProjectId(FirebaseAsync firebase) async {
  var app = await firebase.appAsync();
  return app.projectId;
}

/// Flutter side.
Future<String> flutterProjectId() => readProjectId(firebaseFlutter);
```

### Reaching the native firebase_core app

```dart
import 'package:firebase_core/firebase_core.dart' as core;
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

/// For FlutterFire plugins that have no tekartik wrapper yet.
core.FirebaseApp nativeAppOf(FirebaseApp app) => app.nativeInstance;

bool isDefaultApp(FirebaseApp app) =>
    (app as FirebaseAppFlutter).isDefault ?? false;
```

### Unit test of the option wrapping (no native binding needed)

```dart
import 'package:firebase_core/firebase_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

void main() {
  test('wrapOptions', () {
    var options = firebaseFlutter.wrapOptions(
      const core.FirebaseOptions(
        projectId: 'test',
        apiKey: 'api',
        appId: 'app',
        messagingSenderId: 'sender',
      ),
    );
    expect(options.projectId, 'test');
    expect(firebaseFlutter.isLocal, isFalse);
  });
}
```

## Common mistakes

* Calling `initializeAppAsync` before `WidgetsFlutterBinding.ensureInitialized()`.
* Building a `FirebaseAppOptions` by hand instead of
  `firebaseFlutter.wrapOptions(...)` (throws `'not supported yet'`).
* Using the sync `initializeApp` / `app` in code shared with other backends.
* Expecting named apps: only the default app exists on Flutter.
* Calling `initializeAppAsync()` in a plain `flutter test` unit test.
