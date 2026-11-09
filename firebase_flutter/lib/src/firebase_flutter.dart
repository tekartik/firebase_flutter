import 'dart:async';

import 'package:firebase_core/firebase_core.dart' as flutter;
import 'package:tekartik_firebase/firebase.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase/src/firebase_mixin.dart';

/// Compat to deprecate
@Deprecated('To deprecated since 2024-03-20')
/// Typedef representing [AppFlutter].
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

  // toDebugMap: the mixin one (project id and obfuscated api key), never
  // the native map (api key in clear, client ids).
}

class _FirebaseFlutter with FirebaseMixin implements FirebaseFlutter {
  /// One app per native app name: the products and services registered on
  /// an app are found again when the app is asked again.
  final _apps = <String, _FirebaseAppFlutter>{};

  /// The app of [nativeApp], created once (registered as the latest app).
  App _wrapApp(flutter.FirebaseApp nativeApp) {
    var name = nativeApp.name;
    var app = _apps[name];
    if (app == null || app.nativeInstance != nativeApp) {
      app = _FirebaseAppFlutter(
        firebaseFlutter: this,
        nativeInstance: nativeApp,
        options: wrapOptions(nativeApp.options),
        // Default whatever the options, a named app is not.
        isDefault: name == flutter.defaultFirebaseAppName,
      );
      _apps[name] = app;
    }
    return FirebaseMixin.addApp(app);
  }

  /// Called once [app] is deleted.
  void _removeApp(_FirebaseAppFlutter app) {
    var name = app.name;
    if (identical(_apps[name], app)) {
      _apps.remove(name);
    }
  }

  @override
  Future<App> initializeAppAsync({AppOptions? options, String? name}) async {
    flutter.FirebaseApp nativeApp;
    if (options != null) {
      if (options is _FirebaseAppOptionsFlutter) {
        nativeApp = await flutter.Firebase.initializeApp(
          name: name,
          options: options.nativeInstance,
        );
      } else
      // If empty (checking only projectId)
      // clone the existing options
      if (options.projectId == null) {
        nativeApp = await flutter.Firebase.initializeApp(name: name);
      } else {
        // Checked before creating the native app, which would be left
        // behind.
        throw UnsupportedError(
          'Options other than the flutter ones (projectId ${options.projectId})'
          ' are not supported yet',
        );
      }
    } else {
      nativeApp = await flutter.Firebase.initializeApp(name: name);
    }
    return _wrapApp(nativeApp);
  }

  @override
  App initializeApp({AppOptions? options, String? name}) {
    if (options == null && name == null) {
      // TODO 2020-08-26 if this fail, consider calling async method only
      return _wrapApp(flutter.Firebase.app());
    } else {
      throw 'not supported, use async method';
    }
  }

  @override
  App app({String? name}) {
    if (name == null) {
      return _wrapApp(flutter.Firebase.app());
    }
    throw UnsupportedError(
      'Flutter has only a single default app instantiated',
    );
  }

  @override
  Future<App> appAsync({String? name}) async => initializeAppAsync(name: name);
}

/// Firebase app flutter
abstract class FirebaseAppFlutter implements FirebaseApp {
  /// Native instances if any.
  flutter.FirebaseApp? get nativeInstance;

  /// True if default app/
  bool? get isDefault;
}

/// Firebase app flutter extension.
extension FirebaseAppFlutterExtension on FirebaseApp {
  /// Native instances if any.
  flutter.FirebaseApp get nativeInstance =>
      (this as FirebaseAppFlutter).nativeInstance!;
}

class _FirebaseAppFlutter with FirebaseAppMixin implements FirebaseAppFlutter {
  final FirebaseFlutter firebaseFlutter;
  @override
  final bool? isDefault;
  @override
  final AppOptions options;
  @override
  final flutter.FirebaseApp? nativeInstance;

  _FirebaseAppFlutter({
    required this.firebaseFlutter,
    this.nativeInstance,
    required this.options,
    this.isDefault,
  });

  @override
  Future delete() async {
    await super.delete();
    (firebaseFlutter as _FirebaseFlutter)._removeApp(this);
    await nativeInstance?.delete();
  }

  @override
  String get name => nativeInstance!.name;

  @override
  Firebase get firebase => firebaseFlutter;

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
