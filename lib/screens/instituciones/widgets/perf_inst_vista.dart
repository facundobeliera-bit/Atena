// lib/screens/instituciones/widgets/perf_inst_vista.dart
//
// Vista previa de la ficha pública: cómo ven las familias a la institución.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/extracurriculares/bloque_extracurricular.dart';
import '../../../models/instituciones/instituciones_integrado.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';

/// Datos que se muestran en la vista previa.
class PerfInstVista {
  final String nombre;
  final TipoInstitucion tipo;
  final ModalidadCursado modalidad;

  /// "Ciudad, provincia".
  final String ubicacion;
  final String direccion;

  final Uint8List? logo;
  final List<Uint8List> fotos;
  final PerfilPublico publico;
  final List<NivelCurricular> niveles;
  final List<BloqueExtracurricular> bloques;

  const PerfInstVista({
    required this.nombre,
    required this.tipo,
    required this.modalidad,
    required this.ubicacion,
    required this.direccion,
    required this.logo,
    required this.fotos,
    required this.publico,
    required this.niveles,
    required this.bloques,
  });
}

class PerfInstVistaPrevia extends StatelessWidget {
  final PerfInstVista datos;
  final ValueChanged<Uint8List> onVerFoto;

  const PerfInstVistaPrevia({
    super.key,
    required this.datos,
    required this.onVerFoto,
  });

  static IconData _iconoModalidad(ModalidadCursado m) => switch (m) {
    ModalidadCursado.presencial => Icons.apartment_rounded,
    ModalidadCursado.remoto => Icons.laptop_rounded,
    ModalidadCursado.hibrido => Icons.sync_alt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = datos.publico;
    final tenue = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    );

    final medios = <({IconData icon, String label, String valor})>[
      if (p.telefono.isNotEmpty)
        (icon: Icons.phone_rounded, label: t.commonPhone, valor: p.telefono),
      if (p.whatsapp.isNotEmpty)
        (
          icon: Icons.chat_rounded,
          label: t.perfInstWhatsapp,
          valor: p.whatsapp,
        ),
      if (p.email.isNotEmpty)
        (icon: Icons.mail_rounded, label: t.commonEmail, valor: p.email),
      if (p.sitioWeb.isNotEmpty)
        (icon: Icons.language_rounded, label: t.perfInstWeb, valor: p.sitioWeb),
      if (p.instagram.isNotEmpty)
        (
          icon: Icons.camera_alt_rounded,
          label: t.perfInstInstagram,
          valor: p.instagram,
        ),
      if (p.facebook.isNotEmpty)
        (icon: Icons.facebook, label: t.perfInstFacebook, valor: p.facebook),
      if (p.youtube.isNotEmpty)
        (
          icon: Icons.smart_display_rounded,
          label: t.perfInstYoutube,
          valor: p.youtube,
        ),
    ];

    return AtenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Encabezado(datos: datos),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Etiqueta(
                      icon: _iconoModalidad(datos.modalidad),
                      texto: t.modalidad(datos.modalidad),
                    ),
                    for (final n in datos.niveles)
                      _Etiqueta(icon: iconoNivel(n), texto: t.nivel(n)),
                    for (final b in datos.bloques)
                      _Etiqueta(icon: iconoBloque(b), texto: t.bloque(b)),
                  ],
                ),
                _Titulo(t.perfInstSecSobre),
                if (p.descripcion.isEmpty)
                  Text(t.perfInstVistaSinDescripcion, style: tenue)
                else
                  Text(p.descripcion, style: theme.textTheme.bodyMedium),
                if (datos.fotos.isNotEmpty) ...[
                  _Titulo(t.perfInstFotos),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: datos.fotos.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, i) => _Miniatura(
                        bytes: datos.fotos[i],
                        etiqueta: t.perfInstFotoVer(i + 1),
                        onTap: () => onVerFoto(datos.fotos[i]),
                      ),
                    ),
                  ),
                ],
                if (p.horarioAtencion.isNotEmpty ||
                    p.horarioClases.isNotEmpty) ...[
                  _Titulo(t.perfInstSecHorarios),
                  if (p.horarioAtencion.isNotEmpty)
                    AtenaInfoRow(
                      icon: Icons.schedule_rounded,
                      label: t.perfInstHorarioAtencion,
                      value: p.horarioAtencion,
                    ),
                  if (p.horarioClases.isNotEmpty)
                    AtenaInfoRow(
                      icon: Icons.school_rounded,
                      label: t.perfInstHorarioClases,
                      value: p.horarioClases,
                    ),
                ],
                if (p.servicios.isNotEmpty) ...[
                  _Titulo(t.perfInstSecServicios),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in p.servicios)
                        _Etiqueta(icon: Icons.check_rounded, texto: s),
                    ],
                  ),
                ],
                _Titulo(t.perfInstVistaContacto),
                if (datos.direccion.isNotEmpty)
                  AtenaInfoRow(
                    icon: Icons.place_rounded,
                    label: t.perfInstDireccion,
                    value: datos.direccion,
                  ),
                for (final m in medios)
                  AtenaInfoRow(icon: m.icon, label: m.label, value: m.valor),
                if (medios.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t.perfInstVistaSinContacto, style: tenue),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final PerfInstVista datos;

  const _Encabezado({required this.datos});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final suave = Colors.white.withValues(alpha: 0.88);
    final nombre = datos.nombre.isEmpty ? t.perfInstSinNombre : datos.nombre;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: AtenaBrand.of(context).gradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Row(
          children: [
            AtenaAvatar(
              name: nombre,
              imageBytes: datos.logo,
              size: 64,
              ring: true,
              fallbackIcon: Icons.account_balance_rounded,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.tipoInstitucion(datos.tipo),
                    style: theme.textTheme.bodyMedium?.copyWith(color: suave),
                  ),
                  if (datos.ubicacion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_rounded, size: 16, color: suave),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            datos.ubicacion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: suave,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(texto, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _Etiqueta({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = AtenaTone.of(context, theme.colorScheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: AtenaRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tone.foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final Uint8List bytes;
  final String etiqueta;
  final VoidCallback onTap;

  const _Miniatura({
    required this.bytes,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const ancho = 152.0;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.md)),
      child: SizedBox(
        width: ancho,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              cacheWidth: (ancho * 1.2 * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: cs.surfaceContainerHigh,
                child: Icon(
                  Icons.broken_image_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: etiqueta,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
