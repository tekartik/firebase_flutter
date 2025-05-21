import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:tekartik_firebase_vertex_ai/vertex_ai.dart';

/// Response flutter
class VaiGenerateContentResponseFlutter implements VaiGenerateContentResponse {
  /// Native response
  final fb.GenerateContentResponse nativeResponse;

  /// Constructor
  VaiGenerateContentResponseFlutter(this.nativeResponse);

  @override
  String? get text => nativeResponse.text;
}
