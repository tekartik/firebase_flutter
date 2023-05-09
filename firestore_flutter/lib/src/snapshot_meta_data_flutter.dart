import 'package:cloud_firestore/cloud_firestore.dart' as native;

import 'import_firestore.dart';

class SnapshotMetaDataFlutter
    implements SnapshotMetadata {
  final native.SnapshotMetadata nativeInstance;

  SnapshotMetaDataFlutter(this.nativeInstance);

  @override
  bool get hasPendingWrites => nativeInstance.hasPendingWrites;

  @override
  bool get isFromCache => nativeInstance.isFromCache;
}