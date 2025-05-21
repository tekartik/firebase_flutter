import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timestamp', () {
    test('epoch', () {
      var timestamp = Timestamp(1, 123000000);
      expect(
        Timestamp.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch),
        timestamp,
      );
      timestamp = Timestamp(1, 123456000);
      expect(
        Timestamp.fromMicrosecondsSinceEpoch(timestamp.microsecondsSinceEpoch),
        timestamp,
      );
    });
  });
}
