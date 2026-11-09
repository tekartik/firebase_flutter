# firebase_flutter

The Flutter (FlutterFire) backends of the platform neutral tekartik Firebase
packages: the shared code depends on `tekartik_firebase`,
`tekartik_firebase_firestore`, `tekartik_firebase_auth`... and the Flutter app
plugs these implementations in.

## Packages

| Package | Path | What |
|---|---|---|
| `tekartik_firebase_flutter` | [firebase_flutter](firebase_flutter) | the `FirebaseApp` (`firebaseFlutter`, on firebase_core); start here |
| `tekartik_firebase_firestore_flutter` | [firestore_flutter](firestore_flutter) | Firestore (cloud_firestore) |
| `tekartik_firebase_auth_flutter` | [auth_flutter](auth_flutter) | Auth (firebase_auth) |
| `tekartik_firebase_storage_flutter` | [storage_flutter](storage_flutter) | Storage (firebase_storage) |
| `tekartik_firebase_functions_call_flutter` | [functions_call_flutter](functions_call_flutter) | callable Cloud Functions (cloud_functions) |
| `tekartik_firebase_vertex_ai_flutter` | [vertex_ai_flutter](vertex_ai_flutter) | Vertex AI / Gemini (firebase_ai) |

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: firebase_flutter
```

See the [firebase_flutter package README](firebase_flutter/README.md) for the
initialization and the product services.
