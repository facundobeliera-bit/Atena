import 'package:supabase_flutter/supabase_flutter.dart';
import 'atena_supabase_config.dart';

/// Requests only. The email link is verified by the isolated Auth return page.
/// No session, PKCE verifier, local credential or account lookup is persisted.
class PasswordRecovery {
  static const enabled = bool.fromEnvironment('ATENA_PASSWORD_RECOVERY_READY');
  static const returnUrl =
      'https://atena-staging.facundobeliera.workers.dev/auth/return.html';
  static const neutralMessage =
      'Si esta cuenta admite recuperación y el servicio puede enviar el correo, '
      'recibirás un enlace. Revisá también el correo no deseado. '
      'Si no llega, intentá más tarde o consultá al administrador del piloto.';

  final GoTrueClient _auth;
  PasswordRecovery(this._auth);

  static PasswordRecovery? fromEnvironment() {
    if (!enabled) return null;
    final config = AtenaSupabaseConfig.fromBuildEnvironment();
    if (config == null ||
        config.environment != AtenaRemoteEnvironment.staging) {
      return null;
    }
    return PasswordRecovery(
      GoTrueClient(
        url: '${config.url}/auth/v1',
        headers: {'apikey': config.publishableKey},
        autoRefreshToken: false,
        // The approved email template sends TokenHash in the fragment. Supabase
        // verifies it explicitly as recovery; there is no stored PKCE verifier.
        flowType: AuthFlowType.implicit,
      ),
    );
  }

  Future<void> request(String email) async {
    try {
      await _auth
          .resetPasswordForEmail(email.trim(), redirectTo: returnUrl)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Same result for unknown accounts, rate limits and transport failures.
      // Do not reflect provider errors, email addresses or account existence.
    }
  }

  void dispose() => _auth.dispose();
}
