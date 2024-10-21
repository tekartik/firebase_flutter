import 'package:firebase_vertexai/firebase_vertexai.dart' as fb;
import 'package:tekartik_firebase_vertex_ai/vertex_ai.dart';
import 'package:tekartik_firebase_vertex_ai_flutter/src/vertex_ai_api_flutter.dart';
import 'package:tekartik_firebase_vertex_ai_flutter/src/vertex_ai_flutter.dart';

extension on Iterable<VaiContent> {
  Iterable<fb.Content> toNative() {
    return map((e) => e.toNative());
  }
}

extension on VaiContent {
  fb.Content toNative() {
    return fb.Content(role, parts.map((e) => e.toNative()).toList());
  }
}

extension on VaiContentPart {
  fb.Part toNative() {
    var part = this;
    if (part is VaiContentTextPart) {
      return fb.TextPart(part.text);
    } else if (part is VaiContentDataPart) {
      return fb.DataPart(part.mimeType, part.bytes);
    } else {
      throw 'Unsupported part $part (${part.runtimeType})';
    }
  }
}

/// Flutter impl
class VaiGenerativeModelFlutter implements VaiGenerativeModel {
  /// Vertex AI
  final FirebaseVertexAiFlutter vertexAiFlutter;

  /// The native instance
  final fb.GenerativeModel nativeInstance;

  /// Constructor
  VaiGenerativeModelFlutter(this.vertexAiFlutter, this.nativeInstance);

  @override
  Future<VaiGenerateContentResponse> generateContent(
      Iterable<VaiContent> prompt) async {
    var nativeResponse =
        await nativeInstance.generateContent(prompt.toNative());
    return VaiGenerateContentResponseFlutter(nativeResponse);
  }
}
