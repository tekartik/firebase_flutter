import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as native;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/firestore_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/firestore.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'; // ignore: implementation_imports

FirestoreServiceFlutter? _firestoreServiceFlutter;
FirestoreService get firestoreService => firestoreServiceFlutter;
FirestoreService get firestoreServiceFlutter =>
    _firestoreServiceFlutter ?? FirestoreServiceFlutter();

class FirestoreServiceFlutter
    with FirestoreServiceMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is AppFlutter, 'invalid firebase app type');
      var appFlutter = app as AppFlutter;
      if (appFlutter.isDefault!) {
        return FirestoreFlutter(native.FirebaseFirestore.instance);
      } else {
        return FirestoreFlutter(native.FirebaseFirestore.instanceFor(
            app: appFlutter.nativeInstance!));
      }
    });
  }

  FirestoreServiceFlutter();

  @override
  bool get supportsQuerySelect => false;

  @override
  bool get supportsDocumentSnapshotTime => false;

  @override
  bool get supportsTimestampsInSnapshots => true;

  @override
  bool get supportsTimestamps => true;

  // Native implementation does not allow passing snapshots
  @override
  bool get supportsQuerySnapshotCursor => false;

  @override
  bool get supportsFieldValueArray => true;

  @override
  bool get supportsTrackChanges => true;
}

class FirestoreFlutter implements Firestore {
  final native.FirebaseFirestore nativeInstance;

  FirestoreFlutter(this.nativeInstance);

  @override
  WriteBatch batch() => WriteBatchFlutter(nativeInstance.batch());

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(nativeInstance.collection(path));

  @override
  DocumentReference doc(String path) =>
      _wrapDocumentReference(nativeInstance.doc(path));

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) updateFunction) {
    return nativeInstance.runTransaction((nativeTransaction) async {
      var transaction = TransactionFlutter(nativeTransaction);
      return await updateFunction(transaction);
    });
  }

  @override
  void settings(FirestoreSettings settings) {
    nativeInstance.settings = native.Settings();
  }

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    return await Future.wait(refs.map((ref) => ref.get()));
  }
}

class TransactionFlutter implements Transaction {
  final native.Transaction nativeInstance;

  TransactionFlutter(this.nativeInstance);

  @override
  void delete(DocumentReference documentRef) {
    // ok to ignore the future here
    nativeInstance.delete(_unwrapDocumentReference(documentRef)!);
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async =>
      _wrapDocumentSnapshot(
          await nativeInstance.get(_unwrapDocumentReference(documentRef)!));

  @override
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]) {
    // Warning merge is not handle yet!
    nativeInstance.set(
        _unwrapDocumentReference(documentRef)!,
        documentDataToFlutterData(DocumentData(data)),
        unwrapSetOption(options));
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    nativeInstance.update(_unwrapDocumentReference(documentRef)!,
        documentDataToFlutterData(DocumentData(data)));
  }
}

native.SetOptions? unwrapSetOption(SetOptions? options) =>
    options == null ? null : native.SetOptions(merge: options.merge ?? false);
SetOptions wrapSetOption(native.SetOptions options) =>
    SetOptions(merge: options.merge ?? false);

class WriteBatchFlutter implements WriteBatch {
  final native.WriteBatch nativeInstance;

  WriteBatchFlutter(this.nativeInstance);

  @override
  Future commit() => nativeInstance.commit();

  @override
  void delete(DocumentReference? ref) =>
      nativeInstance.delete(_unwrapDocumentReference(ref!)!);

  @override
  void set(DocumentReference ref, Map<String, Object?> data,
      [SetOptions? options]) {
    nativeInstance.set(
        _unwrapDocumentReference(ref)!,
        documentDataToFlutterData(DocumentData(data)),
        unwrapSetOption(options));
  }

  @override
  void update(DocumentReference ref, Map<String, Object?> data) =>
      nativeInstance.update(_unwrapDocumentReference(ref)!,
          documentDataToFlutterData(DocumentData(data)));
}

