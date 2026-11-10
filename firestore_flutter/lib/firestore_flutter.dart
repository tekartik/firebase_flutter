import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart'
    as firestore_flutter;

export 'package:tekartik_firebase_firestore/firestore.dart';
export 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart'
    show FirestoreFlutter, FirestoreFlutterExt;

/// The Firestore service on cloud_firestore, a single instance:
/// `firestoreServiceFlutter.firestore(app)` gives the `Firestore` of a
/// `firebaseFlutter` app (cached per app).
FirestoreService get firestoreServiceFlutter =>
    firestore_flutter.firestoreService;

/// Compat, use [firestoreServiceFlutter].
@Deprecated('Use firestoreServiceFlutter')
FirestoreService get firestoreService => firestoreServiceFlutter;
