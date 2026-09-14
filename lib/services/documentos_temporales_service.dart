// lib/services/documentos_temporales_service.dart
//
// ATENA – DOCUMENTOS TEMPORALES SERVICE (PROTOTIPO LOCAL)
//
// Objetivo:
// - Solicitud de documentación (institución → alumno) con notificación (CANÓNICA).
// - Subida de documento temporal (alumno → institución) con TTL y limpieza.
// - Listado por perfilId (fuente de verdad de vinculación en UI).
//
// ✅ Canónico:
// - ownerAccountId + perfilId (del alumno).
// - Notificaciones: INBOX OWNER como fuente de verdad + duplicado opcional en perfil.
// - Deeplink: /documentos?ownerAccountId=...&perfilId=... (&documentoId=... / &solicitudId=... opcional)
//
// Nota:
// - Persistencia local durable mediante StorageService/SharedPreferences.
//
// ✅ HARDENING:
// - Sin dependencia directa de CuentaService: registry persistente institucionPerfilId -> ownerAccountId.
// - DEDUP notificaciones: idOverride opcional.
// - Deeplink emitido incluye SIEMPRE ownerAccountId + perfilId.
// - Payload normaliza claves: mantiene 'tipoDocumento' y agrega 'documentoTipo' (compat).
// - TTL cleanup agrega 'eliminado': true en meta de expiración.
// - listarDocumentosInstitucion NO devuelve estado=eliminado (evita fantasmas).
//
// ✅ CIERRE E2E (enero 2026):
// - Cambios de estado de Solicitud (cumplida/cancelada) emiten notificaciones canónicas
//   (alumno + institución best-effort) para visibilidad en campo.
//
// ✅ HARDENING adicional (este archivo):
// - Notificaciones: usa try/catch, no rompe flujo si faltan tipos.
// - Consistencia IDs: normalización única (trim + colapso whitespace).
// - cancelar/marcar por institución: asegura que “foundPerfil” sea el PERFIL ID CANÓNICO del alumno.
// - listarDocumentosPerfil: persiste el estado expirado en storage sin “ensuciar” eliminados.
// - eliminarDocumento: mantiene payload 'eliminado': true.
//
// IMPORTANTE:
// - Este servicio asume que institucionId == institucionPerfilId (canónico).
//

import '../models/notificaciones/notificacion_atena.dart';
import 'notificaciones_service.dart';
import 'storage_service.dart';

// =====================================================
// TIPOS (CANÓNICOS)
// =====================================================

enum TipoDocumento {
  dni,
  partidaNacimiento,
  constanciaCuil,
  certificadoDomicilio,
  libretaSanitaria,
  boletin,
  otro,
}

extension TipoDocumentoX on TipoDocumento {
  String get label {
    switch (this) {
      case TipoDocumento.dni:
        return 'DNI (frente y dorso)';
      case TipoDocumento.partidaNacimiento:
        return 'Partida de nacimiento';
      case TipoDocumento.constanciaCuil:
        return 'Constancia de CUIL';
      case TipoDocumento.certificadoDomicilio:
        return 'Certificado de domicilio';
      case TipoDocumento.libretaSanitaria:
        return 'Libreta sanitaria';
      case TipoDocumento.boletin:
        return 'Boletín / certificado';
      case TipoDocumento.otro:
        return 'Otro';
    }
  }
}

enum EstadoSolicitudDocumento { pendiente, cumplida, cancelada }

enum EstadoDocumentoTemporal { activo, expirado, eliminado }

class SolicitudDocumento {
  final String id;
  final String institucionId;

  final String ownerAccountId;
  final String perfilId;

  final TipoDocumento tipo;
  final String? mensaje;

  final DateTime createdAt;

  final EstadoSolicitudDocumento estado;

  const SolicitudDocumento({
    required this.id,
    required this.institucionId,
    required this.ownerAccountId,
    required this.perfilId,
    required this.tipo,
    required this.createdAt,
    required this.estado,
    this.mensaje,
  });

  SolicitudDocumento copyWith({
    EstadoSolicitudDocumento? estado,
    String? mensaje,
  }) {
    return SolicitudDocumento(
      id: id,
      institucionId: institucionId,
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      tipo: tipo,
      mensaje: mensaje ?? this.mensaje,
      createdAt: createdAt,
      estado: estado ?? this.estado,
    );
  }
}

class DocumentoTemporal {
  final String id;

  /// ✅ Canónico: perfilId de institución (institución solicitante)
  final String institucionSolicitanteId;

  /// ✅ Canónico alumno
  final String ownerAccountId;
  final String perfilId;

  final TipoDocumento tipo;

  /// Referencia (prototipo): path local, url, etc.
  final String ref;

  /// Asociación opcional a una solicitud concreta
  final String? solicitudId;

  final DateTime uploadedAt;
  final DateTime expiresAt;

  final EstadoDocumentoTemporal estado;

  const DocumentoTemporal({
    required this.id,
    required this.institucionSolicitanteId,
    required this.ownerAccountId,
    required this.perfilId,
    required this.tipo,
    required this.ref,
    required this.uploadedAt,
    required this.expiresAt,
    required this.estado,
    this.solicitudId,
  });

  bool get expirado => DateTime.now().isAfter(expiresAt);

  DocumentoTemporal copyWith({
    DateTime? expiresAt,
    EstadoDocumentoTemporal? estado,
    String? ref,
  }) {
    return DocumentoTemporal(
      id: id,
      institucionSolicitanteId: institucionSolicitanteId,
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      tipo: tipo,
      ref: ref ?? this.ref,
      solicitudId: solicitudId,
      uploadedAt: uploadedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      estado: estado ?? this.estado,
    );
  }
}

// =====================================================
// ✅ COMPAT: ALIASES (builds viejos)
// =====================================================

typedef TipoDocumentoAtena = TipoDocumento;

typedef SolicitudDocumentoAtena = SolicitudDocumento;
typedef DocumentoTemporalAtena = DocumentoTemporal;

typedef EstadoSolicitudDocumentoAtena = EstadoSolicitudDocumento;
typedef EstadoDocumentoTemporalAtena = EstadoDocumentoTemporal;

// =====================================================
// SERVICE
// =====================================================