// for both native and not
bool isCommonValue(value) {
  return (value == null ||
      value is String ||
      // value is DateTime ||
      value is num ||
      value is bool);
}

List<Object?>? toNativeValues(Iterable<Object?>? values) =>
    values?.map((e) => toNativeValue(e)).toList(growable: false);

dynamic toNativeValue(value) {
  if (isCommonValue(value)) {
    return value;
  } else if (value is Timestamp) {
    return native.Timestamp(value.seconds, value.nanoseconds);
  } else if (value is DateTime) {
    return native.Timestamp.fromDate(value);
  } else if (value is Iterable) {
    return toNativeValues(value);
  } else if (value is Map) {
    return value.map<String, Object?>(
        (key, value) => MapEntry(key as String, toNativeValue(value)));
  } else if (value is FieldValue) {
    if (FieldValue.delete == value) {
      return native.FieldValue.delete();
    } else if (FieldValue.serverTimestamp == value) {
      return native.FieldValue.serverTimestamp();
    } else if (value.type == FieldValueType.arrayUnion) {
      return native.FieldValue.arrayUnion(value.data as List);
    } else if (value.type == FieldValueType.arrayRemove) {
      return native.FieldValue.arrayRemove(value.data as List);
    }
  } else if (value is DocumentReferenceFlutter) {
    return value.nativeInstance;
  } else if (value is Blob) {
    return native.Blob(value.data);
  } else if (value is GeoPoint) {
    return native.GeoPoint(
        value.latitude.toDouble(), value.longitude.toDouble());
  }

  throw 'not supported $value type ${value.runtimeType}';
}

dynamic fromNativeValue(nativeValue) {
  if (isCommonValue(nativeValue)) {
    return nativeValue;
  }
  if (nativeValue is Iterable) {
    return nativeValue
        .map((nativeValue) => fromNativeValue(nativeValue))
        .toList();
  } else if (nativeValue is Map) {
    return nativeValue.map<String, Object?>((key, nativeValue) =>
        MapEntry(key as String, fromNativeValue(nativeValue)));
  } else if (native.FieldValue.delete() == nativeValue) {
    return FieldValue.delete;
  } else if (native.FieldValue.serverTimestamp() == nativeValue) {
    return FieldValue.serverTimestamp;
  } else if (nativeValue is native.DocumentReference) {
    return DocumentReferenceFlutter(nativeValue);
  } else if (nativeValue is native.Blob) {
    return Blob(nativeValue.bytes);
  } else if (nativeValue is native.GeoPoint) {
    return GeoPoint(nativeValue.latitude, nativeValue.longitude);
  } else if (nativeValue is native.Timestamp) {
    return Timestamp(nativeValue.seconds, nativeValue.nanoseconds);
  } else if (nativeValue is DateTime) {
    // Compat
    return Timestamp.fromDateTime(nativeValue);
  } else {
    throw 'not supported $nativeValue type ${nativeValue.runtimeType}';
  }
}

Map<String, Object?> documentDataToFlutterData(DocumentData data) {
  var map = data.asMap();
  return toNativeValue(map) as Map<String, Object?>;
}

DocumentData documentDataFromFlutterData(Map nativeMap) {
  var map = fromNativeValue(nativeMap) as Map<String, Object?>;
  return DocumentData(map);
}

QueryFlutter _wrapQuery(native.Query nativeInstance) =>
    QueryFlutter(nativeInstance);

class QueryFlutter implements Query {
  final native.Query? nativeInstance;

  QueryFlutter(this.nativeInstance);
  @override
  Query endAt({DocumentSnapshot? snapshot, List? values}) {
    return _wrapQuery(nativeInstance!.endAt(toNativeValue(values) as List));
  }

  @override
  Query endBefore({DocumentSnapshot? snapshot, List? values}) {
    return _wrapQuery(nativeInstance!.endBefore(toNativeValue(values) as List));
  }

