import 'dart:convert';

class HistorialAcademicoEntrada {
  final String institucionId;
  final String periodo; // ej: "2025", "2025-1", "1er trimestre"
  final String descripcion; // ej: "Promocionó", "Repitió", "Cursó"

  final DateTime fecha; // fecha del evento/registro
  final Map<String, dynamic>? extras; // opcional para ampliar sin romper

  HistorialAcademicoEntrada({
    required this.institucionId,
    required this.periodo,
    required this.descripcion,
    required this.fecha,
    this.extras,
  });

  Map<String, dynamic> toMap() => {
    'institucionId': institucionId,
    'periodo': periodo,
    'descripcion': descripcion,
    'fecha': fecha.toIso8601String(),
    'extras': extras,
  };

  factory HistorialAcademicoEntrada.fromMap(Map<String, dynamic> m) =>
      HistorialAcademicoEntrada(
        institucionId: (m['institucionId'] ?? '').toString(),
        periodo: (m['periodo'] ?? '').toString(),
        descripcion: (m['descripcion'] ?? '').toString(),
        fecha:
            DateTime.tryParse((m['fecha'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        extras: (m['extras'] is Map)
            ? Map<String, dynamic>.from(m['extras'] as Map)
            : null,
      );

  String toPacked() => jsonEncode(toMap());

  factory HistorialAcademicoEntrada.fromPacked(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return HistorialAcademicoEntrada.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    }
    throw FormatException('HistorialAcademicoEntrada.fromPacked: inválido');
  }
}
