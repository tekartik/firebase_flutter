import 'package:cloud_functions/cloud_functions.dart' as native;
import 'package:tekartik_common_utils/common_utils_import.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_call/functions_call_mixin.dart';

import 'functions_call_flutter.dart';

/// Firebase functions callable flutter.
class FirebaseFunctionsCallableFlutter
    with FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallable {
  @protected
  /// Constructor
  factory FirebaseFunctionsCallableFlutter(
    FirebaseFunctionsCallFlutter functionsCallFlutter,

    String name,
    native.HttpsCallable nativeInstance,
  ) => _FirebaseFunctionsCallableFlutter(
    functionsCallFlutter,
    name,
    nativeInstance,
  );
}

/// Firebase functions callable flutter.
class _FirebaseFunctionsCallableFlutter
    with FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallableFlutter {
  /// Functions call flutter
  final FirebaseFunctionsCallFlutter functionsCallFlutter;

  /// Native instance
  final native.HttpsCallable nativeInstance;

  @override
  final String name;

  /// Constructor
  _FirebaseFunctionsCallableFlutter(
    this.functionsCallFlutter,
    this.name,
    this.nativeInstance,
  );

  @override
  Future<FirebaseFunctionsCallableResultFlutter<T>> call<T>([
    Object? parameters,
  ]) async {
    try {
      return FirebaseFunctionsCallableResultFlutter(
        await nativeInstance.call<T>(parameters),
      );
    } catch (e) {
      if (e is native.FirebaseFunctionsException) {
        throw HttpsErrorFlutter(e);
      }
      throw HttpsError(HttpsErrorCode.internal, '$e', e);
    }
  }
}

/// Private extension
extension FirebaseFunctionsCallableOptionsPrvExt
    on FirebaseFunctionsCallableOptions {
  /// Access native instance
  native.HttpsCallableOptions get nativeInstance => native.HttpsCallableOptions(
    timeout: timeout,
    limitedUseAppCheckToken: limitedUseAppCheckToken,
  );
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
