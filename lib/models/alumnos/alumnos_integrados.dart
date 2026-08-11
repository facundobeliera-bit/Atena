// ─────────────────────────────────────────────
// ATENA – MODELOS ALUMNOS (INTEGRADOS / COMPATIBLE SERVICES)
// Archivo: lib/models/alumnos/alumnos_integrados.dart
// Estado: COMPATIBLE con AlumnoService (toMap/fromMap)
// ─────────────────────────────────────────────

import 'dart:convert';

// =====================================================
// HELPERS MAP / FECHAS / NORMALIZACIÓN
// =====================================================

DateTime _dtFrom(dynamic v) {
  if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    final p = DateTime.tryParse(v);
    if (p != null) return p;
    final asInt = int.tryParse(v);
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _dtToIso(DateTime d) => d.toIso8601String();

Map<String, double> _mapDouble(dynamic raw) {
  if (raw is Map) {
    return raw.map((k, v) {
      final key = k.toString();
      if (v is num) return MapEntry(key, v.toDouble());
      if (v is String) return MapEntry(key, double.tryParse(v) ?? 0.0);
      return MapEntry(key, 0.0);
    });
  }
  return <String, double>{};
}

String _norm(String s) => s.trim();
String _normDigits(String s) => s.replaceAll(RegExp(r'\D+'), '').trim();

// =====================================================
// MODELO PRINCIPAL DE ALUMNO
// =====================================================

class Alumno {
  final String documento;
  String nombre;
  String apellido;
  DateTime fechaNacimiento;

  String email;
  String telefono;

  String? fotoPerfilLocalPath;

  Alumno({
    required String documento,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.email,
    required this.telefono,
    this.fotoPerfilLocalPath,
  }) : documento = _normDigits(documento);

  String get nombreCompleto => '${nombre.trim()} ${apellido.trim()}'.trim();

  Alumno copyWith({
    String? documento,
    String? nombre,
    String? apellido,
    DateTime? fechaNacimiento,
    String? email,
    String? telefono,
    String? fotoPerfilLocalPath,
    bool clearFotoPerfilLocalPath = false,
  }) {
    return Alumno(
      documento: documento ?? this.documento,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      fotoPerfilLocalPath: clearFotoPerfilLocalPath
          ? null
          : (fotoPerfilLocalPath ?? this.fotoPerfilLocalPath),
    );
  }

  Map<String, dynamic> toMap() => {
    'documento': documento,
    'nombre': _norm(nombre),
    'apellido': _norm(apellido),
    'fechaNacimiento': _dtToIso(fechaNacimiento),
    'email': _norm(email),
    'telefono': _norm(telefono),
    'fotoPerfilLocalPath': fotoPerfilLocalPath,
  };

  factory Alumno.fromMap(Map<String, dynamic> map) => Alumno(
    documento: map['documento']?.toString() ?? '',
    nombre: map['nombre']?.toString() ?? '',
    apellido: map['apellido']?.toString() ?? '',
    fechaNacimiento: _dtFrom(map['fechaNacimiento']),
    email: map['email']?.toString() ?? '',
    telefono: map['telefono']?.toString() ?? '',
    fotoPerfilLocalPath: map['fotoPerfilLocalPath']?.toString(),
  );

  String toJsonString() => jsonEncode(toMap());
  factory Alumno.fromJsonString(String s) => Alumno.fromMap(jsonDecode(s));

  String toPacked() => jsonEncode(toMap());

  factory Alumno.fromPacked(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return Alumno.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw FormatException('Alumno.fromPacked: formato inválido');
  }
}

// =====================================================
// USUARIO / LOGIN ALUMNO
// =====================================================

class AlumnoUsuario {
  final String documento;
  final String email;
  final String passwordHash;

  AlumnoUsuario({
    required String documento,
    required this.email,
    required this.passwordHash,
  }) : documento = _normDigits(documento);

  Map<String, dynamic> toMap() => {
    'documento': documento,
    'email': _norm(email),
    'passwordHash': passwordHash,
  };

  factory AlumnoUsuario.fromMap(Map<String, dynamic> map) => AlumnoUsuario(
    documento: map['documento']?.toString() ?? '',
    email: map['email']?.toString() ?? '',
    passwordHash: map['passwordHash']?.toString() ?? '',
  );
}

// =====================================================
// RECUPERACIÓN DE CONTRASEÑA
// =====================================================

class RecuperacionPasswordAlumno {
  final String documento;
  final String email;
  final DateTime fechaSolicitud;

  RecuperacionPasswordAlumno({
    required String documento,
    required this.email,
    required this.fechaSolicitud,
  }) : documento = _normDigits(documento);

  Map<String, dynamic> toMap() => {
    'documento': documento,
    'email': _norm(email),
    'fechaSolicitud': _dtToIso(fechaSolicitud),
  };

  factory RecuperacionPasswordAlumno.fromMap(Map<String, dynamic> map) =>
      RecuperacionPasswordAlumno(
        documento: map['documento']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        fechaSolicitud: _dtFrom(map['fechaSolicitud']),
      );
}

// =====================================================
// AGENDA – EVENTO
// =====================================================

class EventoAgendaAlumno {
  final String id;
  final String titulo;
  final DateTime fecha;
  final String tipo;
  final String institucion;
  final bool esExtracurricular;

  EventoAgendaAlumno({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.tipo,
    required this.institucion,
    required this.esExtracurricular,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': _norm(titulo),
    'fecha': _dtToIso(fecha),
    'tipo': _norm(tipo),
    'institucion': _norm(institucion),
    'esExtracurricular': esExtracurricular,
  };

  factory EventoAgendaAlumno.fromMap(Map<String, dynamic> map) =>
      EventoAgendaAlumno(
        id: map['id']?.toString() ?? '',
        titulo: map['titulo']?.toString() ?? '',
        fecha: _dtFrom(map['fecha']),
        tipo: map['tipo']?.toString() ?? '',
        institucion: map['institucion']?.toString() ?? '',
        esExtracurricular: map['esExtracurricular'] == true,
      );
}

// =====================================================
// INSCRIPCIÓN DEL ALUMNO
// =====================================================

class InscripcionAlumno {
  final String alumnoDocumento;
  final String institucionId;
  final String actividadNombre;
  final bool esCurricular;
  final DateTime fechaInscripcion;

  InscripcionAlumno({
    required String alumnoDocumento,
    required this.institucionId,
    required this.actividadNombre,
    required this.esCurricular,
    required this.fechaInscripcion,
  }) : alumnoDocumento = _normDigits(alumnoDocumento);

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'institucionId': _norm(institucionId),
    'actividadNombre': _norm(actividadNombre),
    'esCurricular': esCurricular,
    'fechaInscripcion': _dtToIso(fechaInscripcion),
  };

  factory InscripcionAlumno.fromMap(Map<String, dynamic> map) =>
      InscripcionAlumno(
        alumnoDocumento: map['alumnoDocumento']?.toString() ?? '',
        institucionId: map['institucionId']?.toString() ?? '',
        actividadNombre: map['actividadNombre']?.toString() ?? '',
        esCurricular: map['esCurricular'] == true,
        fechaInscripcion: _dtFrom(map['fechaInscripcion']),
      );
}

// =====================================================
// PROGRESO ACADÉMICO
// =====================================================

class ProgresoAlumno {
  final String alumnoDocumento;
  final String institucion;
  final String actividad;
  final double porcentaje;
  final DateTime ultimaActualizacion;

  ProgresoAlumno({
    required String alumnoDocumento,
    required this.institucion,
    required this.actividad,
    required this.porcentaje,
    required this.ultimaActualizacion,
  }) : alumnoDocumento = _normDigits(alumnoDocumento);

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'institucion': _norm(institucion),
    'actividad': _norm(actividad),
    'porcentaje': porcentaje,
    'ultimaActualizacion': _dtToIso(ultimaActualizacion),
  };

  factory ProgresoAlumno.fromMap(Map<String, dynamic> map) => ProgresoAlumno(
    alumnoDocumento: map['alumnoDocumento']?.toString() ?? '',
    institucion: map['institucion']?.toString() ?? '',
    actividad: map['actividad']?.toString() ?? '',
    porcentaje: (map['porcentaje'] is num)
        ? (map['porcentaje'] as num).toDouble()
        : double.tryParse(map['porcentaje']?.toString() ?? '') ?? 0.0,
    ultimaActualizacion: _dtFrom(map['ultimaActualizacion']),
  );
}

