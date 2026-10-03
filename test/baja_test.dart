// test/baja_test.dart
//
// Eliminar la cuenta (familia o institución) borra sus datos, avisa a la otra
// parte y no toca las demás cuentas.

import 'dart:typed_data';

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/core/demo/demo_seeder.dart';
import 'package:atena_app/services/auth_errors.dart';
import 'package:atena_app/services/auth_service.dart';
import 'package:atena_app/services/cuenta_service.dart';
import 'package:atena_app/services/institucion_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> expectWrongPassword(Future<void> f) async {
  try {
    await f;
    fail('Se esperaba AuthException(wrongCredentials)');
  } on AuthException catch (e) {
    expect(e.code, AuthErrorCode.wrongCredentials);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage();
    expect(await DemoSeeder.cargar(), isTrue);
  });

  Future<InstitucionResumen> colegio() async =>
      (await InstitucionesRepo.instance.listar()).firstWhere(
        (i) => i.nombre == 'Colegio San Martín',
      );

  test('familia: borra cuenta, alumnos y trámites, y avisa', () async {
    final cuenta = await AuthService.loginFamilia(
      email: DemoCredenciales.familia,
      password: DemoCredenciales.password,
      remember: true,
    );
    final perfiles = await AlumnosRepo.instance.perfiles(cuenta.id);
    expect(perfiles, hasLength(2));
    final inst = await colegio();

    // Datos personales extra: nota, foto y un banco en el croquis.
    final alumno = perfiles.first;
    await CalendarioRepo.instance.guardarNota(
      NotaPersonal(
        id: '',
        perfilId: alumno.id,
        titulo: 'Llevar útiles',
        fecha: DateTime(2026, 3, 2),
      ),
    );
    await AlumnosRepo.instance.guardarFoto(
      alumno.id,
      Uint8List.fromList([1, 2, 3]),
    );
    final confirmada = (await SolicitudesRepo.instance.confirmadas(
      inst.id,
    )).first;
    final croquis = await CroquisRepo.instance.crear(
      institucionId: inst.id,
      nombre: 'Aula 1',
      ofertaId: confirmada.ofertaId,
    );
    await CroquisRepo.instance.guardar(
      croquis.conAsiento(0, 0, confirmada.alumno.nombreCompleto),
    );

    // Con una contraseña equivocada no se borra nada.
    await expectWrongPassword(
      AuthService.eliminarCuentaFamilia(cuentaId: cuenta.id, password: 'mala'),
    );
    expect(await AlumnosRepo.instance.perfiles(cuenta.id), hasLength(2));

    await AuthService.eliminarCuentaFamilia(
      cuentaId: cuenta.id,
      password: DemoCredenciales.password,
    );

    expect(await AuthService.resolveHome(), isA<HomeLanding>());
    expect(
      await CuentaService.getCuentaByEmail(DemoCredenciales.familia),
      isNull,
    );
    expect(await NotificacionesRepo.instance.listar(cuenta.id), isEmpty);
    for (final p in perfiles) {
      expect(await CuentaService.getPerfilAlumnoById(p.id), isNull);
      expect(await SolicitudesRepo.instance.porPerfil(p.id), isEmpty);
      expect(await DocumentosRepo.instance.porPerfil(p.id), isEmpty);
      expect(await CalendarioRepo.instance.notas(p.id), isEmpty);
      expect(await AlumnosRepo.instance.foto(p.id), isNull);
    }

    // La institución recibe el aviso y el banco queda libre.
    final owner = await NotificacionesRepo.instance.cuentaDeInstitucion(
      inst.id,
    );
    final noti = await NotificacionesRepo.instance.listar(owner);
    expect(
      noti.where((n) => n.tipo == TipoNotificacion.cuentaEliminada),
      isNotEmpty,
    );
    final libre = await CroquisRepo.instance.obtener(inst.id, croquis.id);
    expect(libre!.ocupados, 0);
    final ofertas = await OfertasRepo.instance.conCupo(inst.id);
    expect(ofertas.fold<int>(0, (a, o) => a + o.confirmados), 0);

    // El email queda libre y las demás cuentas siguen funcionando.
    await AuthService.registrarFamilia(
      email: DemoCredenciales.familia,
      password: 'otra12345',
      remember: true,
      nombre: 'Ana',
      apellido: 'Paz',
      dni: '40111222',
      fechaNacimiento: DateTime(2014),
    );
    await AuthService.loginInstitucion(
      email: DemoCredenciales.colegio,
      password: DemoCredenciales.password,
      remember: true,
    );
  });

  test('institución: borra sus datos y cierra las solicitudes', () async {
    final sesion = await AuthService.loginInstitucion(
      email: DemoCredenciales.colegio,
      password: DemoCredenciales.password,
      remember: true,
    );
    final id = sesion.institucionPerfilId;
    final antes = await SolicitudesRepo.instance.porInstitucion(id);
    expect(antes.where((s) => s.estado.esActiva), isNotEmpty);

    await expectWrongPassword(
      AuthService.eliminarCuentaInstitucion(sesion: sesion, password: 'mala'),
    );
    expect(await OfertasRepo.instance.listar(id), isNotEmpty);

    await AuthService.eliminarCuentaInstitucion(
      sesion: sesion,
      password: DemoCredenciales.password,
    );

    expect(await AuthService.resolveHome(), isA<HomeLanding>());
    final directorio = await InstitucionesRepo.instance.listar();
    expect(directorio, hasLength(2));
    expect(directorio.map((i) => i.id), isNot(contains(id)));
    expect(await InstitucionService.getInstitucionById(id), isNull);
    expect(await OfertasRepo.instance.listar(id), isEmpty);
    expect(await CalendarioRepo.instance.eventosInstitucion(id), isEmpty);
    expect(await CalendarioRepo.instance.avisos(id), isEmpty);
    expect(await DocumentosRepo.instance.porInstitucion(id), isEmpty);
    try {
      await AuthService.loginInstitucion(
        email: DemoCredenciales.colegio,
        password: DemoCredenciales.password,
        remember: true,
      );
      fail('La institución eliminada no debería poder ingresar');
    } on AuthException catch (e) {
      expect(e.code, AuthErrorCode.wrongCredentials);
    }

    // Las familias conservan su historial, cerrado, y reciben el aviso.
    final despues = await SolicitudesRepo.instance.porInstitucion(id);
    expect(despues, hasLength(antes.length));
    expect(despues.where((s) => s.estado.esActiva), isEmpty);
    final familia = await AuthService.loginFamilia(
      email: DemoCredenciales.familia,
      password: DemoCredenciales.password,
      remember: true,
    );
    final noti = await NotificacionesRepo.instance.listar(familia.id);
    expect(
      noti.where((n) => n.tipo == TipoNotificacion.institucionEliminada),
      isNotEmpty,
    );

    // Las otras instituciones siguen intactas.
    await AuthService.loginInstitucion(
      email: DemoCredenciales.jardin,
      password: DemoCredenciales.password,
      remember: true,
    );
  });
}
