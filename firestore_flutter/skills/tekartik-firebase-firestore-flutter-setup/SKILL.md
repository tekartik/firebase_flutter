---
name: tekartik-firebase-firestore-flutter-setup
description: >-
  Use when running tekartik_firebase_firestore code in a Flutter app on top of
  cloud_firestore with tekartik_firebase_firestore_flutter:
  firestoreServiceFlutter, firestoreServiceFlutter.firestore(app),
  FirestoreFlutter, FirestoreFlutterExt.useFirestoreEmulator, the
  package:tekartik_firebase_firestore_flutter/firestore_flutter.dart import,
  the supportsXxx flags of the flutter service (no select, no
  createTime/updateTime, aggregate queries, vector values, blobs), one
  condition per where() call, onSnapshot / includeMetadataChanges and
  SnapshotMetadata on Flutter.
---

# tekartik_firebase_firestore_flutter: Firestore on Flutter

`tekartik_firebase_firestore_flutter` implements the
`tekartik_firebase_firestore` abstraction with `package:cloud_firestore`. All
your code keeps using `Firestore`, `CollectionReference`, `DocumentReference`
and `Query`; this package only provides the `FirestoreService` that binds them
to the native FlutterFire plugin.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_firestore_flutter:
      git:
        url: https://github.com/tekartik/firebase_flutter
        path: firestore_flutter
      version: '>=0.4.0'
  ```
  It brings `tekartik_firebase_firestore`, `tekartik_firebase_flutter` and
  `cloud_firestore`; declare the ones you import directly too.
* Import `package:tekartik_firebase_firestore_flutter/firestore_flutter.dart`:
  it re-exports the whole `package:tekartik_firebase_firestore/firestore.dart`
  (hence also `tekartik_firebase/firebase.dart`), so a Flutter file needs no
  other Firestore import. Never import
  `package:tekartik_firebase_firestore_flutter/src/...`.
* Only two names are added: `firestoreServiceFlutter` (the `FirestoreService`)
  and the `FirestoreFlutter` interface with its `FirestoreFlutterExt`. The bare
  `firestoreService` getter of this library is `@Deprecated`: always write
  `firestoreServiceFlutter`.
* Get the database with `firestoreServiceFlutter.firestore(app)` where `app`
  comes from `firebaseFlutter` (`tekartik_firebase_flutter`). The app must be a
  Flutter app (`FirebaseAppFlutter`: an `assert` fires otherwise) and the
  instance is cached per app. Keep the `Firestore` in one place (a provider, a
  singleton holder) and pass it around; write shared code against `Firestore`,
  never against this package.
* Emulator: the extension method is on `FirestoreFlutter`, so cast:
  `await (firestore as FirestoreFlutter).useFirestoreEmulator('localhost', 8080)`.
  It sets the native `Settings(host: 'host:port', sslEnabled: false,
  persistenceEnabled: false)` and calls `useFirestoreEmulator` with
  `automaticHostMapping: true` (so `10.0.2.2` on the Android emulator is
  handled). Call it right after getting the `Firestore`, before any read or
  write.
* `firestore.settings(FirestoreSettings(...))` is effectively a no-op here: it
  resets the native settings to the defaults. Configure persistence or cache
  size through `cloud_firestore` directly if you need it.
* Feature flags of `firestoreServiceFlutter` (check them in shared code with
  `firestore.service.supportsXxx`): `supportsTimestamps`,
  `supportsTimestampsInSnapshots`, `supportsFieldValueArray`,
  `supportsAggregateQueries`, `supportsVectorValue`, `supportsBlobs` and
  `supportsTrackChanges` are `true`; `supportsQuerySelect`,
  `supportsDocumentSnapshotTime` and `supportsQuerySnapshotCursor` are `false`.
* Consequences of the `false` flags: `query.select([...])` silently returns the
  query unchanged (always full documents), and `snapshot.createTime` /
  `snapshot.updateTime` are always `null` - store your own
  `FieldValue.serverTimestamp` field when you need a modification time.
* One condition per `where()` call: the flutter implementation applies the
  first non-default parameter only (`isEqualTo`, then `isLessThan`,
  `isLessThanOrEqualTo`, `isGreaterThan`, `isGreaterThanOrEqualTo`,
  `arrayContains`, then the `arrayContainsAny`/`whereIn`/`isNull` group).
  Chain `.where(...).where(...)` instead of passing two criteria at once.
* Values are converted both ways: `Timestamp`, `Blob`, `GeoPoint`,
  `VectorValue`, `DocumentReference`, `FieldValue.serverTimestamp`,
  `FieldValue.delete`, `FieldValue.arrayUnion/arrayRemove` and nested
  lists/maps. Anything else throws `'not supported <type>'` at write time, so
  convert your models to plain JSON values (`DocumentData` helpers) first.
* Snapshots: `docRef.onSnapshot(includeMetadataChanges: true)` and
  `query.onSnapshot(...)` are native streams; `snapshot.metadata`
  (`hasPendingWrites`, `isFromCache`) is real here and is what offline mode
  exposes. Cancel the subscriptions in `dispose()`.
* Aggregates are native: `query.count()` and
  `query.aggregate([AggregateField.count(), AggregateField.sum('x')])` (up to
  30 fields). `firestore.getAll(refs)` is *not* atomic on Flutter, it is a
  `Future.wait` of individual gets - use `runTransaction` when you need
  consistency.
* Unit tests (`flutter test`) have no native plugin: only the service metadata
  (`firestoreServiceFlutter.supportsBlobs`, ...) can be asserted. Test your
  logic against an in-memory service (`tekartik_firebase_firestore_sembast`)
  and keep the flutter service for the app and `integration_test`.

## Examples

### Wiring the app and the Firestore instance

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_firestore_flutter/firestore_flutter.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

late Firestore firestore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await firebaseFlutter.initializeAppAsync();
  firestore = firestoreServiceFlutter.firestore(app);
  runApp(const Placeholder());
}
```

