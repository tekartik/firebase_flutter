---
name: tekartik-firebase-storage-flutter-setup
description: >-
  Use when reading or writing Firebase Storage files from a Flutter app with
  tekartik_firebase_storage_flutter: storageServiceFlutter,
  storageServiceFlutter.storage(app), app.storage(), bucket(), bucket.file(),
  File.upload / writeAsBytes / writeAsString / readAsBytes / readAsString /
  exists / delete / getMetadata, StorageUploadFileOptions contentType,
  listing with GetFilesOptions / GetFilesResponse.nextQuery,
  storage.ref(path).getDownloadUrl(), and the
  package:tekartik_firebase_storage_flutter/storage_flutter.dart import on top
  of firebase_storage.
---

# tekartik_firebase_storage_flutter: Storage on Flutter

`tekartik_firebase_storage_flutter` implements the `tekartik_firebase_storage`
abstraction with `package:firebase_storage`. Shared code keeps using
`Storage`, `Bucket` and `File`; only the wiring knows about Flutter. It is a
partial implementation: read the caveats below before relying on a member.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_storage_flutter:
      git:
        url: https://github.com/tekartik/firebase_flutter
        path: storage_flutter
  ```
  It brings `tekartik_firebase_storage`, `tekartik_firebase_flutter` and
  `firebase_storage`; declare the ones you import directly too.
* Import `package:tekartik_firebase_storage_flutter/storage_flutter.dart`: it
  re-exports `package:tekartik_firebase_storage/storage.dart` (hence
  `tekartik_firebase/firebase.dart`) and adds exactly one name,
  `storageServiceFlutter`. Never import
  `package:tekartik_firebase_storage_flutter/src/...`.
* Get the product with `storageServiceFlutter.storage(app)`, `app` coming from
  `firebaseFlutter` (an `assert` fires on any other backend). It is cached per
  app and registered on it, so `app.storage()` (extension
  `TekartikFirebaseStorageFirebaseAppExt`) returns the same instance
  afterwards. `Storage` is a typedef of `FirebaseStorage`.
* `storage.bucket()` returns the default bucket of the app
  (`firebase_storage`'s `FirebaseStorage.bucket`); `storage.bucket(name)`
  targets another bucket by name (no `gs://` prefix). `bucket.exists()` only
  returns `true` for the default bucket and `bucket.create()` is not
  implemented (it throws `UnimplementedError`): create buckets in the console.
* Files are referenced by path inside the bucket: `bucket.file('dir/f.txt')`.
  Nothing happens until an operation is awaited.
  - write: `file.upload(bytes, options: StorageUploadFileOptions(contentType: 'image/png'))`,
    `file.writeAsBytes(bytes)`, `file.writeAsString(text)`. When no
    `contentType` is given it is inferred from the file extension.
  - read: `file.readAsBytes()`, `file.readAsString()`, `file.download()`
    (alias of `readAsBytes`). The whole object is loaded in memory (it reads
    the metadata `size` first), so keep it for small files.
  - `file.exists()` (a failing `getMetadata` means `false`, so a permission
    error also reads as `false`), `file.delete()`.
* Metadata: `file.metadata` is always `null` on Flutter (listed files
  included). `file.getMetadata()` returns a `FileMetadata` (`size`,
  `dateUpdated`, `md5Hash`, `contentType`, `cacheControl`) on any file
  (it throws for a missing file).
* Download urls: `storage.ref(path).getDownloadUrl()` (`path` relative to the
  default bucket, or a full `gs://bucket/path` url). `Reference` only exposes
  `getDownloadUrl()`; use `firebase_storage` directly for upload tasks with
  progress, resumable uploads or `putFile`.
* Listing: `bucket.getFiles(GetFilesOptions(prefix: 'dir/', maxResults: 50))`.
  The prefix is a plain string prefix (like Cloud Storage), the sub folders
  are walked. With `autoPaginate` (the default) every page is fetched and
  `maxResults` caps the total; with `autoPaginate: false` one call returns at
  most `maxResults` files and `nextQuery` gives the next page (null at the
  end): loop on `nextQuery`, not on the page size.
  `GetFilesResponse.files` holds `File` objects with their full path.
