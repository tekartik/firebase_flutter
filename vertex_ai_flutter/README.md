# tekartik_firebase_vertex_ai_flutter

Gemini on Flutter through Firebase AI Logic (`firebase_ai`): the
`tekartik_firebase_vertex_ai` abstraction (`FirebaseVertexAi`,
`VaiGenerativeModel`, `generateContent`) on a Flutter Firebase app, with the
Gemini Developer API (free tier) or the Vertex AI backend.

Flutter only (Android, iOS, macOS, web: the platforms of `firebase_ai`). Pure
Dart code uses `tekartik_firebase_vertex_ai_google` (api key) instead.

## Getting started

Enable Firebase AI Logic for the project in the Firebase console (and App
Check before production). Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_vertex_ai_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: vertex_ai_flutter
  tekartik_firebase_flutter:
    git:
      url: https://github.com/tekartik/firebase_flutter
      path: firebase_flutter
```

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_vertex_ai_flutter/vertex_ai_flutter.dart';

/// Built once: the Gemini Developer API (free tier).
final aiService = FirebaseGeminiAiServiceFlutter();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The native app, from the platform configuration (google-services...).
  var app = await firebaseFlutter.initializeAppAsync();
  var model = aiService
      .vertexAi(app)
      .generativeModel(model: vertexAiModelDefault);
  var response = await model.generateContent([
    Content.text('Say hello in french.'),
  ]);
  print(response.text ?? 'no answer');
}
```

`FirebaseVertexAiServiceFlutter(location: vertexAiLocationParis)` gives the
Vertex AI backend instead, same code after it.

## What to know

* Build the service once and keep it: each one has its own instances.
* The app must be a `firebaseFlutter` app (the service casts it).
* `response.text` is null for a blocked or empty answer.
* For JSON output: `GenerationConfig(responseMimeType: 'application/json',
  responseSchema: Schema.object(...))`.
* Prompt parts: text and inline data (`VaiContentDataPart`) only; no
  streaming, chat session or function calling here (use `firebase_ai` on the
  same native app for them).
* The `authService` parameter is not used: `firebase_ai` sends the signed in
  user and App Check tokens itself.
* Unit tests have no native plugin: write the shared code against
  `FirebaseVertexAi` / `VaiGenerativeModel` and fake them.

The [tekartik-firebase-vertex-ai-flutter-setup skill](skills/tekartik-firebase-vertex-ai-flutter-setup/SKILL.md)
has more examples (Vertex AI location, JSON schema, images, multi-turn).
