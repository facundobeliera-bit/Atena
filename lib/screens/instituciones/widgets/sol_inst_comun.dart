// lib/screens/instituciones/widgets/sol_inst_comun.dart
//
// ATENA – Piezas compartidas por Solicitudes y Alumnos de la institución:
// búsqueda por nombre o DNI, resumen del alumno, orden de las vacantes y
// nombres de archivo para los PDF.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_labels.dart';

/// true si la solicitud coincide con la búsqueda por nombre, apellido o DNI
/// (sin distinguir mayúsculas ni tildes; el DNI puede escribirse con puntos).
bool solInstCoincide(Solicitud s, String consulta) {
  final terminos = normalizarBusqueda(
    consulta.replaceAll('.', ''),
  ).split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
  if (terminos.isEmpty) return true;
  final a = s.alumno;
  final texto = normalizarBusqueda(
    '${a.nombre} ${a.apellido} ${a.dni.replaceAll(RegExp(r'\D'), '')}',
  );
  return terminos.every(texto.contains);
}

/// "11 años · DNI 45123456".
String solInstResumenAlumno(AppLocalizations t, AlumnoSnapshot a) {
  final edad = a.edad;
  final dni = a.dni.trim();
  return [
    if (edad != null) t.lblEdadAnios(edad),
    if (dni.isNotEmpty) t.solInstDni(dni),
  ].join(' · ');
}

/// "1° grado · A · Primaria".
String solInstNombreOferta(AppLocalizations t, Oferta o) =>
    '${o.nombreCompleto} · ${t.categoriaOferta(o)}';

/// Orden alfabético por apellido y nombre (sin tildes).
int solInstPorApellido(Solicitud a, Solicitud b) => normalizarBusqueda(
  a.alumno.apellidoNombre,
).compareTo(normalizarBusqueda(b.alumno.apellidoNombre));

/// Orden de las vacantes: curriculares por nivel, después extracurriculares
/// por bloque y, dentro de cada grupo, por nombre.
int solInstOrdenOfertas(Oferta a, Oferta b) {
  if (a.tipo != b.tipo) return a.tipo.index.compareTo(b.tipo.index);
  final na = a.nivel?.index ?? a.bloque?.index ?? 0;
  final nb = b.nivel?.index ?? b.bloque?.index ?? 0;
  if (na != nb) return na.compareTo(nb);
  return normalizarBusqueda(
    a.nombreCompleto,
  ).compareTo(normalizarBusqueda(b.nombreCompleto));
}

/// Nombre de archivo seguro para compartir: "comprobante-gomez-lucia.pdf".
String solInstNombreArchivo(String prefijo, String nombre) {
  final base = normalizarBusqueda(
    '$prefijo $nombre',
  ).replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return '${base.isEmpty ? prefijo : base}.pdf';
}

/// Indicador de progreso chico para botones.
class SolInstSpinner extends StatelessWidget {
  final double size;

  const SolInstSpinner({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: const CircularProgressIndicator(strokeWidth: 2.2),
  );
}

/// Campo de búsqueda por nombre o DNI con botón para limpiar.
class SolInstBuscador extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SolInstBuscador({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, valor, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: t.solInstBuscarHint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: valor.text.isEmpty
              ? null
              : IconButton(
                  tooltip: t.solInstLimpiarBusqueda,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}