class DocumentosTemporalesService {
  // =====================================================
  // STORAGE LOCAL DURABLE
  // =====================================================

  static final StorageService _storage = StorageService.instance;

  static const String _kPerfiles = 'docs_temporales_v1_perfiles';
  static const String _kSolicitudesPrefix = 'docs_temporales_v1_solicitudes_';
  static const String _kDocumentosPrefix = 'docs_temporales_v1_documentos_';
  static const String _kOwnerInstitucionPrefix =
      'docs_temporales_v1_owner_institucion_';

  static const int _minTtlDays = 1;
  static const int _maxTtlDays = 30;

  static String _n(String v) => v.trim();
  static String _ns(String? v) => (v ?? '').trim();

  /// IDs/keys canónicas: trim + colapsa whitespace interno (lo elimina).
  static String _normIdKey(String v) => _n(v).replaceAll(RegExp(r'\s+'), '');

  static int _seq = 0;

  static String _newId(String prefix) {
    // microsecondsSinceEpoch + seq evita colisiones en el mismo tick.
    _seq = (_seq + 1) % 1000000;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_seq.toString().padLeft(6, '0')}';
  }

  // =====================================================
  // ✅ REGISTRO BEST-EFFORT (Institución perfil -> owner)
  // =====================================================

  static Future<void> registrarOwnerDeInstitucion({
    required String institucionPerfilId,
    required String ownerAccountId,
  }) async {
    final pid = _normIdKey(institucionPerfilId);
    final oid = _normIdKey(ownerAccountId);
    if (pid.isEmpty || oid.isEmpty) return;
    final ok = await _storage.setString('$_kOwnerInstitucionPrefix$pid', oid);
    if (!ok) {
      throw StateError('No se pudo persistir el propietario institucional.');
    }
  }

  static Future<String?> _resolveOwnerForInstitucionPerfil(
    String institucionPerfilId,
  ) async {
    final pid = _normIdKey(institucionPerfilId);
    if (pid.isEmpty) return null;
    final v = await _storage.getString('$_kOwnerInstitucionPrefix$pid');
    final vv = _normIdKey(v ?? '');
    return vv.isEmpty ? null : vv;
  }

  static String _kSolicitudes(String perfilId) =>
      '$_kSolicitudesPrefix${_normIdKey(perfilId)}';

  static String _kDocumentos(String perfilId) =>
      '$_kDocumentosPrefix${_normIdKey(perfilId)}';

  static Future<List<String>> _listarPerfilesRegistrados() async {
    final raw = await _storage.getStringList(_kPerfiles);
    final seen = <String>{};
    return raw
        .map(_normIdKey)
        .where((id) => id.isNotEmpty && seen.add(id))
        .toList(growable: false);
  }

  static Future<void> _registrarPerfil(String perfilId) async {
    final perfil = _normIdKey(perfilId);
    if (perfil.isEmpty) return;
    final perfiles = await _listarPerfilesRegistrados();
    if (perfiles.contains(perfil)) return;
    final ok = await _storage.setStringList(_kPerfiles, [...perfiles, perfil]);
    if (!ok) {
      throw StateError('No se pudo persistir el índice documental.');
    }
  }

  static Map<String, dynamic> _solicitudToMap(SolicitudDocumento s) =>
      <String, dynamic>{
        'id': s.id,
        'institucionId': s.institucionId,
        'ownerAccountId': s.ownerAccountId,
        'perfilId': s.perfilId,
        'tipo': s.tipo.name,
        if ((s.mensaje ?? '').trim().isNotEmpty) 'mensaje': s.mensaje,
        'createdAt': s.createdAt.toIso8601String(),
        'estado': s.estado.name,
      };

  static SolicitudDocumento? _solicitudFromMap(Map<String, dynamic> map) {
    final id = _normIdKey(map['id']?.toString() ?? '');
    final institucionId = _normIdKey(map['institucionId']?.toString() ?? '');
    final owner = _normIdKey(map['ownerAccountId']?.toString() ?? '');
    final perfil = _normIdKey(map['perfilId']?.toString() ?? '');
    final createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '');
    final tipoName = map['tipo']?.toString() ?? '';
    final estadoName = map['estado']?.toString() ?? '';
    if (id.isEmpty ||
        institucionId.isEmpty ||
        owner.isEmpty ||
        perfil.isEmpty ||
        createdAt == null) {
      return null;
    }
    TipoDocumento? tipo;
    EstadoSolicitudDocumento? estado;
    for (final value in TipoDocumento.values) {
      if (value.name == tipoName) tipo = value;
    }
    for (final value in EstadoSolicitudDocumento.values) {
      if (value.name == estadoName) estado = value;
    }
    if (tipo == null || estado == null) return null;
    final mensaje = (map['mensaje']?.toString() ?? '').trim();
    return SolicitudDocumento(
      id: id,
      institucionId: institucionId,
      ownerAccountId: owner,
      perfilId: perfil,
      tipo: tipo,
      mensaje: mensaje.isEmpty ? null : mensaje,
      createdAt: createdAt,
      estado: estado,
    );
  }

  static Map<String, dynamic> _documentoToMap(
    DocumentoTemporal d,
  ) => <String, dynamic>{
    'id': d.id,
    'institucionSolicitanteId': d.institucionSolicitanteId,
    'ownerAccountId': d.ownerAccountId,
    'perfilId': d.perfilId,
    'tipo': d.tipo.name,
    'ref': d.ref,
    if ((d.solicitudId ?? '').trim().isNotEmpty) 'solicitudId': d.solicitudId,
    'uploadedAt': d.uploadedAt.toIso8601String(),
    'expiresAt': d.expiresAt.toIso8601String(),
    'estado': d.estado.name,
  };

  static DocumentoTemporal? _documentoFromMap(Map<String, dynamic> map) {
    final id = _normIdKey(map['id']?.toString() ?? '');
    final institucionId = _normIdKey(
      map['institucionSolicitanteId']?.toString() ?? '',
    );
    final owner = _normIdKey(map['ownerAccountId']?.toString() ?? '');
    final perfil = _normIdKey(map['perfilId']?.toString() ?? '');
    final ref = _n(map['ref']?.toString() ?? '');
    final uploadedAt = DateTime.tryParse(map['uploadedAt']?.toString() ?? '');
    final expiresAt = DateTime.tryParse(map['expiresAt']?.toString() ?? '');
    final tipoName = map['tipo']?.toString() ?? '';
    final estadoName = map['estado']?.toString() ?? '';
    if (id.isEmpty ||
        institucionId.isEmpty ||
        owner.isEmpty ||
        perfil.isEmpty ||
        ref.isEmpty ||
        uploadedAt == null ||
        expiresAt == null) {
      return null;
    }
    TipoDocumento? tipo;
    EstadoDocumentoTemporal? estado;
    for (final value in TipoDocumento.values) {
      if (value.name == tipoName) tipo = value;
    }
    for (final value in EstadoDocumentoTemporal.values) {
      if (value.name == estadoName) estado = value;
    }
    if (tipo == null || estado == null) return null;
    final solicitudId = _normIdKey(map['solicitudId']?.toString() ?? '');
    return DocumentoTemporal(
      id: id,
      institucionSolicitanteId: institucionId,
      ownerAccountId: owner,
      perfilId: perfil,
      tipo: tipo,
      ref: ref,
      solicitudId: solicitudId.isEmpty ? null : solicitudId,
      uploadedAt: uploadedAt,
      expiresAt: expiresAt,
      estado: estado,
    );
  }

  static Future<List<SolicitudDocumento>> _leerSolicitudes(
    String perfilId,
  ) async {
    final raw = await _storage.getJsonList(_kSolicitudes(perfilId));
    return raw
        .map(_solicitudFromMap)
        .whereType<SolicitudDocumento>()
        .toList(growable: false);
  }

  static Future<void> _guardarSolicitudes(
    String perfilId,
    List<SolicitudDocumento> solicitudes,
  ) async {
    await _registrarPerfil(perfilId);
    final ok = await _storage.setJsonList(
      _kSolicitudes(perfilId),
      solicitudes.map(_solicitudToMap).toList(growable: false),
    );
    if (!ok) throw StateError('No se pudieron persistir las solicitudes.');
  }

  static Future<List<DocumentoTemporal>> _leerDocumentos(
    String perfilId,
  ) async {
    final raw = await _storage.getJsonList(_kDocumentos(perfilId));
    return raw
        .map(_documentoFromMap)
        .whereType<DocumentoTemporal>()
        .toList(growable: false);
  }

  static Future<void> _guardarDocumentos(
    String perfilId,
    List<DocumentoTemporal> documentos,
  ) async {
    await _registrarPerfil(perfilId);
    final ok = await _storage.setJsonList(
      _kDocumentos(perfilId),
      documentos.map(_documentoToMap).toList(growable: false),
    );
    if (!ok) throw StateError('No se pudieron persistir los documentos.');
  }

  // =====================================================
  // NOTIFICACIONES (CANÓNICO) – HARDENING
  // =====================================================

  static TipoNotificacionAtena? _fallbackTipoNotiOrNull() {
    if (TipoNotificacionAtena.values.isEmpty) return null;

    for (final preferred in const <String>[
      'documentacionActualizada',
      'documentos',
    ]) {
      try {
        return TipoNotificacionAtena.values.firstWhere(
          (e) => e.name == preferred,
        );
      } catch (_) {
        // NO-OP
      }
    }

    return TipoNotificacionAtena.values.first;
  }

  static TipoNotificacionAtena? _tipoNotiByNameOrNull(
    String name, {
    TipoNotificacionAtena? fallback,
  }) {
    final nn = _n(name);
    if (nn.isEmpty) return fallback ?? _fallbackTipoNotiOrNull();

    try {
      return TipoNotificacionAtena.values.firstWhere((e) => e.name == nn);
    } catch (_) {
      return fallback ?? _fallbackTipoNotiOrNull();
    }
  }

  static Future<void> _emitNotificacion({
    required String ownerAccountId,
    required String perfilId,
    required String tipoName,
    required String titulo,
    required String mensaje,
    required Map<String, dynamic> data,
    required bool duplicarEnPerfil,
    String target = 'alumno',
    String? documentoId,
    String? solicitudId,
    String? deeplinkOverride,

    /// ✅ DEDUP: id estable opcional (reintentos / repeat calls)
    String? idOverride,
  }) async {
    final o = _normIdKey(ownerAccountId);
    final pid = _normIdKey(perfilId);
    if (o.isEmpty || pid.isEmpty) return;

    // 1) Deeplink (CANÓNICO): SIEMPRE incluye ownerAccountId + perfilId.
    String deeplink;
    final dlOverride = _ns(deeplinkOverride);
    if (dlOverride.isNotEmpty) {
      deeplink = dlOverride;
    } else {
      final qp = <String, String>{'ownerAccountId': o, 'perfilId': pid};
      final did = _normIdKey(documentoId ?? '');
      final sid = _normIdKey(solicitudId ?? '');

      // Mutua exclusión: en /documentos usamos solicitudId o documentoId, nunca ambos.
      if (sid.isNotEmpty) {
        qp['solicitudId'] = sid;
      } else if (did.isNotEmpty) {
        qp['documentoId'] = did;
      }

      deeplink = Uri(path: '/documentos', queryParameters: qp).toString();
    }

    // 2) Tipo (fallback seguro)
    final fallback = _tipoNotiByNameOrNull(
      'documentos',
      fallback: _fallbackTipoNotiOrNull(),
    );
    final tipoResolved = _tipoNotiByNameOrNull(tipoName, fallback: fallback);
    if (tipoResolved == null) return;

    // 3) Payload (canónico + compat) — copiar para evitar mutación externa.
    final payload = <String, dynamic>{
      'target': target,
      ...Map<String, dynamic>.from(data),
    };

    final override = _normIdKey(idOverride ?? '');
    final stableId = override.isNotEmpty ? override : _newId('DOC_NOTI');

    // 4) Notificación (scope=owner forzado)
    final raw = <String, dynamic>{
      'id': stableId,
      'ownerAccountId': o,
      'perfilId': pid,

      // ✅ Fuente de verdad: INBOX OWNER
      'scope': 'owner',

      'tipo': tipoResolved.name,
      'titulo': titulo,
      'mensaje': mensaje,
      'deeplink': deeplink,
      'fechaIso': DateTime.now().toIso8601String(),
      'leida': false,

      // ✅ Mantener ambas keys para compat (algunos builds leen payload, otros data).
      'data': payload,
      'payload': payload,
    };

    NotificacionAtena notiObj;
    try {
      notiObj = NotificacionAtena.fromMap(raw);
    } catch (_) {
      return;
    }

    try {
      await NotificacionesService.instance.pushToOwner(
        ownerAccountId: o,
        notificacion: notiObj,
        duplicarEnPerfil: duplicarEnPerfil,
      );
    } catch (_) {
      // NO-OP
    }
  }

  static Future<void> _emitNotificacionInstitucion({
    required String institucionPerfilId,
    required String tipoName,
    required String titulo,
    required String mensaje,
    required Map<String, dynamic> data,
    bool duplicarEnPerfil = true,
    String? documentoId,
    String? solicitudId,
    String? deeplinkOverride,
    String? idOverride,
  }) async {
    final instPid = _normIdKey(institucionPerfilId);
    if (instPid.isEmpty) return;

    final owner = await _resolveOwnerForInstitucionPerfil(instPid);
    final o = _normIdKey(owner ?? '');
    if (o.isEmpty) return;

    final d = <String, dynamic>{
      ...Map<String, dynamic>.from(data),
      'institucionId': instPid,
    };

    await _emitNotificacion(
      ownerAccountId: o,
      perfilId: instPid,
      tipoName: tipoName,
      titulo: titulo,
      mensaje: mensaje,
      data: d,
      duplicarEnPerfil: duplicarEnPerfil,
      target: 'institucion',
      documentoId: documentoId,
      solicitudId: solicitudId,
      deeplinkOverride: deeplinkOverride,
      idOverride: idOverride,
    );
  }

  // =====================================================
  // Helper – cambio de estado solicitud + notificación E2E
  // =====================================================

  static Future<void> _setSolicitudEstado({
    required String perfilId,
    required String solicitudId,
    required EstadoSolicitudDocumento nuevoEstado,
    String? motivo,
    bool notificar = true,
    bool duplicarEnPerfilAlumno = true,
  }) async {
    final perfil = _normIdKey(perfilId);
    final sid = _normIdKey(solicitudId);
    if (perfil.isEmpty) throw Exception('perfilId vacío.');
    if (sid.isEmpty) throw Exception('solicitudId vacío.');

    final list = await _leerSolicitudes(perfil);
    if (list.isEmpty) return;

    final idx = list.indexWhere((e) => _normIdKey(e.id) == sid);
    if (idx < 0) return;

    final cur = list[idx];
    if (cur.estado == nuevoEstado) return;

    final next = List<SolicitudDocumento>.from(list);
    final updated = cur.copyWith(estado: nuevoEstado);
    next[idx] = updated;
    await _guardarSolicitudes(perfil, next);

    if (!notificar) return;

    final estadoName = nuevoEstado.name;
    final base = <String, dynamic>{
      'subtipo': 'solicitudEstado',
      'solicitudId': updated.id,
      'institucionId': updated.institucionId,
      'tipoDocumento': updated.tipo.name,
      'documentoTipo': updated.tipo.name,
      'estadoSolicitud': estadoName,
      'motivo': _ns(motivo),
      'alumnoOwnerAccountId': updated.ownerAccountId,
      'alumnoPerfilId': updated.perfilId,
      'changedAtIso': DateTime.now().toIso8601String(),
    };

    final notiIdAlumno = 'DOC_EVT_SOL_STATE_ALU_${updated.id}_$estadoName';
    final notiIdInst = 'DOC_EVT_SOL_STATE_INS_${updated.id}_$estadoName';

    // 🔔 ALUMNO
    await _emitNotificacion(
      ownerAccountId: updated.ownerAccountId,
      perfilId: updated.perfilId,
      tipoName: 'solicitudEstado',
      titulo: 'Solicitud actualizada',
      mensaje: 'Estado de solicitud: ${estadoName.toUpperCase()}',
      data: base,
      duplicarEnPerfil: duplicarEnPerfilAlumno,
      solicitudId: updated.id,
      target: 'alumno',
      idOverride: notiIdAlumno,
    );

    // 🔔 INSTITUCIÓN (best-effort)
    await _emitNotificacionInstitucion(
      institucionPerfilId: updated.institucionId,
      tipoName: 'solicitudEstado',
      titulo: 'Solicitud actualizada',
      mensaje: 'Estado de solicitud: ${estadoName.toUpperCase()}',
      data: <String, dynamic>{...base},
      duplicarEnPerfil: true,
      solicitudId: updated.id,
      idOverride: notiIdInst,
    );
  }

  // =====================================================
  // API – Solicitudes
  // =====================================================

  static Future<void> solicitar({
    required String institucionId,
    required String ownerAccountId,
    required String perfilId,
    required TipoDocumento tipo,
    String? mensaje,
    bool duplicarEnPerfil = true,
  }) async {
    final inst = _normIdKey(institucionId);
    final owner = _normIdKey(ownerAccountId);
    final perfil = _normIdKey(perfilId);

    if (inst.isEmpty) throw Exception('institucionId vacío.');
    if (owner.isEmpty) throw Exception('ownerAccountId vacío.');
    if (perfil.isEmpty) throw Exception('perfilId vacío.');

    final msg = _ns(mensaje);
    final s = SolicitudDocumento(
      id: _newId('SOL_DOC'),
      institucionId: inst,
      ownerAccountId: owner,
      perfilId: perfil,
      tipo: tipo,
      mensaje: msg.isEmpty ? null : msg,
      createdAt: DateTime.now(),
      estado: EstadoSolicitudDocumento.pendiente,
    );

    final list = await _leerSolicitudes(perfil);
    await _guardarSolicitudes(perfil, [s, ...list]);

    // IDs estables por evento (evita duplicados por reintentos)
    final notiIdAlumno = 'DOC_EVT_SOL_ALU_${s.id}';
    final notiIdInst = 'DOC_EVT_SOL_INS_${s.id}';

    // Payload común (compat + canónico)
    final payloadBase = <String, dynamic>{
      'subtipo': 'documentoSolicitado',
      'institucionId': inst,
      'tipoDocumento': tipo.name,
      'documentoTipo': tipo.name,
      'solicitudId': s.id,
      'estadoSolicitud': s.estado.name,
    };

    // 1) 🔔 ALUMNO
    await _emitNotificacion(
      ownerAccountId: owner,
      perfilId: perfil,
      tipoName: 'documentoSolicitado',
      titulo: 'Documentación solicitada',
      mensaje: 'La institución solicitó: ${tipo.label}',
      data: payloadBase,
      duplicarEnPerfil: duplicarEnPerfil,
      solicitudId: s.id,
      target: 'alumno',
      idOverride: notiIdAlumno,
    );

    // 2) 🔔 INSTITUCIÓN (best-effort)
    await _emitNotificacionInstitucion(
      institucionPerfilId: inst,
      tipoName: 'documentoSolicitado',
      titulo: 'Solicitud enviada',
      mensaje: 'Se solicitó al alumno: ${tipo.label}',
      data: <String, dynamic>{
        ...payloadBase,
        'alumnoOwnerAccountId': owner,
        'alumnoPerfilId': perfil,
      },
      duplicarEnPerfil: true,
      solicitudId: s.id,
      idOverride: notiIdInst,
    );
  }

  static Future<void> marcarSolicitudCumplida({
    required String perfilId,
    required String solicitudId,
    bool notificar = true,
    bool duplicarEnPerfil = true,
  }) async {
    await _setSolicitudEstado(
      perfilId: perfilId,
      solicitudId: solicitudId,
      nuevoEstado: EstadoSolicitudDocumento.cumplida,
      notificar: notificar,
      duplicarEnPerfilAlumno: duplicarEnPerfil,
    );
  }

  static Future<void> cancelarSolicitud({
    required String perfilId,
    required String solicitudId,
    String? motivo,
    bool notificar = true,
    bool duplicarEnPerfil = true,
  }) async {
    await _setSolicitudEstado(
      perfilId: perfilId,
      solicitudId: solicitudId,
      nuevoEstado: EstadoSolicitudDocumento.cancelada,
      motivo: motivo,
      notificar: notificar,
      duplicarEnPerfilAlumno: duplicarEnPerfil,
    );
  }

  static Future<void> cancelarSolicitudPorInstitucion({
    required String institucionId,
    required String solicitudId,
    String? motivo,
    bool notificar = true,
  }) async {
    final inst = _normIdKey(institucionId);
    final sid = _normIdKey(solicitudId);
    if (inst.isEmpty) throw Exception('institucionId vacío.');
    if (sid.isEmpty) throw Exception('solicitudId vacío.');

    String? foundPerfil;
    for (final perfil in await _listarPerfilesRegistrados()) {
      for (final s in await _leerSolicitudes(perfil)) {
        if (_normIdKey(s.id) == sid && _normIdKey(s.institucionId) == inst) {
          foundPerfil = perfil;
          break;
        }
      }
      if (foundPerfil != null) break;
    }
    if (foundPerfil == null) return;

    await cancelarSolicitud(
      perfilId: foundPerfil,
      solicitudId: sid,
      motivo: motivo,
      notificar: notificar,
      duplicarEnPerfil: true,
    );
  }

  static Future<void> marcarSolicitudCumplidaPorInstitucion({
    required String institucionId,
    required String solicitudId,
    bool notificar = true,
  }) async {
    final inst = _normIdKey(institucionId);
    final sid = _normIdKey(solicitudId);
    if (inst.isEmpty) throw Exception('institucionId vacío.');
    if (sid.isEmpty) throw Exception('solicitudId vacío.');

    String? foundPerfil;
    for (final perfil in await _listarPerfilesRegistrados()) {
      for (final s in await _leerSolicitudes(perfil)) {
        if (_normIdKey(s.id) == sid && _normIdKey(s.institucionId) == inst) {
          foundPerfil = perfil;
          break;
        }
      }
      if (foundPerfil != null) break;
    }
    if (foundPerfil == null) return;

    await marcarSolicitudCumplida(
      perfilId: foundPerfil,
      solicitudId: sid,
      notificar: notificar,
      duplicarEnPerfil: true,
    );
  }

  static Future<List<SolicitudDocumento>> listarSolicitudesPerfil({
    required String perfilId,
  }) async {
    final perfil = _normIdKey(perfilId);
    if (perfil.isEmpty) return const <SolicitudDocumento>[];
    final list = await _leerSolicitudes(perfil);
    final out = List<SolicitudDocumento>.from(list);
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  static Future<List<SolicitudDocumento>> listarSolicitudesInstitucion({
    required String institucionId,
  }) async {
    final inst = _normIdKey(institucionId);
    if (inst.isEmpty) return const <SolicitudDocumento>[];

    final out = <SolicitudDocumento>[];
    for (final perfil in await _listarPerfilesRegistrados()) {
      for (final s in await _leerSolicitudes(perfil)) {
        if (_normIdKey(s.institucionId) == inst) out.add(s);
      }
    }

    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  static Future<List<SolicitudDocumento>> listarSolicitudesPerfilPos(
    String perfilId,
  ) => listarSolicitudesPerfil(perfilId: perfilId);

  // =====================================================
  // API – Documentos temporales
  // =====================================================

  static Future<void> subirDocumentoTemporal({
    required String institucionSolicitanteId,
    required String ownerAccountId,
    required String perfilId,
    required TipoDocumento tipo,
    required String ref,
    int ttlDays = 5,
    bool notificar = true,
    bool duplicarEnPerfil = true,
    String? solicitudId,
  }) async {
    final inst = _normIdKey(institucionSolicitanteId);
    final owner = _normIdKey(ownerAccountId);
    final perfil = _normIdKey(perfilId);
    final r = _n(ref);

    if (inst.isEmpty) throw Exception('institucionSolicitanteId vacío.');
    if (owner.isEmpty) throw Exception('ownerAccountId vacío.');
    if (perfil.isEmpty) throw Exception('perfilId vacío.');
    if (r.isEmpty) throw Exception('ref vacío.');

    final days = ttlDays < _minTtlDays
        ? _minTtlDays
        : (ttlDays > _maxTtlDays ? _maxTtlDays : ttlDays);

    final now = DateTime.now();
    final exp = now.add(Duration(days: days));

    final sidRaw = _n(solicitudId ?? '');
    final sid = sidRaw.isEmpty ? null : _normIdKey(sidRaw);

    final d = DocumentoTemporal(
      id: _newId('DOC_TMP'),
      institucionSolicitanteId: inst,
      ownerAccountId: owner,
      perfilId: perfil,
      tipo: tipo,
      ref: r,
      solicitudId: sid,
      uploadedAt: now,
      expiresAt: exp,
      estado: EstadoDocumentoTemporal.activo,
    );

    final list = await _leerDocumentos(perfil);
    await _guardarDocumentos(perfil, [d, ...list]);

    if (sid != null) {
      try {
        await marcarSolicitudCumplida(
          perfilId: perfil,
          solicitudId: sid,
          notificar: true,
          duplicarEnPerfil: duplicarEnPerfil,
        );
      } catch (_) {
        // NO-OP
      }
    }

    if (!notificar) return;

    final notiIdAlumno = 'DOC_EVT_UP_ALU_${d.id}';
    final notiIdInst = 'DOC_EVT_UP_INS_${d.id}';

    final meta = <String, dynamic>{
      'subtipo': 'documentoSubido',
      'institucionId': inst,
      'tipoDocumento': tipo.name,
      'documentoTipo': tipo.name,
      'documentoId': d.id,
      'alumnoOwnerAccountId': owner,
      'alumnoPerfilId': perfil,
      if (d.solicitudId != null) 'solicitudId': d.solicitudId!,
      'expiresAtIso': d.expiresAt.toIso8601String(),
      'estadoDocumento': d.estado.name,
    };

    // 1) 🔔 ALUMNO
    await _emitNotificacion(
      ownerAccountId: owner,
      perfilId: perfil,
      tipoName: 'documentoSubido',
      titulo: 'Documento cargado',
      mensaje: 'Se cargó: ${tipo.label} (expira en $days días)',
      data: meta,
      duplicarEnPerfil: duplicarEnPerfil,
      documentoId: d.id,
      solicitudId: d.solicitudId,
      target: 'alumno',
      idOverride: notiIdAlumno,
    );

    // 2) 🔔 INSTITUCIÓN (best-effort)
    await _emitNotificacionInstitucion(
      institucionPerfilId: inst,
      tipoName: 'documentoSubido',
      titulo: 'Documento recibido',
      mensaje: 'Un alumno cargó: ${tipo.label}',
      data: <String, dynamic>{...meta},
      duplicarEnPerfil: true,
      documentoId: d.id,
      solicitudId: d.solicitudId,
      idOverride: notiIdInst,
    );
  }

  static Future<void> subirDocumentoTemporalCompat({
    required String institucionSolicitanteId,
    required String ownerAccountId,
    required String perfilId,
    required TipoDocumento tipo,
    required String ref,
    int ttlDays = 5,
    bool notificar = true,
    bool duplicarEnPerfil = true,
    String? solicitudId,
  }) => subirDocumentoTemporal(
    institucionSolicitanteId: institucionSolicitanteId,
    ownerAccountId: ownerAccountId,
    perfilId: perfilId,
    tipo: tipo,
    ref: ref,
    ttlDays: ttlDays,
    notificar: notificar,
    duplicarEnPerfil: duplicarEnPerfil,
    solicitudId: solicitudId,
  );

  static Future<List<DocumentoTemporal>> listarDocumentosPerfil({
    required String perfilId,
  }) async {
    final perfil = _normIdKey(perfilId);
    if (perfil.isEmpty) return const <DocumentoTemporal>[];

    final list = await _leerDocumentos(perfil);

    final now = DateTime.now();
    final out = <DocumentoTemporal>[];
    var changed = false;

    final seen = <String>{};

    for (final d in list) {
      final did = _normIdKey(d.id);
      if (did.isEmpty || seen.contains(did)) continue;
      seen.add(did);

      if (d.estado == EstadoDocumentoTemporal.eliminado) {
        // No devolver eliminados.
        continue;
      }

      final exp =
          now.isAfter(d.expiresAt) ||
          d.estado == EstadoDocumentoTemporal.expirado;

      if (exp && d.estado != EstadoDocumentoTemporal.expirado) {
        out.add(d.copyWith(estado: EstadoDocumentoTemporal.expirado));
        changed = true;
      } else {
        out.add(d);
      }
    }

    if (changed) {
      // Persistir el estado expirado sin “resucitar” eliminados.
      await _guardarDocumentos(perfil, List<DocumentoTemporal>.from(out));
    }

    out.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return List<DocumentoTemporal>.from(out);
  }

  static Future<List<DocumentoTemporal>> listarDocumentosInstitucion({
    required String institucionId,
  }) async {
    final inst = _normIdKey(institucionId);
    if (inst.isEmpty) return const <DocumentoTemporal>[];

    final now = DateTime.now();
    final out = <DocumentoTemporal>[];

    final perfilKeys = await _listarPerfilesRegistrados();

    for (final perfilKey in perfilKeys) {
      final list = await _leerDocumentos(perfilKey);
      var changed = false;
      final nextPerfil = <DocumentoTemporal>[];

      final seen = <String>{};

      for (final d in list) {
        final did = _normIdKey(d.id);
        if (did.isNotEmpty && seen.contains(did)) {
          // dedup best-effort por id dentro del perfil
          continue;
        }
        if (did.isNotEmpty) seen.add(did);

        // Mantener docs de otras instituciones en storage del perfil
        if (_normIdKey(d.institucionSolicitanteId) != inst) {
          nextPerfil.add(d);
          continue;
        }

        // ✅ No devolver eliminados a institución (evita fantasmas)
        if (d.estado == EstadoDocumentoTemporal.eliminado) {
          nextPerfil.add(d);
          continue;
        }

        final exp =
            now.isAfter(d.expiresAt) ||
            d.estado == EstadoDocumentoTemporal.expirado;

        if (exp && d.estado != EstadoDocumentoTemporal.expirado) {
          final dd = d.copyWith(estado: EstadoDocumentoTemporal.expirado);
          out.add(dd);
          nextPerfil.add(dd);
          changed = true;
        } else {
          out.add(d);
          nextPerfil.add(d);
        }
      }

      if (changed) {
        await _guardarDocumentos(
          perfilKey,
          List<DocumentoTemporal>.from(nextPerfil),
        );
      }
    }

    out.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return out;
  }

  static Future<List<DocumentoTemporal>> listarDocumentosPerfilPos(
    String perfilId,
  ) => listarDocumentosPerfil(perfilId: perfilId);

  // =====================================================
  // ELIMINACIÓN
  // =====================================================

  static Future<void> eliminarDocumento({
    required String perfilId,
    required String documentoId,
  }) async {
    final perfil = _normIdKey(perfilId);
    final docId = _normIdKey(documentoId);

    if (perfil.isEmpty) throw Exception('perfilId vacío.');
    if (docId.isEmpty) throw Exception('documentoId vacío.');

    final list = await _leerDocumentos(perfil);
    if (list.isEmpty) return;

    final idx = list.indexWhere((d) => _normIdKey(d.id) == docId);
    if (idx < 0) return;

    final d = list[idx];
    final now = DateTime.now();
    final exp =
        now.isAfter(d.expiresAt) ||
        d.estado == EstadoDocumentoTemporal.expirado;

    if (exp) {
      throw Exception(
        'El documento está expirado. Usá “Limpiar expirados” para eliminarlo.',
      );
    }

    // ✅ Marcar como eliminado (sin devolverlo en listados)
    final next = List<DocumentoTemporal>.from(list);
    next[idx] = d.copyWith(
      estado: EstadoDocumentoTemporal.eliminado,
      expiresAt: now,
    );
    await _guardarDocumentos(perfil, next);

    final notiIdAlumno = 'DOC_EVT_DEL_ALU_${d.id}';
    final notiIdInst = 'DOC_EVT_DEL_INS_${d.id}';

    final meta = <String, dynamic>{
      'subtipo': 'documentoEliminado',
      'institucionId': d.institucionSolicitanteId,
      'tipoDocumento': d.tipo.name,
      'documentoTipo': d.tipo.name,
      'documentoId': d.id,
      'alumnoOwnerAccountId': d.ownerAccountId,
      'alumnoPerfilId': d.perfilId,
      if (d.solicitudId != null) 'solicitudId': d.solicitudId!,
      'deletedAtIso': now.toIso8601String(),
      'estadoDocumento': EstadoDocumentoTemporal.eliminado.name,
      'accion': 'manual_delete',
      'eliminado': true,
    };

    await _emitNotificacion(
      ownerAccountId: d.ownerAccountId,
      perfilId: d.perfilId,
      tipoName: 'documentoEliminado',
      titulo: 'Documento eliminado',
      mensaje: 'Se eliminó un documento temporal: ${d.tipo.label}',
      data: meta,
      duplicarEnPerfil: true,
      documentoId: d.id,
      solicitudId: d.solicitudId,
      target: 'alumno',
      idOverride: notiIdAlumno,
    );

    await _emitNotificacionInstitucion(
      institucionPerfilId: d.institucionSolicitanteId,
      tipoName: 'documentoEliminado',
      titulo: 'Documento eliminado',
      mensaje: 'Se eliminó un documento temporal: ${d.tipo.label}',
      data: <String, dynamic>{...meta},
      duplicarEnPerfil: true,
      documentoId: d.id,
      solicitudId: d.solicitudId,
      idOverride: notiIdInst,
    );
  }

  static Future<void> eliminarDocumentoPos(
    String perfilId,
    String documentoId,
  ) => eliminarDocumento(perfilId: perfilId, documentoId: documentoId);

  static Future<void> eliminarDocumentoTemporalCompat({
    required String perfilId,
    required String documentoId,
  }) => eliminarDocumento(perfilId: perfilId, documentoId: documentoId);

  static Future<void> eliminarDocumentoPorInstitucion({
    required String institucionId,
    required String documentoId,
  }) async {
    final inst = _normIdKey(institucionId);
    final docId = _normIdKey(documentoId);
    if (inst.isEmpty) throw Exception('institucionId vacío.');
    if (docId.isEmpty) throw Exception('documentoId vacío.');

    String? foundPerfil;
    for (final perfil in await _listarPerfilesRegistrados()) {
      for (final d in await _leerDocumentos(perfil)) {
        if (_normIdKey(d.id) == docId &&
            _normIdKey(d.institucionSolicitanteId) == inst) {
          foundPerfil = perfil;
          break;
        }
      }
      if (foundPerfil != null) break;
    }

    if (foundPerfil == null) return;

    await eliminarDocumento(perfilId: foundPerfil, documentoId: docId);
  }

  static Future<void> eliminarDocumentoPorInstitucionPos(
    String institucionId,
    String documentoId,
  ) => eliminarDocumentoPorInstitucion(
    institucionId: institucionId,
    documentoId: documentoId,
  );

  // =====================================================
  // TTL CLEANUP
  // =====================================================

  static Future<int> limpiarExpiradosPerfil({
    required String perfilId,
    bool notify = true,
    bool duplicarEnPerfil = true,
  }) async {
    final perfil = _normIdKey(perfilId);
    if (perfil.isEmpty) return 0;

    final list = await _leerDocumentos(perfil);
    if (list.isEmpty) return 0;

    final now = DateTime.now();
    var removed = 0;

    final expirados = <DocumentoTemporal>[];
    final next = <DocumentoTemporal>[];

    for (final d in list) {
      if (d.estado == EstadoDocumentoTemporal.eliminado) continue;

      final exp =
          now.isAfter(d.expiresAt) ||
          d.estado == EstadoDocumentoTemporal.expirado;

      if (exp) {
        removed++;
        expirados.add(d);
        continue;
      }
      next.add(d);
    }

    await _guardarDocumentos(perfil, next);

    if (!notify || expirados.isEmpty) return removed;

    for (final d in expirados) {
      final notiIdAlumno = 'DOC_EVT_EXP_ALU_${d.id}';
      final notiIdInst = 'DOC_EVT_EXP_INS_${d.id}';

      final meta = <String, dynamic>{
        'subtipo': 'documentoExpirado',
        'institucionId': d.institucionSolicitanteId,
        'tipoDocumento': d.tipo.name,
        'documentoTipo': d.tipo.name,
        'documentoId': d.id,
        'alumnoOwnerAccountId': d.ownerAccountId,
        'alumnoPerfilId': d.perfilId,
        if (d.solicitudId != null) 'solicitudId': d.solicitudId!,
        'expiredAtIso': now.toIso8601String(),
        'expiresAtIso': d.expiresAt.toIso8601String(),
        'estadoDocumento': EstadoDocumentoTemporal.expirado.name,
        'accion': 'ttl_cleanup',
        // ✅ meta de expiración debe marcar eliminado (cumple tu hardening)
        'eliminado': true,
      };

      await _emitNotificacion(
        ownerAccountId: d.ownerAccountId,
        perfilId: d.perfilId,
        tipoName: 'documentoExpirado',
        titulo: 'Documento expirado',
        mensaje:
            'Un documento temporal expiró y fue eliminado: ${d.tipo.label}',
        data: meta,
        duplicarEnPerfil: duplicarEnPerfil,
        documentoId: d.id,
        solicitudId: d.solicitudId,
        target: 'alumno',
        idOverride: notiIdAlumno,
      );

      await _emitNotificacionInstitucion(
        institucionPerfilId: d.institucionSolicitanteId,
        tipoName: 'documentoExpirado',
        titulo: 'Documento expirado',
        mensaje: 'Expiró y se eliminó: ${d.tipo.label}',
        data: <String, dynamic>{...meta},
        duplicarEnPerfil: true,
        documentoId: d.id,
        solicitudId: d.solicitudId,
        idOverride: notiIdInst,
      );
    }

    return removed;
  }

  static Future<int> limpiarExpiradosPerfilCompat({
    required String perfilId,
    bool notificar = true,
    bool duplicarEnPerfil = true,
  }) => limpiarExpiradosPerfil(
    perfilId: perfilId,
    notify: notificar,
    duplicarEnPerfil: duplicarEnPerfil,
  );

  static Future<int> limpiarExpiradosPerfilPos(
    String perfilId, {
    bool notify = true,
    bool duplicarEnPerfil = true,
  }) => limpiarExpiradosPerfil(
    perfilId: perfilId,
    notify: notify,
    duplicarEnPerfil: duplicarEnPerfil,
  );

  static Future<int> limpiarExpiradosInstitucion({
    required String institucionId,
    bool notify = true,
    bool duplicarEnPerfil = true,
  }) async {
    final inst = _normIdKey(institucionId);
    if (inst.isEmpty) return 0;

    final now = DateTime.now();
    var removed = 0;

    final toRemoveByPerfil = <String, List<DocumentoTemporal>>{};

    for (final perfilKey in await _listarPerfilesRegistrados()) {
      final list = await _leerDocumentos(perfilKey);
      final expirados = <DocumentoTemporal>[];

      for (final d in list) {
        if (_normIdKey(d.institucionSolicitanteId) != inst) continue;
        if (d.estado == EstadoDocumentoTemporal.eliminado) continue;

        final exp =
            now.isAfter(d.expiresAt) ||
            d.estado == EstadoDocumentoTemporal.expirado;

        if (exp) expirados.add(d);
      }

      if (expirados.isNotEmpty) {
        toRemoveByPerfil[perfilKey] = expirados;
      }
    }

    if (toRemoveByPerfil.isEmpty) return 0;

    for (final entry in toRemoveByPerfil.entries) {
      final perfilKey = entry.key;
      final expirados = entry.value;

      final list = await _leerDocumentos(perfilKey);
      final ids = expirados.map((e) => _normIdKey(e.id)).toSet();

      await _guardarDocumentos(
        perfilKey,
        list
            .where((d) => !ids.contains(_normIdKey(d.id)))
            .toList(growable: false),
      );

      removed += expirados.length;

      if (!notify) continue;

      for (final d in expirados) {
        final notiIdAlumno = 'DOC_EVT_EXP_ALU_${d.id}';
        final notiIdInst = 'DOC_EVT_EXP_INS_${d.id}';

        final meta = <String, dynamic>{
          'subtipo': 'documentoExpirado',
          'institucionId': d.institucionSolicitanteId,
          'tipoDocumento': d.tipo.name,
          'documentoTipo': d.tipo.name,
          'documentoId': d.id,
          'alumnoOwnerAccountId': d.ownerAccountId,
          'alumnoPerfilId': d.perfilId,
          if (d.solicitudId != null) 'solicitudId': d.solicitudId!,
          'expiredAtIso': now.toIso8601String(),
          'expiresAtIso': d.expiresAt.toIso8601String(),
          'estadoDocumento': EstadoDocumentoTemporal.expirado.name,
          'accion': 'ttl_cleanup_institucion',
          // ✅ meta de expiración debe marcar eliminado (cumple tu hardening)
          'eliminado': true,
        };

        await _emitNotificacion(
          ownerAccountId: d.ownerAccountId,
          perfilId: d.perfilId,
          tipoName: 'documentoExpirado',
          titulo: 'Documento expirado',
          mensaje:
              'Un documento temporal expiró y fue eliminado: ${d.tipo.label}',
          data: meta,
          duplicarEnPerfil: duplicarEnPerfil,
          documentoId: d.id,
          solicitudId: d.solicitudId,
          target: 'alumno',
          idOverride: notiIdAlumno,
        );

        await _emitNotificacionInstitucion(
          institucionPerfilId: d.institucionSolicitanteId,
          tipoName: 'documentoExpirado',
          titulo: 'Documento expirado',
          mensaje: 'Expiró y se eliminó: ${d.tipo.label}',
          data: <String, dynamic>{...meta},
          duplicarEnPerfil: true,
          documentoId: d.id,
          solicitudId: d.solicitudId,
          idOverride: notiIdInst,
        );
      }
    }

    return removed;
  }

  static Future<int> limpiarExpiradosInstitucionPos(
    String institucionId, {
    bool notify = true,
    bool duplicarEnPerfil = true,
  }) => limpiarExpiradosInstitucion(
    institucionId: institucionId,
    notify: notify,
    duplicarEnPerfil: duplicarEnPerfil,
  );
}
