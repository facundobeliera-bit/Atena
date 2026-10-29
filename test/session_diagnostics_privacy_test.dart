import 'dart:async';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'snapshots and logs contain flags, never account/profile identifiers or caller tag',
    () async {
      const sensitive = 'FICTITIOUS-SENSITIVE-ID';
      SharedPreferences.setMockInitialValues({
        'v2_session_userId': sensitive,
        'v2_session_role': 'cuenta',
        'v2_session_instOwnerAccountId': sensitive,
        'v2_perfil_seleccionado_dni': sensitive,
        'sesion_cuenta': sensitive,
      });
      expect(
        (await SessionService.debugSnapshot()).toString(),
        isNot(contains(sensitive)),
      );
      expect(
        (await CuentaService.debugSnapshot()).toString(),
        isNot(contains(sensitive)),
      );
      final logs = <String>[];
      await runZoned(
        () async {
          await SessionService.debugPrintSnapshot(sensitive);
          await CuentaService.debugPrintSnapshot(sensitive);
          final p = await SharedPreferences.getInstance();
          await p.remove('v2_session_role');
          await SessionService.getSession();
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );
      expect(logs.join(), isNot(contains(sensitive)));
      expect(logs.join(), contains('partial state'));
    },
  );
}
