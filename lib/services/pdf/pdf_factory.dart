// lib/services/pdf/pdf_factory.dart
//
// ATENA – PDF FACTORY (CANÓNICA)
//
// RESPONSABILIDAD:
// - Punto único de creación de PDFs
// - Selección del builder correcto
// - Validación mínima de contexto
//
// NO:
// - Guarda
// - Comparte
// - Accede a UI
//
// USO:
// final pdf = PdfFactory.build(
//   tipo: PdfTipo.solicitudInstitucion,
//   context: PdfContext(...)
// );
//
// ✅ FIX (enero 2026):
// - Nombres consistentes en enum PdfTipo.
// - Validación mínima más clara (errores con code + message).
// - Imports ordenados.
// - Mantiene retorno pw.Document (compat con PdfOutputService.save/share).

import 'package:pdf/widgets.dart' as pw;

import '../../models/alumnos/alumnos_integrados.dart';
import '../../models/solicitudes/solicitud_alumno.dart';

// Builders
import 'pdf_ficha_alumno_institucion.dart';
import 'pdf_ficha_solicitud_institucion.dart';

enum PdfTipo { fichaSolicitudInstitucion, fichaAlumnoInstitucion }

class PdfFactory {
  static pw.Document build({
    required PdfTipo tipo,
    required PdfContext context,
  }) {
    switch (tipo) {
      case PdfTipo.fichaSolicitudInstitucion:
        final s = context.solicitud;
        if (s == null) {
          throw PdfFactoryException(
            'missing_data',
            'SolicitudAlumno requerida para fichaSolicitudInstitucion',
          );
        }

        return PdfFichaSolicitudInstitucion.build(
          solicitud: s,
          generadoPor: context.generadoPor,
        );

      case PdfTipo.fichaAlumnoInstitucion:
        final a = context.alumno;
        if (a == null) {
          throw PdfFactoryException(
            'missing_data',
            'Alumno requerido para fichaAlumnoInstitucion',
          );
        }

        return PdfFichaAlumnoInstitucion.build(
          alumno: a,
          institucionId: context.institucionId ?? '',
          institucionNombre: context.institucionNombre ?? '',
          generadoPor: context.generadoPor,
        );
    }
  }
}

// ─────────────────────────────────────────────
// CONTEXTO UNIFICADO
// ─────────────────────────────────────────────

class PdfContext {
  final String generadoPor;

  // Institución
  final String? institucionId;
  final String? institucionNombre;

  // Alumno
  final Alumno? alumno;

  // Solicitud
  final SolicitudAlumno? solicitud;

  const PdfContext({
    required this.generadoPor,
    this.institucionId,
    this.institucionNombre,
    this.alumno,
    this.solicitud,
  });

  PdfContext copyWith({
    String? generadoPor,
    String? institucionId,
    String? institucionNombre,
    Alumno? alumno,
    SolicitudAlumno? solicitud,
  }) {
    return PdfContext(
      generadoPor: generadoPor ?? this.generadoPor,
      institucionId: institucionId ?? this.institucionId,
      institucionNombre: institucionNombre ?? this.institucionNombre,
      alumno: alumno ?? this.alumno,
      solicitud: solicitud ?? this.solicitud,
    );
  }
}

// ─────────────────────────────────────────────
// EXCEPCIÓN CANÓNICA
// ─────────────────────────────────────────────

class PdfFactoryException implements Exception {
  final String code;
  final String message;

  PdfFactoryException(this.code, this.message);

  @override
  String toString() => 'PdfFactoryException($code): $message';
}
