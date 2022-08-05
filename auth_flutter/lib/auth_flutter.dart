import 'package:tekartik_firebase_auth/auth.dart';

import 'src/auth_flutter.dart' as auth_flutter;

export 'auth_flutter_api.dart';
export 'src/google_auth.dart' show GoogleAuthProvider;

/// The flutter auth service
AuthService get authServiceFlutter => auth_flutter.authService;

@Deprecated('Use authServiceFlutter')
AuthService get authService => authServiceFlutter;