* Big uploads, progress, streamed downloads, metadata updates, custom
  metadata, `putFile`/`putString` and emulator configuration
  (`useStorageEmulator`) are not wrapped: reach for `firebase_storage`
  directly on the native instance (`FirebaseStorage.instanceFor(app:
  app.nativeInstance)`), keeping the tekartik API for everything shared.
* Unit tests (`flutter test`) have no native plugin: assert only on types
  (`storageServiceFlutter`, `StorageService`). Test your logic against
  `tekartik_firebase_storage_fs` (memory) and keep this service for the app
  and `integration_test`.

## Examples

### Wiring and uploading bytes

```dart
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_storage_flutter/storage_flutter.dart';

late Storage storage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await firebaseFlutter.initializeAppAsync();
  storage = storageServiceFlutter.storage(app);

  var file = storage.bucket().file('images/logo.png');
  await file.upload(
    Uint8List.fromList(<int>[1, 2, 3]),
    options: StorageUploadFileOptions(contentType: 'image/png'),
  );
  print('url: ${await storage.ref('images/logo.png').getDownloadUrl()}');
  runApp(const Placeholder());
}
```

### Text file round trip

```dart
import 'package:tekartik_firebase_storage_flutter/storage_flutter.dart';

Future<String?> readOrCreate(Storage storage, String path) async {
  var file = storage.bucket().file(path);
  if (await file.exists()) {
    print('size ${(await file.getMetadata()).size}');
    return await file.readAsString();
  }
  await file.writeAsString('hello');
  return null;
}
```

### Listing a folder, page by page

```dart
import 'package:tekartik_firebase_storage_flutter/storage_flutter.dart';

Future<List<String>> listPaths(Storage storage, String prefix) async {
  var paths = <String>[];
  var bucket = storage.bucket();
  GetFilesOptions? options = GetFilesOptions(
    prefix: prefix,
    maxResults: 50,
    autoPaginate: false,
  );
  while (options != null) {
    var response = await bucket.getFiles(options);
    paths.addAll(response.files.map((file) => file.name));
    options = response.nextQuery;
  }
  return paths;
}
```

### Displaying an image stored in the bucket

```dart
import 'package:flutter/material.dart';
import 'package:tekartik_firebase_storage_flutter/storage_flutter.dart';

class StorageImage extends StatelessWidget {
  final Storage storage;
  final String path;
  const StorageImage({super.key, required this.storage, required this.path});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: storage.ref(path).getDownloadUrl(),
      builder: (context, snapshot) {
        var url = snapshot.data;
        return url == null
            ? const CircularProgressIndicator()
            : Image.network(url);
      },
    );
  }
}
```

### Native escape hatch for a progress upload

```dart
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart' as native;
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

/// The tekartik wrapper has no upload task: use firebase_storage directly.
Stream<double> uploadWithProgress(
  FirebaseApp app,
  String path,
  Uint8List bytes,
) {
  var ref = native.FirebaseStorage.instanceFor(
    app: app.nativeInstance,
  ).ref(path);
  return ref
      .putData(bytes)
      .snapshotEvents
      .map((event) => event.bytesTransferred / event.totalBytes);
}
```

## Common mistakes

* Reading `file.metadata` (always null here) instead of `getMetadata()`.
* Stopping a manual listing loop (`autoPaginate: false`) on a short page
  instead of on a null `nextQuery`.
* Trusting `file.exists()` returning `false` after an error: it also means
  permission denied or no network.
* Expecting `bucket.create()` or a meaningful `bucket.exists()` for a
  non-default bucket.
* Passing a non-Flutter app to `storageServiceFlutter.storage(app)`.
* Downloading a large object with `readAsBytes()` (everything is in memory).
