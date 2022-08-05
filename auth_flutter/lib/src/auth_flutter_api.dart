import 'package:tekartik_firebase_auth/auth.dart';

/// Browser sign in options
class AuthSignInOptionsWeb implements AuthSignInOptions {
  late bool _isPopup;

  // Default
  bool get isPopup => _isPopup == true;

  bool get isRedirect => _isPopup != true;

  AuthSignInOptionsWeb({bool isPopup = false, bool isRedirect = false}) {
    _isPopup = !isRedirect;
  }
}

abstract class AuthFlutter {
  Future<User?> googleSignIn();
}

abstract class AuthServiceFlutter implements AuthService {}
