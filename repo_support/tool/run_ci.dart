import 'package:dev_build/package.dart';
import 'package:path/path.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'storage_flutter',
    'firestore_flutter',
    'firebase_flutter',
    'auth_flutter',
    'functions_call_flutter',
    'vertex_ai_flutter',
  ]) {
    await packageRunCi(join(topDir, dir));
  }
}
