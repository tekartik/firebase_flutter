import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_vertex_ai/vertex_ai.dart';
import 'package:tekartik_firebase_vertex_ai_flutter/src/vertex_ai_model_flutter.dart';

/// Flutter service using vertex ai
final FirebaseVertexAiServiceFlutter firebaseVertexAiServiceFlutter =
    _FirebaseVertexAiServiceFlutter();

/// Flutter service (with free-tier)
final FirebaseGeminiAiServiceFlutter firebaseGeminiAiServiceFlutter =
    _FirebaseGeminiAiServiceFlutter();

/// Flutter service interface
abstract class FirebaseAiServiceFlutter implements FirebaseVertexAiService {}

/// Flutter service interface
abstract class FirebaseVertexAiServiceFlutter
    implements FirebaseAiServiceFlutter {
  /// Optionnal auth service
  ///
  factory FirebaseVertexAiServiceFlutter({
    FirebaseAuthService? authService,
    String? location,
  }) {
    assert(
      authService is FirebaseAuthServiceFlutter?,
      'authService should be a FirebaseAuthServiceFlutter',
    );
    return _FirebaseVertexAiServiceFlutter(
      authServiceFlutter: authService,
      location: location,
    );
  }
}

/// Flutter service interface
abstract class FirebaseGeminiAiServiceFlutter
    implements FirebaseAiServiceFlutter {
  /// Optionnal auth service
  ///
  factory FirebaseGeminiAiServiceFlutter({FirebaseAuthService? authService}) {
    assert(
      authService is FirebaseAuthServiceFlutter?,
      'authService should be a FirebaseAuthServiceFlutter',
    );
    return _FirebaseGeminiAiServiceFlutter(authServiceFlutter: authService);
  }
}

class _FirebaseVertexAiServiceFlutter
    with FirebaseProductServiceMixin<FirebaseVertexAi>
    implements FirebaseVertexAiServiceFlutter {
  final String? location;
  final FirebaseAuthService? authServiceFlutter;

  _FirebaseVertexAiServiceFlutter({this.authServiceFlutter, this.location});

  @override
  FirebaseVertexAiFlutter vertexAi(App app) {
    return getInstance(app, () {
      var appFlutter = app as FirebaseAppFlutter;
      var nativeAuth = authServiceFlutter?.auth(app).nativeInstance;
      var fbVertexAi = fb.FirebaseAI.vertexAI(
        app: appFlutter.nativeInstance!,
        auth: nativeAuth,
        location: location,
      );
      return _FirebaseVertexAiFlutter(this, appFlutter, fbVertexAi);
    });
  }
}

class _FirebaseGeminiAiServiceFlutter
    with FirebaseProductServiceMixin<FirebaseVertexAi>
    implements FirebaseGeminiAiServiceFlutter {
  final FirebaseAuthService? authServiceFlutter;

  _FirebaseGeminiAiServiceFlutter({this.authServiceFlutter});

  @override
  FirebaseVertexAiFlutter vertexAi(App app) {
    return getInstance(app, () {
      var appFlutter = app as FirebaseAppFlutter;
      var nativeAuth = authServiceFlutter?.auth(app).nativeInstance;
      var fbVertexAi = fb.FirebaseAI.googleAI(
        app: appFlutter.nativeInstance!,
        auth: nativeAuth,
      );
      return _FirebaseVertexAiFlutter(this, appFlutter, fbVertexAi);
    });
  }
}

class _FirebaseVertexAiFlutter
    with FirebaseAppProductMixin<FirebaseVertexAi>
    implements FirebaseVertexAiFlutter {
  final FirebaseAiServiceFlutter serviceFlutter;
  final FirebaseAppFlutter appFlutter;
  final fb.FirebaseAI fbVertexAi;

  _FirebaseVertexAiFlutter(
    this.serviceFlutter,
    this.appFlutter,
    this.fbVertexAi,
  );

  @override
  FirebaseApp get app => appFlutter;

  @override
  VaiGenerativeModel generativeModel({
    String? model,
    GenerationConfig? generationConfig,
  }) {
    model ??= vertexAiModelGemini1dot5Flash;
    var nativeModel = fbVertexAi.generativeModel(
      model: model,
      generationConfig: generationConfig?.toFbGenerationConfig(),
    );
    return VaiGenerativeModelFlutter(this, nativeModel);
  }
}

/// Flutter service
abstract class FirebaseVertexAiFlutter implements FirebaseVertexAi {}

extension on SchemaType {
  fb.SchemaType toFbSchemaType() {
    switch (this) {
      case SchemaType.object:
        return fb.SchemaType.object;
      case SchemaType.array:
        return fb.SchemaType.array;
      case SchemaType.integer:
        return fb.SchemaType.integer;
      case SchemaType.boolean:
        return fb.SchemaType.boolean;
      case SchemaType.string:
        return fb.SchemaType.string;
      case SchemaType.number:
        return fb.SchemaType.number;
    }
  }
}

extension on Schema {
  fb.Schema toFbSchema() {
    return fb.Schema(
      type.toFbSchemaType(),
      items: items?.toFbSchema(),
      format: format,
      description: description,
      enumValues: enumValues,
      nullable: nullable,
      properties: properties?.map(
        (key, value) => MapEntry(key, value.toFbSchema()),
      ),
      optionalProperties: optionalProperties,
    );
  }
}

extension on GenerationConfig {
  fb.GenerationConfig toFbGenerationConfig() {
    return fb.GenerationConfig(
      candidateCount: candidateCount,
      maxOutputTokens: maxOutputTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
      responseMimeType: responseMimeType,
      responseSchema: responseSchema?.toFbSchema(),
    );
  }
}
