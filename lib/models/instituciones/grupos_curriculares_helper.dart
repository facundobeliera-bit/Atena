import 'grupo_curricular.dart';

/// Formatos soportados:
///
/// 1) Completo:
/// "1A|30|10;1B|25|25"
/// nombreCurso|cuposTotales|cuposOcupados
///
/// 2) Simple:
/// "1A;1B;2A"
/// (usa valores por defecto)
List<GrupoCurricular> decodeGruposCurriculares(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return [];

  final items = t.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);

  final out = <GrupoCurricular>[];

  for (final it in items) {
    if (it.contains('|')) {
      final parts = it.split('|').map((e) => e.trim()).toList();

      final nombre = (parts.isNotEmpty ? (parts[0]).trim() : '').trim();
      if (nombre.isEmpty) continue;

      final cuposTotales = parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30;
      final cuposOcupados = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

      out.add(
        GrupoCurricular(
          nombreCurso: nombre, // ✅ siempre String no-null
          cuposTotales: cuposTotales,
          cuposOcupados: cuposOcupados,
        ),
      );
    } else {
      final nombre = it.trim();
      if (nombre.isEmpty) continue;

      out.add(
        GrupoCurricular(
          nombreCurso: nombre, // ✅ siempre String no-null
        ),
      );
    }
  }

  return out;
}
