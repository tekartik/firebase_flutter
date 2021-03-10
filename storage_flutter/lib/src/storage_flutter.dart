import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart' as native;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage/src/common/storage_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage/storage.dart';

class StorageServiceFlutter with StorageServiceMixin implements StorageService {
  StorageServiceFlutter();

  @override
  Storage storage(App app) {
    return getInstance(app, () {
      assert(app is AppFlutter, 'invalid firebase app type');
      var appFlutter = app as AppFlutter;
      if (appFlutter.isDefault) {
        return StorageFlutter(native.FirebaseStorage.instance);
      } else {
        return StorageFlutter(
            native.FirebaseStorage.instanceFor(app: appFlutter.nativeInstance));
      }
    });
  }
}

StorageServiceFlutter _storageServiceFlutter;

StorageServiceFlutter get storageServiceFlutter =>
    _storageServiceFlutter ??= StorageServiceFlutter();

Future<native.Reference> getReferenceFromName(
    BucketFlutter bucket, String name) async {
  var ref = bucket.storage.firebaseStorage.refFromURL(nameToUrl(name));
  return ref;
}

class FileFlutter with FileMixin implements File {
  @override
  final BucketFlutter bucket;
  final String path;
  native.Reference _ref;

  FileFlutter(this.bucket, this.path);

  /// init and assign, to use: `_ref ??= await _initRef();`
  Future<native.Reference> _initRef() async {
    return _ref = await getReferenceFromName(bucket, path);
  }

  @override
  Future save(content) async {
    _ref ??= await _initRef();
    Uint8List data;
    if (content is Uint8List) {
      data = content;
    } else if (content is List<int>) {
      data = Uint8List.fromList(content);
    } else if (content is String) {
      data = Uint8List.fromList(utf8.encode(content));
    }
    await _ref.putData(data);
  }

  @override
  Future<Uint8List> download() async {
    _ref ??= await _initRef();
    var metaData = await _ref.getMetadata();
    return await _ref.getData(metaData.size);
  }

