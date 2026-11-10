# tekartik_firebase_functions_call_flutter

Calls Firebase callable functions from a Flutter app through
`cloud_functions`, behind the `tekartik_firebase_functions_call` interface:
shared code keeps calling `FirebaseFunctionsCall.callable(name).call(...)`,
only the app wiring knows it is Flutter (the http, rest and sim
implementations share the same interface).

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_functions_call_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: functions_call_flutter
  tekartik_firebase_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: firebase_flutter
```

The native Firebase setup of the app (`flutterfire configure`) is required.

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await firebaseFlutter.initializeAppAsync();
  // One instance per app and region: keep it.
  var functionsCall = firebaseFunctionsCallServiceFlutter.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var result = await functionsCall.callable('hello').call<Object?>({
    'name': 'Bob',
  });
  print(result.dataAsText);
}
```

## Platforms

Flutter Android, iOS, macOS and web (the platforms of `cloud_functions`).

## What to know

* `functions_call_flutter.dart` re-exports the functions call API
  (`FirebaseFunctionsCall`, `FirebaseFunctionsCallOptions`,
  `FirebaseFunctionsCallableOptions`, regions); `HttpsError` and
  `HttpsErrorCode` come from `tekartik_firebase_functions`.
* `callable(name)` targets a function of the region of the options,
  `callableFromUri(uri)` a function by url (2nd gen); options: `timeout`
  (60 seconds) and `limitedUseAppCheckToken`.
* Every failure is an `HttpsError` (`code` such as `not-found`,
  `unauthenticated`, `internal`).
* The auth and App Check tokens are added by the native SDK.
* The instances are cached by app name and region, outside the app: they are
  not found with `app.getProduct`, and they outlive `app.delete()` (a new app
  of the same name gets the old instance): keep the instance you created and
  do not delete and re-create the app.
* No emulator hook: call `useFunctionsEmulator` on the native
  `FirebaseFunctions.instanceFor(app: app.nativeInstance, region: region)`
  before the first call.

The [tekartik-firebase-functions-call-flutter-setup skill](skills/tekartik-firebase-functions-call-flutter-setup/SKILL.md)
has more examples (typed calls and errors, 2nd gen url, emulator).
