// lib/screens/instituciones/institucion_perfiles_selector_page.dart
//
// ATENA – INSTITUCIÓN · SELECTOR DE ACTIVIDAD + PERFILES (FASE 2 · CANÓNICO)
//
// ✅ FIX REAL (feb 2026 · fondo incompleto):
// - El fondo estaba en Positioned.fill pero el Stack NO expandía porque los Positioned
//   no contribuyen al tamaño del Stack.
// - Solución: Stack(fit: StackFit.expand) + contenido en Positioned.fill / SafeArea.
// - Fondo SIEMPRE fullscreen; contenido en SafeArea para respetar insets.
//
// ✅ FIX (feb 2026 · assets canónicos):
// - Fondo usa Image.asset(AtenaAssets.bgInstitucionSelector) + AtenaAssets.ensureCanonical(...).
//
// ✅ MEJORA (feb 2026 · solicitado):
// - Renombrar “perfiles de trabajo” por actividad (alias visible), SIN tocar workProfileId.
// - Persistencia en SharedPreferences con keys estables (backend-ready).
// - Fallback automático: "Perfil de trabajo 1/2/3/…"
// - UX: lápiz + long-press + dialog Guardar/Cancelar + “Restaurar default”.
//
// ✅ FIX (feb 2026 · PopScope compat):
// - Evita depender de callbacks deprecated / no disponibles.
// - Se usa PopScope(canPop: true) sin callback (no necesitamos interceptar pop).
//
// ✅ MEJORA (feb 2026 · requested hardening):
// - Pull-to-refresh también re-lee Institución + planConfig y reconstruye actividades.
// - Si el plan cambia y la actividad seleccionada deja de existir, se limpia selección.
//
// i18n / Theme:
// - AppLocalizations + ColorScheme.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ L10N CANÓNICO (package import)
import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/institucion_area_locks.dart';
import '../../services/institucion_service.dart';
import '../../ui/atena_assets.dart';
import 'institucion_area_page.dart';

// =====================================================
// PREFS SAFE GET (timeout) – evita await colgado
// =====================================================

Future<SharedPreferences> _prefsSafeGet() {
  return SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
}

// =====================================================
// Helpers safe (enum name best-effort)
// =====================================================

String _enumName(Object e) {
  try {
    // ignore: avoid_dynamic_calls
    return (e as dynamic).name?.toString() ?? e.toString();
  } catch (_) {
    return e.toString();
  }
}

String _capUi(String s) {
  final t = s.trim().replaceAll('_', ' ');
  if (t.isEmpty) return t;
  if (t.length == 1) return t.toUpperCase();
  return '${t[0].toUpperCase()}${t.substring(1)}';
}

String _prefsKeySafe(String v, {String fallback = ''}) {
  final t = v.trim();
  if (t.isEmpty) return fallback;

  final s = t
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_\-\.]'), '_')
      .replaceAll(RegExp(r'_+'), '_');

  return s.isEmpty ? fallback : s;
}

String _normHuman(String v, {String fallback = ''}) {
  final t = v.trim();
  if (t.isEmpty) return fallback;
  final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  final out = parts.join(' ');
  return out.isEmpty ? fallback : out;
}

String _safeToString(dynamic v) => (v == null) ? '' : v.toString();

bool _truthy(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí';
}

String _uiNormalizeAlias(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  return t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).join(' ');
}

int _profileIndexFromId(String profileId) {
  final pid = profileId.trim();
  if (pid.isEmpty) return 1;

  final m = RegExp(r'(\d+)\s*$').firstMatch(pid);
  if (m != null) {
    final raw = m.group(1) ?? '';
    final n = int.tryParse(raw);
    if (n != null && n > 0) return n;
  }

  final m2 = RegExp(r'^wp_(\d+)$').firstMatch(pid);
  if (m2 != null) {
    final raw = m2.group(1) ?? '';
    final n = int.tryParse(raw);
    if (n != null && n > 0) return n;
  }

  return 1;
}

/// Label local “best-effort” para áreas (sin agregar keys).
String _areaLabel(InstitucionAreaKey a) => _capUi(_enumName(a));

// =====================================================
// L10N SAFE (evita romper compilación si faltan getters)
// =====================================================

String _l10nWorkProfileFallback(AppLocalizations l10n, int index) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final member = dyn.institucionWorkProfileFallback;
    if (member is Function) {
      final v = member(index);
      final out = (v?.toString() ?? '').trim();
      return out.isEmpty ? 'Perfil de trabajo $index' : out;
    }
    if (member is String) {
      final base = member.trim();
      if (base.isEmpty) return 'Perfil de trabajo $index';
      return '$base $index';
    }
  } catch (_) {}
  return 'Perfil de trabajo $index';
}

String _l10nIdWithValue(AppLocalizations l10n, String id) {
  final v = id.trim();
  if (v.isEmpty) return '';
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final member = dyn.idWithValue;
    if (member is Function) {
      final out = member(v);
      return (out?.toString() ?? '').trim().isEmpty ? v : out.toString();
    }
    if (member is String) {
      final base = member.trim();
      if (base.isEmpty) return v;
      return '$base $v';
    }
  } catch (_) {}
  return v;
}

String _l10nActivityWithValue(AppLocalizations l10n, String label) {
  final v = label.trim();
  if (v.isEmpty) return '';
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final member = dyn.activityWithValue;
    if (member is Function) {
      final out = member(v);
      return (out?.toString() ?? '').trim().isNotEmpty ? out.toString() : v;
    }
    if (member is String) {
      final base = member.trim();
      if (base.isEmpty) return v;
      return '$base $v';
    }
  } catch (_) {}
  return v;
}

