import 'dart:async';

import 'package:firebase_core/firebase_core.dart' as flutter;
import 'package:tekartik_firebase/firebase.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase/src/firebase_mixin.dart';

/// Compat to deprecate
@Deprecated('To deprecated since 2024-03-20')
typedef AppFlutter = FirebaseAppFlutter;

class _FirebaseAppOptionsFlutter with FirebaseAppOptionsMixin {
  final flutter.FirebaseOptions nativeInstance;

  _FirebaseAppOptionsFlutter(this.nativeInstance);

  @override
  String? get apiKey => nativeInstance.apiKey;

  @override
  String? get appId => nativeInstance.appId;

  @override
  String? get authDomain => nativeInstance.authDomain;

  @override
  String? get databaseURL => nativeInstance.databaseURL;

  @override
  String? get measurementId => nativeInstance.measurementId;

  @override
  String? get messagingSenderId => nativeInstance.messagingSenderId;

  @override
  String? get projectId => nativeInstance.projectId;

  @override
  String? get storageBucket => nativeInstance.storageBucket;

  @override
  Map<String, Object?> toDebugMap() => nativeInstance.asMap;
}

class _FirebaseFlutter implements FirebaseFlutter {
  @override
  Future<App> initializeAppAsync({AppOptions? options, String? name}) async {
    flutter.FirebaseApp nativeApp;
    var isDefault = false;
    if (options != null) {
      if (options is _FirebaseAppOptionsFlutter) {
        nativeApp = await flutter.Firebase.initializeApp(
            name: name, options: options.nativeInstance);
      } else
      // If empty (checking only projectId)
      // clone the existing options
      if (options.projectId == null) {
        nativeApp = await flutter.Firebase.initializeApp(name: name);
      } else {
        nativeApp = await flutter.Firebase.initializeApp(
            name: name,
            options: flutter.FirebaseOptions(
                apiKey: options.apiKey!,
                appId: options.appId!,
                messagingSenderId: options.messagingSenderId!,
                projectId: options.projectId!));
        throw 'not supported yet';
      }
    } else {
      isDefault = true;
      nativeApp = await flutter.Firebase.initializeApp(name: name);
    }
    options = wrapOptions(nativeApp.options);

    return _FirebaseAppFlutter(
        nativeInstance: nativeApp, options: options, isDefault: isDefault);
  }

  @override
  App initializeApp({AppOptions? options, String? name}) {
    if (options == null && name == null) {
      // TODO 2020-08-26 if this fail, consider calling async method only
      var nativeApp = flutter.Firebase.app();
      options = wrapOptions(nativeApp.options);
      return _FirebaseAppFlutter(
          nativeInstance: nativeApp, options: options, isDefault: true);
    } else {
      throw 'not supported, use async method';
    }
  }

  @override
  App app({String? name}) {
    if (name == null) {
      var nativeApp = flutter.Firebase.app();
      return _FirebaseAppFlutter(
          nativeInstance: nativeApp,
          options: wrapOptions(nativeApp.options),
          isDefault: true);
    }
    throw UnsupportedError(
        'Flutter has only a single default app instantiated');
  }

  @override
  Future<App> appAsync({String? name}) async => initializeAppAsync(name: name);
}

/// Firebase app flutter
abstract class FirebaseAppFlutter {
  /// Native instances if any.
  flutter.FirebaseApp? get nativeInstance;

  /// True if default app/
  bool? get isDefault;
}

class _FirebaseAppFlutter with FirebaseAppMixin implements FirebaseAppFlutter {
  @override
  final bool? isDefault;
  @override
  final AppOptions options;
  @override
  final flutter.FirebaseApp? nativeInstance;

  _FirebaseAppFlutter(
      {this.nativeInstance, required this.options, this.isDefault});

  @override
  Future delete() async {
    await closeServices();
    // delete is not supported, simply ignore
    // throw 'not supported';
  }

  @override
  String get name => nativeInstance!.name;

  @override
  String toString() => 'AppFlutter($name)';
}

/// Firebase flutter extension.
extension FirebaseFlutterExtension on Firebase {
  /// Wrap a native options.
  FirebaseAppOptions wrapOptions(flutter.FirebaseOptions fbOptions) {
    var options = _FirebaseAppOptionsFlutter(fbOptions);
    return options;
  }
}

/// Firebase flutter.
abstract class FirebaseFlutter implements FirebaseAsync, Firebase {}

FirebaseFlutter? _firebaseFlutter;

/// The firebase flutter service.
FirebaseFlutter get firebaseFlutter => _firebaseFlutter ??= _FirebaseFlutter();
