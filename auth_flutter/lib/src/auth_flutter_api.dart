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

/// Browser sign in result
abstract class AuthFlutter implements Auth {
  /// Sign in with popup
  Future<User?> googleSignIn();
}

/// Auth service for flutter
abstract class AuthServiceFlutter implements AuthService {}
