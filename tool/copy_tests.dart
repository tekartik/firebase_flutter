import 'dart:io';

import 'package:path/path.dart';

Future main() async {
  Future _copy(String src, String dst) async {
    Future copy(String file) async {
      var dstFile = join(dst, file);
      await Directory(dirname(dstFile)).create(recursive: true);
      await File(join(src, file)).copy(join(dst, file));
    }

    Future copyAll(List<String> files) async {
      for (var file in files) {
        print(file);
        await copy(file);
      }
    }

    var list = Directory(src)
        .listSync(recursive: true)
        .map((entity) => relative(entity.path, from: src));

    if (Directory(dst).existsSync()) {
      await Directory(dst).delete(recursive: true);
    }
    print(list);
    await copyAll([
      ...list,
    ]);
  }

  await _copy('../firebase.dart/firebase_flutter/test',
      'all_firebase_flutter/test/core');
  await _copy('../firebase_auth.dart/auth_flutter/test',
      'all_firebase_flutter/test/auth');
  await _copy('../firebase_firestore.dart/firestore_flutter/test',
      'all_firebase_flutter/test/firestore');
}
