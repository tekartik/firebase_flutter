/// Gemini on Flutter through Firebase AI Logic (`firebase_ai`): the
/// `tekartik_firebase_vertex_ai` abstraction on a `firebaseFlutter` app.
///
/// Build a service once ([FirebaseGeminiAiServiceFlutter] for the Gemini
/// Developer API, [FirebaseVertexAiServiceFlutter] for Vertex AI), then
/// `service.vertexAi(app).generativeModel(...)`.
library;

export 'package:tekartik_firebase_vertex_ai/vertex_ai.dart';
export 'src/vertex_ai_constant.dart';
export 'src/vertex_ai_flutter.dart'
    show
        FirebaseVertexAiServiceFlutter,
        FirebaseVertexAiFlutter,
        FirebaseAiServiceFlutter,
        FirebaseGeminiAiServiceFlutter;
