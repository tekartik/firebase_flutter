---
name: tekartik-firebase-vertex-ai-flutter-setup
description: >-
  Use when calling Gemini / Vertex AI from a Flutter app through Firebase AI
  Logic with tekartik_firebase_vertex_ai_flutter:
  FirebaseVertexAiServiceFlutter (agent platform, location, vertexAiLocationParis),
  FirebaseGeminiAiServiceFlutter (google AI), FirebaseAiServiceFlutter,
  FirebaseVertexAiFlutter, service.vertexAi(app), generativeModel(model:,
  generationConfig:), generateContent with VaiContent / Content.text /
  VaiContentTextPart / VaiContentDataPart, GenerationConfig and Schema for
  JSON output, and the
  package:tekartik_firebase_vertex_ai_flutter/vertex_ai_flutter.dart import on
  top of firebase_ai.
---

# tekartik_firebase_vertex_ai_flutter: Gemini on Flutter

`tekartik_firebase_vertex_ai_flutter` implements the
`tekartik_firebase_vertex_ai` abstraction with `package:firebase_ai` (Firebase
AI Logic). It offers the two backends of `firebase_ai`: the Gemini Developer
API (free tier) and the Vertex AI / agent platform one, behind the same
`FirebaseVertexAi` interface.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_vertex_ai_flutter:
      git:
        url: https://github.com/tekartik/firebase_flutter
        path: vertex_ai_flutter
  ```
  It brings `tekartik_firebase_vertex_ai`, `tekartik_firebase_flutter`,
  `tekartik_firebase_auth_flutter` and `firebase_ai`. Enable Firebase AI Logic
  for the project in the Firebase console first (and App Check in production).
* Import `package:tekartik_firebase_vertex_ai_flutter/vertex_ai_flutter.dart`.
  It re-exports `package:tekartik_firebase_vertex_ai/vertex_ai.dart`
  (`FirebaseVertexAi`, `FirebaseVertexAiService`, `VaiGenerativeModel`,
  `VaiContent`/`Content`, `VaiContentTextPart`/`TextPart`,
  `VaiContentDataPart`/`InlineDataPart`, `VaiGenerateContentResponse`,
  `GenerationConfig`, `Schema`, `SchemaType`,
  `vertexAiModelGemini1dot5Flash`) plus `vertexAiLocationParis`
  (`'europe-west9'`). It does **not** re-export `tekartik_firebase`: import
  `package:tekartik_firebase_flutter/firebase_flutter.dart` for the app.
* Pick a service by constructing it (the library exports the interfaces with
  their factory constructors; there is no exported singleton):
  - `FirebaseGeminiAiServiceFlutter()` - Gemini Developer API
    (`FirebaseAI.googleAI`), the free tier, no location.
  - `FirebaseVertexAiServiceFlutter(location: vertexAiLocationParis)` -
    Vertex AI agent platform (`FirebaseAI.agentPlatform`); `location` is
    optional and defaults to the `firebase_ai` default (`'global'`).
  Both implement `FirebaseAiServiceFlutter` / `FirebaseVertexAiService`, so
  the rest of the code does not care which one is used.
* Build the service **once** and keep it (top-level `final`, provider,
  injected field): each constructor call creates a new service with its own
  per-app cache, and every call registers a new product on the app.
* `service.vertexAi(app)` needs an app created by `firebaseFlutter`
  (`FirebaseAppFlutter`): it casts, so any other backend throws a
  `TypeError`. The result is cached per app and registered on it
  (`app.getProduct<FirebaseVertexAi>()`), and disposed with the app.
* `vertexAi.generativeModel(model: 'gemini-2.5-flash')`: always pass an
  explicit model, the fallback is `vertexAiModelGemini1dot5Flash`
  (`'gemini-1.5-flash'`), which is old. The model name is not validated at
  creation: a wrong one fails at `generateContent`.
* `await model.generateContent([Content.text('...')])` returns a
  `VaiGenerateContentResponse` whose `text` is **nullable** (blocked or empty
  answer): test it, never `!` it.
* Prompt parts: only `VaiContentTextPart` (text) and `VaiContentDataPart`
  (`mimeType` + `Uint8List`, for inline images/audio) are converted; any other
  `VaiContentPart` throws `'Unsupported part'`. Build them with
  `VaiContent.text`, `VaiContent.data`, `VaiContent.multi` and
  `VaiContent.model` (role `'user'` / `'model'`), and pass the conversation as
  the prompt list for multi-turn.
* `GenerationConfig` is mapped field by field to the native one:
  `candidateCount`, `maxOutputTokens`, `temperature`, `topP`, `topK`,
  `responseMimeType`, `responseSchema`. `stopSequences` is **dropped** here.
  For JSON output set `responseMimeType: 'application/json'` and a
  `responseSchema` (`Schema.object(properties: {...},
  optionalProperties: [...])`, `Schema.string()`, `Schema.number()`,
  `Schema.array(items: ...)`; every property is required unless listed in
  `optionalProperties`).
* `authService` (`FirebaseVertexAiServiceFlutter(authService: ...)`,
  `FirebaseGeminiAiServiceFlutter(authService: ...)`) must be a
  `FirebaseAuthServiceFlutter` (an `assert` fires otherwise) but is currently
  unused by the implementation: the native SDK picks up the signed-in user and
  App Check itself. Do not rely on it to select an identity.
* The wrapper is deliberately minimal: no streaming, chat session, function
  calling, safety settings, token counting, embedding or image generation. For
  those, use `firebase_ai` directly with the same app
  (`FirebaseAI.googleAI(app: app.nativeInstance)`) and keep the tekartik API
  for the shared code.
* There is no `close()`: the product lives as long as the `FirebaseApp`.
* Unit tests (`flutter test`) have no native plugin and no network: write the
  shared code against `FirebaseVertexAi` / `VaiGenerativeModel` so a fake can
  be substituted, and exercise the real service in `integration_test`.

## Examples

### Free tier (Gemini Developer API) setup and first prompt

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_vertex_ai_flutter/vertex_ai_flutter.dart';

/// Build the service once.
final aiService = FirebaseGeminiAiServiceFlutter();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await firebaseFlutter.initializeAppAsync();
  var vertexAi = aiService.vertexAi(app);
  var model = vertexAi.generativeModel(model: 'gemini-2.5-flash');
  var response = await model.generateContent([
    Content.text('Explain Firebase AI Logic in one sentence.'),
  ]);
  print(response.text ?? 'no answer');
  runApp(const Placeholder());
}
```

