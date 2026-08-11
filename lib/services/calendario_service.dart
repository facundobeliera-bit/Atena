import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendario/evento_calendario.dart';

class CalendarioService {
  CalendarioService._();

  static String _kEventosOwner(String ownerAccountId) =>
      'cal_eventos_owner_$ownerAccountId';

  static String _norm(String v) => v.trim();
  static bool _has(String? v) => v != null && v.trim().isNotEmpty;

  /// Lee la lista raw de eventos (maps) del owner.
  /// Hardening: tolera JSON corrupto / no-list / maps inválidos.
  static Future<List<Map<String, dynamic>>> _readOwnerMaps(
    String ownerAccountId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kEventosOwner(ownerAccountId));
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <Map<String, dynamic>>[];
      for (final x in decoded) {
        if (x is Map) out.add(Map<String, dynamic>.from(x));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Persiste la lista raw de eventos (maps) del owner.
  static Future<void> _writeOwnerMaps(
    String ownerAccountId,
    List<Map<String, dynamic>> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEventosOwner(ownerAccountId), jsonEncode(list));
  }

  /// Agrega evento al calendario del owner (upsert por id).
  static Future<void> addEvento(EventoCalendario e) async {
    final owner = _norm(e.ownerAccountId);
    if (owner.isEmpty) return;

    final list = await _readOwnerMaps(owner);

    final idx = list.indexWhere((m) => (m['id'] ?? '').toString() == e.id);
    if (idx >= 0) {
      list[idx] = e.toMap();
    } else {
      list.add(e.toMap());
    }

    await _writeOwnerMaps(owner, list);
  }

  /// Upsert batch (reduce IO cuando se actualizan múltiples eventos).
  static Future<void> addEventosBatch(
    String ownerAccountId,
    List<EventoCalendario> eventos,
  ) async {
    final owner = _norm(ownerAccountId);
    if (owner.isEmpty) return;
    if (eventos.isEmpty) return;

    final list = await _readOwnerMaps(owner);

    for (final e in eventos) {
      if (_norm(e.ownerAccountId) != owner) continue;

      final idx = list.indexWhere((m) => (m['id'] ?? '').toString() == e.id);
      if (idx >= 0) {
        list[idx] = e.toMap();
      } else {
        list.add(e.toMap());
      }
    }

    await _writeOwnerMaps(owner, list);
  }

  /// Elimina un evento por id (si existe).
  static Future<void> removeEvento({
    required String ownerAccountId,
    required String eventoId,
  }) async {
    final owner = _norm(ownerAccountId);
    final id = _norm(eventoId);
    if (owner.isEmpty || id.isEmpty) return;

    final list = await _readOwnerMaps(owner);
    list.removeWhere((m) => (m['id'] ?? '').toString() == id);
    await _writeOwnerMaps(owner, list);
  }

  /// Lista eventos del owner (puede filtrar por perfil).
  /// - incluirCerrados: si false, omite cerrados.
  /// - includeGlobalDeCuenta: si false, omite eventos con perfilId == null.
  /// - includeEventosEspeciales: si false, omite tipo == eventoEspecial.
  static Future<List<EventoCalendario>> getEventos({
    required String ownerAccountId,
    String? perfilId,
    bool incluirCerrados = true,
    bool includeGlobalDeCuenta = true,
    bool includeEventosEspeciales = true,
  }) async {
    final owner = _norm(ownerAccountId);
    if (owner.isEmpty) return [];

    final maps = await _readOwnerMaps(owner);
    if (maps.isEmpty) return [];

    final pid = _has(perfilId) ? _norm(perfilId!) : null;

    final out = <EventoCalendario>[];
    for (final m in maps) {
      final e = EventoCalendario.fromMap(m);

      // Defensa: si el evento no pertenece al owner, se ignora.
      if (_norm(e.ownerAccountId) != owner) continue;

      if (pid != null) {
        if (_norm(e.perfilId ?? '') != pid) continue;
      } else {
        if (!includeGlobalDeCuenta && !_has(e.perfilId)) continue;
      }

      if (!includeEventosEspeciales && e.esEventoEspecial) continue;

      if (!incluirCerrados && e.cerrado == true) continue;

      out.add(e);
    }

    out.sort((a, b) => a.inicio.compareTo(b.inicio));
    return out;
  }

  /// Lista SOLO eventos especiales institucionales.
  /// Permite filtrar por institución y/o tipo (curricular/extracurricular).
  static Future<List<EventoCalendario>> getEventosEspeciales({
    required String ownerAccountId,
    String? institucionId,
    bool? esCurricular,
    String? perfilId,
    bool incluirCerrados = true,
  }) async {
    final owner = _norm(ownerAccountId);
    if (owner.isEmpty) return [];

    final instId = _has(institucionId) ? _norm(institucionId!) : null;

    final eventos = await getEventos(
      ownerAccountId: owner,
      perfilId: perfilId,
      incluirCerrados: incluirCerrados,
      includeGlobalDeCuenta: true,
      includeEventosEspeciales: true,
    );

    final out = <EventoCalendario>[];
    for (final e in eventos) {
      if (!e.esEventoEspecial) continue;

      if (instId != null) {
        if (_norm(e.institucionId ?? '') != instId) continue;
      }
      if (esCurricular != null) {
        if (e.esCurricular != esCurricular) continue;
      }

      out.add(e);
    }

    out.sort((a, b) => a.inicio.compareTo(b.inicio));
    return out;
  }

  /// Cierra (no borra) eventos vinculados a una solicitud.
  /// Optimiza: batch write.
  static Future<void> cerrarEventosPorSolicitud({
    required String ownerAccountId,
    required String solicitudId,
  }) async {
    final owner = _norm(ownerAccountId);
    final solId = _norm(solicitudId);
    if (owner.isEmpty || solId.isEmpty) return;

    final eventos = await getEventos(ownerAccountId: owner);

    final updates = <EventoCalendario>[];
    for (final e in eventos) {
      if (_norm(e.solicitudId ?? '') != solId) continue;
      if (e.cerrado == true) continue;
      updates.add(e.copyWith(cerrado: true));
    }

    await addEventosBatch(owner, updates);
  }
}
