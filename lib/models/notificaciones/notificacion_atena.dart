// lib/models/notificaciones/notificacion_atena.dart
//
// ATENA – NOTIFICACIÓN (CANÓNICA)
// ownerAccountId (cuenta) → perfiles → perfilId
//
// Fuente de verdad de enums:
// - TipoNotificacionAtena
// - NotificacionScopeAtena
//
// HARDENING (enero 2026):
// - Parsing robusto (map/json/legacy).
// - Canoniza deeplink vía AtenaDeeplink.ensureCanonicoString().
// - Si scope=perfil pero falta perfilId → degrada a owner.
// - Normaliza ids (sin whitespace).
// - Evita “inventar owner”: si no existe, queda vacío (caller decide).
//
// ✅ EXTRA HARDENING (enero 2026):
// - fromMap(): soporta scope en keys legacy (scope/tipo como enum string o name).
// - fecha: acepta 'fechaIso'/'fecha'/'fechaMs'/'ts' y strings numéricas.
// - toMap(): no serializa perfilId vacío; normaliza deeplink a string (si viene).
// - copyWith(): permite limpiar deeplink/data de manera explícita.
// - Sanitiza ids con _normIdKey consistente con services.
// - Mantiene enums fuente de verdad y helpers públicos (tipoNotiFromString/scopeFromString)
//   consumidos por NotificacionesService (y otros).
//
// ✅ AJUSTE (feb 2026):
// - fechaMs/ts robusto: si el número parece segundos (< 1e12), lo convierte a ms.
// - toMap(): canoniza deeplink best-effort con owner/perfil si están disponibles.
//
// ✅ CIERRE CANÓNICO (feb 2026):
// - toMap(): no serializa keys con null/vacías (deeplink/data/payload/destinatarioDni/perfilId).
// - toMap(): si scope=perfil pero perfilId vacío, degrada a owner (consistente con fromMap()).
//
// ✅ FIX CANÓNICO (feb 2026):
// - scopeFromString(): NO infiere scope=perfil solo por existir perfilId.
//   Canon: una notificación puede tener perfilId (target) y seguir siendo scope=owner.
//   La UI/Service fuerza scope explícito al persistir/leer por inbox.
//   Esto evita que legacy sin 'scope' se “reclasifique” incorrectamente.
// ─────────────────────────────────────────────

import 'dart:convert';
import 'dart:math';

import '../../routes/atena_deeplink.dart';

/// =====================================================
/// ENUMS (FUENTE DE VERDAD)
/// =====================================================

enum TipoNotificacionAtena {
  confirmada,
  rechazada,
  info,
  documentos,
  calendario,
  sistema,

  // Extensiones típicas del prototipo
  perfilActualizado,
  solicitudCreada,
  solicitudCancelada,
  boletinActualizado,
  tituloEmitido,
  documentacionActualizada,
  documentoSolicitado,

  // Documentos temporales
  documentoSubido,
  documentoExpirado,
  documentoEliminado,

  // Dominio
  becaActualizada,
  sancionActualizada,
  equivalenciaActualizada,
}

extension TipoNotificacionAtenaX on TipoNotificacionAtena {
  String get label {
    switch (this) {
      case TipoNotificacionAtena.confirmada:
        return 'Confirmada';
      case TipoNotificacionAtena.rechazada:
        return 'Rechazada';
      case TipoNotificacionAtena.info:
        return 'Info';
      case TipoNotificacionAtena.documentos:
        return 'Documentos';
      case TipoNotificacionAtena.calendario:
        return 'Calendario';
      case TipoNotificacionAtena.sistema:
        return 'Sistema';

      case TipoNotificacionAtena.perfilActualizado:
        return 'Perfil actualizado';
      case TipoNotificacionAtena.solicitudCreada:
        return 'Solicitud creada';
      case TipoNotificacionAtena.solicitudCancelada:
        return 'Solicitud cancelada';
      case TipoNotificacionAtena.boletinActualizado:
        return 'Boletín actualizado';
      case TipoNotificacionAtena.tituloEmitido:
        return 'Título emitido';
      case TipoNotificacionAtena.documentacionActualizada:
        return 'Documentación actualizada';
      case TipoNotificacionAtena.documentoSolicitado:
        return 'Documento solicitado';

      case TipoNotificacionAtena.documentoSubido:
        return 'Documento subido';
      case TipoNotificacionAtena.documentoExpirado:
        return 'Documento expirado';
      case TipoNotificacionAtena.documentoEliminado:
        return 'Documento eliminado';

      case TipoNotificacionAtena.becaActualizada:
        return 'Beca actualizada';
      case TipoNotificacionAtena.sancionActualizada:
        return 'Sanción actualizada';
      case TipoNotificacionAtena.equivalenciaActualizada:
        return 'Equivalencia actualizada';
    }
  }
}