### Vertex AI in a given location

```dart
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_vertex_ai_flutter/vertex_ai_flutter.dart';

final vertexAiService = FirebaseVertexAiServiceFlutter(
  location: vertexAiLocationParis, // europe-west9
);

Future<String?> ask(FirebaseApp app, String question) async {
  var model = vertexAiService
      .vertexAi(app)
      .generativeModel(model: 'gemini-2.5-flash');
  var response = await model.generateContent([Content.text(question)]);
  return response.text;
}
```

### JSON output with a schema

```dart
import 'dart:convert';

import 'package:tekartik_firebase_vertex_ai_flutter/vertex_ai_flutter.dart';

Future<Map<String, Object?>?> extractPerson(
  FirebaseVertexAi vertexAi,
  String text,
) async {
  var model = vertexAi.generativeModel(
    model: 'gemini-2.5-flash',
    generationConfig: GenerationConfig(
      temperature: 0,
      responseMimeType: 'application/json',
      responseSchema: Schema.object(
        properties: {
          'name': Schema.string(),
          'age': Schema.integer(),
          'city': Schema.string(nullable: true),
        },
        optionalProperties: ['city'],
      ),
    ),
  );
  var response = await model.generateContent([
    Content.text('Extract the person from: $text'),
  ]);
  var answer = response.text;
  return answer == null ? null : jsonDecode(answer) as Map<String, Object?>;
}
```

### Multimodal prompt and multi-turn conversation

```dart
import 'dart:typed_data';

import 'package:tekartik_firebase_vertex_ai_flutter/vertex_ai_flutter.dart';

Future<String?> describeImage(
  VaiGenerativeModel model,
  Uint8List pngBytes,
) async {
  var response = await model.generateContent([
    VaiContent.multi([
      VaiContentTextPart('What is in this image?'),
      VaiContentDataPart('image/png', pngBytes),
    ]),
  ]);
  return response.text;
}

Future<String?> followUp(VaiGenerativeModel model, String previousAnswer) async {
  var response = await model.generateContent([
    VaiContent.text('List three french cities'),
    VaiContent.model([VaiContentTextPart(previousAnswer)]),
    VaiContent.text('Which one is the biggest?'),
  ]);
  return response.text;
}
```

### Native escape hatch for streaming

```dart
import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

/// The tekartik wrapper has no streaming: use firebase_ai on the same app.
Stream<String> streamAnswer(FirebaseApp app, String prompt) {
  var model = fb.FirebaseAI.googleAI(
    app: app.nativeInstance,
  ).generativeModel(model: 'gemini-2.5-flash');
  return model
      .generateContentStream([fb.Content.text(prompt)])
      .map((response) => response.text ?? '');
}
```

## Common mistakes

* Expecting an exported `firebaseVertexAiServiceFlutter` singleton: construct
  `FirebaseGeminiAiServiceFlutter()` / `FirebaseVertexAiServiceFlutter()` once
  yourself.
* Re-creating the service on every call (new cache, new product each time).
* Using the default model instead of passing a current one.
* Using `response.text!` on a possibly blocked answer.
* Passing `stopSequences` in `GenerationConfig` (ignored on Flutter) or
  expecting streaming / chat / function calling from this wrapper.
* Passing a memory or rest app to `service.vertexAi(app)` (TypeError).
