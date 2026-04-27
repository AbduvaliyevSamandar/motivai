import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';

/// Thin wrapper around `google_sign_in` that returns the Google ID token
/// our backend can verify.
class GoogleAuth {
  static GoogleSignIn? _instance;

  static GoogleSignIn _signIn() {
    if (_instance != null) return _instance!;
    final id = K.googleClientId.isEmpty ? null : K.googleClientId;
    if (kIsWeb) {
      // Web: Google Identity Services needs the OAuth client ID.
      _instance = GoogleSignIn(
        clientId: id,
        scopes: const ['email', 'profile', 'openid'],
      );
    } else {
      // Android/iOS: package + SHA-1 (or bundle id) authorize the
      // platform client; we only set serverClientId so the issued ID
      // token's audience matches the Web client our backend verifies.
      _instance = GoogleSignIn(
        serverClientId: id,
        scopes: const ['email', 'profile', 'openid'],
      );
    }
    return _instance!;
  }

  /// Available when there's a configured client ID. Without it, Google
  /// sign-in won't work, so we hide the button entirely.
  static bool get available => K.googleClientId.isNotEmpty;

  /// Triggers the Google account picker and returns the ID token. Returns
  /// null if the user cancelled or anything failed.
  ///
  /// Always signs out first so the system always shows the account picker
  /// — otherwise Google quietly reuses the last signed-in account, which
  /// is a usability surprise.
  static Future<String?> signIn() async {
    if (!available) return null;
    try {
      try {
        await _signIn().signOut();
        await _signIn().disconnect();
      } catch (_) {
        // First call has nothing to disconnect — that's fine.
      }
      final account = await _signIn().signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    if (!available) return;
    try {
      await _signIn().signOut();
    } catch (_) {}
  }
}