String _l10nUnknownError(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;

    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.unknownError,
      dyn.errorUnknown,
      dyn.genericError,
      dyn.errorGeneric,
    ];

    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Error';
}

String _l10nName(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.name,
      dyn.commonName,
      dyn.nombre,
      dyn.commonNombre,
    ];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Nombre';
}

String _l10nSave(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.save,
      dyn.guardar,
      dyn.commonSave,
      dyn.commonGuardar,
    ];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Guardar';
}

String _l10nAvailable(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.available,
      dyn.disponible,
      dyn.commonAvailable,
      dyn.commonDisponible,
    ];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Disponible';
}

String _l10nPlan(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[dyn.plan, dyn.commonPlan];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Plan';
}

String _l10nPerfiles(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.perfiles,
      dyn.commonPerfiles,
      dyn.profiles,
      dyn.commonProfiles,
    ];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Perfiles';
}

String _l10nRefresh(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.refresh,
      dyn.actualizar,
      dyn.commonRefresh,
      dyn.commonActualizar,
    ];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Actualizar';
}

String _l10nRename(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.rename,
      dyn.renombrar,
      dyn.commonRename,
      dyn.commonRenombrar,
    ];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Renombrar';
}

String _l10nRestoreDefault(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final cands = <dynamic>[
      dyn.restoreDefault,
      dyn.restaurarDefault,
      dyn.commonRestoreDefault,
      dyn.commonRestaurarDefault,
      dyn.restore,
      dyn.restaurar,
    ];
    for (final m in cands) {
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is Function) {
        final out = m();
        if (out is String && out.trim().isNotEmpty) return out.trim();
      }
    }
  } catch (_) {}
  return 'Restaurar default';
}

String _l10nInstitution(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.institution;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Institución';
}

String _l10nSelectActivityTitle(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.seleccionarActividad;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Seleccionar actividad';
}

String _l10nFirstSelectActivity(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.primeroSeleccionaUnaActividad;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Primero seleccioná una actividad';
}

String _l10nWorkProfiles(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.perfilesDeTrabajo;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Perfiles de trabajo';
}

String _l10nWorkProfilesHint(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.losPerfilesDeTrabajoSonInternos;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Los perfiles de trabajo son internos para organizar tareas dentro de la institución.';
}

String _l10nEnter(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.entrar;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Entrar';
}

String _l10nNoActivitiesEnabled(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.noHayActividadesHabilitadas;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'No hay actividades habilitadas.';
}

String _l10nCurricularPlural(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.curricularPlural;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Curricular';
}

String _l10nExtracurricularPlural(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.extracurricularPlural;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Extracurricular';
}

String _l10nRetry(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.retry;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Reintentar';
}

String _l10nCancel(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.cancelar;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Cancelar';
}

String _l10nLocked(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.bloqueado;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Bloqueado';
}

String _l10nLockedBy(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.bloqueadoPor;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Bloqueado por';
}

String _l10nLockedByYou(AppLocalizations l10n) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = l10n as dynamic;
    // ignore: avoid_dynamic_calls
    final m = dyn.bloqueadoPorVos;
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is Function) {
      final out = m();
      if (out is String && out.trim().isNotEmpty) return out.trim();
    }
  } catch (_) {}
  return 'Bloqueado por vos';
}

// =====================================================
// CANÓNICO: Normalización profileId por actividad (SIN dynamic)
// =====================================================

String _normalizeProfileIdForActividad({
  required String profileId,
  required String actividadKey,
}) {
  final pid = profileId.trim();
  final act = actividadKey.trim();
  if (pid.isEmpty) return pid;
  if (act.isEmpty) return pid;

  try {
    return InstitucionAreaLockService.normalizeProfileIdForActividad(
      profileId: pid,
      actividadKey: act,
    ).trim();
  } catch (_) {}

  final actSafe = _prefsKeySafe(act, fallback: 'actividad_default');
  final scopedPrefix = 'wp_${actSafe}_';

  if (pid.startsWith(scopedPrefix)) return pid;

  final mLegacy = RegExp(r'^wp_(\d+)$').firstMatch(pid);
  if (mLegacy != null) {
    final n = mLegacy.group(1) ?? '';
    if (n.trim().isEmpty) return pid;
    return 'wp_${actSafe}_$n';
  }

  return pid;
}

/// ✅ InstId para locks/prefs: KEY-SAFE (mismo normalizador del Guard/Locks service).
String _normalizeInstIdForLocks(String instIdData) {
  final v = instIdData.trim();
  if (v.isEmpty) return '';

  try {
    return InstitucionAreaLockService.normalizeInstIdForLocks(v).trim();
  } catch (_) {
    final h = _normHuman(v, fallback: '');
    if (h.isEmpty) return '';
    return h
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-\.]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }
}

/// ✅ Actividad scope estable (key-safe) para TODO (prefs/locks/navegación).
String _normalizeActividadForScope(String actividadKeyAny) {
  final raw = actividadKeyAny.trim();
  if (raw.isEmpty) return '';
  try {
    return InstitucionAreaLockService.normalizeActividadKeyForScope(raw).trim();
  } catch (_) {
    return _prefsKeySafe(raw, fallback: 'actividad_default').trim();
  }
}

// =====================================================
// STATUS FREE LOCAL (contrato actual)
// =====================================================

InstitucionAreaLockStatus _freeStatusLocal() {
  return const InstitucionAreaLockStatus(
    locked: false,
    mine: false,
    deviceId: null,
    profileId: null,
    profileName: null,
    expiresAt: null,
  );
}

// =====================================================
// ACTIVIDAD A GESTIONAR
// =====================================================

enum InstitucionActividadKind { curricular, extracurricular }

class InstitucionActividadRef {
  final InstitucionActividadKind kind;
  final String key; // ✅ key “estable” (ya debe ser scope-safe)
  final String label;

