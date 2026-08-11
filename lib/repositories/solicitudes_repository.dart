// // lib/repositories/solicitudes_repository.dart
//
// ATENA – SOLICITUDES REPOSITORY (CANÓNICO)
// Contrato estable para persistencia/queries de solicitudes.
//
// HARDENING (enero 2026):
// - Comentarios alineados: la sección “Institución (canónico)” opera sobre
//   SolicitudAlumno (fuente de verdad).
// - La sección “Institución (compat)” mantiene SolicitudVacanteInstitucion
//   SOLO por compilación / legado.
//
// Nota de diseño:
// - Este repo es intencionalmente “thin”: sin lógica de negocio.
// - La lógica de dedupe, validación moduleKey, validación de transiciones de estado,
//   reglas de permisos y consistencia canónica vive en el modelo/service.
// - Implementaciones deben TRIM de ids en límites de persistencia para evitar
//   “ghost keys” por espacios (sin mutar el modelo en memoria).
//
// Contrato canónico:
// - ownerAccountId: cuentaId (owner) fuente de verdad a nivel INBOX.
// - perfilId: id del perfil (Alumno) fuente de verdad de vinculación UI.
// - institucionId: para solicitudes, es el perfilId de institución (regla canónica).
//
// Importante:
// - La institución consume solicitudes del ALUMNO (SolicitudAlumno) filtradas/indexadas
//   por institucionId (= perfilId de institución).

import '../models/solicitudes/solicitud_alumno.dart';
import '../models/solicitudes/solicitud_vacante_institucion.dart';

abstract class SolicitudesRepository {
  // =========================
  // Alumno (CANÓNICO)
  // =========================

  Future<void> saveSolicitudAlumno(SolicitudAlumno s);
  Future<SolicitudAlumno?> getSolicitudAlumnoById(String id);
  Future<void> deleteSolicitudAlumnoById(String id);

  /// Fuente global (prototipo): todas las solicitudes alumno persistidas.
  Future<List<SolicitudAlumno>> getAllSolicitudesAlumno();

  /// Solicitudes asociadas a un perfil (perfilId canónico).
  Future<List<SolicitudAlumno>> getSolicitudesPerfil(String perfilId);

  /// Solicitudes asociadas a un owner (ownerAccountId canónico).
  Future<List<SolicitudAlumno>> getSolicitudesOwner(String ownerAccountId);

  // =========================
  // Institución (CANÓNICO)
  // =========================

  /// Para institución (institucionId = perfilId institución).
  Future<List<SolicitudAlumno>> getSolicitudesInstitucion(String institucionId);

  /// Listado directo de pendientes para institución (sin filtrar en memoria).
  Future<List<SolicitudAlumno>> getSolicitudesInstitucionPendientes(
    String institucionId,
  );

  // =========================
  // Institución (COMPAT / LEGACY)
  // =========================
  //
  // ⚠️ No es fuente de verdad. Mantener solo para no romper compilación
  // mientras exista código legacy de instituciones (read-only idealmente).

  Future<void> saveSolicitudInstitucion(SolicitudVacanteInstitucion s);
  Future<SolicitudVacanteInstitucion?> getSolicitudInstitucionById(String id);
  Future<void> deleteSolicitudInstitucionById(String id);

  // =========================
  // Rebuild / migración
  // =========================
  //
  // Se usa cuando:
  // - cambian reglas de indexado
  // - hay migraciones/emancipaciones que requieren recomputar índices
  // - hay cleanup de claves legacy
  //
  // Debe ser idempotente y best-effort.

  Future<void> rebuildIndexes();
}