/// Canon: el service usa NotificacionScopeAtena.
///
/// Nota: "institucion" se mantiene por compat histórica, pero el flujo canónico
/// se resuelve siempre owner→perfil. Si llega scope=institucion en legacy,
/// se preserva sin forzar owner/perfil.
enum NotificacionScopeAtena { owner, perfil, institucion }

extension NotificacionScopeAtenaX on NotificacionScopeAtena {
  String get label {
    switch (this) {
      case NotificacionScopeAtena.owner:
        return 'Cuenta';
      case NotificacionScopeAtena.perfil:
        return 'Perfil';
      case NotificacionScopeAtena.institucion:
        return 'Institución';
    }
  }
}

/// =====================================================
/// COMPAT (READ-ONLY / legacy no canónico)
/// =====================================================

@Deprecated('Usar NotificacionScopeAtena. Migrar referencias y remover luego.')
enum ScopeNotificacionAtena { owner, perfil, institucion }

/// =====================================================
/// HELPERS
/// =====================================================

String _s(dynamic v) => (v ?? '').toString().trim();

String _normToken(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');

/// IDs: trim + elimina whitespace interno (key/lookup estable).
String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

bool _b(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is double) return v.toInt() != 0;

  final s = _s(v).toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí') {
    return true;
  }
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

Map<String, dynamic> _mapToStringKeyMap(Map m) {
  final out = <String, dynamic>{};
  m.forEach((k, v) {
    out[_s(k)] = v;
  });
  return out;
}

Map<String, dynamic>? _asMap(dynamic v) {
  if (v == null) return null;

  if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
  if (v is Map) return _mapToStringKeyMap(v);

  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    try {
      final d = jsonDecode(s);
      if (d is Map) return _mapToStringKeyMap(d);
    } catch (_) {}
  }
  return null;
}

TipoNotificacionAtena tipoNotiFromString(String v) {
  final raw = v.trim();
  if (raw.isEmpty) return TipoNotificacionAtena.info;

  final sLower = raw.toLowerCase();

  if (sLower.startsWith('tiponotificacionatena.')) {
    final tail = raw.split('.').last.trim().toLowerCase();
    for (final t in TipoNotificacionAtena.values) {
      if (t.name.toLowerCase() == tail) return t;
    }
  }

  final needle = _normToken(raw);
  for (final t in TipoNotificacionAtena.values) {
    if (_normToken(t.name) == needle) return t;
  }

  switch (needle) {
    case 'doc':
    case 'docs':
    case 'documento':
    case 'documentos':
      return TipoNotificacionAtena.documentos;

    case 'calendar':
    case 'calendario':
    case 'event':
    case 'agenda':
      return TipoNotificacionAtena.calendario;

    case 'documentosolicitado':
      return TipoNotificacionAtena.documentoSolicitado;
    case 'documentosubido':
      return TipoNotificacionAtena.documentoSubido;
    case 'documentoexpirado':
    case 'documentovencido':
      return TipoNotificacionAtena.documentoExpirado;
    case 'documentoeliminado':
    case 'doceliminado':
    case 'docborrado':
      return TipoNotificacionAtena.documentoEliminado;

    case 'documentacionactualizada':
      return TipoNotificacionAtena.documentacionActualizada;

    case 'system':
    case 'sistema':
      return TipoNotificacionAtena.sistema;

    default:
      return TipoNotificacionAtena.info;
  }
}

