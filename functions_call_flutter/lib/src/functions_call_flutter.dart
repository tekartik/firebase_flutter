import 'package:cloud_functions/cloud_functions.dart' as native;
import 'package:tekartik_firebase/firebase.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'
    show FirebaseAppFlutter;

import 'functions_call.dart';

/// Firebase functions call service flutter
final _firebaseFunctionsCallServiceFlutter =
    FirebaseFunctionsCallServiceFlutter();

/// Firebase functions call service flutter
FirebaseFunctionsCallService get firebaseFunctionsCallServiceFlutter =>
    _firebaseFunctionsCallServiceFlutter;

/// Firebase functions call service flutter
class FirebaseFunctionsCallServiceFlutter
    with FirebaseProductServiceMixin<FirebaseFunctionsCallFlutter>
    implements FirebaseFunctionsCallService {
  @override
  FirebaseFunctionsCallFlutter functionsCall(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppFlutter, 'invalid firebase app type');
      var appFlutter = app as FirebaseAppFlutter;
      if (appFlutter.isDefault!) {
        return FirebaseFunctionsCallFlutter(
            this, native.FirebaseFunctions.instance);
      } else {
        return FirebaseFunctionsCallFlutter(
            this,
            native.FirebaseFunctions.instanceFor(
                app: appFlutter.nativeInstance!));
      }
    });
  }
}

/// Firebase functions call flutter
class FirebaseFunctionsCallFlutter implements FirebaseFunctionsCall {
  /// Service
  final FirebaseFunctionsCallServiceFlutter service;

  /// Native instance
  final native.FirebaseFunctions nativeInstance;

  /// Constructor
  FirebaseFunctionsCallFlutter(this.service, this.nativeInstance);

  @override
  FirebaseFunctionsCallableFlutter callable(String name,
      {FirebaseFunctionsCallableOptions? options}) {
    return FirebaseFunctionsCallableFlutter(
        this,
        nativeInstance.httpsCallable(
          name,
          options: options?.nativeInstance,
        ));
  }
}

extension on FirebaseFunctionsCallableOptions {
  native.HttpsCallableOptions get nativeInstance => native.HttpsCallableOptions(
      timeout: timeout, limitedUseAppCheckToken: limitedUseAppCheckToken);
}

/// Firebase functions callable flutter.
class FirebaseFunctionsCallableFlutter implements FirebaseFunctionsCallable {
  /// Functions call flutter
  final FirebaseFunctionsCallFlutter functionsCallFlutter;

  /// Native instance
  final native.HttpsCallable nativeInstance;

  /// Constructor
  FirebaseFunctionsCallableFlutter(
      this.functionsCallFlutter, this.nativeInstance);

  @override
  Future<FirebaseFunctionsCallableResultFlutter> call<T>(
      [Object? parameters]) async {
    return FirebaseFunctionsCallableResultFlutter(
        await nativeInstance.call<T>(parameters));
  }
}

/// Firebase functions callable result flutter.
class FirebaseFunctionsCallableResultFlutter<T>
    with FirebaseFunctionsCallableResultDefaultMixin<T>
    implements FirebaseFunctionsCallableResult<T> {
  /// Native instance
  final native.HttpsCallableResult nativeInstance;

  /// Constructor
  FirebaseFunctionsCallableResultFlutter(this.nativeInstance);

  @override
  T get data => nativeInstance.data as T;
}
