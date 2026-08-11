// ─────────────────────────────────────────────
// ATENA – ALUMNOS HELPERS (COMPAT / FALLBACK)
// Archivo: lib/services/alumnos_helpers.dart
// ─────────────────────────────────────────────
//
// Objetivo:
// - Mantener compat mínima para pantallas que aún llaman
//   "cargarAlumnoPorDni".
// - NO reintroduce flujo legacy por DNI.
// - Resolución controlada:
//     DNI → Perfil (CuentaService) → Perfil canónico (AlumnoService).
//

import '../models/alumnos/alumnos_integrados.dart';
import '../services/cuenta_service.dart';
import '../services/alumno_service.dart';

/// -----------------------------------------------------
/// TOP-LEVEL COMPAT
/// Permite: cargarAlumnoPorDni(dni)
/// -----------------------------------------------------
Future<Alumno?> cargarAlumnoPorDni(String dni) async {
  final d = dni.trim();
  if (d.isEmpty) return null;

  // 🔎 Legacy-controlado: DNI → Perfil
  final perfil = await CuentaService.getPerfilAlumnoByDni(d);
  if (perfil == null) return null;

  final owner = (perfil.ownerAccountId ?? '').trim().isNotEmpty
      ? perfil.ownerAccountId!.trim()
      : perfil.cuentaId.trim();

  final perfilId = perfil.id.trim();
  if (owner.isEmpty || perfilId.isEmpty) return null;

  try {
    return await AlumnoService.instance.getPerfilAlumnoByPerfilId(
      ownerAccountId: owner,
      perfilId: perfilId,
    );
  } catch (_) {
    return null;
  }
}

/// -----------------------------------------------------
/// WRAPPER DE CLASE (OPCIONAL / COMPAT)
// Permite: AlumnosHelpers.cargarAlumnoPorDni(...)
/// -----------------------------------------------------
class AlumnosHelpers {
  static Future<Alumno?> cargarAlumnoPorDni(String dni) {
    return cargarAlumnoPorDni(dni);
  }
}