/// ✅ Hardening: tolera "owner", "NotificacionScopeAtena.owner",
/// "ScopeNotificacionAtena.owner", etc.
///
/// ✅ Canon: NO infiere perfil por existir perfilId.
NotificacionScopeAtena scopeFromString(String v, {String? perfilId}) {
  final raw = v.trim();
  if (raw.isEmpty) return NotificacionScopeAtena.owner;

  final sLower = raw.toLowerCase();

  if (sLower.startsWith('notificacionscopeatena.') ||
      sLower.startsWith('scopenotificacionatena.')) {
    final tail = raw.split('.').last.trim().toLowerCase();
    for (final t in NotificacionScopeAtena.values) {
      if (t.name.toLowerCase() == tail) return t;
    }
  }

  final needle = _normToken(raw);
  for (final t in NotificacionScopeAtena.values) {
    if (_normToken(t.name) == needle) return t;
  }

  // fallback canónico
  return NotificacionScopeAtena.owner;
}

String _fallbackIdFromMap(Map<String, dynamic> m) {
  final rnd = Random();
  final ts = DateTime.now().microsecondsSinceEpoch.toString();
  final hint = _s(m['titulo']).isNotEmpty ? _s(m['titulo']) : 'noti';
  final salt = rnd.nextInt(1 << 30).toString();
  return 'n_${ts}_${salt}_${hint.hashCode.abs()}';
}

int _epochMsFromNum(num n) {
  // 2026ms ~ 1.7e12. Si viene <1e12 es casi seguro segundos.
  final v = n.toInt();
  if (v > 0 && v < 1000000000000) return v * 1000;
  return v;
}

DateTime _parseFechaDynamic(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(_epochMsFromNum(v));
  if (v is double) {
    return DateTime.fromMillisecondsSinceEpoch(_epochMsFromNum(v));
  }
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return DateTime.now();
    final p = DateTime.tryParse(s);
    if (p != null) return p;

    final asInt = int.tryParse(s);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(_epochMsFromNum(asInt));
    }
    final asDouble = double.tryParse(s);
    if (asDouble != null) {
      return DateTime.fromMillisecondsSinceEpoch(_epochMsFromNum(asDouble));
    }
  }
  return DateTime.now();
}

DateTime _parseFechaFromMap(Map<String, dynamic> m) {
  final iso = _s(m['fechaIso']);
  final legacy = _s(m['fecha']);

  if (iso.isNotEmpty) return _parseFechaDynamic(iso);
  if (legacy.isNotEmpty) return _parseFechaDynamic(legacy);

  if (m.containsKey('fechaMs')) return _parseFechaDynamic(m['fechaMs']);
  if (m.containsKey('ts')) return _parseFechaDynamic(m['ts']);

  return DateTime.now();
}

String? _canonizeDeeplinkBestEffort({
  required String raw,
  String? ownerAccountId,
  String? perfilId,
}) {
  final dl = raw.trim();
  if (dl.isEmpty) return null;

  try {
    return AtenaDeeplink.ensureCanonicoString(
      dl,
      ownerAccountId: (ownerAccountId ?? '').trim().isEmpty
          ? null
          : _normIdKey(ownerAccountId!),
      perfilId: (perfilId ?? '').trim().isEmpty ? null : _normIdKey(perfilId!),
    );
  } catch (_) {
    return dl;
  }
}

/// =====================================================
/// MODELO
/// =====================================================

class NotificacionAtena {
  final String id;
  final String ownerAccountId;
  final String? perfilId;

  final String? _destinatarioDniLegacy;

  @Deprecated(
    'Legacy-only. No usar en flujo canónico (NO DNI como clave). Remover cuando se elimine compat.',
  )
  String? get destinatarioDni => _destinatarioDniLegacy;

  final NotificacionScopeAtena scope;
  final TipoNotificacionAtena tipo;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final bool leida;
  final String? deeplink;
  final Map<String, dynamic>? data;

