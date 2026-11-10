import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_flutter/src/storage_flutter.dart'
    as storage_flutter;
export 'package:tekartik_firebase_storage/storage.dart';

/// The Storage service on firebase_storage, a single instance:
/// `storageServiceFlutter.storage(app)` gives the `Storage` of a
/// `firebaseFlutter` app (cached per app).
StorageService get storageServiceFlutter =>
    storage_flutter.storageServiceFlutter;