  @override
  Future<bool> exists() async {
    _ref ??= await _initRef();
    try {
      await _ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future delete() async {
    _ref ??= await _initRef();
    await _ref.delete();
  }

  @override
  String get name => _ref.name;
}

class BucketFlutter with BucketMixin implements Bucket {
  final StorageFlutter storage;
  @override
  final String name;

  BucketFlutter(this.storage, String name) : name = name ?? '_default';

  Future list() {
    throw UnsupportedError('list not supported yet');
    // Not implemented
    // storage.firebaseStorage.ref().child(name).
  }

  @override
  File file(String path) => FileFlutter(this, path);

  @override
  Future<bool> exists() async {
    try {
      await storage.firebaseStorage.ref(name).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }
}

String nameToUrl(String name) => 'gs://$name';

class ReferenceFlutter with ReferenceMixin implements Reference {
  final native.Reference nativeInstance;

  ReferenceFlutter(this.nativeInstance);

  @override
  Future<String> getDownloadUrl() => nativeInstance.getDownloadURL();
}

class StorageFlutter implements Storage {
  final native.FirebaseStorage firebaseStorage;

  StorageFlutter(this.firebaseStorage);

  @override
  Bucket bucket([String name]) {
    return BucketFlutter(this, name);
  }

  @override
  Reference ref([String path]) {
    path ??= '/';
    path = path.isEmpty ? '/' : path;
    return ReferenceFlutter(firebaseStorage.ref(path));
  }
}

/*
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as native;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/firestore_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/firestore.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'; // ignore: implementation_imports

FirestoreServiceFlutter _firestoreServiceFlutter;
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
      if (appFlutter.isDefault) {
        return FirestoreFlutter(native.Firestore.instance);
      } else {
        return FirestoreFlutter(
            native.Firestore(app: appFlutter.nativeInstance));
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
  final native.Firestore nativeInstance;

  FirestoreFlutter(this.nativeInstance);

  @override
  WriteBatch batch() => WriteBatchFlutter(nativeInstance.batch());

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(nativeInstance.collection(path));

  @override
  DocumentReference doc(String path) =>
      _wrapDocumentReference(nativeInstance.document(path));

  @override
  Future runTransaction(Function(Transaction transaction) updateFunction) {
    return nativeInstance.runTransaction((nativeTransaction) async {
      var transaction = TransactionFlutter(nativeTransaction);
      return await updateFunction(transaction);
    });
  }

  @override
  void settings(FirestoreSettings settings) {
    nativeInstance.settings(
        //    timestampsInSnapshotsEnabled: settings?.timestampsInSnapshots == true
        );
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
    nativeInstance.delete(_unwrapDocumentReference(documentRef));
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async =>
      _wrapDocumentSnapshot(
          await nativeInstance.get(_unwrapDocumentReference(documentRef)));

  @override
  void set(DocumentReference documentRef, Map<String, dynamic> data,
      [SetOptions options]) {
    // Warning merge is not handle yet!
    nativeInstance.set(_unwrapDocumentReference(documentRef),
        documentDataToFlutterData(DocumentData(data)));
  }

  @override
  void update(DocumentReference documentRef, Map<String, dynamic> data) {
    nativeInstance.update(_unwrapDocumentReference(documentRef),
        documentDataToFlutterData(DocumentData(data)));
  }
}

class WriteBatchFlutter implements WriteBatch {
  final native.WriteBatch nativeInstance;

  WriteBatchFlutter(this.nativeInstance);

  @override
  Future commit() => nativeInstance.commit();

  @override
  void delete(DocumentReference ref) =>
      nativeInstance.delete(_unwrapDocumentReference(ref));

  @override
  void set(DocumentReference ref, Map<String, dynamic> data,
      [SetOptions options]) {
    nativeInstance.setData(_unwrapDocumentReference(ref),
        documentDataToFlutterData(DocumentData(data)),
        merge: options?.merge == true);
  }

  @override
  void update(DocumentReference ref, Map<String, dynamic> data) =>
      nativeInstance.updateData(_unwrapDocumentReference(ref),
          documentDataToFlutterData(DocumentData(data)));
}

// for both native and not
bool isCommonValue(value) {
  return (value == null ||
      value is String ||
      value is DateTime ||
      value is num ||
      value is bool);
}

dynamic toNativeValue(value) {
  if (isCommonValue(value)) {
    return value;
  } else if (value is Timestamp) {
    return native.Timestamp(value.seconds, value.nanoseconds);
  } else if (value is Iterable) {
    return value.map((nativeValue) => toNativeValue(nativeValue)).toList();
  } else if (value is Map) {
    return value.map<String, dynamic>(
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
        value.latitude?.toDouble(), value.longitude?.toDouble());
  }

  throw 'not supported ${value} type ${value.runtimeType}';
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
    return nativeValue.map<String, dynamic>((key, nativeValue) =>
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
  } else {
    throw 'not supported ${nativeValue} type ${nativeValue.runtimeType}';
  }
}

Map<String, dynamic> documentDataToFlutterData(DocumentData data) {
  if (data != null) {
    var map = data.asMap();
    return toNativeValue(map) as Map<String, dynamic>;
  }
  return null;
}

DocumentData documentDataFromFlutterData(Map<String, dynamic> nativeMap) {
  if (nativeMap != null) {
    var map = fromNativeValue(nativeMap) as Map<String, dynamic>;
    return DocumentData(map);
  }
  return null;
}

QueryFlutter _wrapQuery(native.Query nativeInstance) =>
    nativeInstance != null ? QueryFlutter(nativeInstance) : null;

class QueryFlutter implements Query {
  final native.Query nativeInstance;

  QueryFlutter(this.nativeInstance);
  @override
  Query endAt({DocumentSnapshot snapshot, List values}) {
    return _wrapQuery(nativeInstance.endAt(toNativeValue(values) as List));
  }

  @override
  Query endBefore({DocumentSnapshot snapshot, List values}) {
    return _wrapQuery(nativeInstance.endBefore(toNativeValue(values) as List));
  }

  @override
  Future<QuerySnapshot> get() async =>
      _wrapQuerySnapshot(await nativeInstance.getDocuments());

  @override
  Query limit(int limit) {
    return _wrapQuery(nativeInstance.limit(limit));
  }

  @override
  Stream<QuerySnapshot> onSnapshot() {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.QuerySnapshot nativeQuerySnapshot,
            EventSink<QuerySnapshot> sink) {
      sink.add(_wrapQuerySnapshot(nativeQuerySnapshot));
    });
    return nativeInstance.snapshots().transform(transformer);
  }

  @override
  Query orderBy(String key, {bool descending}) {
    return _wrapQuery(
        nativeInstance.orderBy(key, descending: descending == true));
  }

  @override
  Query select(List<String> keyPaths) {
    // not supported
    return this;
  }

  @override
  Query startAfter({DocumentSnapshot snapshot, List values}) {
    return _wrapQuery(nativeInstance.startAfter(toNativeValue(values) as List));
  }

  @override
  Query startAt({DocumentSnapshot snapshot, List values}) {
    return _wrapQuery(nativeInstance.startAt(toNativeValue(values) as List));
  }

  @override
  Query where(String fieldPath,
      {isEqualTo,
      isLessThan,
      isLessThanOrEqualTo,
      isGreaterThan,
      isGreaterThanOrEqualTo,
      arrayContains,
      bool isNull}) {
    return _wrapQuery(nativeInstance.where(fieldPath,
        isEqualTo: toNativeValue(isEqualTo),
        isLessThan: toNativeValue(isLessThan),
        isLessThanOrEqualTo: toNativeValue(isLessThanOrEqualTo),
        isGreaterThan: toNativeValue(isGreaterThan),
        isGreaterThanOrEqualTo: toNativeValue(isGreaterThanOrEqualTo),
        arrayContains: toNativeValue(arrayContains),
        isNull: isNull));
  }
}

class CollectionReferenceFlutter extends QueryFlutter
    implements CollectionReference {
  CollectionReferenceFlutter(native.CollectionReference nativeInstance)
      : super(nativeInstance);
  @override
  native.CollectionReference get nativeInstance =>
      super.nativeInstance as native.CollectionReference;

  @override
  Future<DocumentReference> add(Map<String, dynamic> data) async =>
      _wrapDocumentReference(await nativeInstance
          .add(documentDataToFlutterData(DocumentData(data))));

  @override
  DocumentReference doc([String path]) {
    return _wrapDocumentReference(nativeInstance.document(path));
  }

  @override
  String get id => nativeInstance.id;

  @override
  DocumentReference get parent {
    return _wrapDocumentReference(
        nativeInstance.firestore.document(url.dirname(path)));
  }

  @override
  String get path => nativeInstance.path;

  @override
  String toString() => 'CollRef($path)';

  @override
  int get hashCode => nativeInstance.hashCode;

  @override
  bool operator ==(other) =>
      (other is CollectionReferenceFlutter) &&
      nativeInstance == other.nativeInstance;
}

native.DocumentReference _unwrapDocumentReference(DocumentReference ref) =>
    (ref as DocumentReferenceFlutter).nativeInstance;
CollectionReferenceFlutter _wrapCollectionReference(
        native.CollectionReference nativeInstance) =>
    nativeInstance != null ? CollectionReferenceFlutter(nativeInstance) : null;
DocumentReferenceFlutter _wrapDocumentReference(
        native.DocumentReference nativeInstance) =>
    nativeInstance != null ? DocumentReferenceFlutter(nativeInstance) : null;
QuerySnapshotFlutter _wrapQuerySnapshot(native.QuerySnapshot nativeInstance) =>
    nativeInstance != null ? QuerySnapshotFlutter(nativeInstance) : null;
DocumentSnapshotFlutter _wrapDocumentSnapshot(
        native.DocumentSnapshot nativeInstance) =>
    nativeInstance != null ? DocumentSnapshotFlutter(nativeInstance) : null;
DocumentChangeFlutter _wrapDocumentChange(
        native.DocumentChange nativeInstance) =>
    nativeInstance != null ? DocumentChangeFlutter(nativeInstance) : null;
DocumentChangeType _wrapDocumentChangeType(
    native.DocumentChangeType nativeInstance) {
  switch (nativeInstance) {
    case native.DocumentChangeType.added:
      return DocumentChangeType.added;
    case native.DocumentChangeType.modified:
      return DocumentChangeType.modified;
    case native.DocumentChangeType.removed:
      return DocumentChangeType.removed;
  }
  return null;
}

class DocumentReferenceFlutter implements DocumentReference {
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
  String get id => nativeInstance.documentID;

  @override
  Stream<DocumentSnapshot> onSnapshot() {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.DocumentSnapshot nativeDocumentSnapshot,
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
  Future set(Map<String, dynamic> data, [SetOptions options]) =>
      nativeInstance.setData(documentDataToFlutterData(DocumentData(data)),
          merge: options?.merge == true);

  @override
  Future update(Map<String, dynamic> data) =>
      nativeInstance.updateData(documentDataToFlutterData(DocumentData(data)));

  @override
  String toString() => 'DocRef($path)';

  @override
  int get hashCode => nativeInstance.hashCode;

  @override
  bool operator ==(other) =>
      (other is DocumentReferenceFlutter) &&
      nativeInstance == other.nativeInstance;
}

class DocumentSnapshotFlutter implements DocumentSnapshot {
  final native.DocumentSnapshot nativeInstance;

  DocumentSnapshotFlutter(this.nativeInstance);

  @override
  Map<String, dynamic> get data =>
      documentDataFromFlutterData(nativeInstance.data)?.asMap();

  @override
  bool get exists => nativeInstance.exists;

  @override
  DocumentReference get ref => _wrapDocumentReference(nativeInstance.reference);

  // not supported
  @override
  Timestamp get updateTime => null;

  // not supported
  @override
  Timestamp get createTime => null;
}

class QuerySnapshotFlutter implements QuerySnapshot {
  final native.QuerySnapshot nativeInstance;

  QuerySnapshotFlutter(this.nativeInstance);

  @override
  List<DocumentSnapshot> get docs => nativeInstance.documents
      ?.map((nativeInstance) => _wrapDocumentSnapshot(nativeInstance))
      ?.toList();

  @override
  List<DocumentChange> get documentChanges => nativeInstance.documentChanges
      ?.map((nativeInstance) => _wrapDocumentChange(nativeInstance))
      ?.toList();
}

class DocumentChangeFlutter implements DocumentChange {
  final native.DocumentChange nativeInstance;

  DocumentChangeFlutter(this.nativeInstance);

  @override
  DocumentSnapshot get document => null;

  @override
  int get newIndex => nativeInstance.newIndex;

  @override
  int get oldIndex => nativeInstance.oldIndex;

  @override
  DocumentChangeType get type => _wrapDocumentChangeType(nativeInstance.type);
}
*/
