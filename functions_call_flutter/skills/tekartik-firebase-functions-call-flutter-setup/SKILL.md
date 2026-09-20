---
name: tekartik-firebase-functions-call-flutter-setup
description: >-
  Use when calling Firebase https callable cloud functions from a Flutter app
  with tekartik_firebase_functions_call_flutter:
  firebaseFunctionsCallServiceFlutter, functionsCall(app, options:
  FirebaseFunctionsCallOptions(region: regionBelgium)), callable(name),
  callableFromUri(uri) for 2nd gen functions, FirebaseFunctionsCallableOptions
  (timeout, limitedUseAppCheckToken), FirebaseFunctionsCallableResult data /
  dataAsMap / dataAsText, catching HttpsError and HttpsErrorCode, and the
  package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart
  import on top of cloud_functions.
---

# tekartik_firebase_functions_call_flutter: callables on Flutter

`tekartik_firebase_functions_call_flutter` implements the
`tekartik_firebase_functions_call` client abstraction with
`package:cloud_functions`. Shared code keeps calling
`FirebaseFunctionsCall.callable(...)`; only the app wiring knows about
Flutter.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_functions_call_flutter:
      git:
        url: https://github.com/tekartik/firebase_flutter
        path: functions_call_flutter
  ```
  It brings `tekartik_firebase_functions_call`, `tekartik_firebase_functions`,
  `tekartik_firebase_flutter` and `cloud_functions`; declare explicitly the
  ones you import (`tekartik_firebase_functions` for `HttpsError`).
* Import
  `package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart`.
  It re-exports `package:tekartik_firebase_functions_call/functions_call.dart`
  (`FirebaseFunctionsCall`, `FirebaseFunctionsCallService`,
  `FirebaseFunctionsCallOptions`, `FirebaseFunctionsCallable`,
  `FirebaseFunctionsCallableOptions`, `FirebaseFunctionsCallableResult`,
  `FirebaseFunctionsCallableResultExt`, the region constants and
  `tekartik_firebase/firebase.dart`) and adds exactly one name:
  `firebaseFunctionsCallServiceFlutter`. `HttpsError` / `HttpsErrorCode` are
  *not* re-exported: import
  `package:tekartik_firebase_functions/firebase_functions.dart` for them.
* Create the product from the flutter service and a Flutter app
  (`firebaseFlutter.initializeAppAsync()`, an `assert` fires on any other
  backend):
  `firebaseFunctionsCallServiceFlutter.functionsCall(app, options:
  FirebaseFunctionsCallOptions(region: regionBelgium))`.
  `region` is required; use the exported constants `regionBelgium`,
  `regionUsCentral1`, `regionFrankfurt` or the raw region string of your
  deployment. Instances are cached per `(app.name, region)`, so asking twice
  for the same region returns the same object and several regions can live
  side by side.
* `FirebaseFunctionsCallOptions.baseUri` is ignored on Flutter: the native SDK
  resolves the endpoint itself. Use `callableFromUri` when you need a specific
  url.
* The flutter service keeps its own cache and does not register the product on
  the app, so `FirebaseFunctionsCall.instance` and
  `app.getProduct<FirebaseFunctionsCall>()` do **not** work here: keep the
  `FirebaseFunctionsCall` you created (provider, singleton, injected field).
* `functionsCall.callable('name')` targets a 1st gen callable in the configured
  region; `functionsCall.callableFromUri(Uri.parse('https://...'))` targets a
  2nd gen callable by url (the region of the options is then irrelevant).
  Both accept `options: FirebaseFunctionsCallableOptions(timeout: Duration(...),
  limitedUseAppCheckToken: true)` (defaults: 60 s, `false`).
* Call with `await callable.call<T>(parameters)` and read `result.data`.
  `parameters` must be JSON-compatible (`null`, `String`, `num`, `bool`,
  `List`, `Map` of those); a model object must be converted to a map first.
  `T` is a cast of the decoded response, so use `Map<String, Object?>`,
  `List<Object?>`, `String` or `num`, or read the untyped result through
  `result.dataAsMap` / `result.dataAsMapOrNull` / `result.dataAsText`
  (`FirebaseFunctionsCallableResultExt`).
* Errors: every failure is rethrown as an `HttpsError`. A native
  `FirebaseFunctionsException` keeps its `code` (an `HttpsErrorCode` string
  such as `unauthenticated`, `permission-denied`, `not-found`,
  `failed-precondition`, `deadline-exceeded`, `internal`), its trimmed
  `message` and its `details`; anything else becomes
  `HttpsError(HttpsErrorCode.internal, ...)`. Catch `HttpsError` and compare
  `error.code` with the `HttpsErrorCode` constants; never catch
  `FirebaseFunctionsException` in shared code.
* Auth and App Check tokens are added by the native SDK: sign in with
  `tekartik_firebase_auth_flutter` before calling a function that requires
  `request.auth`.
* Emulator: this package exposes no emulator hook. Get the same native
  instance from `cloud_functions`
  (`FirebaseFunctions.instanceFor(app: app.nativeInstance, region: region)`)
  and call `useFunctionsEmulator(host, port)` on it before the first call.
* `functionsCallObsolete(app, region: ...)` is `@Deprecated`: always use
  `functionsCall(app, options: ...)`.
* Unit tests (`flutter test`) have no native plugin: assert only on the types
  and on your own wrapper, and fake the result with the
  `FirebaseFunctionsCallableResult(data)` factory.

## Examples

### Wiring and a first call

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart';

late FirebaseFunctionsCall functionsCall;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await firebaseFlutter.initializeAppAsync();
  functionsCall = firebaseFunctionsCallServiceFlutter.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var result = await functionsCall.callable('ping').call<String>();
  print('ping: ${result.data}');
  runApp(const Placeholder());
}
```

