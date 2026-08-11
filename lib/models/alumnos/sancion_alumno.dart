class SancionAlumno {
  final String id;
  final String alumnoDocumento;
  final String institucionId;

  final String motivo; // ej: "Inasistencia", "Conducta", etc.
  final String? detalle; // texto libre opcional
  final String? tipo; // ej: "Apercibimiento", "Suspensión", etc.

  final DateTime fecha;
  final DateTime? hasta; // si es suspensión/medida con fin
  final bool activa;

  SancionAlumno({
    required this.id,
    required this.alumnoDocumento,
    required this.institucionId,
    required this.motivo,
    required this.fecha,
    this.detalle,
    this.tipo,
    this.hasta,
    this.activa = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'alumnoDocumento': alumnoDocumento,
    'institucionId': institucionId,
    'motivo': motivo,
    'detalle': detalle,
    'tipo': tipo,
    'fecha': fecha.toIso8601String(),
    'hasta': hasta?.toIso8601String(),
    'activa': activa,
  };

  factory SancionAlumno.fromMap(Map<String, dynamic> m) => SancionAlumno(
    id: (m['id'] ?? '').toString(),
    alumnoDocumento: (m['alumnoDocumento'] ?? '').toString(),
    institucionId: (m['institucionId'] ?? '').toString(),
    motivo: (m['motivo'] ?? '').toString(),
    detalle: m['detalle']?.toString(),
    tipo: m['tipo']?.toString(),
    fecha: DateTime.tryParse((m['fecha'] ?? '').toString()) ?? DateTime.now(),
    hasta: (m['hasta'] == null)
        ? null
        : DateTime.tryParse((m['hasta'] ?? '').toString()),
    activa: (m['activa'] is bool) ? (m['activa'] as bool) : true,
  );
}
