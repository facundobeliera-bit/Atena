// ─────────────────────────────────────────────
// ATENA – MODELO INSTITUCIÓN PERFIL (LEGACY / Packed)
// Archivo: lib/models/instituciones/institucion_perfil.dart
// ─────────────────────────────────────────────

import 'dart:convert';

class InstitucionPerfil {
  final String nombre;

  /// En tu pantalla AlumnoSeleccionGrupoPage lo usás así:
  /// perfil.gruposCurriculares.trim().isNotEmpty
  /// decodeGruposCurriculares(perfil.gruposCurriculares)
  final String gruposCurriculares;

  const InstitucionPerfil({required this.nombre, this.gruposCurriculares = ''});

  // ------------------------------------------------------------
  // SERIALIZACIÓN (Map / Packed) para StorageService.getStringList
  // ------------------------------------------------------------

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'gruposCurriculares': gruposCurriculares,
  };

  factory InstitucionPerfil.fromMap(Map<String, dynamic> m) =>
      InstitucionPerfil(
        nombre: (m['nombre'] ?? '').toString(),
        gruposCurriculares: (m['gruposCurriculares'] ?? '').toString(),
      );

  String toPacked() => jsonEncode(toMap());

  factory InstitucionPerfil.fromPacked(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return InstitucionPerfil.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw FormatException('InstitucionPerfil.fromPacked: formato inválido');
  }
}