  @override
  Future<QuerySnapshot> get() async =>
      _wrapQuerySnapshot(await nativeInstance!.get());

  @override
  Query limit(int limit) {
    return _wrapQuery(nativeInstance!.limit(limit));
  }

  @override
  Stream<QuerySnapshot> onSnapshot() {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.QuerySnapshot<Map<String, Object?>> nativeQuerySnapshot,
            EventSink<QuerySnapshot> sink) {
      sink.add(_wrapQuerySnapshot(nativeQuerySnapshot));
    });
    return nativeInstance!.snapshots().transform(transformer);
  }

  @override
  Query orderBy(String key, {bool? descending}) {
    return _wrapQuery(
        nativeInstance!.orderBy(key, descending: descending == true));
  }

  @override
  Query select(List<String> keyPaths) {
    // not supported
    return this;
  }

  @override
  Query startAfter({DocumentSnapshot? snapshot, List? values}) {
    return _wrapQuery(
        nativeInstance!.startAfter(toNativeValue(values) as List));
  }

  @override
  Query startAt({DocumentSnapshot? snapshot, List? values}) {
    return _wrapQuery(nativeInstance!.startAt(toNativeValue(values) as List));
  }

  @override
  Query where(String fieldPath,
      {dynamic isEqualTo,
      dynamic isLessThan,
      dynamic isLessThanOrEqualTo,
      dynamic isGreaterThan,
      dynamic isGreaterThanOrEqualTo,
      dynamic arrayContains,
      List<Object?>? arrayContainsAny,
      List<Object?>? whereIn,
      bool? isNull}) {
    return _wrapQuery(nativeInstance!.where(fieldPath,
        isEqualTo: toNativeValue(isEqualTo),
        isLessThan: toNativeValue(isLessThan),
        isLessThanOrEqualTo: toNativeValue(isLessThanOrEqualTo),
        isGreaterThan: toNativeValue(isGreaterThan),
        isGreaterThanOrEqualTo: toNativeValue(isGreaterThanOrEqualTo),
        arrayContains: toNativeValue(arrayContains),
        arrayContainsAny: toNativeValues(arrayContainsAny),
        whereIn: toNativeValues(whereIn),
        isNull: isNull));
  }
}

mixin PathReferenceFlutterMixin {
  @override
  int get hashCode => path.hashCode;

  String get path;

  @override
  bool operator ==(other) =>
      (other is PathReferenceFlutterMixin) && path == other.path;
}

class CollectionReferenceFlutter extends QueryFlutter
    with PathReferenceFlutterMixin
    implements CollectionReference {
  CollectionReferenceFlutter(native.CollectionReference nativeInstance)
      : super(nativeInstance);
  @override
  native.CollectionReference? get nativeInstance =>
      super.nativeInstance as native.CollectionReference;

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async =>
      _wrapDocumentReference(await nativeInstance!
          .add(documentDataToFlutterData(DocumentData(data))));

  @override
  DocumentReference doc([String? path]) {
    return _wrapDocumentReference(nativeInstance!.doc(path));
  }

  @override
  String get id => nativeInstance!.id;

  @override
  DocumentReference get parent {
    return _wrapDocumentReference(
        nativeInstance!.firestore.doc(url.dirname(path)));
  }

  @override
  String get path => nativeInstance!.path;

  @override
  String toString() => 'CollRef($path)';
}

native.DocumentReference? _unwrapDocumentReference(DocumentReference ref) =>
    (ref as DocumentReferenceFlutter).nativeInstance;
CollectionReferenceFlutter _wrapCollectionReference(
        native.CollectionReference nativeInstance) =>
    CollectionReferenceFlutter(nativeInstance);
DocumentReferenceFlutter _wrapDocumentReference(
        native.DocumentReference nativeInstance) =>
    DocumentReferenceFlutter(nativeInstance);
