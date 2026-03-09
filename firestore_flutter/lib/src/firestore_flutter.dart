import 'package:cloud_firestore/cloud_firestore.dart' as native;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

import 'aggregate_query_flutter.dart';
import 'document_snapshot_flutter.dart';
import 'import.dart';
import 'import_firestore.dart';

/// Sentinel value to check whether user passed values explicitly through .where() method
@internal
const notSetQueryParam = Object();

FirestoreServiceFlutter? _firestoreServiceFlutter;

FirestoreService get firestoreService => firestoreServiceFlutter;

FirestoreService get firestoreServiceFlutter =>
    _firestoreServiceFlutter ?? FirestoreServiceFlutter();

class FirestoreServiceFlutter
    with FirebaseProductServiceMixin<Firestore>, FirestoreServiceDefaultMixin
    implements FirestoreService {
  @override
  FirestoreFlutter firestore(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppFlutter, 'invalid firebase app type');
      var appFlutter = app as FirebaseAppFlutter;
      if (appFlutter.isDefault!) {
        return FirestoreFlutter(
          this,
          appFlutter,
          native.FirebaseFirestore.instance,
        );
      } else {
        return FirestoreFlutter(
          this,
          appFlutter,
          native.FirebaseFirestore.instanceFor(app: appFlutter.nativeInstance!),
        );
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

  @override
  bool get supportsAggregateQueries => true;

  @override
  bool get supportsVectorValue => true;
}

class FirestoreFlutter
    with FirebaseAppProductMixin<Firestore>, FirestoreDefaultMixin
    implements Firestore {
  @override
  final FirestoreServiceFlutter service;
  final native.FirebaseFirestore nativeInstance;

  final FirebaseAppFlutter appFlutter;
  FirestoreFlutter(this.service, this.appFlutter, this.nativeInstance);

  @override
  WriteBatch batch() => WriteBatchFlutter(nativeInstance.batch());

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(this, nativeInstance.collection(path));

  @override
  QueryFlutter collectionGroup(String collectionId) =>
      _wrapQuery(this, nativeInstance.collectionGroup(collectionId));

  @override
  DocumentReference doc(String path) =>
      wrapDocumentReference(this, nativeInstance.doc(path));

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) updateFunction,
  ) {
    return nativeInstance.runTransaction((nativeTransaction) async {
      var transaction = TransactionFlutter(this, nativeTransaction);
      return await updateFunction(transaction);
    });
  }

  @override
  void settings(FirestoreSettings settings) {
    nativeInstance.settings = const native.Settings();
  }

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    return await Future.wait(refs.map((ref) => ref.get()));
  }

  @override
  FirebaseApp get app => appFlutter;
}

class TransactionFlutter implements Transaction {
  final Firestore firestore;
  final native.Transaction nativeInstance;

  TransactionFlutter(this.firestore, this.nativeInstance);

  @override
  void delete(DocumentReference documentRef) {
    // ok to ignore the future here
    nativeInstance.delete(_unwrapDocumentReference(documentRef)!);
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async =>
      _wrapDocumentSnapshot(
        firestore,
        await nativeInstance.get(_unwrapDocumentReference(documentRef)!),
      );

  @override
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {
    // Warning merge is not handle yet!
    nativeInstance.set(
      _unwrapDocumentReference(documentRef)!,
      documentDataToFlutterData(DocumentData(data)),
      unwrapSetOption(options),
    );
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    nativeInstance.update(
      _unwrapDocumentReference(documentRef)!,
      documentDataToFlutterData(DocumentData(data)),
    );
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
  void set(
    DocumentReference ref,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {
    nativeInstance.set(
      _unwrapDocumentReference(ref)!,
      documentDataToFlutterData(DocumentData(data)),
      unwrapSetOption(options),
    );
  }

  @override
  void update(DocumentReference ref, Map<String, Object?> data) =>
      nativeInstance.update(
        _unwrapDocumentReference(ref)!,
        documentDataToFlutterData(DocumentData(data)),
      );
}

// for both native and not
bool isCommonValue(Object? value) {
  return (value == null ||
      value is String ||
      // value is DateTime ||
      value is num ||
      value is bool);
}

List<Object?>? toNativeValues(Iterable<Object?>? values) =>
    values?.map((e) => toNativeValue(e)).toList(growable: false);

dynamic toNativeValue(Object? value) {
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
      (key, value) => MapEntry(key as String, toNativeValue(value)),
    );
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
      value.latitude.toDouble(),
      value.longitude.toDouble(),
    );
  } else if (value is VectorValue) {
    return native.VectorValue(value.toArray());
  }