// =====================================================
// BOLETINES
// =====================================================

class BoletinAlumno {
  final String alumnoDocumento;
  final String institucion;
  final String actividad;
  final int anio;
  final String periodo;
  final Map<String, double> calificaciones;
  final String observaciones;

  BoletinAlumno({
    required String alumnoDocumento,
    required this.institucion,
    required this.actividad,
    required this.anio,
    required this.periodo,
    required this.calificaciones,
    required this.observaciones,
  }) : alumnoDocumento = _normDigits(alumnoDocumento);

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'institucion': _norm(institucion),
    'actividad': _norm(actividad),
    'anio': anio,
    'periodo': _norm(periodo),
    'calificaciones': calificaciones,
    'observaciones': _norm(observaciones),
  };

  factory BoletinAlumno.fromMap(Map<String, dynamic> map) => BoletinAlumno(
    alumnoDocumento: map['alumnoDocumento']?.toString() ?? '',
    institucion: map['institucion']?.toString() ?? '',
    actividad: map['actividad']?.toString() ?? '',
    anio: (map['anio'] is num)
        ? (map['anio'] as num).toInt()
        : int.tryParse(map['anio']?.toString() ?? '') ?? 0,
    periodo: map['periodo']?.toString() ?? '',
    calificaciones: _mapDouble(map['calificaciones']),
    observaciones: map['observaciones']?.toString() ?? '',
  );

  String toPacked() => jsonEncode(toMap());

  factory BoletinAlumno.fromPacked(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return BoletinAlumno.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw FormatException('BoletinAlumno.fromPacked: formato inválido');
  }
}

