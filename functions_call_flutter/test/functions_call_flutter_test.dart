library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_functions_call_flutter/functions_call_flutter.dart';

void main() {
  group('functions_call_flutter', () {
    test('api', () {
      // ignore: unnecessary_statements
      [
        FirebaseFunctionsCallService,
        firebaseFunctionsCallServiceFlutter,
        FirebaseFunctionsCall,
        FirebaseFunctionsCallable,
        FirebaseFunctionsCallableOptions,
      ];
    });
  });
}
