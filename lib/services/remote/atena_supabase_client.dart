import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_auth_storage.dart';

import 'atena_supabase_config.dart';

class AtenaSupabaseClient {
  AtenaSupabaseClient._();

  static bool _initialized = false;
  static SecureAuthLocalStorage? _secureStorage;

  static Future<void> initializeIfConfigured() async {
    final config = AtenaSupabaseConfig.fromBuildEnvironment();
    if (config == null || _initialized) return;
    var authOptions = const FlutterAuthClientOptions();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final store = SecureAuthStore(await SharedPreferences.getInstance());
      _secureStorage = SecureAuthLocalStorage(
        store,
        'sb-${Uri.parse(config.url).host.split('.').first}-auth-token',
      );
      authOptions = FlutterAuthClientOptions(
        localStorage: _secureStorage,
        pkceAsyncStorage: SecureAuthPkceStorage(store),
      );
    }
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      authOptions: authOptions,
      debug: false,
    );
    _initialized = true;
  }

  static SupabaseClient? get optionalClient =>
      _initialized ? Supabase.instance.client : null;

  static Future<void> finishLocalSignOut(SupabaseClient client) async {
    if (identical(client, optionalClient) &&
        client.auth.currentSession == null) {
      // SDK persistence callbacks are asynchronous; do not announce completion
      // until this queued secure removal has also completed.
      await _secureStorage?.removePersistedSession();
    }
  }
}
