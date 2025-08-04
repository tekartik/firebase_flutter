import 'package:tekartik_firebase_auth/auth.dart';

import 'auth_flutter.dart';
import 'src/auth_flutter.dart' as auth_flutter;

export 'package:tekartik_firebase_auth/auth.dart';

export 'auth_flutter_api.dart';
export 'src/auth_flutter.dart' show FirebaseAuthFlutterExtension;

/// The flutter auth service
FirebaseAuthService get firebaseAuthServiceFlutter => auth_flutter.authService;

/// Compat
AuthService get authServiceFlutter => firebaseAuthServiceFlutter;

/// The flutter auth service
@Deprecated('Use authServiceFlutter')
AuthService get authService => firebaseAuthServiceFlutter;
