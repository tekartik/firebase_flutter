// Checks of the native calls with fakes of the plugin classes (no device).
// ignore_for_file: implementation_imports, depend_on_referenced_packages, subtype_of_sealed_class
library;

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' as native;
import 'package:cloud_firestore_platform_interface/src/method_channel/utils/firestore_message_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_flutter/src/document_snapshot_flutter.dart';
import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart';

/// Records the calls, each call returns a new fake query.
class _FakeQuery implements native.Query<Map<String, Object?>> {
  final List<Invocation> calls;

  _FakeQuery([List<Invocation>? calls]) : calls = calls ?? [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    return _FakeQuery(calls);
  }
}

class _FakeFirestore implements Firestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNativeReference
    implements native.DocumentReference<Map<String, Object?>> {
  @override
  String get id => 'doc';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNativeSnapshot
    implements native.DocumentSnapshot<Map<String, Object?>> {
  @override
  native.DocumentReference<Map<String, Object?>> get reference =>
      _FakeNativeReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A query whose get fails like the plugin does.
class _FailingQuery implements native.Query<Map<String, Object?>> {
  @override
  Future<native.QuerySnapshot<Map<String, Object?>>> get([
    native.GetOptions? options,
  ]) async => throw native.FirebaseException(
    plugin: 'cloud_firestore',
    code: 'permission-denied',
    message: 'denied',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firestore_flutter_fake', () {
    test('where several conditions in one call', () {
      var fake = _FakeQuery();
      var query =
          QueryFlutter(
                _FakeFirestore(),
                fake,
              ).where('v', isGreaterThan: 1, isLessThan: 5)
              as QueryFlutter;
      // A single native call with both conditions (a fake receives every
      // named parameter, the unset ones with their default).
      var named = fake.calls.single.namedArguments;
      expect(named[#isGreaterThan], 1);
      expect(named[#isLessThan], 5);
      expect(query.queryInfo!.wheres.length, 2);
    });

    test('where isEqualTo and arrayContainsAny', () {
      var fake = _FakeQuery();
      QueryFlutter(
        _FakeFirestore(),
        fake,
      ).where('v', isEqualTo: 1, arrayContainsAny: [2]);
      var named = fake.calls.single.namedArguments;
      expect(named[#isEqualTo], 1);
      expect(named[#arrayContainsAny], [2]);
    });

    test('cursors with a snapshot', () {
      var fake = _FakeQuery();
      var query = QueryFlutter(_FakeFirestore(), fake);
      var snapshot = DocumentSnapshotFlutter(
        _FakeFirestore(),
        _FakeNativeSnapshot(),
      );
      query.startAt(snapshot: snapshot);
      query.startAfter(snapshot: snapshot);
      query.endAt(snapshot: snapshot);
      query.endBefore(snapshot: snapshot);
      expect(fake.calls.map((call) => call.memberName), [
        #startAtDocument,
        #startAfterDocument,
        #endAtDocument,
        #endBeforeDocument,
      ]);
      query.endAt(values: [1]);
      expect(fake.calls.last.memberName, #endAt);
      expect(fake.calls.last.positionalArguments.single, [1]);
    });

    test('arrayUnion and arrayRemove elements converted', () {
      var codec = const FirestoreMessageCodec();
      // Encoding a tekartik value (not converted) throws.
      codec.encodeMessage(
        toNativeValue(FieldValue.arrayUnion([Timestamp(1, 0)])),
      );
      codec.encodeMessage(
        toNativeValue(
          FieldValue.arrayRemove([
            Blob(Uint8List.fromList([1])),
          ]),
        ),
      );
    });

    test('plugin errors are FirestoreException', () async {
      var query = QueryFlutter(_FakeFirestore(), _FailingQuery());
      try {
        await query.get();
        fail('should fail');
      } catch (e) {
        expect(e, isA<FirestoreException>());
        expect(e, isA<native.FirebaseException>());
        expect((e as FirestoreException).code, 'permission-denied');
      }
    });
  });
}