  const InstitucionActividadRef({
    required this.kind,
    required this.key,
    required this.label,
  });

  String get keyScope => _normalizeActividadForScope(key);
}

class _ActividadStore {
  static String _kActiveActividad(String instIdLocks) =>
      'inst_act_active_v1_${_prefsKeySafe(instIdLocks, fallback: 'inst')}';

  static Future<String?> getActiveActividadKey(String instIdLocks) async {
    final prefs = await _prefsSafeGet();
    final v = (prefs.getString(_kActiveActividad(instIdLocks)) ?? '').trim();
    return v.isEmpty ? null : v;
  }

  static Future<void> setActiveActividadKey(
    String instIdLocks,
    String? key,
  ) async {
    final prefs = await _prefsSafeGet();
    final v = (key ?? '').trim();
    if (v.isEmpty) {
      await prefs.remove(_kActiveActividad(instIdLocks));
      return;
    }
    await prefs.setString(_kActiveActividad(instIdLocks), v);
  }
}

// =====================================================
// PERFIL DE TRABAJO POR ACTIVIDAD (UX + nombres)
// =====================================================

class InstitucionWorkProfilesStore {
  static String _kActiveProfile(String instIdLocks, String actividadKey) {
    final i = _prefsKeySafe(instIdLocks, fallback: 'inst');
    final a = _prefsKeySafe(actividadKey, fallback: 'actividad_default');
    return 'inst_wp_active_v2_${i}_$a';
  }

  static String _kProfileName(
    String instIdLocks,
    String actividadKey,
    String profileId,
  ) {
    final i = _prefsKeySafe(instIdLocks, fallback: 'inst');
    final a = _prefsKeySafe(actividadKey, fallback: 'actividad_default');
    final p = _prefsKeySafe(profileId, fallback: 'wp');
    return 'inst_wp_name_v2_${i}_${a}_$p';
  }

  static List<String> scopedProfileIds({
    required String actividadKey,
    required int max,
  }) {
    final a = _prefsKeySafe(actividadKey, fallback: 'actividad_default');
    return List<String>.generate(max, (i) => 'wp_${a}_${i + 1}');
  }

  static Future<String?> getActiveProfileId(
    String instIdLocks,
    String actividadKey,
  ) async {
    final prefs = await _prefsSafeGet();
    final v =
        (prefs.getString(_kActiveProfile(instIdLocks, actividadKey)) ?? '')
            .trim();
    return v.isEmpty ? null : v;
  }

  static Future<void> setActiveProfileId(
    String instIdLocks,
    String actividadKey,
    String? profileId,
  ) async {
    final prefs = await _prefsSafeGet();
    final v = (profileId ?? '').trim();
    if (v.isEmpty) {
      await prefs.remove(_kActiveProfile(instIdLocks, actividadKey));
      return;
    }
    await prefs.setString(_kActiveProfile(instIdLocks, actividadKey), v);
  }

  static Future<String> getProfileName({
    required String instIdLocks,
    required String actividadKey,
    required String profileId,
    required String fallback,
  }) async {
    final prefs = await _prefsSafeGet();
    final v =
        (prefs.getString(_kProfileName(instIdLocks, actividadKey, profileId)) ??
                '')
            .trim();
    return v.isEmpty ? fallback : v;
  }

  static Future<void> setProfileName({
    required String instIdLocks,
    required String actividadKey,
    required String profileId,
    required String name,
  }) async {
    final prefs = await _prefsSafeGet();
    final v = name.trim();
    if (v.isEmpty) return;
    await prefs.setString(
      _kProfileName(instIdLocks, actividadKey, profileId),
      v,
    );
  }

  static Future<void> clearProfileName({
    required String instIdLocks,
    required String actividadKey,
    required String profileId,
  }) async {
    final prefs = await _prefsSafeGet();
    await prefs.remove(_kProfileName(instIdLocks, actividadKey, profileId));
  }
}

// =====================================================
// PAGE
// =====================================================

class InstitucionPerfilesSelectorPage extends StatefulWidget {
  final String? ownerAccountId;

  // ✅ CANÓNICO (preferido)
  final String? institucionPerfilId;

  // ✅ LEGACY (mantener compat con callers viejos)
  final String? institucionId;

  final String institucionNombre;
  final Institucion institucion;

  const InstitucionPerfilesSelectorPage({
    super.key,
    this.ownerAccountId,
    this.institucionPerfilId,
    this.institucionId,
    required this.institucionNombre,
    required this.institucion,
  });

  /// ✅ Fuente de verdad DATA:
  /// 1) institucionPerfilId (canónico)
  /// 2) institucion.id (dominio canónico; suele ser == perfilId)
  /// 3) institucionId (legacy)
  String get institucionIdData {
    final a = (institucionPerfilId ?? '').trim();
    if (a.isNotEmpty) return a;

    final b = institucion.id.trim();
    if (b.isNotEmpty) return b;

    return (institucionId ?? '').trim();
  }

  @override
  State<InstitucionPerfilesSelectorPage> createState() =>
      _InstitucionPerfilesSelectorPageState();
}

