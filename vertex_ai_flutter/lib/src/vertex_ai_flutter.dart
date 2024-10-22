import 'package:firebase_vertexai/firebase_vertexai.dart' as fb;
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';
import 'package:tekartik_firebase_vertex_ai/vertex_ai.dart';
import 'package:tekartik_firebase_vertex_ai_flutter/src/vertex_ai_model_flutter.dart';

/// Flutter service
final FirebaseVertexAiServiceFlutter firebaseVertexAiServiceFlutter =
    _FirebaseVertexAiServiceFlutter();

/// Flutter service interface
abstract class FirebaseVertexAiServiceFlutter
    implements FirebaseVertexAiService {
  /// Optionnal auth service
  ///
  factory FirebaseVertexAiServiceFlutter(
      {FirebaseAuthService? authService, String? location}) {
    assert(authService is FirebaseAuthServiceFlutter?,
        'authService should be a FirebaseAuthServiceFlutter');
    return _FirebaseVertexAiServiceFlutter(
        authServiceFlutter: authService, location: location);
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
      var fbVertexAi = fb.FirebaseVertexAI.instanceFor(
          app: appFlutter.nativeInstance!,
          auth: nativeAuth,
          location: location);
      return _FirebaseVertexAiFlutter(this, appFlutter, fbVertexAi);
    });
  }
}

class _FirebaseVertexAiFlutter
    with FirebaseAppProductMixin<FirebaseVertexAi>
    implements FirebaseVertexAiFlutter {
  final FirebaseVertexAiServiceFlutter serviceFlutter;
  final FirebaseAppFlutter appFlutter;
  final fb.FirebaseVertexAI fbVertexAi;

  _FirebaseVertexAiFlutter(
      this.serviceFlutter, this.appFlutter, this.fbVertexAi);

  @override
  FirebaseApp get app => appFlutter;

  @override
  VaiGenerativeModel generativeModel({String? model}) {
    model ??= vertexAiModelGemini1dot5Flash;
    var nativeModel = fbVertexAi.generativeModel(model: model);
    return VaiGenerativeModelFlutter(this, nativeModel);
  }
}

/// Flutter service
abstract class FirebaseVertexAiFlutter implements FirebaseVertexAi {}
