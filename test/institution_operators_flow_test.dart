import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/screens/instituciones/institucion_operadores_page.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institutionA = 'institution-A';
const institutionB = 'institution-B';
const ownerA = 'owner-A';
const ownerB = 'owner-B';

Future<void> _sessionA() async {
  await SessionService.setSession(
    userId: institutionA,
    role: SessionRole.institucion,
    rememberMe: true,
  );
  await SessionService.setInstitucionOwnerAccountId(ownerA);
}

Future<AreaOperativa> _area(
  String institution,
  String key, {
  TipoAreaOperativa type = TipoAreaOperativa.curricular,
}) async => (await InstitucionAreasService.instance.resolverYGuardar(
  institucionId: institution,
  tipo: type,
  claveOrigen: key,
  nombre: key,
))!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(StorageService.instance.resetCache);

  test(
    'institución histórica obtiene un único propietario idempotente',
    () async {
      final first = await InstitucionOperadoresService.instance
          .asegurarPropietario(
            institucionId: institutionA,
            ownerAccountId: ownerA,
            perfilInstitucionId: institutionA,
            nombreVisible: 'Propietario A',
          );
      final second = await InstitucionOperadoresService.instance
          .asegurarPropietario(
            institucionId: institutionA,
            ownerAccountId: ownerA,
            perfilInstitucionId: institutionA,
            nombreVisible: 'Otro nombre',
          );
      expect(second.id, first.id);
      expect(
        (await InstitucionOperadoresService.instance.listar(institutionA)),
        hasLength(1),
      );
      expect(first.cuentaId, ownerA);
      expect(first.perfilInstitucionId, institutionA);
      expect(first.esPropietario, isTrue);
    },
  );

  test('propietarios quedan aislados entre instituciones', () async {
    final a = await InstitucionOperadoresService.instance.asegurarPropietario(
      institucionId: institutionA,
      ownerAccountId: ownerA,
      perfilInstitucionId: institutionA,
      nombreVisible: 'A',
    );
    final b = await InstitucionOperadoresService.instance.asegurarPropietario(
      institucionId: institutionB,
      ownerAccountId: ownerB,
      perfilInstitucionId: institutionB,
      nombreVisible: 'B',
    );
    expect(a.id, isNot(b.id));
    expect(
      await InstitucionOperadoresService.instance.buscar(institutionB, a.id),
      isNull,
    );
  });

  test('operador local persiste y renombrarlo conserva identidad', () async {
    final created = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Ana Operadora',
    );
    expect(created.cuentaId, isNull);
    expect(
      await InstitucionOperadoresService.instance.actualizar(
        institucionId: institutionA,
        operadorId: created.id,
        nombreVisible: 'Ana Coordinadora',
      ),
      isTrue,
    );
    StorageService.instance.resetCache();
    final persisted = await InstitucionOperadoresService.instance.buscar(
      institutionA,
      created.id,
    );
    expect(persisted?.id, created.id);
    expect(persisted?.nombreVisible, 'Ana Coordinadora');
  });

  test('suspensión y revocación impiden activar operador', () async {
    await _sessionA();
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Operador',
    );
    expect(
      await InstitucionOperadoresService.instance.actualizar(
        institucionId: institutionA,
        operadorId: operator.id,
        estado: EstadoOperadorInstitucional.suspendido,
      ),
      isTrue,
    );
    expect(
      await InstitucionOperadoresService.instance.activar(
        institucionId: institutionA,
        operadorId: operator.id,
      ),
      isFalse,
    );
    expect(
      await InstitucionOperadoresService.instance.actualizar(
        institucionId: institutionA,
        operadorId: operator.id,
        estado: EstadoOperadorInstitucional.revocado,
      ),
      isTrue,
    );
    expect(
      await InstitucionOperadoresService.instance.activar(
        institucionId: institutionA,
        operadorId: operator.id,
      ),
      isFalse,
    );
  });

  test('asignaciones admiten múltiples áreas y operadores', () async {
    final primary = await _area(institutionA, 'primaria');
    final secondary = await _area(institutionA, 'secundaria');
    final first = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Primero',
    );
    final second = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Segundo',
    );
    for (final area in [primary, secondary]) {
      expect(
        await InstitucionOperadoresService.instance.asignarArea(
          institucionId: institutionA,
          operadorId: first.id,
          areaId: area.id,
        ),
        isTrue,
      );
    }
    expect(
      await InstitucionOperadoresService.instance.asignarArea(
        institucionId: institutionA,
        operadorId: second.id,
        areaId: primary.id,
      ),
      isTrue,
    );
    expect(
      await InstitucionOperadoresService.instance.areasAsignadas(
        institutionA,
        first.id,
      ),
      containsAll([primary.id, secondary.id]),
    );
    expect(
      await InstitucionOperadoresService.instance.operadoresDelArea(
        institutionA,
        primary.id,
      ),
      hasLength(2),
    );
  });

  test('área ajena se rechaza y desasignar no borra operador', () async {
    final foreign = await _area(institutionB, 'primaria');
    final local = await _area(institutionA, 'primaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Local',
    );
    expect(
      await InstitucionOperadoresService.instance.asignarArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: foreign.id,
      ),
      isFalse,
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: local.id,
    );
    await InstitucionOperadoresService.instance.desasignarArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: local.id,
    );
    expect(
      await InstitucionOperadoresService.instance.buscar(
        institutionA,
        operator.id,
      ),
      isNotNull,
    );
    expect(
      await InstitucionOperadoresService.instance.areasAsignadas(
        institutionA,
        operator.id,
      ),
      isEmpty,
    );
  });

  test('área inactiva no puede asignarse ni habilita acceso', () async {
    final area = await _area(institutionA, 'primaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Local',
    );
    await InstitucionAreasService.instance.setActiva(
      institucionId: institutionA,
      areaId: area.id,
      activa: false,
    );
    expect(
      await InstitucionOperadoresService.instance.asignarArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: area.id,
      ),
      isFalse,
    );
    expect(
      await InstitucionOperadoresService.instance.puedeAccederArea(
        institucionId: institutionA,
        operadorId: operator.id,
        areaId: area.id,
      ),
      isFalse,
    );
  });

  test('renombrar área conserva asignación por ID', () async {
    final area = await _area(institutionA, 'primaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Local',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institutionA,
      operadorId: operator.id,
      areaId: area.id,
    );
    final renamed = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institutionA,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: 'primaria',
      nombre: 'Nivel primario',
    );
    expect(renamed?.id, area.id);
    expect(
      await InstitucionOperadoresService.instance.areasAsignadas(
        institutionA,
        operator.id,
      ),
      contains(area.id),
    );
  });

  test(
    'contexto activo valida institución y sobrevive reconstrucción',
    () async {
      await _sessionA();
      final operator = await InstitucionOperadoresService.instance.crearLocal(
        institucionId: institutionA,
        nombreVisible: 'Activo',
      );
      final foreign = await InstitucionOperadoresService.instance.crearLocal(
        institucionId: institutionB,
        nombreVisible: 'Ajeno',
      );
      expect(
        await InstitucionOperadoresService.instance.activar(
          institucionId: institutionA,
          operadorId: operator.id,
        ),
        isTrue,
      );
      expect(
        await InstitucionOperadoresService.instance.activar(
          institucionId: institutionA,
          operadorId: foreign.id,
        ),
        isFalse,
      );
      expect(
        await SessionService.getInstitucionOperatorIdLogueado(),
        operator.id,
      );
      StorageService.instance.resetCache();
      expect(
        (await InstitucionOperadoresService.instance.operadorActivo(
          institutionA,
        ))?.id,
        operator.id,
      );
    },
  );

  test('logout elimina operador activo y F5 no lo restaura', () async {
    await _sessionA();
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Activo',
    );
    await InstitucionOperadoresService.instance.activar(
      institucionId: institutionA,
      operadorId: operator.id,
    );
    await SessionService.logout();
    expect(await SessionService.getSession(), isNull);
    expect(await SessionService.getInstitucionOperatorIdLogueado(), isNull);
    expect(
      await InstitucionOperadoresService.instance.operadorActivo(institutionA),
      isNull,
    );
  });

  testWidgets('UI muestra propietario, crea operador y no afirma presencia', (
    tester,
  ) async {
    await _sessionA();
    await _area(institutionA, 'primaria');
    await tester.pumpWidget(
      const MaterialApp(
        home: InstitucionOperadoresPage(
          ownerAccountId: ownerA,
          institucionId: institutionA,
          institucionNombre: 'Institución A',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Propietario'), findsWidgets);
    expect(find.textContaining('conectado'), findsNothing);
    await tester.tap(find.text('Crear operador'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Operador UI');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
    await tester.pumpAndSettle();
    expect(find.text('Operador UI'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Áreas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('primaria'));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    final operator = (await InstitucionOperadoresService.instance.listar(
      institutionA,
    )).last;
    expect(
      await InstitucionOperadoresService.instance.areasAsignadas(
        institutionA,
        operator.id,
      ),
      hasLength(1),
    );
  });
}
