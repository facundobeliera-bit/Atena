enum AtenaRemoteEnvironment { local, staging, production }

class AtenaSupabaseConfig {
  static const _environment = String.fromEnvironment(
    'ATENA_REMOTE_ENV',
    defaultValue: 'local',
  );
  static const _url = String.fromEnvironment('ATENA_SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'ATENA_SUPABASE_PUBLISHABLE_KEY',
  );
  static const stagingProjectUrl = 'https://eaegvxxxkvhdukbkydvy.supabase.co';

  final AtenaRemoteEnvironment environment;
  final String url;
  final String publishableKey;

  const AtenaSupabaseConfig._({
    required this.environment,
    required this.url,
    required this.publishableKey,
  });

  /// Local remains the default. Missing remote settings are an error only when
  /// a remote environment was explicitly selected for the build.
  static AtenaSupabaseConfig? fromBuildEnvironment() {
    if (_environment == 'local') return null;
    final environment = switch (_environment) {
      'staging' => AtenaRemoteEnvironment.staging,
      'production' => AtenaRemoteEnvironment.production,
      _ => throw StateError('Entorno remoto de Atena inválido.'),
    };
    return validate(
      environment: environment,
      url: _url,
      publishableKey: _publishableKey,
    );
  }

  static AtenaSupabaseConfig validate({
    required AtenaRemoteEnvironment environment,
    required String url,
    required String publishableKey,
  }) {
    if (environment == AtenaRemoteEnvironment.local) {
      throw ArgumentError('El entorno local no necesita Supabase.');
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.path.isNotEmpty ||
        !uri.host.endsWith('.supabase.co')) {
      throw ArgumentError('URL pública de Supabase inválida.');
    }
    if (environment == AtenaRemoteEnvironment.staging &&
        uri.toString() != stagingProjectUrl) {
      throw ArgumentError('Staging apunta a otro proyecto Supabase.');
    }
    if (environment == AtenaRemoteEnvironment.production &&
        uri.toString() == stagingProjectUrl) {
      throw ArgumentError('Producción no puede usar el proyecto de staging.');
    }
    final key = publishableKey.trim();
    if (!key.startsWith('sb_publishable_') || key.length < 25) {
      throw ArgumentError('Se requiere una clave publishable de Supabase.');
    }
    return AtenaSupabaseConfig._(
      environment: environment,
      url: uri.toString(),
      publishableKey: key,
    );
  }
}