class _InstitucionPerfilesSelectorPageState
    extends State<InstitucionPerfilesSelectorPage> {
  Timer? _poll;

  bool _loading = true;
  bool _refreshing = false;

  bool _inChildRoute = false;

  String? _loadError;

  Timer? _loadWatchdog;
  int _loadToken = 0;

  String? _deviceId;

  // ✅ Overlay suave para diagnóstico visual de navegación.
  bool _navOverlay = false;

  // ✅ Fuente real de dominio (best-effort desde prefs por ID canónico)
  late Institucion _instDomain;

  String get _instIdData => widget.institucionIdData;
  String get _instIdLocks => _normalizeInstIdForLocks(_instIdData);

  List<InstitucionActividadRef> _actividades = const [];
  InstitucionActividadRef? _actividadSeleccionada;

  final Map<String, String> _names = {};
  String? _activeProfileId;

  final Map<String, _ProfileWorkingInfo> _workingByProfile = {};
  final Map<InstitucionAreaKey, InstitucionAreaLockStatus> _areaStatus = {};

  int _profilesPerActividad(Institucion inst) {
    final raw = (inst.tipoPlan).toString();
    final v = raw.trim().toLowerCase();
    return v.contains('premium') ? 10 : 3;
  }

  dynamic _planOf(Institucion inst) {
    try {
      // ignore: avoid_dynamic_calls
      final p = (inst as dynamic).planSafe;
      if (p != null) return p;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final p = (inst as dynamic).plan;
      if (p != null) return p;
    } catch (_) {}
    return null;
  }

  // =====================================================
  // DEVICE ID (LOCAL, SIN DEPENDENCIAS EXTERNAS)
  // =====================================================

  static const String _kDeviceId = 'atena_device_id_v1';

  Future<String> _ensureDeviceId() async {
    final existing = (_deviceId ?? '').trim();
    if (existing.isNotEmpty) return existing;

    try {
      final prefs = await _prefsSafeGet();
      final stored = (prefs.getString(_kDeviceId) ?? '').trim();
      if (stored.isNotEmpty) {
        _deviceId = stored;
        return stored;
      }

      final now = DateTime.now().microsecondsSinceEpoch;
      final did = 'dev_$now';
      await prefs.setString(_kDeviceId, did);
      _deviceId = did;
      return did;
    } catch (_) {
      final now = DateTime.now().microsecondsSinceEpoch;
      final did = 'dev_$now';
      _deviceId = did;
      return did;
    }
  }

  Future<InstitucionAreaLockStatus> _getStatusSafe({
    required String instIdData,
    required String actividadKeyScope,
    required InstitucionAreaKey area,
  }) async {
    try {
      final dev = await _ensureDeviceId();
      return await InstitucionAreaLockService.getStatus(
        instId: instIdData, // ✅ SIEMPRE DATA
        actividadKey: actividadKeyScope, // ✅ SIEMPRE SCOPE
        area: area,
        deviceId: dev,
        mine: false,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {
      return _freeStatusLocal();
    }
  }

  @override
  void initState() {
    super.initState();

    _instDomain = widget.institucion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _loadSafe();
    });

    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_loading || _refreshing || _inChildRoute) return;
      if (_loadError != null) return;
      if (_actividadSeleccionada == null) return;
      // ignore: discarded_futures
      _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _poll = null;

    _loadWatchdog?.cancel();
    _loadWatchdog = null;

    super.dispose();
  }

  void _startLoadWatchdog({
    Duration timeout = const Duration(seconds: 12),
    String tag = 'load',
  }) {
    _loadWatchdog?.cancel();
    _loadWatchdog = null;

    final myToken = ++_loadToken;

    _loadWatchdog = Timer(timeout, () {
      if (!mounted) return;
      if (_loadToken != myToken) return;
      if (!_loading) return;

      debugPrint('[ATENA][WP-SELECT][$tag][WATCHDOG] timeout -> error view');
      setState(() {
        _loadError = 'Timeout';
        _loading = false;
      });
    });
  }

  void _stopLoadWatchdog() {
    _loadWatchdog?.cancel();
    _loadWatchdog = null;
  }

  // =====================================================
  // UI PIECES
  // =====================================================

  Widget _buildBackground() {
    final path = AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionSelector);
    final cs = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: cs.surface);
        },
      ),
    );
  }

  Widget _buildTopPanel(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final act = _actividadSeleccionada;

    String planText = '';
    try {
      // ignore: avoid_dynamic_calls
      final p = (_instDomain as dynamic).tipoPlan;
      planText = _safeToString(p).trim();
    } catch (_) {}

    final perfilesMax = _profilesPerActividad(_instDomain);

    final instIdLine = _l10nIdWithValue(l10n, _instIdData);
    final actLine = (act == null)
        ? _l10nFirstSelectActivity(l10n)
        : _l10nActivityWithValue(l10n, act.label);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(color: cs.onSurface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.institucionNombre.trim().isEmpty
                  ? _l10nInstitution(l10n)
                  : widget.institucionNombre.trim(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (instIdLine.trim().isNotEmpty)
              Text(instIdLine, style: Theme.of(context).textTheme.bodySmall),
            if (planText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_l10nPlan(l10n)}: $planText · ${_l10nPerfiles(l10n)}: $perfilesMax',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 10),
            Text(
              actLine,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _l10nWorkProfilesHint(l10n),
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActividadSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildActividadTile(InstitucionActividadRef act) {
    final cs = Theme.of(context).colorScheme;
    final selected = (_actividadSeleccionada?.keyScope ?? '') == act.keyScope;

    return InkWell(
      onTap: () => _selectActividad(act),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.85)
              : cs.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              act.kind == InstitucionActividadKind.curricular
                  ? Icons.school
                  : Icons.extension,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                act.label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesPanel(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    final act = _actividadSeleccionada;
    if (act == null) {
      return const SizedBox.shrink();
    }

    final actScope = act.keyScope.trim();
    final max = _profilesPerActividad(_instDomain);
    final ids = _profileIdsForActividad(actividadKeyScope: actScope, max: max);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _l10nWorkProfiles(l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: _loading
                    ? null
                    : () => _refresh(allowWhileLoading: true),
                icon: Icon(Icons.refresh, size: 18, color: cs.primary),
                label: Text(_l10nRefresh(l10n)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < ids.length; i++)
                _buildProfileChip(l10n: l10n, profileId: ids[i], index: i + 1),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAreaStatusSummary(l10n)),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: (_activeProfileId ?? '').trim().isEmpty
                    ? null
                    : _enterAreaOperativa,
                icon: const Icon(Icons.login),
                label: Text(_l10nEnter(l10n)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip({
    required AppLocalizations l10n,
    required String profileId,
    required int index,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selected = (_activeProfileId ?? '').trim() == profileId.trim();
    final info = _workingByProfile[profileId];
    final isWorking = info?.isWorking == true;

    final label = (_names[profileId] ?? '').trim().isEmpty
        ? _l10nWorkProfileFallback(l10n, index)
        : _names[profileId]!.trim();

    return InkWell(
      onTap: () => _selectProfile(profileId),
      onLongPress: () => _editProfileName(profileId: profileId),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.9)
              : cs.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWorking ? Icons.circle : Icons.circle_outlined,
              size: 12,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _editProfileName(profileId: profileId),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaStatusSummary(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    String lineFor(InstitucionAreaKey k) {
      final st = _areaStatus[k] ?? _freeStatusLocal();
      final label = _areaLabel(k);
      if (!st.locked) return '$label: ${_l10nAvailable(l10n)}';
      if (st.mine) return '$label: ${_l10nLockedByYou(l10n)}';
      final by = (st.profileName ?? '').trim().isNotEmpty
          ? (st.profileName ?? '').trim()
          : (st.profileId ?? '').trim();
      if (by.isEmpty) return '$label: ${_l10nLocked(l10n)}';
      return '$label: ${_l10nLockedBy(l10n)} $by';
    }

    final lines = <String>[
      lineFor(InstitucionAreaKey.vacantes),
      lineFor(InstitucionAreaKey.solicitudes),
      lineFor(InstitucionAreaKey.notificaciones),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              s,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final msg = (_loadError ?? '').trim();

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 28),
            const SizedBox(height: 10),
            Text(
              msg.isEmpty ? _l10nUnknownError(l10n) : msg,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadSafe, child: Text(_l10nRetry(l10n))),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // UI ACTIONS
  // =====================================================

  Future<void> _selectActividad(InstitucionActividadRef act) async {
    final actScope = act.keyScope.trim();
    if (actScope.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _actividadSeleccionada = act;
      _loadError = null;
    });

    if (_instIdLocks.isNotEmpty) {
      try {
        await _ActividadStore.setActiveActividadKey(
          _instIdLocks,
          actScope,
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }

    await _loadProfilesForActividad(act);
  }

  Future<void> _selectProfile(String profileId) async {
    final act = _actividadSeleccionada;
    if (act == null) return;

    final actScope = act.keyScope.trim();
    if (_instIdLocks.isNotEmpty == false || actScope.isEmpty) return;

    final normalized = _normalizeProfileIdForActividad(
      profileId: profileId,
      actividadKey: actScope,
    );

    if (!mounted) return;
    setState(() {
      _activeProfileId = normalized;
      _loadError = null;
    });

    try {
      await InstitucionWorkProfilesStore.setActiveProfileId(
        _instIdLocks,
        actScope,
        normalized,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}

    await _refresh(allowWhileLoading: true);
  }

  Future<void> _editProfileName({required String profileId}) async {
    final act = _actividadSeleccionada;
    if (act == null) return;

    final actScope = act.keyScope.trim();
    if (_instIdLocks.isNotEmpty == false || actScope.isEmpty) return;

    final normalizedPid = _normalizeProfileIdForActividad(
      profileId: profileId,
      actividadKey: actScope,
    );

    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    final idx = _profileIndexFromId(normalizedPid);

    final controller = TextEditingController(
      text: (_names[normalizedPid] ?? '').trim(),
    );

    final res = await showDialog<_RenameResult>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text(_l10nRename(l10n)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _l10nWorkProfileFallback(l10n, idx),
                  style: Theme.of(ctx).textTheme.bodySmall!.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: _l10nName(l10n),
                  hintText: _l10nWorkProfileFallback(l10n, idx),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_RenameResult.cancel),
              child: Text(_l10nCancel(l10n)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_RenameResult.restore),
              child: Text(_l10nRestoreDefault(l10n)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(_RenameResult.save),
              child: Text(_l10nSave(l10n)),
            ),
          ],
        );
      },
    );

    if (res == null || res == _RenameResult.cancel) return;

    if (res == _RenameResult.restore) {
      try {
        await InstitucionWorkProfilesStore.clearProfileName(
          instIdLocks: _instIdLocks,
          actividadKey: actScope,
          profileId: normalizedPid,
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}

      if (!mounted) return;
      setState(() => _names.remove(normalizedPid));
      return;
    }

    final name = _uiNormalizeAlias(controller.text);

    if (name.isEmpty) {
      try {
        await InstitucionWorkProfilesStore.clearProfileName(
          instIdLocks: _instIdLocks,
          actividadKey: actScope,
          profileId: normalizedPid,
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}

      if (!mounted) return;
      setState(() => _names.remove(normalizedPid));
      return;
    }

    final safe = name.length > 40 ? name.substring(0, 40).trim() : name;

    try {
      await InstitucionWorkProfilesStore.setProfileName(
        instIdLocks: _instIdLocks,
        actividadKey: actScope,
        profileId: normalizedPid,
        name: safe,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}

    if (!mounted) return;
    setState(() => _names[normalizedPid] = safe);
  }

  Future<void> _enterAreaOperativa() async {
    final act = _actividadSeleccionada;
    final pid = (_activeProfileId ?? '').trim();
    if (act == null || pid.isEmpty) return;

    final instIdData = _instIdData.trim();
    final actScope = act.keyScope.trim();
    if (instIdData.isEmpty || actScope.isEmpty) return;

    setState(() {
      _navOverlay = true;
      _inChildRoute = true;
    });

    try {
      final normalizedPid = _normalizeProfileIdForActividad(
        profileId: pid,
        actividadKey: actScope,
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InstitucionAreaPage(
            ownerAccountId: widget.ownerAccountId,
            institucionId: instIdData, // DATA (perfil institución)
            institucionNombre: widget.institucionNombre,
            institucion: _instDomain,
            workProfileId: normalizedPid,
            actividadKey: actScope,
            actividadLabel: act.label,
          ),
        ),
      );
    } catch (_) {
      // no-op
    } finally {
      if (mounted) {
        setState(() {
          _navOverlay = false;
          _inChildRoute = false;
        });
        // ignore: discarded_futures
        _refresh(allowWhileLoading: true);
      }
    }
  }

  // =====================================================
  // BUILD (FIX fondo fullscreen real)
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        title: Text(_l10nSelectActivityTitle(l10n)),
      ),
      body: PopScope(
        canPop: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            Positioned.fill(
              child: SafeArea(
                child: _loading
                    ? Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        ),
                      )
                    : (_loadError != null)
                    ? _buildError(l10n)
                    : RefreshIndicator(
                        onRefresh: () => _refresh(allowWhileLoading: true),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            _buildTopPanel(l10n),
                            if (_actividades.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  _l10nNoActivitiesEnabled(l10n),
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              )
                            else ...[
                              _buildActividadSectionTitle(
                                _l10nCurricularPlural(l10n),
                              ),
                              for (final a in _actividades.where(
                                (x) =>
                                    x.kind ==
                                    InstitucionActividadKind.curricular,
                              ))
                                _buildActividadTile(a),
                              const SizedBox(height: 6),
                              _buildActividadSectionTitle(
                                _l10nExtracurricularPlural(l10n),
                              ),
                              for (final a in _actividades.where(
                                (x) =>
                                    x.kind ==
                                    InstitucionActividadKind.extracurricular,
                              ))
                                _buildActividadTile(a),
                            ],
                            if (_actividadSeleccionada != null)
                              _buildProfilesPanel(l10n),
                          ],
                        ),
                      ),
              ),
            ),
            if (_navOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: cs.surface.withValues(alpha: 0.06),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // LOADERS / REFRESH (pasteable)
  // =====================================================

  Future<void> _loadSafe() async {
    _startLoadWatchdog(tag: 'loadSafe');
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _loadError = null;
      });

      // Best-effort: refrescar institución desde service si existe
      try {
        final inst = await InstitucionService.getInstitucionById(
          _instIdData,
        ).timeout(const Duration(seconds: 2));
        if (inst != null) _instDomain = inst;
      } catch (_) {}

      await _ensureDeviceId();

      await _loadActividadesBestEffort(force: true);

      // Selección previa guardada (best-effort)
      if (_instIdLocks.isNotEmpty) {
        try {
          final last = await _ActividadStore.getActiveActividadKey(
            _instIdLocks,
          ).timeout(const Duration(seconds: 2));
          if (last != null) {
            final hit = _actividades
                .where((a) => a.keyScope.trim() == last.trim())
                .toList();
            if (hit.isNotEmpty) _actividadSeleccionada = hit.first;
          }
        } catch (_) {}
      }

      if (_actividadSeleccionada != null) {
        await _loadProfilesForActividad(_actividadSeleccionada!);
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    } finally {
      _stopLoadWatchdog();
    }
  }

  Future<void> _refresh({bool allowWhileLoading = false}) async {
    if (!allowWhileLoading && (_loading || _refreshing)) return;
    if (_refreshing) return;

    try {
      if (mounted) setState(() => _refreshing = true);

      // 1) best-effort: refrescar institución (plan puede haber cambiado)
      try {
        final inst = await InstitucionService.getInstitucionById(
          _instIdData,
        ).timeout(const Duration(seconds: 2));
        if (inst != null) _instDomain = inst;
      } catch (_) {}

      // 2) reconstruir actividades (planConfig actualizado)
      await _loadActividadesBestEffort(force: true);

      // 3) si la actividad seleccionada ya no existe, limpiarla
      final selectedScope = (_actividadSeleccionada?.keyScope ?? '').trim();
      if (selectedScope.isNotEmpty) {
        final still = _actividades.any(
          (a) => a.keyScope.trim() == selectedScope,
        );
        if (!still) {
          _actividadSeleccionada = null;
          _activeProfileId = null;
          _names.clear();
          _workingByProfile.clear();
          _areaStatus.clear();
          if (_instIdLocks.isNotEmpty) {
            try {
              await _ActividadStore.setActiveActividadKey(
                _instIdLocks,
                null,
              ).timeout(const Duration(seconds: 2));
            } catch (_) {}
          }
        }
      }

      final act = _actividadSeleccionada;
      if (act == null) {
        if (!mounted) return;
        setState(() {});
        return;
      }

      final actScope = act.keyScope.trim();

      // refresco locks/status
      for (final k in InstitucionAreaKey.values) {
        final st = await _getStatusSafe(
          instIdData: _instIdData,
          actividadKeyScope: actScope,
          area: k,
        );
        _areaStatus[k] = st;
      }

      // working info simplificado
      final max = _profilesPerActividad(_instDomain);
      final ids = _profileIdsForActividad(
        actividadKeyScope: actScope,
        max: max,
      );

      for (final id in ids) {
        _workingByProfile[id] = _ProfileWorkingInfo(
          profileId: id,
          isActive: (_activeProfileId ?? '').trim() == id.trim(),
          isWorking: false,
        );
      }

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // no-op
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _loadProfilesForActividad(InstitucionActividadRef act) async {
    final actScope = act.keyScope.trim();
    if (_instIdLocks.isEmpty || actScope.isEmpty) return;

    final max = _profilesPerActividad(_instDomain);
    final ids = _profileIdsForActividad(actividadKeyScope: actScope, max: max);

    // Active profile (persistido)
    try {
      final stored = await InstitucionWorkProfilesStore.getActiveProfileId(
        _instIdLocks,
        actScope,
      ).timeout(const Duration(seconds: 2));
      if (stored != null && stored.trim().isNotEmpty) {
        _activeProfileId = stored.trim();
      } else {
        _activeProfileId = ids.isNotEmpty ? ids.first : null;
      }
    } catch (_) {
      _activeProfileId = ids.isNotEmpty ? ids.first : null;
    }

    // Names
    _names.removeWhere((k, _) => !ids.contains(k));
    for (int i = 0; i < ids.length; i++) {
      final pid = ids[i];
      try {
        final name = await InstitucionWorkProfilesStore.getProfileName(
          instIdLocks: _instIdLocks,
          actividadKey: actScope,
          profileId: pid,
          fallback: '',
        ).timeout(const Duration(seconds: 2));
        if (name.trim().isNotEmpty) {
          _names[pid] = name.trim();
        } else {
          _names.remove(pid);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {});
    await _refresh(allowWhileLoading: true);
  }

  List<String> _profileIdsForActividad({
    required String actividadKeyScope,
    required int max,
  }) {
    if (actividadKeyScope.trim().isEmpty) return const [];
    return InstitucionWorkProfilesStore.scopedProfileIds(
      actividadKey: actividadKeyScope,
      max: max,
    );
  }

  // =====================================================
  // ACTIVIDADES (CANÓNICO) – extracción best-effort desde planConfig
  // =====================================================

  dynamic _tryJsonDecode(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      return jsonDecode(t);
    } catch (_) {
      return null;
    }
  }

  dynamic _mapGet(Map<dynamic, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k)) return m[k];

      final ks = k.replaceAll('_', '');
      for (final entry in m.entries) {
        final kk = entry.key?.toString() ?? '';
        if (kk.replaceAll('_', '').toLowerCase() == ks.toLowerCase()) {
          return entry.value;
        }
      }
    }
    return null;
  }

  Iterable<dynamic> _iterFromAny(dynamic v) {
    if (v == null) return const [];

    if (v is Map) {
      final out = <dynamic>[];
      for (final entry in v.entries) {
        final k = entry.key;
        final val = entry.value;
        if (_truthy(val)) out.add(k);
      }
      return out;
    }

    if (v is Iterable) return v.cast<dynamic>();
    if (v is List) return v.cast<dynamic>();

    return const [];
  }

  dynamic _planConfigOf(dynamic planAny) {
    if (planAny == null) {
      try {
        // ignore: avoid_dynamic_calls
        final pc0 = (_instDomain as dynamic).planConfig;
        if (pc0 != null) return pc0;
      } catch (_) {}
      try {
        // ignore: avoid_dynamic_calls
        final raw = (_instDomain as dynamic).planConfigJson;
        if (raw is String) {
          final decoded = _tryJsonDecode(raw);
          if (decoded != null) return decoded;
        }
      } catch (_) {}
      try {
        // ignore: avoid_dynamic_calls
        final raw = (_instDomain as dynamic).planConfigMap;
        if (raw is Map) return raw;
      } catch (_) {}
      try {
        // ignore: avoid_dynamic_calls
        final raw = (_instDomain as dynamic).planConfigRaw;
        if (raw is String) {
          final decoded = _tryJsonDecode(raw);
          if (decoded != null) return decoded;
        }
        if (raw is Map) return raw;
      } catch (_) {}
      return null;
    }

    try {
      // ignore: avoid_dynamic_calls
      final pc0 = (_instDomain as dynamic).planConfig;
      if (pc0 != null) return pc0;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final raw = (_instDomain as dynamic).planConfigJson;
      if (raw is String) {
        final decoded = _tryJsonDecode(raw);
        if (decoded != null) return decoded;
      }
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final raw = (_instDomain as dynamic).planConfigMap;
      if (raw is Map) return raw;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final raw = (_instDomain as dynamic).planConfigRaw;
      if (raw is String) {
        final decoded = _tryJsonDecode(raw);
        if (decoded != null) return decoded;
      }
      if (raw is Map) return raw;
    } catch (_) {}

    if (planAny is String) {
      final decoded = _tryJsonDecode(planAny);
      if (decoded != null) return decoded;
    }

    if (planAny is Map) {
      final m = planAny.cast<dynamic, dynamic>();
      final niveles = _mapGet(m, const [
        'niveles',
        'nivelesCurriculares',
        'nivelesSeleccionados',
        'nivelesCurricularesSeleccionados',
      ]);
      final modulos = _mapGet(m, const [
        'modulos',
        'modulosExtracurriculares',
        'modulosSeleccionados',
        'modulosExtracurricularesSeleccionados',
      ]);
      if (niveles != null || modulos != null) return planAny;
      final pc = _mapGet(m, const ['planConfig', 'config', 'data']);
      if (pc != null) return pc;
    }

    try {
      // ignore: avoid_dynamic_calls
      final niveles = (planAny as dynamic).niveles;
      // ignore: avoid_dynamic_calls
      final modulos = (planAny as dynamic).modulos;
      if (niveles != null || modulos != null) return planAny;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final pc = (planAny as dynamic).planConfig;
      if (pc != null) return pc;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final pc = (planAny as dynamic).config;
      if (pc != null) return pc;
    } catch (_) {}

    try {
      // ignore: avoid_dynamic_calls
      final pc = (planAny as dynamic).data;
      if (pc != null) return pc;
    } catch (_) {}

    return null;
  }

  bool _itemHabilitado(dynamic item) {
    final candidates = <dynamic>[];
    try {
      // ignore: avoid_dynamic_calls
      candidates.add((item as dynamic).habilitado);
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      candidates.add((item as dynamic).enabled);
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      candidates.add((item as dynamic).selected);
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      candidates.add((item as dynamic).activo);
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      candidates.add((item as dynamic).isEnabled);
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      candidates.add((item as dynamic).isSelected);
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      candidates.add((item as dynamic).isActive);
    } catch (_) {}

    for (final v in candidates) {
      if (_truthy(v)) return true;
    }
    return false;
  }

  String _nivelNameOf(dynamic n) {
    if (n == null) return '';
    if (n is String) return n.trim();

    try {
      // ignore: avoid_dynamic_calls
      final v = (n as dynamic).nivel;
      final s = _enumName(v).trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final v = (n as dynamic).key;
      final s = _safeToString(v).trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final v = (n as dynamic).nombre;
      final s = _safeToString(v).trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
    if (n is Map) {
      final m = n.cast<dynamic, dynamic>();
      final v = _mapGet(m, const ['nivel', 'key', 'nombre', 'name', 'id']);
      final s = _safeToString(v).trim();
      if (s.isNotEmpty) return s;
    }

    final s = _safeToString(n).trim();
    if (s.isNotEmpty && !s.contains('Instance of')) return s;
    return '';
  }

  String _moduloNameOf(dynamic m) {
    if (m == null) return '';
    if (m is String) return m.trim();

    try {
      // ignore: avoid_dynamic_calls
      final v = (m as dynamic).bloque;
      final s = _enumName(v).trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final v = (m as dynamic).modulo;
      final s = _enumName(v).trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final v = (m as dynamic).key;
      final s = _safeToString(v).trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final v = (m as dynamic).nombre;
      final s = _safeToString(v).trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
    if (m is Map) {
      final mm = m.cast<dynamic, dynamic>();
      final v = _mapGet(mm, const [
        'bloque',
        'modulo',
        'key',
        'nombre',
        'name',
        'id',
      ]);
      final s = _safeToString(v).trim();
      if (s.isNotEmpty) return s;
    }

    final s = _enumName(m).trim();
    if (s.isNotEmpty && !s.contains('Instance of')) return s;
    return '';
  }

  String _nombrePropioOf(dynamic item) {
    try {
      // ignore: avoid_dynamic_calls
      final v = (item as dynamic).nombrePropio;
      final s = _safeToString(v).trim();
      return s;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final v = (item as dynamic).label;
      final s = _safeToString(v).trim();
      return s;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final v = (item as dynamic).displayName;
      final s = _safeToString(v).trim();
      return s;
    } catch (_) {}
    if (item is Map) {
      final m = item.cast<dynamic, dynamic>();
      final v = _mapGet(m, const [
        'nombrePropio',
        'label',
        'displayName',
        'display_name',
      ]);
      return _safeToString(v).trim();
    }
    return '';
  }

  Future<void> _loadActividadesBestEffort({bool force = false}) async {
    if (!force && _actividades.isNotEmpty) return;

    final planAny = _planOf(_instDomain);
    final pc = _planConfigOf(planAny);

    final out = <InstitucionActividadRef>[];

    // Curricular: niveles truthy
    try {
      dynamic niveles;
      if (pc is Map) {
        niveles = _mapGet(pc.cast<dynamic, dynamic>(), const [
          'niveles',
          'nivelesCurriculares',
          'nivelesSeleccionados',
          'nivelesCurricularesSeleccionados',
        ]);
      } else {
        // ignore: avoid_dynamic_calls
        niveles = (pc as dynamic).niveles;
      }

      for (final n in _iterFromAny(niveles)) {
        if (!_itemHabilitado(n) && n is! String) continue;
        final key = _nivelNameOf(n);
        if (key.trim().isEmpty) continue;
        final propio = _nombrePropioOf(n).trim();
        final label = propio.isNotEmpty ? propio : key;
        out.add(
          InstitucionActividadRef(
            kind: InstitucionActividadKind.curricular,
            key: key,
            label: label,
          ),
        );
      }
    } catch (_) {}

    // Extracurricular: modulos truthy
    try {
      dynamic modulos;
      if (pc is Map) {
        modulos = _mapGet(pc.cast<dynamic, dynamic>(), const [
          'modulos',
          'modulosExtracurriculares',
          'modulosSeleccionados',
          'modulosExtracurricularesSeleccionados',
        ]);
      } else {
        // ignore: avoid_dynamic_calls
        modulos = (pc as dynamic).modulos;
      }

      for (final m in _iterFromAny(modulos)) {
        if (!_itemHabilitado(m) && m is! String) continue;
        final key = _moduloNameOf(m);
        if (key.trim().isEmpty) continue;
        final propio = _nombrePropioOf(m).trim();
        final label = propio.isNotEmpty ? propio : key;
        out.add(
          InstitucionActividadRef(
            kind: InstitucionActividadKind.extracurricular,
            key: key,
            label: label,
          ),
        );
      }
    } catch (_) {}

    _actividades = out;
  }
}

// =====================================================
// DTO local de UI
// =====================================================

class _ProfileWorkingInfo {
  final String profileId;
  final bool isActive;
  final bool isWorking;

  const _ProfileWorkingInfo({
    required this.profileId,
    required this.isActive,
    required this.isWorking,
  });
}

enum _RenameResult { cancel, save, restore }
