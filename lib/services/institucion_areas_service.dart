import '../models/instituciones/area_operativa.dart';
import 'storage_service.dart';

class InstitucionAreasService {
  InstitucionAreasService._();
  static final instance = InstitucionAreasService._();

  static const _prefix = 'inst_operational_areas_v1_';
  static const _curricularKeys = <String>{
    'jardin',
    'primaria',
    'secundaria',
    'tecnica',
    'terciario',
  };

  static String normalizeKey(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static String stableId({
    required String institucionId,
    required TipoAreaOperativa tipo,
    required String claveOrigen,
  }) {
    final institution = normalizeKey(institucionId);
    final origin = normalizeKey(claveOrigen);
    if (institution.isEmpty || origin.isEmpty) return '';
    final institutionHash = _stableHash(institution).toRadixString(16);
    final type = tipo == TipoAreaOperativa.curricular ? 'cur' : 'ext';
    return 'area_${institutionHash}_${type}_$origin';
  }

  String _key(String institucionId) => '$_prefix${normalizeKey(institucionId)}';

  Future<List<AreaOperativa>> listar(String institucionId) async {
    final institution = institucionId.trim();
    if (institution.isEmpty) return const [];
    final raw = await StorageService.instance.getJsonList(_key(institution));
    final result = <AreaOperativa>[];
    for (final item in raw) {
      final area = AreaOperativa.fromMap(item);
      if (area.id.isEmpty || area.institucionId != institution) continue;
      result.add(area);
    }
    return result;
  }

  Future<AreaOperativa?> buscarPorId(
    String institucionId,
    String areaId,
  ) async {
    final institution = institucionId.trim();
    final id = areaId.trim();
    if (institution.isEmpty || id.isEmpty) return null;
    for (final area in await listar(institution)) {
      if (area.id == id && area.institucionId == institution) return area;
    }
    return null;
  }

  Future<AreaOperativa?> resolverYGuardar({
    required String institucionId,
    required TipoAreaOperativa tipo,
    required String claveOrigen,
    required String nombre,
  }) async {
    final institution = institucionId.trim();
    final origin = normalizeKey(claveOrigen);
    if (institution.isEmpty || origin.isEmpty) return null;
    if (tipo == TipoAreaOperativa.curricular &&
        !_curricularKeys.contains(origin)) {
      return null;
    }
    final id = stableId(
      institucionId: institution,
      tipo: tipo,
      claveOrigen: origin,
    );
    if (id.isEmpty) return null;
    final areas = await listar(institution);
    final index = areas.indexWhere((area) => area.id == id);
    final now = DateTime.now().toUtc();
    if (index >= 0) {
      final current = areas[index];
      final visibleName = nombre.trim().isEmpty
          ? current.nombre
          : nombre.trim();
      if (visibleName != current.nombre || !current.activa) {
        areas[index] = current.copyWith(
          nombre: visibleName,
          activa: true,
          updatedAt: now,
        );
        await StorageService.instance.setJsonList(
          _key(institution),
          areas.map((area) => area.toMap()).toList(),
        );
      }
      return areas[index];
    }
    final area = AreaOperativa(
      id: id,
      institucionId: institution,
      tipo: tipo,
      claveOrigen: origin,
      nombre: nombre.trim().isEmpty ? origin : nombre.trim(),
      activa: true,
      createdAt: now,
      updatedAt: now,
    );
    areas.add(area);
    await StorageService.instance.setJsonList(
      _key(institution),
      areas.map((value) => value.toMap()).toList(),
    );
    return area;
  }
}
