import 'remote/multiuser_session.dart';
import 'remote/documentos_supabase_repository.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/instituciones/operador_institucional.dart';
import '../models/solicitudes/solicitud_alumno.dart';
import 'cuenta_service.dart';
import 'documentos_temporales_service.dart';
import 'institucion_contexto_operativo_service.dart';
import 'institucion_operadores_service.dart';
import 'session_service.dart';
import 'solicitudes_service.dart';

/// Frontera de las pantallas documentales. Conserva las colecciones históricas.
/// El archivo local no representa un objeto remoto ni una garantía SINGLE/CLOSE.
class DocumentacionOperativaService {
  static final Set<String> _subidas = {};
  static const maxBytes = 2 * 1024 * 1024;

  static Future<void> validarAlumno(String owner, String perfil) async {
    if (MultiuserSession.enabled) {
      await DocumentosSupabaseRepository(
        MultiuserSession.current,
      ).profile(owner, perfil);
      return;
    }
    final session = await SessionService.getSession();
    if (session?.role != SessionRole.cuenta ||
        session?.userId != owner ||
        await CuentaService.getSesionCuentaId() != owner) {
      throw StateError('Iniciá sesión con la cuenta del alumno.');
    }
    await _identidad(owner, perfil);
  }

  static Future<void> _identidad(
    String owner,
    String perfil, [
    String? documento,
  ]) async {
    final a = await CuentaService.getCuentaById(owner);
    final p = await CuentaService.getPerfilAlumnoById(perfil);
    if (a == null ||
        p == null ||
        p.cuentaId != owner ||
        (p.ownerAccountId ?? p.cuentaId) != owner ||
        !a.perfilesAlumnoIds.contains(perfil) ||
        await CuentaService.getOwnerAccountIdForPerfilAlumno(perfil) != owner ||
        (documento != null && documento != p.documento)) {
      throw StateError('No se pudo validar el perfil del alumno.');
    }
  }

  static Future<({String area, OperadorInstitucional actor})> contexto(
    String institution, {
    bool escribir = false,
  }) async {
    final c = await InstitucionContextoOperativoService.instance
        .reconstruirContextoOperativo();
    if (c == null || c.institutionId != institution) {
      throw StateError('Ingresá desde un área y un operador autorizados.');
    }
    final p = await CuentaService.getPerfilInstitucionById(institution);
    final a = await CuentaService.getCuentaById(c.ownerAccountId);
    if (p == null ||
        a == null ||
        p.cuentaId != a.id ||
        (p.ownerAccountId ?? p.cuentaId) != a.id ||
        !a.perfilesInstitucionIds.contains(institution)) {
      throw StateError('El propietario institucional no coincide.');
    }
    final op = await InstitucionOperadoresService.instance.autorizarActivo(
      institucionId: institution,
      areaId: c.areaId,
      capacidad: escribir
          ? CapacidadInstitucional.documentsWrite
          : CapacidadInstitucional.documentsRead,
    );
    if (op == null) {
      throw StateError(
        'El operador no tiene permiso de documentación en esta área.',
      );
    }
    return (area: c.areaId, actor: op);
  }

  static Future<List<SolicitudAlumno>> destinatarios(
    String institution, {
    String? remoteAreaId,
  }) async {
    if (MultiuserSession.enabled) {
      return DocumentosSupabaseRepository(
        MultiuserSession.current,
      ).enrollments(institution, remoteAreaId ?? '');
    }
    final c = await contexto(institution);
    final result = <SolicitudAlumno>[];
    for (final s in await SolicitudesService.obtenerSolicitudesParaInstitucion(
      institucionId: institution,
    )) {
      if (s.estado != EstadoSolicitud.confirmada ||
          s.areaId != c.area ||
          s.institucionId != institution) {
        continue;
      }
      try {
        await _identidad(
          s.ownerAccountId ?? '',
          s.perfilId ?? '',
          s.alumnoDocumento,
        );
        result.add(s);
      } on StateError {
        /* No inferir identidades históricas por documento. */
      }
    }
    return result;
  }

