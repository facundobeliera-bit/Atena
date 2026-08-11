import 'dart:convert';

class TituloAcademicoAlumno {
  final String id;

  final String alumnoDocumento;
  final String institucionId;

  final String titulo; // ej: "Bachiller", "Técnico", "Certificado Inglés B2"
  final String? entidadEmisora; // escuela / instituto / organismo
  final DateTime fechaEmision;

  final String? archivoLocalPath; // opcional: PDF/imagen en el dispositivo
  final Map<String, dynamic>? extras;

  TituloAcademicoAlumno({
    required this.id,
    required this.alumnoDocumento,
    required this.institucionId,
    required this.titulo,
    required this.fechaEmision,
    this.entidadEmisora,
    this.archivoLocalPath,
    this.extras,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'alumnoDocumento': alumnoDocumento,
    'institucionId': institucionId,
    'titulo': titulo,
    'entidadEmisora': entidadEmisora,
    'fechaEmision': fechaEmision.toIso8601String(),
    'archivoLocalPath': archivoLocalPath,
    'extras': extras,
  };

  factory TituloAcademicoAlumno.fromMap(Map<String, dynamic> m) =>
      TituloAcademicoAlumno(
        id: (m['id'] ?? '').toString(),
        alumnoDocumento: (m['alumnoDocumento'] ?? '').toString(),
        institucionId: (m['institucionId'] ?? '').toString(),
        titulo: (m['titulo'] ?? '').toString(),
        entidadEmisora: m['entidadEmisora']?.toString(),
        fechaEmision:
            DateTime.tryParse((m['fechaEmision'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        archivoLocalPath: m['archivoLocalPath']?.toString(),
        extras: (m['extras'] is Map)
            ? Map<String, dynamic>.from(m['extras'] as Map)
            : null,
      );

  String toPacked() => jsonEncode(toMap());

  factory TituloAcademicoAlumno.fromPacked(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return TituloAcademicoAlumno.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw FormatException('TituloAcademicoAlumno.fromPacked: inválido');
  }
}
