import 'dart:async';
import 'dart:convert';
import '../models/alumnos/modulo_educativo.dart';
import '../models/instituciones/operador_institucional.dart';
import '../models/solicitudes/solicitud_alumno.dart';
import 'alumno_service.dart';
import 'cuenta_service.dart';
import 'institucion_contexto_operativo_service.dart';
import 'institucion_operadores_service.dart';
import 'session_service.dart';
import 'solicitudes_service.dart';
import 'notificaciones_service.dart';
import '../models/notificaciones/notificacion_atena.dart';

/// Operaciones locales sobre las seis colecciones educativas existentes.
/// Cada registro conserva la inscripción, área, identidad y revisiones.
class TrayectoriaEducativaService {
  TrayectoriaEducativaService._();
  static final instance = TrayectoriaEducativaService._();
  Future<void>? _cola;

  Future<OperadorInstitucional> _autorizar(
    String institution,
    String area, {
    bool escribir = false,
  }) async {
    final context = await InstitucionContextoOperativoService.instance
        .reconstruirContextoOperativo();
    if (context == null ||
        context.institutionId != institution ||
        context.areaId != area) {
      throw StateError('Ingresá con un operador del área correspondiente.');
    }
    final institutionalProfile = await CuentaService.getPerfilInstitucionById(
      institution,
    );
    final account = await CuentaService.getCuentaById(context.ownerAccountId);
    if (institutionalProfile == null ||
        account == null ||
        institutionalProfile.cuentaId != account.id ||
        (institutionalProfile.ownerAccountId ??
                institutionalProfile.cuentaId) !=
            account.id ||
        !account.perfilesInstitucionIds.contains(institution)) {
      throw StateError(
        'El propietario institucional no coincide con la identidad validada.',
      );
    }
    final operator = await InstitucionOperadoresService.instance
        .autorizarActivo(
          institucionId: institution,
          areaId: area,
          capacidad: escribir
              ? CapacidadInstitucional.educationWrite
              : CapacidadInstitucional.educationRead,
        );
    if (operator == null) {
      throw StateError(
        'El operador no tiene permiso para esta información educativa.',
      );
    }
    return operator;
  }

  Future<bool> puedeEditar(String institution, String area) async {
    try {
      await _autorizar(institution, area, escribir: true);
      return true;
    } on StateError {
      return false;
    }
  }

  Future<void> _identidad(
    String owner,
    String profile, [
    String? document,
  ]) async {
    final account = await CuentaService.getCuentaById(owner);
    final student = await CuentaService.getPerfilAlumnoById(profile);
    if (owner.isEmpty ||
        profile.isEmpty ||
        account == null ||
        student == null ||
        student.cuentaId != owner ||
        (student.ownerAccountId ?? student.cuentaId) != owner ||
        !account.perfilesAlumnoIds.contains(profile) ||
        await CuentaService.getOwnerAccountIdForPerfilAlumno(profile) !=
            owner ||
        (document != null && student.documento != document)) {
      throw StateError('El perfil del alumno y su cuenta no coinciden.');
    }
  }

  Future<List<SolicitudAlumno>> inscripciones(
    String institution,
    String area,
  ) async {
    await _autorizar(institution, area);
    final all = await SolicitudesService.obtenerSolicitudesParaInstitucion(
      institucionId: institution,
    );
    final result = <SolicitudAlumno>[];
    for (final s in all) {
      if (s.estado != EstadoSolicitud.confirmada ||
          s.areaId != area ||
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
        /* Los registros sin identidad verificable no se asignan por DNI. */
      }
    }
    return result;
  }

  Future<SolicitudAlumno> _inscripcion(
    String institution,
    String area,
    String id,
  ) async {
    final values = await inscripciones(institution, area);
    for (final s in values) {
      if (s.id == id) return s;
    }
    throw StateError(
      'No hay una inscripción confirmada y verificable en esta área.',
    );
  }