  static Future<void> solicitar(
    String institution,
    String inscripcion,
    TipoDocumento tipo,
    String mensaje, {
    String? remoteAreaId,
    String? operationId,
  }) async {
    if (MultiuserSession.enabled) {
      await DocumentosSupabaseRepository(MultiuserSession.current).request(
        institution,
        remoteAreaId ?? '',
        inscripcion,
        tipo,
        mensaje,
        operationId ?? MultiuserSession.operationId(),
      );
      return;
    }
    final c = await contexto(institution, escribir: true);
    final s = (await destinatarios(
      institution,
    )).where((s) => s.id == inscripcion).firstOrNull;
    if (s == null) {
      throw StateError('Seleccioná una inscripción válida del área.');
    }
    final again = await contexto(institution, escribir: true);
    if (c != again && (c.actor.id != again.actor.id || c.area != again.area)) {
      throw StateError('Cambió el contexto operativo.');
    }
    await DocumentosTemporalesService.solicitar(
      institucionId: institution,
      ownerAccountId: s.ownerAccountId!,
      perfilId: s.perfilId!,
      tipo: tipo,
      mensaje: mensaje.trim(),
      areaId: c.area,
      emittedByOperatorId: c.actor.id,
    );
  }

  static Future<List<SolicitudDocumento>> solicitudesInstitucion(
    String institution, {
    String? remoteAreaId,
  }) async {
    if (MultiuserSession.enabled) {
      return DocumentosSupabaseRepository.requests(
        await DocumentosSupabaseRepository(
          MultiuserSession.current,
        ).read(institution: institution, area: remoteAreaId ?? ''),
      );
    }
    final c = await contexto(institution);
    final enrolled = await destinatarios(institution);
    return (await DocumentosTemporalesService.listarSolicitudesInstitucion(
          institucionId: institution,
        ))
        .where(
          (s) =>
              s.areaId == c.area &&
              enrolled.any(
                (e) =>
                    e.ownerAccountId == s.ownerAccountId &&
                    e.perfilId == s.perfilId,
              ),
        )
        .toList();
  }

  static Future<List<DocumentoTemporal>> documentosInstitucion(
    String institution, {
    String? remoteAreaId,
  }) async {
    if (MultiuserSession.enabled) {
      return DocumentosSupabaseRepository.documents(
        await DocumentosSupabaseRepository(
          MultiuserSession.current,
        ).read(institution: institution, area: remoteAreaId ?? ''),
      );
    }
    final requests = await solicitudesInstitucion(institution);
    return (await DocumentosTemporalesService.listarDocumentosInstitucion(
          institucionId: institution,
        ))
        .where(
          (d) => requests.any(
            (s) =>
                s.id == d.solicitudId &&
                s.ownerAccountId == d.ownerAccountId &&
                s.perfilId == d.perfilId &&
                s.tipo == d.tipo,
          ),
        )
        .toList();
  }

  static Future<void> cancelar(
    String institution,
    String id, {
    String? remoteAreaId,
  }) async {
    if (MultiuserSession.enabled) {
      await DocumentosSupabaseRepository(
        MultiuserSession.current,
      ).cancel(institution, remoteAreaId ?? '', id);
      return;
    }
    await contexto(institution, escribir: true);
    final s = (await solicitudesInstitucion(
      institution,
    )).where((s) => s.id == id).firstOrNull;
    if (s == null || s.estado != EstadoSolicitudDocumento.pendiente) {
      throw StateError('La solicitud ya no está pendiente.');
    }
    await DocumentosTemporalesService.cancelarSolicitud(
      perfilId: s.perfilId,
      solicitudId: s.id,
    );
  }

  static Future<List<SolicitudDocumento>> solicitudesAlumno(
    String owner,
    String profile,
  ) async {
    await validarAlumno(owner, profile);
    if (MultiuserSession.enabled) {
      return DocumentosSupabaseRepository.requests(
        await DocumentosSupabaseRepository(
          MultiuserSession.current,
        ).read(profile: profile),
      );
    }
    return DocumentosTemporalesService.listarSolicitudesPerfil(
      perfilId: profile,
    );
  }

  static Future<List<DocumentoTemporal>> documentosAlumno(
    String owner,
    String profile,
  ) async {
    await validarAlumno(owner, profile);
    if (MultiuserSession.enabled) {
      return DocumentosSupabaseRepository.documents(
        await DocumentosSupabaseRepository(
          MultiuserSession.current,
        ).read(profile: profile),
      );
    }
    return DocumentosTemporalesService.listarDocumentosPerfil(
      perfilId: profile,
    );
  }

  static Future<int> limpiar(String owner, String profile) async {
    await validarAlumno(owner, profile);
    if (MultiuserSession.enabled) {
      return DocumentosSupabaseRepository(
        MultiuserSession.current,
      ).remove(profile, expiredOnly: true);
    }
    return DocumentosTemporalesService.limpiarExpiradosPerfil(
      perfilId: profile,
      notify: true,
      duplicarEnPerfil: true,
    );
  }

  static Future<void> eliminar(String owner, String profile, String id) async {
    await validarAlumno(owner, profile);
    if (MultiuserSession.enabled) {
      await DocumentosSupabaseRepository(
        MultiuserSession.current,
      ).remove(profile, id: id);
      return;
    }
    await DocumentosTemporalesService.eliminarDocumento(
      perfilId: profile,
      documentoId: id,
    );
  }