### Typed call with error handling

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart'
    show HttpsError, HttpsErrorCode;
import 'package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart';

Future<Map<String, Object?>?> getProfile(
  FirebaseFunctionsCall functionsCall,
  String userId,
) async {
  var callable = functionsCall.callable(
    'getProfile',
    options: FirebaseFunctionsCallableOptions(timeout: Duration(seconds: 10)),
  );
  try {
    var result = await callable.call<Map<String, Object?>>({'userId': userId});
    return result.data;
  } on HttpsError catch (e) {
    if (e.code == HttpsErrorCode.notFound) {
      return null;
    }
    if (e.code == HttpsErrorCode.unauthenticated) {
      throw StateError('sign in first');
    }
    rethrow;
  }
}
```

### 2nd gen function called by url

```dart
import 'package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart';

Future<String> callV2(FirebaseFunctionsCall functionsCall, Uri uri) async {
  var callable = functionsCall.callableFromUri(
    uri, // https://<function>-<hash>-<region>.a.run.app
    options: FirebaseFunctionsCallableOptions(limitedUseAppCheckToken: true),
  );
  var result = await callable.call<Object?>({'action': 'refresh'});
  return result.dataAsText;
}
```

### Local functions emulator

```dart
import 'package:cloud_functions/cloud_functions.dart' as native;
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart';

/// Call before the first callable call. [host] is `10.0.2.2` on the android
/// emulator, `localhost` elsewhere.
FirebaseFunctionsCall devFunctionsCall(
  FirebaseApp app, {
  String region = regionBelgium,
  String host = 'localhost',
  int port = 5001,
}) {
  native.FirebaseFunctions.instanceFor(
    app: app.nativeInstance,
    region: region,
  ).useFunctionsEmulator(host, port);
  return firebaseFunctionsCallServiceFlutter.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: region),
  );
}
```

### A thin api client on top of the callables

```dart
import 'package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart';

/// Keep one instance in a provider: the underlying callables are cheap but
/// the FirebaseFunctionsCall must be created once per app and region.
class ApiClient {
  final FirebaseFunctionsCall functionsCall;
  ApiClient(this.functionsCall);

  Future<Map<String, Object?>?> post(String name, Map<String, Object?> data) =>
      functionsCall.callable(name).call<Object?>(data).then((r) => r.dataAsMap);
}
```

## Common mistakes

* Using `FirebaseFunctionsCall.instance` or `app.getProduct<...>()`: the
  flutter service does not register the product on the app.
* Forgetting `options:` / the `region`, or expecting `baseUri` to be honoured.
* Catching `FirebaseFunctionsException`: this package always throws
  `HttpsError`.
* Passing a model object to `call(...)` instead of a JSON map.
* Asking for a `T` that does not match what the function returns (the cast
  throws inside `call`).