  Future<List<Map<String, dynamic>>> leerInstitucion({
    required String institucionId,
    required String areaId,
    required String solicitudId,
    required ModuloEducativo modulo,
  }) async {
    final s = await _inscripcion(institucionId, areaId, solicitudId);
    final all = await AlumnoService.instance.leerEducacion(
      ownerAccountId: s.ownerAccountId!,
      perfilId: s.perfilId!,
      modulo: modulo.name,
    );
    return all.where((r) => _coincide(r, s)).toList();
  }

  bool _coincide(Map<String, dynamic> r, SolicitudAlumno s) =>
      r['institucionId'] == s.institucionId &&
      r['areaId'] == s.areaId &&
      r['solicitudId'] == s.id &&
      r['alumnoDocumento'] == s.alumnoDocumento &&
      r['ownerAccountId'] == s.ownerAccountId &&
      r['perfilId'] == s.perfilId;

  Future<List<Map<String, dynamic>>> leerAlumno({
    required String ownerAccountId,
    required String perfilId,
    required ModuloEducativo modulo,
  }) async {
    final session = await SessionService.getSession();
    if (session?.role != SessionRole.cuenta ||
        session?.userId != ownerAccountId ||
        await CuentaService.getSesionCuentaId() != ownerAccountId) {
      throw StateError('Iniciá sesión con la cuenta del alumno.');
    }
    await _identidad(ownerAccountId, perfilId);
    final student = (await CuentaService.getPerfilAlumnoById(perfilId))!;
    final all = await AlumnoService.instance.leerEducacion(
      ownerAccountId: ownerAccountId,
      perfilId: perfilId,
      modulo: modulo.name,
    );
    // No se infiere publicación ni identidad de registros legacy incompletos.
    return all
        .where(
          (r) =>
              r['visibleAlumno'] == true &&
              r['ownerAccountId'] == ownerAccountId &&
              r['perfilId'] == perfilId &&
              r['alumnoDocumento'] == student.documento &&
              (r['institucionId'] ?? '').toString().isNotEmpty &&
              (r['areaId'] ?? '').toString().isNotEmpty,
        )
        // Sólo campos presentados para publicación. Metadatos desconocidos o
        // notas internas legacy no se publican al compartir un registro.
        .map(
          (r) => <String, dynamic>{
            for (final key in {
              ...modulo.campos.keys,
              if (modulo.booleano != null) modulo.booleano!,
              'id',
              'institucionId',
              'institucion',
              'institucionDestinoId',
              'ownerAccountId',
              'perfilId',
              'alumnoDocumento',
              'alumnoNombre',
              'areaId',
              'solicitudId',
              'grupoId',
              'actividad',
              'aula',
              'turno',
              'visibleAlumno',
              'operadorNombre',
              'ultimaActualizacion',
              'revision',
              'completo',
            })
              if (r.containsKey(key)) key: r[key],
          },
        )
        .toList();
  }

  Future<void> guardar({
    required String institucionId,
    required String areaId,
    required String solicitudId,
    required ModuloEducativo modulo,
    required String id,
    required Map<String, dynamic> datos,
    required bool visibleAlumno,
    int? revisionEsperada,
  }) {
    final done = Completer<void>();
    final previous = _cola;
    final release = Completer<void>();
    _cola = release.future;
    () async {
      if (previous != null) await previous;
      try {
        await _guardar(
          institucionId,
          areaId,
          solicitudId,
          modulo,
          id,
          datos,
          visibleAlumno,
          revisionEsperada,
        );
        done.complete();
      } catch (e, stack) {
        done.completeError(e, stack);
      } finally {
        if (identical(_cola, release.future)) _cola = null;
        release.complete();
      }
    }();
    return done.future;
  }

