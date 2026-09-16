import 'package:atena_app/models/calendario/evento_calendario.dart';
import 'package:atena_app/models/instituciones/area_operativa.dart';
import 'package:atena_app/services/institucion_areas_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.instance.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(StorageService.instance.resetCache);

  test('identidad estable no depende del nombre visible', () async {
    final first = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: 'institucion-A',
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: 'primaria',
      nombre: 'Primaria',
    );
    final renamed = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: 'institucion-A',
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: 'primaria',
      nombre: 'Nivel primario',
    );
    expect(renamed!.id, first!.id);
    expect(renamed.nombre, 'Nivel primario');
  });

  test('curricular, Técnica y Terciario son representables', () async {
    for (final key in const [
      'jardin',
      'primaria',
      'secundaria',
      'tecnica',
      'terciario',
    ]) {
      final area = await InstitucionAreasService.instance.resolverYGuardar(
        institucionId: 'institucion-A',
        tipo: TipoAreaOperativa.curricular,
        claveOrigen: key,
        nombre: key,
      );
      expect(area, isNotNull, reason: key);
      expect(area!.tipo, TipoAreaOperativa.curricular);
    }
  });

  test('extracurricular e instituciones permanecen aisladas', () async {
    final a = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: 'institucion-A',
      tipo: TipoAreaOperativa.extracurricular,
      claveOrigen: 'robotica',
      nombre: 'Robótica',
    );
    final b = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: 'institucion-B',
      tipo: TipoAreaOperativa.extracurricular,
      claveOrigen: 'robotica',
      nombre: 'Robótica',
    );
    expect(a!.id, isNot(b!.id));
    expect(
      await InstitucionAreasService.instance.buscarPorId('institucion-B', a.id),
      isNull,
    );
  });

  test('dato curricular inválido no crea un área arbitraria', () async {
    final area = await InstitucionAreasService.instance.resolverYGuardar(
      institucionId: 'institucion-A',
      tipo: TipoAreaOperativa.curricular,
      claveOrigen: 'nombre ambiguo',
      nombre: 'Nombre ambiguo',
    );
    expect(area, isNull);
    expect(
      await InstitucionAreasService.instance.listar('institucion-A'),
      isEmpty,
    );
  });

  test('evento preserva área y grupo en round-trip', () {
    final event = EventoCalendario(
      id: 'event-1',
      ownerAccountId: 'owner-A',
      perfilId: 'student-A',
      titulo: 'Reunión',
      descripcion: '',
      inicio: DateTime(2026, 9, 16),
      fin: null,
      institucionId: 'institucion-A',
      institucionNombre: 'Institución A',
      solicitudId: null,
      alumnoDni: null,
      actividadNombre: 'Primaria',
      esCurricular: true,
      areaId: 'area-A-primary',
      grupoId: 'grupo-1A',
      tipo: TipoEventoCalendario.eventoEspecial,
      tipoEspecial: TipoEventoEspecial.otro,
      segmentoEspecial: null,
      cerrado: false,
    );
    final decoded = EventoCalendario.fromMap(event.toMap());
    expect(decoded.areaId, 'area-A-primary');
    expect(decoded.grupoId, 'grupo-1A');
  });

  test('evento histórico sin área continúa legible y sin clasificar', () {
    final historical = EventoCalendario.fromMap({
      'id': 'legacy-event',
      'ownerAccountId': 'owner-A',
      'perfilId': 'student-A',
      'titulo': 'Evento histórico',
      'descripcion': '',
      'inicio': '2026-09-16T10:00:00.000',
      'institucionId': 'institucion-A',
      'actividadNombre': 'Nivel',
      'esCurricular': true,
      'tipo': 'eventoEspecial',
      'cerrado': false,
    });
    expect(historical.id, 'legacy-event');
    expect(historical.areaId, isNull);
    expect(historical.grupoId, isNull);
  });
}
