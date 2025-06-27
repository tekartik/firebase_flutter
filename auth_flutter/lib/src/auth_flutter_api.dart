import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:tekartik_firebase_auth/auth.dart';

/// Browser sign in options
class AuthSignInOptionsWeb implements AuthSignInOptions {
  late bool _isPopup;

  /// True if it is a popup
  bool get isPopup => _isPopup;

  /// True if it is a redirect
  bool get isRedirect => !_isPopup;

  /// Constructor
  AuthSignInOptionsWeb({bool isPopup = false, bool isRedirect = false}) {
    _isPopup = !isRedirect;
  }
}

/// compat
typedef AuthFlutter = FirebaseAuthFlutter;

/// Browser sign in result
abstract class FirebaseAuthFlutter implements Auth {
  /// The native instance
  native.FirebaseAuth get nativeInstance;
}

/// compat
typedef AuthServiceFlutter = FirebaseAuthServiceFlutter;

/// Auth service for flutter
abstract class FirebaseAuthServiceFlutter implements FirebaseAuthService {
  @override
  FirebaseAuthFlutter auth(App app);
}
