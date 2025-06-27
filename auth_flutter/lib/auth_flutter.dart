import 'package:tekartik_firebase_auth/auth.dart';

import 'auth_flutter.dart';
import 'src/auth_flutter.dart' as auth_flutter;

export 'package:tekartik_firebase_auth/auth.dart';

export 'auth_flutter_api.dart';
export 'src/auth_flutter.dart' show FirebaseAuthFlutterExtension;

/// The flutter auth service
FirebaseAuthService get authServiceFlutter => auth_flutter.authService;

/// The flutter auth service
@Deprecated('Use authServiceFlutter')
AuthService get authService => authServiceFlutter;
