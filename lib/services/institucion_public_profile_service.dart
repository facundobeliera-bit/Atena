// lib/services/institucion_public_profile_service.dart
//
// ATENA – INSTITUCIÓN · PUBLIC PROFILE SERVICE (CANÓNICO · BACKEND READY)
//
// Objetivo:
// - Proveer una API estable para leer/escribir el “Perfil público” institucional.
// - HOY: persistencia local (StorageService / SharedPreferences wrapper).
// - MAÑANA: reemplazar implementación por Firestore/Cloud sin tocar pantallas.
//
// Reglas:
// - Keyed SIEMPRE por institucionPerfilId CANÓNICO.
// - Nunca tirar exceptions hacia UI (best-effort).
// - No decide planes, locks ni navegación.
//
// ─────────────────────────────────────────────────────────────

import '../services/storage_service.dart';

class InstitucionPublicProfileService {
  InstitucionPublicProfileService._();

  static final InstitucionPublicProfileService instance =
      InstitucionPublicProfileService._();

  // Versionado por si migramos el esquema.
  static const String _kPrefix = 'inst_public_profile_v1_';

  String _keyFor(String institucionPerfilId) {
    final id = institucionPerfilId.trim();
    if (id.isEmpty) return '';
    // Mantener estable (la pantalla ya normaliza, pero no duele).
    return '$_kPrefix${id.replaceAll(RegExp(r"\s+"), "")}';
  }

  Future<String> loadRawJson(String institucionPerfilId) async {
    final k = _keyFor(institucionPerfilId);
    if (k.isEmpty) return '';
    try {
      return (await StorageService.instance.getString(k)) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> saveRawJson(String institucionPerfilId, String json) async {
    final k = _keyFor(institucionPerfilId);
    if (k.isEmpty) return false;
    try {
      return await StorageService.instance.setString(k, json);
    } catch (_) {
      return false;
    }
  }

  Future<bool> clear(String institucionPerfilId) async {
    final k = _keyFor(institucionPerfilId);
    if (k.isEmpty) return false;
    try {
      return await StorageService.instance.remove(k);
    } catch (_) {
      return false;
    }
  }
}
