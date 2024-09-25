import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart'
    as firestore_flutter;

export 'package:tekartik_firebase_firestore/firestore.dart';

FirestoreService get firestoreServiceFlutter =>
    firestore_flutter.firestoreService;

@Deprecated('Use firestoreServiceFlutter')
FirestoreService get firestoreService => firestoreServiceFlutter;
