import 'package:atena_app/services/remote/atena_supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

const _publishableKey = 'sb_publishable_test_only_not_a_real_key';

void main() {
  test('sin configuración remota conserva el arranque local', () {
    expect(AtenaSupabaseConfig.fromBuildEnvironment(), isNull);
  });

  test('staging acepta exclusivamente el proyecto Atena indicado', () {
    final config = AtenaSupabaseConfig.validate(
      environment: AtenaRemoteEnvironment.staging,
      url: AtenaSupabaseConfig.stagingProjectUrl,
      publishableKey: _publishableKey,
    );
    expect(config.environment, AtenaRemoteEnvironment.staging);
    expect(
      () => AtenaSupabaseConfig.validate(
        environment: AtenaRemoteEnvironment.staging,
        url: 'https://another-project.supabase.co',
        publishableKey: _publishableKey,
      ),
      throwsArgumentError,
    );
  });

  test('producción no reutiliza por accidente la base de staging', () {
    expect(
      () => AtenaSupabaseConfig.validate(
        environment: AtenaRemoteEnvironment.production,
        url: AtenaSupabaseConfig.stagingProjectUrl,
        publishableKey: _publishableKey,
      ),
      throwsArgumentError,
    );
  });

  test('rechaza URLs inseguras y claves que no sean publishable', () {
    for (final url in [
      'http://eaegvxxxkvhdukbkydvy.supabase.co',
      'https://user:password@eaegvxxxkvhdukbkydvy.supabase.co',
    ]) {
      expect(
        () => AtenaSupabaseConfig.validate(
          environment: AtenaRemoteEnvironment.staging,
          url: url,
          publishableKey: _publishableKey,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => AtenaSupabaseConfig.validate(
        environment: AtenaRemoteEnvironment.staging,
        url: AtenaSupabaseConfig.stagingProjectUrl,
        publishableKey: 'service_role_invalid',
      ),
      throwsArgumentError,
    );
  });
}
