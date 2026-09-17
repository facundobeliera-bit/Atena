import 'package:atena_app/main.dart' as app;
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/asignacion_operador_area.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/screens/instituciones/institucion_area_page.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_contexto_operativo_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institutionA = 'context-institution-a';
const institutionB = 'context-institution-b';
const ownerA = 'context-owner-a';

Future<AreaOperativa> _area(String institution, String key) async =>
    (await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institution,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: key,
      nombre: key == 'primaria' ? 'Primaria' : 'Secundaria',
    ))!;

Future<void> _session() async {
  await SessionService.setSession(
    userId: institutionA,
    role: SessionRole.institucion,
    rememberMe: true,
  );
  await SessionService.setInstitucionOwnerAccountId(ownerA);
}

Future<OperadorInstitucional> _assigned(AreaOperativa area, String name) async {
  final operator = await InstitucionOperadoresService.instance.crearLocal(
    institucionId: area.institucionId,
    nombreVisible: name,
  );
  await InstitucionOperadoresService.instance.asignarArea(
    institucionId: area.institucionId,
    operadorId: operator.id,
    areaId: area.id,
  );
  return operator;
}

Future<InstitutionOperationalContext?> _activate(
  AreaOperativa area,
  OperadorInstitucional operator,
) => InstitucionContextoOperativoService.instance.activarContextoOperativo(
  institucionId: institutionA,
  ownerAccountId: ownerA,
  areaId: area.id,
  operadorId: operator.id,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'activa y reconstruye exactamente institución, área y operador',
    () async {
      await _session();
      final primary = await _area(institutionA, 'primaria');
      final facu = await _assigned(primary, 'Facu');
      final context = await _activate(primary, facu);
      expect(context?.institutionId, institutionA);
      expect(context?.ownerAccountId, ownerA);
      expect(context?.areaId, primary.id);
      expect(context?.operatorId, facu.id);
      expect(
        await InstitucionContextoOperativoService.instance
            .reconstruirContextoOperativo(),
        isNotNull,
      );
    },
  );

  test('argumentos ajenos no reemplazan un contexto válido anterior', () async {
    await _session();
    final primary = await _area(institutionA, 'primaria');
    final facu = await _assigned(primary, 'Facu');
    final original = await _activate(primary, facu);
    final foreignArea = await _area(institutionB, 'primaria');
    final foreignOperator = await _assigned(foreignArea, 'Ajeno');

    expect(
      await InstitucionContextoOperativoService.instance
          .activarContextoOperativo(
            institucionId: institutionA,
            ownerAccountId: ownerA,
            areaId: foreignArea.id,
            operadorId: foreignOperator.id,
          ),
      isNull,
    );
    final stored = await SessionService.getInstitutionOperationalContext();
    expect(stored?.areaId, original?.areaId);
    expect(stored?.operatorId, original?.operatorId);
  });

  test(
    'operador de Primaria no puede fabricar contexto en Secundaria',
    () async {
      await _session();
      final primary = await _area(institutionA, 'primaria');
      final secondary = await _area(institutionA, 'secundaria');
      final facu = await _assigned(primary, 'Facu');
      expect(
        await InstitucionContextoOperativoService.instance
            .activarContextoOperativo(
              institucionId: institutionA,
              ownerAccountId: ownerA,
              areaId: secondary.id,
              operadorId: facu.id,
            ),
        isNull,
      );
    },
  );

  test('suspensiones y área inactiva invalidan reconstrucción', () async {
    await _session();
    final primary = await _area(institutionA, 'primaria');
    final facu = await _assigned(primary, 'Facu');
    await _activate(primary, facu);
    await InstitucionOperadoresService.instance.setEstadoAsignacion(
      institucionId: institutionA,
      operadorId: facu.id,
      areaId: primary.id,
      estado: EstadoAsignacionOperadorArea.suspendida,
    );
    expect(
      await InstitucionContextoOperativoService.instance
          .reconstruirContextoOperativo(),
      isNull,
    );
    await InstitucionOperadoresService.instance.setEstadoAsignacion(
      institucionId: institutionA,
      operadorId: facu.id,
      areaId: primary.id,
      estado: EstadoAsignacionOperadorArea.activa,
    );
    await _activate(primary, facu);
    await InstitucionAreasService.instance.setActiva(
      institucionId: institutionA,
      areaId: primary.id,
      activa: false,
    );
    expect(
      await InstitucionContextoOperativoService.instance
          .reconstruirContextoOperativo(),
      isNull,
    );
  });

  test('logout y cambio a alumno limpian área y operador', () async {
    await _session();
    final primary = await _area(institutionA, 'primaria');
    final facu = await _assigned(primary, 'Facu');
    await _activate(primary, facu);
    await SessionService.setSession(
      userId: ownerA,
      role: SessionRole.cuenta,
      rememberMe: true,
    );
    expect(await SessionService.getInstitutionOperationalContext(), isNull);
    await _session();
    await _activate(primary, facu);
    await SessionService.logout();
    expect(await SessionService.getInstitutionOperationalContext(), isNull);
  });

  testWidgets('F5 reconstruye Administración sólo con contexto aún válido', (
    tester,
  ) async {
    await _session();
    final primary = await _area(institutionA, 'primaria');
    final facu = await _assigned(primary, 'Facu');
    await _activate(primary, facu);
    await app.main();
    await tester.pumpAndSettle();
    expect(find.byType(InstitucionAreaPage), findsOneWidget);
    expect(
      (await SessionService.getInstitutionOperationalContext())?.operatorId,
      facu.id,
    );
  });
}
