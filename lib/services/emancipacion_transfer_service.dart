// ─────────────────────────────────────────────
// ATENA – EMANCIPACIÓN: TRANSFERENCIA TOTAL (CANÓNICO)
// Archivo: lib/services/emancipacion_transfer_service.dart
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/solicitudes/solicitud_alumno.dart';
import '../services/cuenta_service.dart';
import '../repositories/solicitudes_repository_prefs.dart';

class EmancipacionTransferService {
  static const String _kSolAlumnoPrefix = 'sol_alumno_';

  static Future<void> emanciparYTransferirTodo({
    required String perfilId,
    required String cuentaDestinoId,
  }) async {
    final pid = _normId(perfilId);
    final destino = _normId(cuentaDestinoId);

    if (pid.isEmpty || destino.isEmpty) {
      throw Exception('perfilId/cuentaDestinoId inválidos.');
    }

    // 1) Perfil antes (para resolver owner anterior)
    final perfilAntes = await CuentaService.getPerfilAlumnoById(pid);
    if (perfilAntes == null) {
      throw Exception('Perfil inexistente.');
    }

    final cuentaOrigenId = _normId(perfilAntes.cuentaId);
    final ownerAnterior = _normId(perfilAntes.ownerAccountId ?? '');
    final ownerOrigen = ownerAnterior.isNotEmpty
        ? ownerAnterior
        : cuentaOrigenId;

    // 2) Emancipar: ownerAccountId → cuentaDestinoId
    await CuentaService.emanciparPerfilAlumno(
      perfilId: pid,
      cuentaDestinoId: destino,
    );

    // 3) Remover perfil del listado de la cuenta origen
    await _removerPerfilAlumnoDeCuentaOrigen(
      cuentaOrigenId: cuentaOrigenId,
      perfilId: pid,
    );

    // 4) Migrar solicitudes (reescritura canónica)
    await _migrarSolicitudesDePerfilANuevoOwner(
      perfilId: pid,
      ownerNuevo: destino,
    );

    // 5) Rebuild índices (best-effort)
    try {
      final repo = SolicitudesRepositoryPrefs();
      await repo.rebuildIndexes();
    } catch (_) {}

    // ownerOrigen queda disponible si más adelante se migra
    // notificaciones / documentos
    // ignore: unused_local_variable
    final _ = ownerOrigen;
  }

  // =====================================================
  // Remover perfil del listado de la cuenta origen
  // =====================================================
  static Future<void> _removerPerfilAlumnoDeCuentaOrigen({
    required String cuentaOrigenId,
    required String perfilId,
  }) async {
    final cid = _normId(cuentaOrigenId);
    final pid = _normId(perfilId);
    if (cid.isEmpty || pid.isEmpty) return;

    final cuenta = await CuentaService.getCuentaById(cid);
    if (cuenta == null) return;

    final nueva = List<String>.from(cuenta.perfilesAlumnoIds)
      ..removeWhere((x) => _normId(x) == pid);

    if (nueva.length == cuenta.perfilesAlumnoIds.length) return;

    cuenta.perfilesAlumnoIds = nueva;
    await CuentaService.actualizarCuenta(cuenta);

    try {
      final ultimo = await CuentaService.getUltimoPerfil(cid);
      if (_normId(ultimo ?? '') == pid) {
        await CuentaService.clearUltimoPerfil(cid);
      }
    } catch (_) {}
  }

  // =====================================================
  // Migrar solicitudes del perfil a nuevo owner
  // =====================================================
  static Future<void> _migrarSolicitudesDePerfilANuevoOwner({
    required String perfilId,
    required String ownerNuevo,
  }) async {
    final pid = _normId(perfilId);
    final on = _normId(ownerNuevo);
    if (pid.isEmpty || on.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_kSolAlumnoPrefix))
        .toList(growable: false);

    final nowIso = DateTime.now().toIso8601String();

    for (final k in keys) {
      final raw = prefs.getString(k);
      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;

        final s = SolicitudAlumno.fromMap(Map<String, dynamic>.from(decoded));

        final sPid = _normId(s.perfilId ?? '');
        if (sPid != pid) continue;

        final m = s.toMap();
        m['ownerAccountId'] = on;
        m['perfilId'] = pid;
        m['fechaUltimoCambio'] = nowIso;

        await prefs.setString(k, jsonEncode(m));
      } catch (_) {
        // ignorar corruptas
      }
    }
  }

  static String _normId(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), '');
  }
}
