import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/models/instituciones/operador_institucional.dart';
import 'package:atena_app/models/instituciones/registro_auditoria_institucional.dart';
import 'package:atena_app/screens/instituciones/institucion_historial_actividad_page.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/institucion_auditoria_service.dart';
import 'package:atena_app/services/institucion_operadores_service.dart';
import 'package:atena_app/services/session_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const institutionA = 'audit-institution-A';
const institutionB = 'audit-institution-B';
const ownerA = 'audit-owner-A';

Future<AreaOperativa> createArea(String institution, String key) async =>
    (await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: institution,
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: key,
      nombre: key == 'primaria' ? 'Primaria' : 'Secundaria',
    ))!;

Future<OperadorInstitucional> ownerOperator() async =>
    InstitucionOperadoresService.instance.asegurarPropietario(
      institucionId: institutionA,
      ownerAccountId: ownerA,
      perfilInstitucionId: institutionA,
      nombreVisible: 'Propietario Atena',
    );

Future<void> activateInstitution() async {
  await SessionService.setSession(
    userId: institutionA,
    role: SessionRole.institucion,
    rememberMe: true,
  );
  await SessionService.setInstitucionOwnerAccountId(ownerA);
}

Future<RegistroAuditoriaInstitucional> append({
  required String institution,
  required String areaId,
  required String operatorId,
  String action = AccionAuditoriaInstitucional.requestConfirmed,
  String resourceId = 'request-1',
  DateTime? occurredAt,
  Map<String, Object?> metadata = const {},
}) => InstitucionAuditoriaService.instance.append(
  institucionId: institution,
  areaId: areaId,
  operatorId: operatorId,
  action: action,
  resourceType: 'request',
  resourceId: resourceId,
  occurredAt: occurredAt,
  metadata: metadata,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'append reconstruye registros con IDs únicos y orden temporal',
    () async {
      final primary = await createArea(institutionA, 'primaria');
      final owner = await ownerOperator();
      final older = await append(
        institution: institutionA,
        areaId: primary.id,
        operatorId: owner.id,
        resourceId: 'older',
        occurredAt: DateTime.utc(2026, 9, 16, 20),
      );
      final newer = await append(
        institution: institutionA,
        areaId: primary.id,
        operatorId: owner.id,
        resourceId: 'newer',
        occurredAt: DateTime.utc(2026, 9, 16, 21),
      );
      StorageService.instance.resetCache();
      final records = await InstitucionAuditoriaService.instance.listarInterno(
        institutionA,
      );
      expect(older.id, isNot(newer.id));
      expect(records.map((value) => value.resourceId), ['newer', 'older']);
    },
  );

  test('instituciones permanecen aisladas', () async {
    final areaA = await createArea(institutionA, 'primaria');
    final areaB = await createArea(institutionB, 'primaria');
    final owner = await ownerOperator();
    await append(
      institution: institutionA,
      areaId: areaA.id,
      operatorId: owner.id,
    );
    await expectLater(
      append(institution: institutionB, areaId: areaB.id, operatorId: owner.id),
      throwsStateError,
    );
    expect(
      await InstitucionAuditoriaService.instance.listarInterno(institutionB),
      isEmpty,
    );
  });

  test('metadata sensible y contenido completo se descartan', () async {
    final primary = await createArea(institutionA, 'primaria');
    final owner = await ownerOperator();
    final record = await append(
      institution: institutionA,
      areaId: primary.id,
      operatorId: owner.id,
      metadata: {
        'previousCapacity': 10,
        'passwordHash': 'secret',
        'dniAlumno': '12345678',
        'mensajeCompleto': 'contenido privado',
      },
    );
    expect(record.metadata, {'previousCapacity': 10});
  });

  test('registro permanece legible tras revocar al operador', () async {
    final primary = await createArea(institutionA, 'primaria');
    final operator = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Operador histórico',
    );
    await append(
      institution: institutionA,
      areaId: primary.id,
      operatorId: operator.id,
    );
    await InstitucionOperadoresService.instance.actualizar(
      institucionId: institutionA,
      operadorId: operator.id,
      estado: EstadoOperadorInstitucional.revocado,
    );
    expect(
      (await InstitucionAuditoriaService.instance.listarInterno(
        institutionA,
      )).single.operatorId,
      operator.id,
    );
  });

  test('propietario ve toda la institución', () async {
    await activateInstitution();
    final primary = await createArea(institutionA, 'primaria');
    final secondary = await createArea(institutionA, 'secundaria');
    final owner = await ownerOperator();
    await InstitucionOperadoresService.instance.activar(
      institucionId: institutionA,
      operadorId: owner.id,
    );
    for (final entry in [(primary, 'primary'), (secondary, 'secondary')]) {
      await append(
        institution: institutionA,
        areaId: entry.$1.id,
        operatorId: owner.id,
        resourceId: entry.$2,
      );
    }
    expect(
      await InstitucionAuditoriaService.instance.listarAutorizado(
        institucionId: institutionA,
      ),
      hasLength(2),
    );
  });

  test('audit.read respeta simultáneamente área y operador activo', () async {
    await activateInstitution();
    final primary = await createArea(institutionA, 'primaria');
    final secondary = await createArea(institutionA, 'secundaria');
    final owner = await ownerOperator();
    final reader = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Lector Primaria',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institutionA,
      operadorId: reader.id,
      areaId: primary.id,
    );
    await InstitucionOperadoresService.instance.setCapacidades(
      institucionId: institutionA,
      operadorId: reader.id,
      capacidades: {CapacidadInstitucional.auditRead},
    );
    await append(
      institution: institutionA,
      areaId: primary.id,
      operatorId: owner.id,
      resourceId: 'primary',
    );
    await append(
      institution: institutionA,
      areaId: secondary.id,
      operatorId: owner.id,
      resourceId: 'secondary',
    );
    await InstitucionOperadoresService.instance.activar(
      institucionId: institutionA,
      operadorId: reader.id,
    );
    final visible = await InstitucionAuditoriaService.instance.listarAutorizado(
      institucionId: institutionA,
    );
    expect(visible.map((value) => value.resourceId), ['primary']);
  });

  test('área asignada sin audit.read no concede lectura', () async {
    await activateInstitution();
    final primary = await createArea(institutionA, 'primaria');
    final owner = await ownerOperator();
    final reader = await InstitucionOperadoresService.instance.crearLocal(
      institucionId: institutionA,
      nombreVisible: 'Sin capacidad',
    );
    await InstitucionOperadoresService.instance.asignarArea(
      institucionId: institutionA,
      operadorId: reader.id,
      areaId: primary.id,
    );
    await append(
      institution: institutionA,
      areaId: primary.id,
      operatorId: owner.id,
    );
    await InstitucionOperadoresService.instance.activar(
      institucionId: institutionA,
      operadorId: reader.id,
    );
    expect(
      await InstitucionAuditoriaService.instance.listarAutorizado(
        institucionId: institutionA,
      ),
      isEmpty,
    );
  });

  testWidgets('UI traduce acción y evita lenguaje de auditoría certificada', (
    tester,
  ) async {
    await activateInstitution();
    final primary = await createArea(institutionA, 'primaria');
    final owner = await ownerOperator();
    await InstitucionOperadoresService.instance.activar(
      institucionId: institutionA,
      operadorId: owner.id,
    );
    await append(
      institution: institutionA,
      areaId: primary.id,
      operatorId: owner.id,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: InstitucionHistorialActividadPage(institucionId: institutionA),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Historial de actividad'), findsOneWidget);
    expect(find.text('Confirmó una solicitud'), findsOneWidget);
    expect(find.textContaining('Propietario Atena'), findsOneWidget);
    expect(find.textContaining('Primaria'), findsWidgets);
    expect(find.textContaining('certific'), findsNothing);
    expect(find.textContaining('inviolable'), findsNothing);
  });
}