### Local emulator during development

```dart
import 'package:tekartik_firebase_firestore_flutter/firestore_flutter.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

/// [host] is `localhost` on desktop/ios, `10.0.2.2` on the android emulator
/// (handled by automaticHostMapping).
Future<Firestore> devFirestore({
  String host = 'localhost',
  int port = 8080,
}) async {
  var app = await firebaseFlutter.initializeAppAsync();
  var firestore = firestoreServiceFlutter.firestore(app);
  await (firestore as FirestoreFlutter).useFirestoreEmulator(host, port);
  return firestore;
}
```

### Reading, writing and querying

```dart
import 'package:tekartik_firebase_firestore_flutter/firestore_flutter.dart';

Future<void> demo(Firestore firestore) async {
  var users = firestore.collection('users');
  await users.doc('123').set({
    'name': 'John',
    'age': 42,
    'updated': FieldValue.serverTimestamp,
  });

  var snapshot = await users.doc('123').get();
  if (snapshot.exists) {
    print(snapshot.data['name']);
  }

  // One condition per where() call.
  var query = users
      .where('age', isGreaterThanOrEqualTo: 18)
      .where('active', isEqualTo: true)
      .orderBy('age')
      .limit(10);
  for (var doc in (await query.get()).docs) {
    print('${doc.ref.id}: ${doc.data}');
  }
  print('adults: ${await users.where('age', isGreaterThanOrEqualTo: 18).count()}');
}
```

### Live list widget on a query

```dart
import 'package:flutter/material.dart';
import 'package:tekartik_firebase_firestore_flutter/firestore_flutter.dart';

class UserList extends StatelessWidget {
  final Firestore firestore;
  const UserList({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').orderBy('name').onSnapshot(),
      builder: (context, snapshot) {
        var docs = snapshot.data?.docs ?? <DocumentSnapshot>[];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) => ListTile(
            title: Text('${docs[index].data['name']}'),
            subtitle: Text(docs[index].ref.path),
          ),
        );
      },
    );
  }
}
```

### Transaction and batch

```dart
import 'package:tekartik_firebase_firestore_flutter/firestore_flutter.dart';

Future<int> increment(Firestore firestore, String path) async {
  return await firestore.runTransaction((txn) async {
    var ref = firestore.doc(path);
    var snapshot = await txn.get(ref);
    var count = (snapshot.exists ? snapshot.data['count'] as int? : null) ?? 0;
    txn.set(ref, {'count': count + 1}, SetOptions(merge: true));
    return count + 1;
  });
}

Future<void> deleteAll(Firestore firestore, List<DocumentReference> refs) async {
  var batch = firestore.batch();
  for (var ref in refs) {
    batch.delete(ref);
  }
  await batch.commit();
}
```

## Common mistakes

* Passing a non-Flutter `FirebaseApp` (memory, rest) to
  `firestoreServiceFlutter.firestore(app)`.
* Two criteria in a single `where()` call: the second one is ignored.
* Expecting `select()`, `snapshot.updateTime` or `snapshot.createTime` to work.
* Calling `useFirestoreEmulator` on a `Firestore` typed variable without the
  `as FirestoreFlutter` cast, or after the first read/write.
* Using `firestore.settings(...)` to configure persistence.
* Writing a custom model object directly: convert to plain values first.
