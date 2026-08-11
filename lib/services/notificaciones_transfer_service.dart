// ─────────────────────────────────────────────
// ATENA – NOTIFICACIONES TRANSFER (OWNER MOVE)
// Archivo: lib/services/notificaciones_transfer_service.dart
// ─────────────────────────────────────────────
//
// Uso principal: emancipación.
// - Mueve notificaciones del OWNER anterior al OWNER nuevo,
//   filtrando por perfilId.
// - No toca el feed de PERFIL (notificaciones_perfil_<perfilId>).
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notificaciones/notificacion_atena.dart';

class NotificacionesTransferService {
  // Keys (deben coincidir con NotificacionesService)
  static String _kOwner(String ownerAccountId) =>
      'notificaciones_owner_${ownerAccountId.trim()}';

  // Lectura compat: en tu NotificacionesService soportás StringList o String JSON.
  static Future<List<String>> _getStringListCompat(String key) async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList(key);
    if (list != null) return list;

    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <String>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => jsonEncode(e)).toList();
      }
      return <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  static Future<void> _setStringListCompat(
    String key,
    List<String> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, list);
  }

  static List<NotificacionAtena> _decodeList(List<String> rawList) {
    final out = <NotificacionAtena>[];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          out.add(
            NotificacionAtena.fromMap(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {}
    }
    out.sort((a, b) => b.fecha.compareTo(a.fecha));
    return out;
  }

  static List<String> _encodeList(List<NotificacionAtena> list) {
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list.map((n) => jsonEncode(n.toMap())).toList();
  }

  /// Mueve (o copia) todas las notificaciones del owner anterior que correspondan al perfil.
  ///
  /// - Si removeFromOld == true => se eliminan del feed del owner anterior.
  /// - Siempre se insertan en el feed del owner nuevo.
  ///
  /// Nota:
  /// - Se considera “del perfil” si n.perfilId == perfilId.
  /// - Si querés también mover las que vengan por dni (destinatarioDni),
  ///   hacelo en otro paso (yo NO lo incluyo porque tu canónico ya es por perfil).
  static Future<int> moverNotificacionesDePerfil({
    required String perfilId,
    required String ownerAnterior,
    required String ownerNuevo,
    bool removeFromOld = true,
  }) async {
    final pid = perfilId.trim();
    final oldOwner = ownerAnterior.trim();
    final newOwner = ownerNuevo.trim();

    if (pid.isEmpty || oldOwner.isEmpty || newOwner.isEmpty) return 0;
    if (oldOwner == newOwner) return 0;

    final oldKey = _kOwner(oldOwner);
    final newKey = _kOwner(newOwner);

    final oldRaw = await _getStringListCompat(oldKey);
    if (oldRaw.isEmpty) return 0;

    final oldList = _decodeList(oldRaw);

    final aMover = oldList
        .where((n) => (n.perfilId ?? '').trim() == pid)
        .toList();
    if (aMover.isEmpty) return 0;

    // Reescribir ownerAccountId (mantener resto)
    final reOwner = aMover
        .map((n) => n.copyWith(ownerAccountId: newOwner))
        .toList();

    // Cargar destino
    final newRaw = await _getStringListCompat(newKey);
    final newList = _decodeList(newRaw);

    // Dedupe simple por id (si querés dedupe más fuerte, se puede)
    final existingIds = newList.map((e) => e.id).toSet();
    for (final n in reOwner) {
      if (!existingIds.contains(n.id)) {
        newList.add(n);
        existingIds.add(n.id);
      }
    }

    await _setStringListCompat(newKey, _encodeList(newList));

    if (removeFromOld) {
      final remaining = oldList
          .where((n) => (n.perfilId ?? '').trim() != pid)
          .toList();
      await _setStringListCompat(oldKey, _encodeList(remaining));
    }

    return reOwner.length;
  }
}
