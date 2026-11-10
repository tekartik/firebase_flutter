# tekartik_firebase_firestore_flutter

The Flutter backend of [tekartik_firebase_firestore](https://github.com/tekartik/firebase_firestore.dart/tree/master/firestore),
on top of the FlutterFire `cloud_firestore` plugin: shared code uses
`Firestore`, `CollectionReference`, `Query`... and runs on this backend in
the app, on a memory backend in tests.

Platforms of `cloud_firestore`: Android, iOS, macOS, Windows and web.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_firestore_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: firestore_flutter
```

Initialize the app with [tekartik_firebase_flutter](../firebase_flutter/README.md),
then get the Firestore of the app:

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

Future<List<String>> adults() async {
  var users = firestore.collection('users');
  await users.doc('alice').set({'name': 'Alice', 'age': 30});
  var snapshot = await users
      .where('age', isGreaterThanOrEqualTo: 18, isLessThan: 65)
      .orderBy('age')
      .get();
  return snapshot.docs.map((doc) => doc.ref.id).toList();
}
```

`package:tekartik_firebase_firestore_flutter/firestore_flutter.dart`
re-exports the whole Firestore abstraction; it only adds
`firestoreServiceFlutter` (one service, one `Firestore` per app) and
`FirestoreFlutter` (emulator).

## What is supported

* Reads, writes, batches, transactions, queries (every condition of a
  `where` call applies, cursors by values or by snapshot), listeners
  (`onSnapshot`, with `SnapshotMetadata`), `count()` and `aggregate`.
* Values: `Timestamp`, `DateTime` (stored as a timestamp), `Blob`,
  `GeoPoint`, `VectorValue`, `DocumentReference` and the `FieldValue`s.
* Not supported: `select` (full documents are returned),
  `createTime`/`updateTime` of a snapshot (null),
  `listDocuments` of missing documents. Check `firestore.service.supportsXxx`
  in shared code.

## Common pitfalls

* The app must be a Flutter app (`firebaseFlutter`).
* Emulator: `await (firestore as FirestoreFlutter).useFirestoreEmulator('localhost', 8080)`
  right after getting the `Firestore`, before any read or write.
* A value of another type (a model object, a firestore logger reference)
  throws when written: convert to plain values first.
* `getAll(refs)` is a `Future.wait` of gets, not atomic: use a transaction
  when you need consistency.
* Unit tests: call `setupFirebaseCoreMocks()`
  (`package:firebase_core_platform_interface/test.dart`) to create the app and
  the `Firestore`; there is no native plugin to read or write, test the data
  code on a memory backend (`tekartik_firebase_firestore_sembast`).

The [tekartik-firebase-firestore-flutter-setup skill](skills/tekartik-firebase-firestore-flutter-setup/SKILL.md)
has more examples.