  NotificacionAtena({
    required this.id,
    required this.ownerAccountId,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.tipo,
    required this.scope,
    required this.leida,
    this.perfilId,
    String? destinatarioDni,
    this.deeplink,
    this.data,
  }) : _destinatarioDniLegacy = destinatarioDni;

  NotificacionAtena copyWith({
    String? id,
    String? ownerAccountId,
    String? perfilId,
    String? destinatarioDni,
    NotificacionScopeAtena? scope,
    TipoNotificacionAtena? tipo,
    String? titulo,
    String? mensaje,
    DateTime? fecha,
    bool? leida,
    String? deeplink,
    Map<String, dynamic>? data,
    bool clearData = false,
    bool clearDeeplink = false,
  }) {
    return NotificacionAtena(
      id: id ?? this.id,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      perfilId: perfilId ?? this.perfilId,
      destinatarioDni: destinatarioDni ?? _destinatarioDniLegacy,
      scope: scope ?? this.scope,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      fecha: fecha ?? this.fecha,
      leida: leida ?? this.leida,
      deeplink: clearDeeplink ? null : (deeplink ?? this.deeplink),
      data: clearData ? null : (data ?? this.data),
    );
  }

  Map<String, dynamic> toMap() {
    final ownerNorm = _normIdKey(ownerAccountId);

    final pidTrim = (perfilId ?? '').trim();
    final pidNorm = pidTrim.isEmpty ? null : _normIdKey(pidTrim);

    // ✅ Canon: si scope=perfil pero falta perfilId, degradar a owner (consistente con fromMap()).
    final scopeSafe =
        (scope == NotificacionScopeAtena.perfil && (pidNorm ?? '').isEmpty)
        ? NotificacionScopeAtena.owner
        : scope;

    final dlTrim = (deeplink ?? '').trim();
    final dlCanon = dlTrim.isEmpty
        ? null
        : _canonizeDeeplinkBestEffort(
            raw: dlTrim,
            ownerAccountId: ownerNorm.isEmpty ? null : ownerNorm,
            perfilId: pidNorm,
          );

    final dniTrim = (_destinatarioDniLegacy ?? '').trim();
    final dataFinal = data == null ? null : Map<String, dynamic>.from(data!);

    final out = <String, dynamic>{
      'id': _normIdKey(id),
      'ownerAccountId': ownerNorm,
      'scope': scopeSafe.name,
      'tipo': tipo.name,
      'titulo': titulo,
      'mensaje': mensaje,
      'fechaIso': fecha.toIso8601String(),
      'leida': leida,
    };

    if (pidNorm != null && pidNorm.isNotEmpty) out['perfilId'] = pidNorm;
    if (dniTrim.isNotEmpty) out['destinatarioDni'] = dniTrim;

    if (dlCanon != null && dlCanon.trim().isNotEmpty) {
      out['deeplink'] = dlCanon;
    }

    if (dataFinal != null) {
      out['data'] = dataFinal;
      out['payload'] = dataFinal; // compat espejo
    }

    return out;
  }

