# tekartik_firebase_storage_flutter

The Flutter backend of [tekartik_firebase_storage](https://github.com/tekartik/firebase_storage.dart/tree/master/storage),
on top of the FlutterFire `firebase_storage` plugin: shared code uses
`Storage`, `Bucket` and `File`, the app plugs this implementation in.

Platforms of `firebase_storage`: Android, iOS, macOS and web.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_storage_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: storage_flutter
```

Initialize the app with [tekartik_firebase_flutter](../firebase_flutter/README.md),
then get the storage of the app:

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_storage_flutter/storage_flutter.dart';

late Storage storage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await firebaseFlutter.initializeAppAsync();
  storage = storageServiceFlutter.storage(app);
  runApp(const Placeholder());
}

Future<String> roundTrip() async {
  var file = storage.bucket().file('notes/hello.txt');
  await file.writeAsString('hello');
  var url = await storage.ref('notes/hello.txt').getDownloadUrl();
  debugPrint('download url: $url');
  return await file.readAsString();
}
```

## What is supported

* Files: `upload` (content type from the extension unless given),
  `writeAsBytes`/`writeAsString`, `readAsBytes`/`readAsString`/`download`,
  `exists`, `delete`, `getMetadata`.
* Listing: `bucket.getFiles(GetFilesOptions(prefix: 'dir/', maxResults: 100))`,
  every page by default (`autoPaginate`), or one page and its `nextQuery`
  with `autoPaginate: false`.
* Download urls: `storage.ref(path).getDownloadUrl()` (a path of the default
  bucket or a `gs://bucket/path` url).
* Not wrapped: upload tasks with progress, custom metadata, the emulator
  (`useStorageEmulator`), bucket creation. Use `firebase_storage` directly on
  `app.nativeInstance` for them.

## Common pitfalls

* The app must be a Flutter app (`firebaseFlutter`).
* A read loads the whole file in memory: keep it for small files.
* `file.exists()` is `false` on any error (permission denied, network), not
  only for a missing file.
* `bucket.exists()` is `true` for the default bucket of the app only.
* `file.metadata` is always `null` here: `await file.getMetadata()`.

The [tekartik-firebase-storage-flutter-setup skill](skills/tekartik-firebase-storage-flutter-setup/SKILL.md)
has more examples.
