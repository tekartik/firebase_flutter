import 'package:cloud_firestore/cloud_firestore.dart' as native;
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore_flutter/src/snapshot_meta_data_flutter.dart';

import 'firestore_flutter.dart';

class DocumentSnapshotFlutter
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  final native.DocumentSnapshot nativeInstance;

  DocumentSnapshotFlutter(this.nativeInstance);

  @override
  Map<String, Object?> get data =>
      documentDataFromFlutterData(nativeInstance.data() as Map).asMap();

  @override
  bool get exists => nativeInstance.exists;

  @override
  DocumentReference get ref => wrapDocumentReference(nativeInstance.reference);

  // not supported
  @override
  Timestamp? get updateTime => null;

  // not supported
  @override
  Timestamp? get createTime => null;

  @override
  SnapshotMetadata get metadata =>
      SnapshotMetaDataFlutter(nativeInstance.metadata);
}

extension DocumentSnapshotFlutterExt on DocumentSnapshot {
  DocumentSnapshotFlutter get flutter => this as DocumentSnapshotFlutter;
}