  static NotificacionAtena fromMap(Map<String, dynamic> m) {
    // Owner (compat)
    var owner = _s(m['ownerAccountId']);
    if (owner.isEmpty) {
      final c1 = _s(m['cuentaId']);
      final c2 = _s(m['accountId']);
      final c3 = _s(m['ownerId']);
      owner = c1.isNotEmpty ? c1 : (c2.isNotEmpty ? c2 : c3);
    }
    owner = _normIdKey(owner);

    // Perfil
    var perfil = _normIdKey(_s(m['perfilId']));

    // ID
    final rawId = _s(m['id']);
    final id = _normIdKey(rawId.isNotEmpty ? rawId : _fallbackIdFromMap(m));

    // Tipo
    final tipoRaw = _s(m['tipo']).isNotEmpty ? _s(m['tipo']) : _s(m['type']);
    final tipo = tipoNotiFromString(tipoRaw);

    // Data/Payload
    final dataMap = _asMap(m['data']);
    final payloadMap = _asMap(m['payload']);
    final dataFinal = dataMap ?? payloadMap;

    // Deeplink
    String pickDl(Map<String, dynamic>? mm) {
      if (mm == null) return '';
      final d1 = _s(mm['deeplink']);
      if (d1.isNotEmpty) return d1;
      final d2 = _s(mm['link']);
      if (d2.isNotEmpty) return d2;
      final d3 = _s(mm['route']);
      if (d3.isNotEmpty) return d3;
      return '';
    }

    final dl0 = _s(m['deeplink']);
    final link0 = _s(m['link']);
    final route0 = _s(m['route']);

    var deeplinkRaw = dl0.isNotEmpty
        ? dl0
        : (link0.isNotEmpty ? link0 : (route0.isNotEmpty ? route0 : ''));

    if (deeplinkRaw.trim().isEmpty) {
      deeplinkRaw = pickDl(dataFinal);
      if (deeplinkRaw.trim().isEmpty) {
        deeplinkRaw = pickDl(payloadMap);
      }
    }

    // Extraer owner/perfil desde deeplink si faltan
    if (deeplinkRaw.trim().isNotEmpty) {
      try {
        final d = AtenaDeeplink.parse(deeplinkRaw);
        final o2 = _s(d.ownerAccountId).trim();
        final p2 = _s(d.perfilId).trim();
        if (owner.isEmpty && o2.isNotEmpty) owner = _normIdKey(o2);
        if (perfil.isEmpty && p2.isNotEmpty) perfil = _normIdKey(p2);
      } catch (_) {
        // preserve raw
      }
    }

    String? deeplinkCanon;
    final dlTrim = deeplinkRaw.trim();
    if (dlTrim.isNotEmpty) {
      deeplinkCanon = _canonizeDeeplinkBestEffort(
        raw: dlTrim,
        ownerAccountId: owner.isEmpty ? null : owner,
        perfilId: perfil.isEmpty ? null : perfil,
      );
    }

    final tituloRaw = _s(m['titulo']);
    final titulo = tituloRaw.isEmpty ? 'Notificación' : tituloRaw;
    final mensaje = _s(m['mensaje']);

    // Scope (hardening + fallback legacy keys)
    final scopeRaw = _s(m['scope']).isNotEmpty
        ? _s(m['scope'])
        : (_s(m['notiScope']).isNotEmpty
              ? _s(m['notiScope'])
              : _s(m['scoped']));

    final scope = scopeFromString(
      scopeRaw,
      perfilId: perfil.isEmpty ? null : perfil,
    );

    // ✅ Canon: si scope=perfil pero falta perfilId → degrada a owner
    final scopeSafe = (scope == NotificacionScopeAtena.perfil && perfil.isEmpty)
        ? NotificacionScopeAtena.owner
        : scope;

    final perfilFinal = perfil.isEmpty ? null : perfil;

    final dniRaw = _s(m['destinatarioDni']);

    return NotificacionAtena(
      id: id.isEmpty ? _fallbackIdFromMap(m) : id,
      ownerAccountId: owner, // no inventamos owner
      perfilId: perfilFinal,
      destinatarioDni: dniRaw.isEmpty ? null : dniRaw,
      scope: scopeSafe,
      tipo: tipo,
      titulo: titulo,
      mensaje: mensaje,
      fecha: _parseFechaFromMap(m),
      leida: _b(m['leida'], fallback: false),
      deeplink: deeplinkCanon,
      data: dataFinal == null ? null : Map<String, dynamic>.from(dataFinal),
    );
  }

  String toJson() => jsonEncode(toMap());

  static NotificacionAtena fromJson(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is Map) return fromMap(Map<String, dynamic>.from(m));
    } catch (_) {}

    return NotificacionAtena(
      id: _fallbackIdFromMap(<String, dynamic>{}),
      ownerAccountId: '',
      titulo: 'Notificación',
      mensaje: '',
      fecha: DateTime.now(),
      tipo: TipoNotificacionAtena.info,
      scope: NotificacionScopeAtena.owner,
      leida: false,
    );
  }
}