QuerySnapshotFlutter _wrapQuerySnapshot(native.QuerySnapshot nativeInstance) =>
    QuerySnapshotFlutter(nativeInstance);
DocumentSnapshotFlutter _wrapDocumentSnapshot(
        native.DocumentSnapshot nativeInstance) =>
    DocumentSnapshotFlutter(nativeInstance);
DocumentChangeFlutter _wrapDocumentChange(
        native.DocumentChange nativeInstance) =>
    DocumentChangeFlutter(nativeInstance);
DocumentChangeType? _wrapDocumentChangeType(
    native.DocumentChangeType nativeInstance) {
  switch (nativeInstance) {
    case native.DocumentChangeType.added:
      return DocumentChangeType.added;
    case native.DocumentChangeType.modified:
      return DocumentChangeType.modified;
    case native.DocumentChangeType.removed:
      return DocumentChangeType.removed;
  }
}

class DocumentReferenceFlutter
    with PathReferenceFlutterMixin
    implements DocumentReference {
  final native.DocumentReference nativeInstance;

  DocumentReferenceFlutter(this.nativeInstance);
  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(nativeInstance.collection(path));

  @override
  Future delete() => nativeInstance.delete();

  @override
  Future<DocumentSnapshot> get() async =>
      _wrapDocumentSnapshot(await nativeInstance.get());

  @override
  String get id => nativeInstance.id;

  @override
  Stream<DocumentSnapshot> onSnapshot() {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.DocumentSnapshot<Map<String, Object?>> nativeDocumentSnapshot,
            EventSink<DocumentSnapshot> sink) {
      sink.add(_wrapDocumentSnapshot(nativeDocumentSnapshot));
    });
    return nativeInstance.snapshots().transform(transformer);
  }

  // _TODO: implement parent
  @override
  CollectionReference get parent => _wrapCollectionReference(
      nativeInstance.firestore.collection(url.dirname(path)));

  @override
  String get path => nativeInstance.path;

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) =>
      nativeInstance.set(documentDataToFlutterData(DocumentData(data)),
          unwrapSetOption(options));

  @override
  Future update(Map<String, Object?> data) =>
      nativeInstance.update(documentDataToFlutterData(DocumentData(data)));

  @override
  String toString() => 'DocRef($path)';
}

class DocumentSnapshotFlutter implements DocumentSnapshot {
  final native.DocumentSnapshot nativeInstance;

  DocumentSnapshotFlutter(this.nativeInstance);

  @override
  Map<String, Object?> get data =>
      documentDataFromFlutterData(nativeInstance.data() as Map).asMap();

  @override
  bool get exists => nativeInstance.exists;

  @override
  DocumentReference get ref => _wrapDocumentReference(nativeInstance.reference);

  // not supported
  @override
  Timestamp? get updateTime => null;

  // not supported
  @override
  Timestamp? get createTime => null;
}

class QuerySnapshotFlutter implements QuerySnapshot {
  final native.QuerySnapshot nativeInstance;

  QuerySnapshotFlutter(this.nativeInstance);

  @override
  List<DocumentSnapshot> get docs => nativeInstance.docs
      .map((nativeInstance) => _wrapDocumentSnapshot(nativeInstance))
      .toList();

  @override
  List<DocumentChange> get documentChanges => nativeInstance.docChanges
      .map((nativeInstance) => _wrapDocumentChange(nativeInstance))
      .toList();
}

class DocumentChangeFlutter implements DocumentChange {
  final native.DocumentChange nativeInstance;

  DocumentChangeFlutter(this.nativeInstance);

  @override
  DocumentSnapshot get document => _wrapDocumentSnapshot(nativeInstance.doc);

  @override
  int get newIndex => nativeInstance.newIndex;

  @override
  int get oldIndex => nativeInstance.oldIndex;

  @override
  DocumentChangeType get type => _wrapDocumentChangeType(nativeInstance.type)!;
}