// =====================================================
// DOCUMENTACIÓN DEL ALUMNO
// =====================================================

class DocumentoAlumno {
  final String alumnoDocumento;
  final String tipo;
  final String archivoLocalPath;
  final bool aprobado;

  DocumentoAlumno({
    required String alumnoDocumento,
    required this.tipo,
    required this.archivoLocalPath,
    required this.aprobado,
  }) : alumnoDocumento = _normDigits(alumnoDocumento);

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'tipo': _norm(tipo),
    'archivoLocalPath': archivoLocalPath,
    'aprobado': aprobado,
  };

  factory DocumentoAlumno.fromMap(Map<String, dynamic> map) => DocumentoAlumno(
    alumnoDocumento: map['alumnoDocumento']?.toString() ?? '',
    tipo: map['tipo']?.toString() ?? '',
    archivoLocalPath: map['archivoLocalPath']?.toString() ?? '',
    aprobado: map['aprobado'] == true,
  );
}

// =====================================================
// DOCUMENTOS PENDIENTES
// =====================================================

class DocumentoPendienteAlumno {
  final String alumnoDocumento;
  final String institucion;
  final String documentoRequerido;
  final bool presentado;

  DocumentoPendienteAlumno({
    required String alumnoDocumento,
    required this.institucion,
    required this.documentoRequerido,
    required this.presentado,
  }) : alumnoDocumento = _normDigits(alumnoDocumento);

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'institucion': _norm(institucion),
    'documentoRequerido': _norm(documentoRequerido),
    'presentado': presentado,
  };

  factory DocumentoPendienteAlumno.fromMap(Map<String, dynamic> map) =>
      DocumentoPendienteAlumno(
        alumnoDocumento: map['alumnoDocumento']?.toString() ?? '',
        institucion: map['institucion']?.toString() ?? '',
        documentoRequerido: map['documentoRequerido']?.toString() ?? '',
        presentado: map['presentado'] == true,
      );
}

// =====================================================
// TÍTULOS Y CERTIFICADOS
// =====================================================

class TituloAlumno {
  final String alumnoDocumento;
  final String institucion;
  final String titulo;
  final DateTime fechaEmision;
  final String pdfLocalPath;

  TituloAlumno({
    required String alumnoDocumento,
    required this.institucion,
    required this.titulo,
    required this.fechaEmision,
    required this.pdfLocalPath,
  }) : alumnoDocumento = _normDigits(alumnoDocumento);

  Map<String, dynamic> toMap() => {
    'alumnoDocumento': alumnoDocumento,
    'institucion': _norm(institucion),
    'titulo': _norm(titulo),
    'fechaEmision': _dtToIso(fechaEmision),
    'pdfLocalPath': pdfLocalPath,
  };

  factory TituloAlumno.fromMap(Map<String, dynamic> map) => TituloAlumno(
    alumnoDocumento: map['alumnoDocumento']?.toString() ?? '',
    institucion: map['institucion']?.toString() ?? '',
    titulo: map['titulo']?.toString() ?? '',
    fechaEmision: _dtFrom(map['fechaEmision']),
    pdfLocalPath: map['pdfLocalPath']?.toString() ?? '',
  );
}