  Future<void> _guardar(
    String institution,
    String area,
    String enrollment,
    ModuloEducativo module,
    String id,
    Map<String, dynamic> data,
    bool published,
    int? revision,
  ) async {
    final operator = await _autorizar(institution, area, escribir: true);
    final s = await _inscripcion(institution, area, enrollment);
    if (id.trim().isEmpty) {
      throw ArgumentError('Falta el identificador del registro.');
    }
    final fields = module.validar(data);
    final all = await AlumnoService.instance.leerEducacion(
      ownerAccountId: s.ownerAccountId!,
      perfilId: s.perfilId!,
      modulo: module.name,
    );
    final index = all.indexWhere((r) => r['id'] == id);
    final old = index < 0 ? null : all[index];
    if (old != null && !_coincide(old, s)) {
      throw StateError('El registro pertenece a otro contexto.');
    }
    if ((old?['revision'] as int? ?? 0) != (revision ?? 0)) {
      throw StateError('El registro cambió. Volvé a abrirlo antes de guardar.');
    }
    // Un progreso por inscripción; un boletín por período/año, sin duplicados.
    if (all.any(
      (r) =>
          r['id'] != id &&
          _coincide(r, s) &&
          (module == ModuloEducativo.progreso ||
              (module == ModuloEducativo.boletines &&
                  r['anio'] == fields['anio'] &&
                  r['periodo'] == fields['periodo'])),
    )) {
      throw StateError('Ya existe ese registro. Abrilo para actualizarlo.');
    }
    final now = DateTime.now().toIso8601String();
    final student = (await CuentaService.getPerfilAlumnoById(s.perfilId!))!;
    final updated = <String, dynamic>{
      ...?old,
      ...fields,
      'id': id,
      'institucionId': institution,
      'institucion': s.institucionNombre,
      'institucionDestinoId': institution,
      'ownerAccountId': s.ownerAccountId,
      'perfilId': s.perfilId,
      'alumnoDocumento': s.alumnoDocumento,
      'alumnoNombre': student.displayName,
      'areaId': area,
      'solicitudId': s.id,
      'grupoId': s.grupoCurricularId,
      'actividad': s.actividadNombre,
      'aula': s.aula,
      'turno': s.turno,
      'visibleAlumno': published,
      'createdAt': old?['createdAt'] ?? now,
      'createdByOperatorId': old?['createdByOperatorId'] ?? operator.id,
      'updatedByOperatorId': operator.id,
      'operadorNombre': operator.nombreVisible,
      'ultimaActualizacion': now,
      'revision': (revision ?? 0) + 1,
      'historial': [
        ...?old?['historial'] as List?,
        if (old != null) {...old}..remove('historial'),
      ],
    };
    if (index < 0) {
      all.add(updated);
    } else {
      all[index] = updated;
    }
    // Revalidar el contexto tras las lecturas asíncronas; no guardar con sesión vieja.
    final still = await _autorizar(institution, area, escribir: true);
    if (still.id != operator.id) {
      throw StateError('El operador cambió. Volvé a abrir el registro.');
    }
    await AlumnoService.instance.guardarEducacion(
      ownerAccountId: s.ownerAccountId!,
      perfilId: s.perfilId!,
      modulo: module.name,
      registros: all,
    );
    final stored = await AlumnoService.instance.leerEducacion(
      ownerAccountId: s.ownerAccountId!,
      perfilId: s.perfilId!,
      modulo: module.name,
    );
    if (!stored.any((r) => jsonEncode(r) == jsonEncode(updated))) {
      throw StateError('No se pudo verificar el guardado.');
    }
    if (published) {
      // El aviso no copia calificaciones, sanciones ni contenido sensible.
      // Un mismo registro actualiza su aviso, sin multiplicarlo por revisión.
      await NotificacionesService.instance.pushToOwner(
        ownerAccountId: s.ownerAccountId!,
        notificacion: NotificacionAtena(
          id: 'education_${module.name}_${s.perfilId}_$id',
          ownerAccountId: s.ownerAccountId!,
          perfilId: s.perfilId!,
          titulo: '${module.label}: información disponible',
          mensaje:
              '${s.institucionNombre} compartió una actualización. Abrí el módulo para consultarla.',
          fecha: DateTime.parse(now),
          tipo: TipoNotificacionAtena.info,
          scope: NotificacionScopeAtena.perfil,
          leida: false,
          deeplink: Uri(
            path: '/${module.name}',
            queryParameters: {
              'ownerAccountId': s.ownerAccountId!,
              'perfilId': s.perfilId!,
            },
          ).toString(),
        ),
      );
    }
  }
}