  static String referencia(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw ArgumentError('Seleccioná un PDF, PNG o JPEG de hasta 2 MB.');
    }
    final mime =
        bytes.length >= 5 &&
            ascii.decode(bytes.take(5).toList(), allowInvalid: true) == '%PDF-'
        ? 'application/pdf'
        : bytes.length >= 8 &&
              base64Encode(bytes.sublist(0, 8)) == 'iVBORw0KGgo='
        ? 'image/png'
        : bytes.length >= 3 &&
              bytes[0] == 255 &&
              bytes[1] == 216 &&
              bytes[2] == 255
        ? 'image/jpeg'
        : null;
    if (mime == null) {
      throw ArgumentError('El contenido no corresponde a PDF, PNG o JPEG.');
    }
    return Uri.dataFromBytes(bytes, mimeType: mime).toString();
  }

  static Future<void> adjuntar(
    String owner,
    String perfil,
    String solicitudId,
    Uint8List bytes,
  ) async {
    final key = '$owner::$perfil';
    if (!_subidas.add(key)) {
      throw StateError('Ya se está guardando un archivo de este perfil.');
    }
    try {
      final ref = referencia(bytes);
      if (MultiuserSession.enabled) {
        await DocumentosSupabaseRepository(
          MultiuserSession.current,
        ).upload(owner, perfil, solicitudId, bytes);
        return;
      }
      await validarAlumno(owner, perfil);
      final s =
          (await DocumentosTemporalesService.listarSolicitudesPerfil(
                perfilId: perfil,
              ))
              .where(
                (s) =>
                    s.id == solicitudId &&
                    s.ownerAccountId == owner &&
                    s.perfilId == perfil,
              )
              .firstOrNull;
      if (s == null || s.estado != EstadoSolicitudDocumento.pendiente) {
        throw StateError('La solicitud ya no está pendiente.');
      }
      final persisted =
          (await DocumentosTemporalesService.listarDocumentosPerfil(
                perfilId: perfil,
              ))
              .where(
                (d) =>
                    d.solicitudId == s.id &&
                    d.ownerAccountId == owner &&
                    d.institucionSolicitanteId == s.institucionId &&
                    d.tipo == s.tipo &&
                    !d.expirado &&
                    d.estado == EstadoDocumentoTemporal.activo,
              )
              .toList();
      if (persisted.isNotEmpty) {
        if (persisted.length != 1 || persisted.single.ref != ref) {
          throw StateError(
            'La solicitud ya tiene un archivo. Revisalo antes de adjuntar otro.',
          );
        }
        // Retomar una escritura interrumpida sin volver a guardar el archivo.
        await DocumentosTemporalesService.marcarSolicitudCumplida(
          perfilId: perfil,
          solicitudId: s.id,
        );
      } else {
        await DocumentosTemporalesService.subirDocumentoTemporal(
          institucionSolicitanteId: s.institucionId,
          ownerAccountId: owner,
          perfilId: perfil,
          tipo: s.tipo,
          ref: ref,
          solicitudId: s.id,
        );
      }
      final saved = (await DocumentosTemporalesService.listarSolicitudesPerfil(
        perfilId: perfil,
      )).where((entry) => entry.id == s.id).firstOrNull;
      if (saved?.estado != EstadoSolicitudDocumento.cumplida) {
        throw StateError(
          'El archivo quedó guardado, pero no se pudo completar la solicitud. Reintentá con el mismo archivo.',
        );
      }
    } finally {
      _subidas.remove(key);
    }
  }

  static Future<DocumentoTemporal> abrir(DocumentoTemporal supplied) async {
    if (MultiuserSession.enabled) {
      return DocumentosSupabaseRepository(
        MultiuserSession.current,
      ).open(supplied.id);
    }
    final session = await SessionService.getSession();
    List<DocumentoTemporal> docs;
    if (session?.role == SessionRole.institucion) {
      docs = await documentosInstitucion(supplied.institucionSolicitanteId);
    } else {
      await validarAlumno(supplied.ownerAccountId, supplied.perfilId);
      docs = await DocumentosTemporalesService.listarDocumentosPerfil(
        perfilId: supplied.perfilId,
      );
    }
    final d = docs
        .where(
          (d) =>
              d.id == supplied.id &&
              d.ownerAccountId == supplied.ownerAccountId,
        )
        .firstOrNull;
    if (d == null || d.expirado || d.estado != EstadoDocumentoTemporal.activo) {
      throw StateError('El documento no está disponible.');
    }
    return d;
  }
}
