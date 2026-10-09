import 'dart:convert';
import 'dart:typed_data';
import '../../models/solicitudes/solicitud_alumno.dart';
import '../documentos_temporales_service.dart';
import 'multiuser_session.dart';

/// Private temporary files; bytes fetched only by an authorized RPC, never a URL.
class DocumentosSupabaseRepository {
  final MultiuserSession session;
  DocumentosSupabaseRepository(this.session);
  Future<dynamic> _rpc(String name, Map<String, dynamic> params) async {
    final identity = session.userId;
    if (identity.isEmpty) throw StateError('Ingresá con tu cuenta remota.');
    final result = await session.client.rpc(name, params: params);
    if (session.userId != identity) throw StateError('La sesión cambió.');
    return result;
  }

  Future<void> profile(String owner, String profile) async {
    if (owner != session.userId ||
        !(await session.context()).profiles.contains(profile)) {
      throw StateError('Perfil no autorizado.');
    }
  }

  Future<List<SolicitudAlumno>> enrollments(
    String institution,
    String area,
  ) async {
    final scope = await session.institution(
      institution,
      area,
      'documents.read',
    );
    final rows =
        await _rpc('atena_document_enrollments', {
              'p_institution': institution,
              'p_area': area,
            })
            as List;
    return rows
        .map(
          (r) => SolicitudAlumno(
            id: r['id'],
            alumnoDocumento: '',
            institucionId: institution,
            institucionNombre: scope.name,
            actividadNombre: scope.areaName,
            esCurricular: r['kind'] == 'curricular',
            estado: EstadoSolicitud.confirmada,
            fechaCreacion: DateTime.parse(r['created_at']),
            fechaUltimoCambio: DateTime.parse(r['updated_at']),
            dedupKey: '',
            perfilId: r['profile_id'],
            areaId: area,
            grupoCurricularId: r['group_id'],
            aula: r['group_id'],
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> read({
    String? profile,
    String? institution,
    String? area,
  }) async {
    if (profile != null) {
      await this.profile(session.userId, profile);
    } else {
      await session.institution(institution!, area!, 'documents.read');
    }
    return Map<String, dynamic>.from(
      await _rpc('atena_documents_read', {
        'p_profile': profile,
        'p_institution': institution,
        'p_area': area,
      }),
    );
  }

  static List<SolicitudDocumento> requests(Map<String, dynamic> data) =>
      (data['requests'] as List)
          .map(
            (r) => SolicitudDocumento(
              id: r['id'],
              institucionId: r['institucionId'],
              areaId: r['areaId'],
              ownerAccountId: r['ownerAccountId'],
              perfilId: r['perfilId'],
              tipo: TipoDocumento.values.byName(r['tipo']),
              mensaje: r['mensaje'],
              createdAt: DateTime.parse(r['createdAt']),
              estado: EstadoSolicitudDocumento.values.byName(r['estado']),
            ),
          )
          .toList();
  static DocumentoTemporal document(Map r) => DocumentoTemporal(
    id: r['id'],
    institucionSolicitanteId: r['institucionSolicitanteId'],
    ownerAccountId: r['ownerAccountId'],
    perfilId: r['perfilId'],
    tipo: TipoDocumento.values.byName(r['tipo']),
    ref: '',
    solicitudId: r['solicitudId'],
    uploadedAt: DateTime.parse(r['uploadedAt']),
    expiresAt: DateTime.parse(r['expiresAt']),
    estado: EstadoDocumentoTemporal.values.byName(r['estado']),
  );
  static List<DocumentoTemporal> documents(Map<String, dynamic> data) =>
      (data['documents'] as List).map((r) => document(r as Map)).toList();
  Future<void> request(
    String institution,
    String area,
    String enrollment,
    TipoDocumento type,
    String message,
    String operation,
  ) async {
    await session.institution(institution, area, 'documents.write');
    final id = await _rpc('atena_document_request', {
      'p_institution': institution,
      'p_area': area,
      'p_request': enrollment,
      'p_id': operation,
      'p_kind': type.name,
      'p_message': message.trim(),
    });
    if (id != operation) {
      throw const FormatException('Respuesta documental contradictoria.');
    }
  }

  Future<void> cancel(String institution, String area, String id) async {
    await session.institution(institution, area, 'documents.write');
    await _rpc('atena_document_cancel', {'p_id': id});
  }

  Future<void> upload(
    String owner,
    String profile,
    String id,
    Uint8List bytes,
  ) async {
    await this.profile(owner, profile);
    final result = await _rpc('atena_document_upload', {
      'p_profile': profile,
      'p_id': id,
      'p_base64': base64Encode(bytes),
    });
    if (result != id) {
      throw const FormatException('Respuesta documental contradictoria.');
    }
  }

  Future<DocumentoTemporal> open(String id) async {
    final r = Map<String, dynamic>.from(
      await _rpc('atena_document_open', {'p_id': id}),
    );
    if (r['id'] != id ||
        !['application/pdf', 'image/png', 'image/jpeg'].contains(r['mime'])) {
      throw const FormatException('Respuesta documental contradictoria.');
    }
    final bytes = base64Decode(
      (r['base64'] as String).replaceAll(RegExp(r'\s'), ''),
    );
    if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
      throw const FormatException('Tamaño documental inválido.');
    }
    return document(
      r,
    ).copyWith(ref: Uri.dataFromBytes(bytes, mimeType: r['mime']).toString());
  }

  Future<int> remove(
    String profile, {
    String? id,
    bool expiredOnly = false,
  }) async {
    await this.profile(session.userId, profile);
    return await _rpc('atena_documents_remove', {
          'p_profile': profile,
          'p_id': id,
          'p_expired_only': expiredOnly,
        })
        as int;
  }
}
