import 'package:pdf/widgets.dart' as pw;
import '../../models/alumnos/modulo_educativo.dart';
import 'pdf_base.dart';

/// Renderiza sólo el registro ya autorizado por el servicio de trayectoria.
class PdfTrayectoria {
  static pw.Document build(
    ModuloEducativo module,
    Map<String, dynamic> record,
  ) {
    if (module != ModuloEducativo.boletines &&
        module != ModuloEducativo.titulos) {
      throw ArgumentError('Este módulo no emite documentos PDF.');
    }
    return PdfBase.build(
      PdfBaseParams(
        titulo: module.label,
        subtitulo: 'Documento local de Atena - sin validación oficial externa',
        generadoPor: (record['operadorNombre'] ?? '').toString(),
        ownerAccountId: (record['ownerAccountId'] ?? '').toString(),
        perfilId: (record['perfilId'] ?? '').toString(),
        contenido: [
          pw.Text('Institución: ${record['institucion']}'),
          pw.Text(
            'Alumno: ${record['alumnoNombre'] ?? record['alumnoDocumento']} - Documento: ${record['alumnoDocumento']}',
          ),
          pw.Text(
            'Actividad: ${record['actividad']} - Grupo: ${record['aula']} - Turno: ${record['turno']}',
          ),
          pw.Text(
            'Registro: ${record['id']} - Revisión: ${record['revision']}',
          ),
          pw.SizedBox(height: 12),
          if (module == ModuloEducativo.boletines && record['completo'] != true)
            pw.Text('INCOMPLETO: faltan calificaciones.'),
          for (final field in module.campos.entries) ...[
            pw.Text(
              field.value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (record[field.key] is Map)
              for (final grade in (record[field.key] as Map).entries)
                pw.Text('${grade.key}: ${grade.value}')
            else
              pw.Text((record[field.key] ?? 'Sin información').toString()),
            pw.SizedBox(height: 8),
          ],
          pw.Text(module.aviso),
          pw.Text(
            'Estado: ${record['visibleAlumno'] == true ? 'Compartido con alumno/familia' : 'Interno institucional'}',
          ),
        ],
      ),
    );
  }
}
