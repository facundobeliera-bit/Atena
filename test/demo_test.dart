// test/demo_test.dart
//
// Los datos de ejemplo se cargan completos y una sola vez.

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/core/demo/demo_seeder.dart';
import 'package:atena_app/services/auth_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetStorage);

  test('carga instituciones, ofertas y una familia con solicitudes', () async {
    expect(await DemoSeeder.cargar(), isTrue);

    final instituciones = await InstitucionesRepo.instance.listar();
    expect(instituciones, hasLength(3));

    final colegio = instituciones.firstWhere(
      (i) => i.nombre == 'Colegio San Martín',
    );
    final ofertas = await OfertasRepo.instance.conCupo(colegio.id);
    expect(ofertas.length, greaterThanOrEqualTo(5));
    expect(ofertas.fold<int>(0, (a, o) => a + o.confirmados), 2);

    final familia = await AuthService.loginFamilia(
      email: DemoCredenciales.familia,
      password: DemoCredenciales.password,
      remember: true,
    );
    final perfiles = await AlumnosRepo.instance.perfiles(familia.id);
    expect(perfiles, hasLength(2));

    final noti = await NotificacionesRepo.instance.listar(familia.id);
    expect(noti, isNotEmpty);

    final sesionInst = await AuthService.loginInstitucion(
      email: DemoCredenciales.colegio,
      password: DemoCredenciales.password,
      remember: true,
    );
    expect(sesionInst.institucionPerfilId, colegio.id);
    expect((await SessionService.getSession())?.role, SessionRole.institucion);
  });

  test('no duplica si ya está cargado', () async {
    expect(await DemoSeeder.cargar(), isTrue);
    expect(await DemoSeeder.cargar(), isFalse);
    expect(await InstitucionesRepo.instance.listar(), hasLength(3));
  });
}
