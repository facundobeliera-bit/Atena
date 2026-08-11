class BecaAlumno {
  final String id;
  final String alumnoDocumento;
  final String institucionId;

  final String nombre;
  final String? descripcion;

  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final bool activa;

  BecaAlumno({
    required this.id,
    required this.alumnoDocumento,
    required this.institucionId,
    required this.nombre,
    required this.fechaInicio,
    this.descripcion,
    this.fechaFin,
    this.activa = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'alumnoDocumento': alumnoDocumento,
    'institucionId': institucionId,
    'nombre': nombre,
    'descripcion': descripcion,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin?.toIso8601String(),
    'activa': activa,
  };

  factory BecaAlumno.fromMap(Map<String, dynamic> m) => BecaAlumno(
    id: (m['id'] ?? '').toString(),
    alumnoDocumento: (m['alumnoDocumento'] ?? '').toString(),
    institucionId: (m['institucionId'] ?? '').toString(),
    nombre: (m['nombre'] ?? '').toString(),
    descripcion: m['descripcion']?.toString(),
    fechaInicio:
        DateTime.tryParse((m['fechaInicio'] ?? '').toString()) ??
        DateTime.now(),
    fechaFin: (m['fechaFin'] == null)
        ? null
        : DateTime.tryParse((m['fechaFin'] ?? '').toString()),
    activa: (m['activa'] is bool) ? m['activa'] as bool : true,
  );
}
