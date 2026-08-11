class EquivalenciaAcademica {
  final String id;

  final String alumnoDocumento;
  final String institucionOrigenId;
  final String institucionDestinoId;

  final String materiaOrigen;
  final String materiaDestino;

  final String? observacion;
  final bool aprobada;
  final DateTime fecha;

  EquivalenciaAcademica({
    required this.id,
    required this.alumnoDocumento,
    required this.institucionOrigenId,
    required this.institucionDestinoId,
    required this.materiaOrigen,
    required this.materiaDestino,
    required this.fecha,
    this.observacion,
    this.aprobada = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'alumnoDocumento': alumnoDocumento,
    'institucionOrigenId': institucionOrigenId,
    'institucionDestinoId': institucionDestinoId,
    'materiaOrigen': materiaOrigen,
    'materiaDestino': materiaDestino,
    'observacion': observacion,
    'aprobada': aprobada,
    'fecha': fecha.toIso8601String(),
  };

  factory EquivalenciaAcademica.fromMap(Map<String, dynamic> m) =>
      EquivalenciaAcademica(
        id: (m['id'] ?? '').toString(),
        alumnoDocumento: (m['alumnoDocumento'] ?? '').toString(),
        institucionOrigenId: (m['institucionOrigenId'] ?? '').toString(),
        institucionDestinoId: (m['institucionDestinoId'] ?? '').toString(),
        materiaOrigen: (m['materiaOrigen'] ?? '').toString(),
        materiaDestino: (m['materiaDestino'] ?? '').toString(),
        observacion: m['observacion']?.toString(),
        aprobada: (m['aprobada'] is bool) ? (m['aprobada'] as bool) : false,
        fecha:
            DateTime.tryParse((m['fecha'] ?? '').toString()) ?? DateTime.now(),
      );
}
