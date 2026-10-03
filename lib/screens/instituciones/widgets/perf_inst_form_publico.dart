// lib/screens/instituciones/widgets/perf_inst_form_publico.dart
//
// Pestaña "Perfil público": lo que ven las familias (imágenes, descripción,
// horarios, contacto, redes y servicios).

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';
import 'perf_inst_campos.dart';
import 'perf_inst_servicios.dart';

class PerfInstFormPublico extends StatelessWidget {
  final PerfInstCampos campos;
  final bool habilitado;

  /// Indicador de completitud (arriba de todo).
  final Widget completitud;

  /// Editor del logo y galería de fotos: se guardan aparte, al momento.
  final Widget logo;
  final Widget galeria;

  final List<String> servicios;
  final ValueChanged<List<String>> onServicios;

  const PerfInstFormPublico({
    super.key,
    required this.campos,
    required this.habilitado,
    required this.completitud,
    required this.logo,
    required this.galeria,
    required this.servicios,
    required this.onServicios,
  });

  static const int _maxDescripcion = 800;
  static const int _maxLinea = 120;
  static const int _maxEnlace = 200;
  static const int _maxServicios = 20;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const gap = SizedBox(height: 14);
    const seccion = SizedBox(height: AtenaSpace.md);
    final redes = [
      (
        campo: campos.instagram,
        label: t.perfInstInstagram,
        icon: Icons.camera_alt_outlined,
      ),
      (campo: campos.facebook, label: t.perfInstFacebook, icon: Icons.facebook),
      (
        campo: campos.youtube,
        label: t.perfInstYoutube,
        icon: Icons.smart_display_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        completitud,
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecImagenes,
          children: [logo, const Divider(height: 36), galeria],
        ),
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecSobre,
          children: [
            TextFormField(
              controller: campos.descripcion,
              enabled: habilitado,
              minLines: 4,
              maxLines: 10,
              maxLength: _maxDescripcion,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.perfInstDescripcion,
                hintText: t.perfInstDescripcionHint,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecHorarios,
          children: [
            PerfInstCampo(
              controller: campos.horarioAtencion,
              label: t.perfInstHorarioAtencion,
              hint: t.perfInstHorarioAtencionHint,
              icon: Icons.schedule_rounded,
              habilitado: habilitado,
              mayusculas: TextCapitalization.sentences,
              largoMaximo: _maxLinea,
            ),
            gap,
            PerfInstCampo(
              controller: campos.horarioClases,
              label: t.perfInstHorarioClases,
              hint: t.perfInstHorarioClasesHint,
              icon: Icons.school_outlined,
              habilitado: habilitado,
              mayusculas: TextCapitalization.sentences,
              largoMaximo: _maxLinea,
            ),
          ],
        ),
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecContacto,
          ayuda: t.perfInstSecContactoAyuda,
          children: [
            PerfInstCampo(
              controller: campos.telefonoPublico,
              label: t.commonPhone,
              icon: Icons.phone_outlined,
              habilitado: habilitado,
              teclado: TextInputType.phone,
              formato: [PerfInstFormato.teclasTelefono],
              largoMaximo: 24,
              validator: (v) => PerfInstFormato.telefono(t, v),
            ),
            gap,
            PerfInstCampo(
              controller: campos.whatsapp,
              label: t.perfInstWhatsapp,
              helper: t.perfInstWhatsappAyuda,
              icon: Icons.chat_outlined,
              habilitado: habilitado,
              teclado: TextInputType.phone,
              formato: [PerfInstFormato.teclasTelefono],
              largoMaximo: 24,
              validator: (v) => PerfInstFormato.telefono(t, v),
            ),
            gap,
            PerfInstCampo(
              controller: campos.emailPublico,
              label: t.perfInstEmailFamilias,
              icon: Icons.mail_outline_rounded,
              habilitado: habilitado,
              teclado: TextInputType.emailAddress,
              largoMaximo: _maxLinea,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? null : AuthValidators.email(t, v),
            ),
            gap,
            PerfInstCampo(
              controller: campos.web,
              label: t.perfInstWeb,
              hint: t.perfInstWebHint,
              icon: Icons.language_rounded,
              habilitado: habilitado,
              teclado: TextInputType.url,
              largoMaximo: _maxEnlace,
              validator: (v) => PerfInstFormato.web(t, v),
            ),
          ],
        ),
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecRedes,
          ayuda: t.perfInstSecRedesAyuda,
          children: [
            for (final (i, red) in redes.indexed) ...[
              if (i > 0) gap,
              PerfInstCampo(
                controller: red.campo,
                label: red.label,
                icon: red.icon,
                habilitado: habilitado,
                teclado: TextInputType.url,
                largoMaximo: _maxEnlace,
                validator: (v) => PerfInstFormato.red(t, v),
              ),
            ],
          ],
        ),
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecServicios,
          ayuda: t.perfInstSecServiciosAyuda,
          children: [
            PerfInstServicios(
              servicios: servicios,
              maximo: _maxServicios,
              habilitado: habilitado,
              onChanged: onServicios,
            ),
          ],
        ),
      ],
    );
  }
}
