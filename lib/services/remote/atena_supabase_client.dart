import 'package:supabase_flutter/supabase_flutter.dart';

import 'atena_supabase_config.dart';

class AtenaSupabaseClient {
  AtenaSupabaseClient._();

  static bool _initialized = false;

  static Future<void> initializeIfConfigured() async {
    final config = AtenaSupabaseConfig.fromBuildEnvironment();
    if (config == null || _initialized) return;
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    _initialized = true;
  }

  static SupabaseClient? get optionalClient =>
      _initialized ? Supabase.instance.client : null;
}
