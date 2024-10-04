import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'
    as firebase_flutter;

import 'src/firebase_flutter.dart';

export 'package:tekartik_firebase/firebase.dart';

export 'src/firebase_flutter.dart'
    show FirebaseFlutter, FirebaseFlutterExtension, FirebaseAppFlutterExtension;

/// Flutter async for initialization
/// Compat
FirebaseFlutter get firebaseFlutterAsync => firebase_flutter.firebaseFlutter;

/// firebase Flutter service.
FirebaseFlutter get firebaseFlutter => firebase_flutter.firebaseFlutter;
