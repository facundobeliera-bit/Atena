// lib/services/institucion_storage_repository.dart
//
// ATENA – INSTITUCION STORAGE REPOSITORY
//
// Persistencia canónica del dominio Institucion sobre StorageService.
// No reemplaza modelos existentes ni crea una identidad paralela.
//
// Reglas:
// - Institucion.id es la identidad canónica del dominio.
// - Se conserva compatibilidad con las keys actuales de InstitucionService.
// - El índice global se reconstruye desde las keys persistidas, por lo que
//   también descubre instituciones guardadas por versiones anteriores.

import '../models/instituciones/instituciones_integrado.dart';
import 'storage_service.dart';

class InstitucionStorageRepository {
  InstitucionStorageRepository._();

  static final InstitucionStorageRepository instance =
      InstitucionStorageRepository._();

  static const String _idsKey = 'atena_instituciones_ids';
  static const String _domainPrefix = 'atena_institucion_by_id_';
  static const String _aliasPrefix = 'atena_institucion_alias_';

  final StorageService _storage = StorageService.instance;

  static String _norm(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');

  static String _domainKey(String id) =>
      '$_domainPrefix${_norm(id)}';

  static String _aliasKey(String id) =>
      '$_aliasPrefix${_norm(id)}';

  Future<void> _addId(String id) async {
    final normalized = _norm(id);
    if (normalized.isEmpty) return;

    final ids = await _storage.getStringList(_idsKey);
    if (!ids.contains(normalized)) {
      await _storage.setStringList(_idsKey, <String>[...ids, normalized]);
    }
  }

  Future<void> _setAlias(String fromId, String toId) async {
    final from = _norm(fromId);
    final to = _norm(toId);
    if (from.isEmpty || to.isEmpty || from == to) return;
    await _storage.setString(_aliasKey(from), to);
  }

  Future<String?> _resolveAlias(String id) async {
    final normalized = _norm(id);
    if (normalized.isEmpty) return null;
    final alias = await _storage.getString(_aliasKey(normalized));
    final resolved = _norm(alias ?? '');
    return resolved.isEmpty ? null : resolved;
  }

  Future<Institucion?> getById(String institucionId) async {
    final requested = _norm(institucionId);
    if (requested.isEmpty) return null;

    Map<String, dynamic>? raw = await _storage.getJson(
      _domainKey(requested),
    );

    if (raw == null) {
      final alias = await _resolveAlias(requested);
      if (alias != null) {
        raw = await _storage.getJson(_domainKey(alias));
      }
    }

    if (raw == null) return null;

    try {
      return Institucion.fromMap(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> upsert(Institucion institucion) async {
    final primaryId = _norm(institucion.id);
    if (primaryId.isEmpty) {
      throw Exception('Institución inválida (id vacío).');
    }

    final raw = institucion.toMap();
    final ok = await _storage.setJson(_domainKey(primaryId), raw);
    if (!ok) return false;

    await _addId(primaryId);

    // Mantener compatibilidad con los IDs alternativos que ya forman parte
    // del modelo canónico, sin modificar la identidad Institucion.id.
    final dynamic dyn = institucion;
    final candidates = <String>[
      _safeDynamicId(() => dyn.institucionId),
      _safeDynamicId(() => dyn.perfilId),
      _safeDynamicId(() => dyn.institucionPerfilId),
      _safeDynamicId(() => dyn.ownerAccountId),
    ];

    for (final candidate in candidates) {
      final normalized = _norm(candidate);
      if (normalized.isEmpty || normalized == primaryId) continue;
      await _storage.setJson(_domainKey(normalized), raw);
      await _addId(normalized);
      await _setAlias(normalized, primaryId);
    }

    return true;
  }

  Future<List<Institucion>> listAll() async {
    // Primero usamos el índice persistido.
    final indexed = await _storage.getStringList(_idsKey);
    final ids = <String>{
      for (final id in indexed)
        if (_norm(id).isNotEmpty) _norm(id),
    };

    // Después reconstruimos desde las keys reales. Esto permite recuperar
    // instituciones creadas por versiones anteriores que no tenían índice.
    final keys = await _storage.getKeys();
    for (final key in keys) {
      if (!key.startsWith(_domainPrefix)) continue;
      final id = _norm(key.substring(_domainPrefix.length));
      if (id.isNotEmpty) ids.add(id);
    }

    final result = <Institucion>[];
    final canonicalIds = <String>{};

    for (final id in ids) {
      final inst = await getById(id);
      if (inst == null) continue;

      final canonicalId = _norm(inst.id);
      if (canonicalId.isEmpty || canonicalIds.contains(canonicalId)) {
        continue;
      }

      canonicalIds.add(canonicalId);
      result.add(inst);

      if (id != canonicalId) {
        await _setAlias(id, canonicalId);
      }
      await _addId(canonicalId);
    }

    return result;
  }

  Future<void> rebuildIndex() async {
    final keys = await _storage.getKeys();
    final ids = <String>{
      for (final key in keys)
        if (key.startsWith(_domainPrefix))
          _norm(key.substring(_domainPrefix.length)),
    }..removeWhere((id) => id.isEmpty);

    if (ids.isEmpty) {
      await _storage.setStringList(_idsKey, <String>[]);
      return;
    }

    await _storage.setStringList(
      _idsKey,
      ids.toList(growable: false)..sort(),
    );
  }

  static String _safeDynamicId(String Function() read) {
    try {
      return read().trim();
    } catch (_) {
      return '';
    }
  }
}
