import 'package:dev_test/package.dart';

Future main() async {
  for (var dir in [
    'all_firebase_flutter',
  ]) {
    await packageRunCi(dir);
  }
}
