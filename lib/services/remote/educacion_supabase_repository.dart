import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../models/alumnos/modulo_educativo.dart';
import '../../models/solicitudes/solicitud_alumno.dart';
import 'multiuser_session.dart';

/// Reuses ModuloEducativo and the existing education screens. Server validates
/// enrollment, author, publication state, fields and expected revision again.
class EducacionSupabaseRepository {
  final MultiuserSession session;
  EducacionSupabaseRepository(this.session);
  Future<dynamic> _rpc(String name, Map<String, dynamic> params) async {
    final auth = session.userId;
    if (auth.isEmpty) throw StateError('Ingresá con tu cuenta remota.');
    final value = await session.client.rpc(name, params: params);
    if (session.userId != auth) throw StateError('La sesión cambió.');
    return value;
  }

  Future<List<SolicitudAlumno>> enrollments(
    String institution,
    String area,
  ) async {
    final scope = await session.institution(
      institution,
      area,
      'education.read',
    );
    final rows =
        await _rpc('atena_education_enrollments', {
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

  Future<List<Map<String, dynamic>>> readStudent(
    String owner,
    String profile,
    ModuloEducativo module,
  ) async {
    if (owner != session.userId ||
        !(await session.context()).profiles.contains(profile)) {
      throw StateError('Perfil no autorizado.');
    }
    return _rows(
      await _rpc('atena_education_read', {
        'p_module': module.name,
        'p_profile': profile,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> readInstitution(
    String institution,
    String area,
    String request,
    ModuloEducativo module,
  ) async {
    await session.institution(institution, area, 'education.read');
    return _rows(
      await _rpc('atena_education_read', {
        'p_module': module.name,
        'p_institution': institution,
        'p_area': area,
        'p_request': request,
      }),
    );
  }

  Future<void> save({
    required String institution,
    required String area,
    required String request,
    required String id,
    required ModuloEducativo module,
    required Map<String, dynamic> data,
    required bool visible,
    required int revision,
  }) async {
    await session.institution(institution, area, 'education.write');
    final fields = module.validar(data);
    final payload = {
      'p_institution': institution,
      'p_area': area,
      'p_request': request,
      'p_id': id,
      'p_module': module.name,
      'p_data': fields,
      'p_visible': visible,
      'p_revision': revision,
    };
    // Deterministic retry key from the immutable edit intent; no credential or
    // identity is encoded. Server rejects reuse with any different payload.
    final digest = await Sha256().hash(utf8.encode(jsonEncode(payload)));
    final h = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    payload['p_operation'] =
        '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
    final result = await _rpc('atena_education_save', payload);
    if (result is! Map ||
        result['id'] != id ||
        result['revision'] != revision + 1) {
      throw const FormatException('Respuesta educativa contradictoria.');
    }
  }

  static List<Map<String, dynamic>> _rows(dynamic data) =>
      (data as List).map((r) => Map<String, dynamic>.from(r)).toList();
}
