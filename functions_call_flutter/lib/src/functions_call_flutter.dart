import 'package:cloud_functions/cloud_functions.dart' as native;
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'
    show FirebaseAppFlutter;
import 'package:tekartik_firebase_functions_call/functions_call.dart';

/// Firebase functions call service flutter
final _firebaseFunctionsCallServiceFlutter =
    FirebaseFunctionsCallServiceFlutter();

/// Firebase functions call service flutter
FirebaseFunctionsCallService get firebaseFunctionsCallServiceFlutter =>
    _firebaseFunctionsCallServiceFlutter;

/// Firebase functions call service flutter
class FirebaseFunctionsCallServiceFlutter
    with
        FirebaseProductServiceMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {
  /// Most implementation need a single instance, keep it in memory!
  final _instances = <String, FirebaseFunctionsCallFlutter>{};

  FirebaseFunctionsCallFlutter _getInstance(App app, String region,
      FirebaseFunctionsCallFlutter Function() createIfNotFound) {
    var key = '${app.name}_$region';
    var instance = _instances[key];
    if (instance == null) {
      var newInstance = instance = createIfNotFound();
      _instances[key] = newInstance;
    }
    return instance;
  }

  @override
  FirebaseFunctionsCallFlutter functionsCall(App app,
      {required String region, Uri? baseUri}) {
    return _getInstance(app, region, () {
      assert(app is FirebaseAppFlutter, 'invalid firebase app type');
      var appFlutter = app as FirebaseAppFlutter;

      return FirebaseFunctionsCallFlutter(
          this,
          native.FirebaseFunctions.instanceFor(
              app: appFlutter.nativeInstance!, region: region));
    });
  }
}

/// Firebase functions call flutter
class FirebaseFunctionsCallFlutter
    with FirebaseAppProductMixin<FirebaseFunctionsCall>
    implements FirebaseFunctionsCall {
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