  throw 'not supported $value type ${value.runtimeType}';
}

dynamic fromNativeValue(Firestore firestore, Object? nativeValue) {
  if (isCommonValue(nativeValue)) {
    return nativeValue;
  }
  if (nativeValue is Iterable) {
    return nativeValue
        .map((nativeValue) => fromNativeValue(firestore, nativeValue))
        .toList();
  } else if (nativeValue is Map) {
    return nativeValue.map<String, Object?>(
      (key, nativeValue) =>
          MapEntry(key as String, fromNativeValue(firestore, nativeValue)),
    );
  } else if (native.FieldValue.delete() == nativeValue) {
    return FieldValue.delete;
  } else if (native.FieldValue.serverTimestamp() == nativeValue) {
    return FieldValue.serverTimestamp;
  } else if (nativeValue is native.DocumentReference) {
    return DocumentReferenceFlutter(
      firestore,
      (nativeValue as native.DocumentReference<Map<String, Object?>>),
    );
  } else if (nativeValue is native.Blob) {
    return Blob(nativeValue.bytes);
  } else if (nativeValue is native.GeoPoint) {
    return GeoPoint(nativeValue.latitude, nativeValue.longitude);
  } else if (nativeValue is native.Timestamp) {
    return Timestamp(nativeValue.seconds, nativeValue.nanoseconds);
  } else if (nativeValue is native.VectorValue) {
    return VectorValue(nativeValue.toArray());
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

DocumentData documentDataFromFlutterData(Firestore firestore, Map nativeMap) {
  var map = fromNativeValue(firestore, nativeMap) as Map<String, Object?>;
  return DocumentData(map);
}

QueryFlutter _wrapQuery(
  Firestore firestore,
  native.Query<Map<String, Object?>> nativeInstance,
) => QueryFlutter(firestore, nativeInstance);

class QueryFlutter
    with QueryDefaultMixin, FirestoreQueryExecutorMixin
    implements Query {
  @override
  final Firestore firestore;
  final native.Query<Map<String, Object?>> nativeInstance;

  QueryFlutter(this.firestore, this.nativeInstance);

  @override
  Query endAt({DocumentSnapshot? snapshot, List? values}) {
    return _wrapQuery(
      firestore,
      nativeInstance.endAt(toNativeValue(values) as List),
    );
  }

  @override
  Query endBefore({DocumentSnapshot? snapshot, List? values}) {
    return _wrapQuery(
      firestore,
      nativeInstance.endBefore(toNativeValue(values) as List),
    );
  }

  @override
  Future<QuerySnapshot> get() async =>
      _wrapQuerySnapshot(firestore, await nativeInstance.get());

  /// Simplifies aggregate response.
  @override
  Future<int> count() async => (await nativeInstance.count().get()).count!;

  @override
  Query limit(int limit) {
    return _wrapQuery(firestore, nativeInstance.limit(limit));
  }

  @override
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    var transformer = StreamTransformer.fromHandlers(
      handleData:
          (
            native.QuerySnapshot<Map<String, Object?>> nativeQuerySnapshot,
            EventSink<QuerySnapshot> sink,
          ) {
            sink.add(_wrapQuerySnapshot(firestore, nativeQuerySnapshot));
          },
    );
    return nativeInstance
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .transform(transformer);
  }

  @override
  Query orderBy(String key, {bool? descending}) {
    return _wrapQuery(
      firestore,
      nativeInstance.orderBy(key, descending: descending == true),
    );
  }

  @override
  Query orderById({bool? descending}) {
    return _wrapQuery(
      firestore,
      nativeInstance.orderBy(
        native.FieldPath.documentId,
        descending: descending == true,
      ),
    );
  }

  @override
  Query select(List<String> keyPaths) {
    // not supported
    return this;
  }

  @override
  Query startAfter({DocumentSnapshot? snapshot, List? values}) {
    if (snapshot != null) {
      return _wrapQuery(
        firestore,
        nativeInstance.startAfterDocument(snapshot.flutter.nativeInstance),
      );
    } else {
      return _wrapQuery(
        firestore,
        nativeInstance.startAfter(toNativeValue(values) as List),
      );
    }
  }

  @override
  Query startAt({DocumentSnapshot? snapshot, List? values}) {
    if (snapshot != null) {
      return _wrapQuery(
        firestore,
        nativeInstance.startAtDocument(snapshot.flutter.nativeInstance),
      );
    } else {
      return _wrapQuery(
        firestore,
        nativeInstance.startAt(toNativeValue(values) as List),
      );
    }
  }

  @override
  Query where(
    String fieldPath, {
    Object? isEqualTo = notSetQueryParam,
    Object? isLessThan = notSetQueryParam,
    Object? isLessThanOrEqualTo = notSetQueryParam,
    Object? isGreaterThan = notSetQueryParam,
    Object? isGreaterThanOrEqualTo = notSetQueryParam,
    Object? arrayContains = notSetQueryParam,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    bool? isNull,
  }) {
    if (isEqualTo != notSetQueryParam) {
      return _wrapQuery(
        firestore,
        nativeInstance.where(fieldPath, isEqualTo: toNativeValue(isEqualTo)),
      );
    } else if (isLessThan != notSetQueryParam) {
      return _wrapQuery(
        firestore,
        nativeInstance.where(fieldPath, isLessThan: toNativeValue(isLessThan)),
      );
    } else if (isLessThanOrEqualTo != notSetQueryParam) {
      return _wrapQuery(
        firestore,
        nativeInstance.where(
          fieldPath,
          isLessThanOrEqualTo: toNativeValue(isLessThanOrEqualTo),
        ),
      );
    } else if (isGreaterThan != notSetQueryParam) {
      return _wrapQuery(
        firestore,
        nativeInstance.where(
          fieldPath,
          isGreaterThan: toNativeValue(isGreaterThan),
        ),
      );
    } else if (isGreaterThanOrEqualTo != notSetQueryParam) {
      return _wrapQuery(
        firestore,
        nativeInstance.where(
          fieldPath,
          isGreaterThanOrEqualTo: toNativeValue(isGreaterThanOrEqualTo),
        ),
      );
    } else if (arrayContains != notSetQueryParam) {
      return _wrapQuery(
        firestore,
        nativeInstance.where(
          fieldPath,
          arrayContains: toNativeValue(arrayContains),
        ),
      );
    }
    return _wrapQuery(
      firestore,
      nativeInstance.where(
        fieldPath,
        arrayContainsAny: toNativeValues(arrayContainsAny),
        whereIn: toNativeValues(whereIn),
        isNull: isNull,
      ),
    );
  }

  @override
  AggregateQuery aggregate(List<AggregateField> fields) {
    return AggregateQueryFlutter(this, fields);
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
  CollectionReferenceFlutter(
    super.firestore,
    native.CollectionReference<Map<String, Object?>> super.nativeInstance,
  );

  @override
  native.CollectionReference<Map<String, Object?>> get nativeInstance =>
      super.nativeInstance as native.CollectionReference<Map<String, Object?>>;

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async =>
      wrapDocumentReference(
        firestore,
        await nativeInstance.add(documentDataToFlutterData(DocumentData(data))),
      );

  @override
  DocumentReference doc([String? path]) {
    return wrapDocumentReference(firestore, nativeInstance.doc(path));
  }

  @override
  String get id => nativeInstance.id;

  @override
  DocumentReference? get parent {
    var parentPath = url.dirname(path);
    if (parentPath == '.') {
      return null;
    }
    return wrapDocumentReference(
      firestore,
      nativeInstance.firestore.doc(url.dirname(path)),
    );
  }

  @override
  String get path => nativeInstance.path;

  @override
  String toString() => 'CollRef($path)';
}

native.DocumentReference<Map<String, Object?>>? _unwrapDocumentReference(
  DocumentReference ref,
) => (ref as DocumentReferenceFlutter).nativeInstance;

CollectionReferenceFlutter _wrapCollectionReference(
  Firestore firestore,
  native.CollectionReference<Map<String, Object?>> nativeInstance,
) => CollectionReferenceFlutter(firestore, nativeInstance);

DocumentReferenceFlutter wrapDocumentReference(
  Firestore firestore,
  native.DocumentReference<Map<String, Object?>> nativeInstance,
) => DocumentReferenceFlutter(firestore, nativeInstance);

QuerySnapshotFlutter _wrapQuerySnapshot(
  Firestore firestore,
  native.QuerySnapshot<Map<String, Object?>> nativeInstance,
) => QuerySnapshotFlutter(firestore, nativeInstance);

DocumentSnapshotFlutter _wrapDocumentSnapshot(
  Firestore firestore,
  native.DocumentSnapshot<Map<String, Object?>> nativeInstance,
) => DocumentSnapshotFlutter(firestore, nativeInstance);

DocumentChangeFlutter _wrapDocumentChange(
  Firestore firestore,
  native.DocumentChange<Map<String, Object?>> nativeInstance,
) => DocumentChangeFlutter(firestore, nativeInstance);

DocumentChangeType? _wrapDocumentChangeType(
  native.DocumentChangeType nativeInstance,
) {
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
    with DocumentReferenceDefaultMixin, PathReferenceFlutterMixin
    implements DocumentReference {
  @override
  final Firestore firestore;
  final native.DocumentReference<Map<String, Object?>> nativeInstance;

  DocumentReferenceFlutter(this.firestore, this.nativeInstance);

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(firestore, nativeInstance.collection(path));

  @override
  Future delete() => nativeInstance.delete();

  @override
  Future<DocumentSnapshot> get() async =>
      _wrapDocumentSnapshot(firestore, await nativeInstance.get());

  @override
  String get id => nativeInstance.id;

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    var transformer = StreamTransformer.fromHandlers(
      handleData:
          (
            native.DocumentSnapshot<Map<String, Object?>>
            nativeDocumentSnapshot,
            EventSink<DocumentSnapshot> sink,
          ) {
            // devPrint('$this onSnapshot ${nativeDocumentSnapshot.data()}');
            try {
              sink.add(
                _wrapDocumentSnapshot(firestore, nativeDocumentSnapshot),
              );
            } catch (e) {
              if (kDebugMode) {
                print(
                  'onSnapshot.error ${nativeDocumentSnapshot.reference.path}: $e',
                );
              }
              rethrow;
            }
          },
    );
    return nativeInstance
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .transform(transformer);
  }

  // _TODO: implement parent
  @override
  CollectionReference get parent => _wrapCollectionReference(
    firestore,
    nativeInstance.firestore.collection(url.dirname(path)),
  );

  @override
  String get path => nativeInstance.path;

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) =>
      nativeInstance.set(
        documentDataToFlutterData(DocumentData(data)),
        unwrapSetOption(options),
      );

  @override
  Future update(Map<String, Object?> data) =>
      nativeInstance.update(documentDataToFlutterData(DocumentData(data)));

  @override
  String toString() => 'DocRef($path)';
}

class QuerySnapshotFlutter implements QuerySnapshot {
  final Firestore firestore;
  final native.QuerySnapshot<Map<String, Object?>> nativeInstance;

  QuerySnapshotFlutter(this.firestore, this.nativeInstance);

  @override
  List<DocumentSnapshot> get docs => nativeInstance.docs
      .map((nativeInstance) => _wrapDocumentSnapshot(firestore, nativeInstance))
      .toList();

  @override
  List<DocumentChange> get documentChanges => nativeInstance.docChanges
      .map((nativeInstance) => _wrapDocumentChange(firestore, nativeInstance))
      .toList();
}

class DocumentChangeFlutter implements DocumentChange {
  final Firestore firestore;
  final native.DocumentChange<Map<String, Object?>> nativeInstance;

  DocumentChangeFlutter(this.firestore, this.nativeInstance);

  @override
  DocumentSnapshot get document =>
      _wrapDocumentSnapshot(firestore, nativeInstance.doc);

  @override
  int get newIndex => nativeInstance.newIndex;

  @override
  int get oldIndex => nativeInstance.oldIndex;

  @override
  DocumentChangeType get type => _wrapDocumentChangeType(nativeInstance.type)!;
}
