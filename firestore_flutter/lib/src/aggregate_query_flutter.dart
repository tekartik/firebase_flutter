import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart';

import 'import_firestore.dart';
import 'import_native.dart' as native;

class AggregateQueryFlutter implements AggregateQuery {
  final QueryFlutter queryFlutter;
  late final native.AggregateQuery nativeInstance;

  native.AggregateField _convertField(AggregateField field) {
    if (field is AggregateFieldCount) {
      return native.count();
    } else if (field is AggregateFieldAverage) {
      return native.average(field.field);
    } else if (field is AggregateFieldSum) {
      return native.sum(field.field);
    } else {
      throw ArgumentError(field);
    }
  }

  native.AggregateField? _convertFieldAt(
    List<AggregateField> fields,
    int index,
  ) {
    if (index < fields.length) {
      return _convertField(fields[index]);
    }
    return null;
  }

  AggregateQueryFlutter(this.queryFlutter, List<AggregateField> fields) {
    var i = 0;
    nativeInstance = queryFlutter.nativeInstance.aggregate(
      _convertFieldAt(fields, i++)!,
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
      _convertFieldAt(fields, i++),
    );
  }

  @override
  Future<AggregateQuerySnapshot> get() async {
    var nativeSnapshot = await nativeInstance.get();
    return AggregateQuerySnapshotFlutter(this, nativeSnapshot);
  }
}

class AggregateQuerySnapshotFlutter implements AggregateQuerySnapshot {
  final AggregateQueryFlutter aggregateQueryFlutter;
  late final native.AggregateQuerySnapshot nativeInstance;

  AggregateQuerySnapshotFlutter(
    this.aggregateQueryFlutter,
    this.nativeInstance,
  );

  @override
  int? get count => nativeInstance.count;

  @override
  double? getAverage(String field) => nativeInstance.getAverage(field);

  @override
  double? getSum(String field) => nativeInstance.getSum(field);

  @override
  Query get query => aggregateQueryFlutter.queryFlutter;
}
