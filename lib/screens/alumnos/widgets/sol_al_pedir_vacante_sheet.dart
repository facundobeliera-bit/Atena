// lib/screens/alumnos/widgets/sol_al_pedir_vacante_sheet.dart
//
// ATENA – Hoja para pedir una vacante: resumen de la oferta y del alumno,
// aviso si la edad no coincide (se puede enviar igual) y mensaje opcional
// para la institución. Devuelve la solicitud creada.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/cuentas/cuenta.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';
import 'explorar_comun.dart';

/// Muestra la hoja y devuelve la solicitud creada (null si se cerró).
Future<Solicitud?> mostrarPedirVacanteSheet(
  BuildContext context, {
  required String cuentaId,
  required PerfilAlumno alumno,
  Uint8List? fotoAlumno,
  required String institucionNombre,
  required OfertaConCupo oferta,
}) {
  return showModalBottomSheet<Solicitud>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AtenaRoleTheme(
      role: AtenaRole.alumno,
      child: _PedirVacanteSheet(
        cuentaId: cuentaId,
        alumno: alumno,
        fotoAlumno: fotoAlumno,
        institucionNombre: institucionNombre,
        oferta: oferta,
      ),
    ),
  );
}

class _PedirVacanteSheet extends StatefulWidget {
  final String cuentaId;
  final PerfilAlumno alumno;
  final Uint8List? fotoAlumno;
  final String institucionNombre;
  final OfertaConCupo oferta;

  const _PedirVacanteSheet({
    required this.cuentaId,
    required this.alumno,
    required this.fotoAlumno,
    required this.institucionNombre,
    required this.oferta,
  });

  @override
  State<_PedirVacanteSheet> createState() => _PedirVacanteSheetState();
}

class _PedirVacanteSheetState extends State<_PedirVacanteSheet> {
  static const int _maxMensaje = 500;

  final _mensaje = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _mensaje.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      // Si la institución retiró la vacante (o se dio de baja) mientras la
      // hoja estaba abierta, no se envía el pedido.
      final mostrada = widget.oferta.oferta;
      final vigente = await OfertasRepo.instance.obtener(
        mostrada.institucionId,
        mostrada.id,
      );
      if (vigente == null) {
        throw const AtenaException(AtenaError.ofertaInactiva);
      }
      final creada = await SolicitudesRepo.instance.crear(
        alumno: AlumnosRepo.instance.snapshot(widget.cuentaId, widget.alumno),
        institucionNombre: widget.institucionNombre,
        oferta: vigente,
        mensaje: _mensaje.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(creada);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = coreErrorText(t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final item = widget.oferta;
    final o = item.oferta;
    final p = widget.alumno;

    final nacimiento = p.fechaNacimiento;
    final edad = nacimiento.millisecondsSinceEpoch == 0
        ? null
        : edadEnAnios(nacimiento);
    final primerNombre = p.nombre.trim().isEmpty
        ? p.displayName
        : p.nombre.trim();
    final fueraDeEdad = edad != null && !o.aceptaEdad(edad);
    final horario = o.horario.trim();
    final dias = o.dias.trim();
    final arancel = o.arancel.trim();
    final rango = explorarRangoEdad(t, o.edadMinima, o.edadMaxima);
    final error = (_error ?? '').trim();

    return PopScope(
      canPop: !_enviando,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.solAlPedirTitulo, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                widget.institucionNombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: AtenaRadius.card,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AtenaIconBadge(icon: iconoOferta(o), size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.nombreCompleto,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                t.categoriaOferta(o),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        ExplorarDato(
                          icon: Icons.schedule_rounded,
                          texto: [
                            t.turno(o.turno),
                            if (horario.isNotEmpty) horario,
                          ].join(' · '),
                        ),
                        if (dias.isNotEmpty)
                          ExplorarDato(
                            icon: Icons.calendar_month_rounded,
                            texto: dias,
                          ),
                        if (rango.isNotEmpty)
                          ExplorarDato(
                            icon: Icons.cake_rounded,
                            texto: rango,
                            color: fueraDeEdad
                                ? AtenaBrand.of(context).warning
                                : null,
                          ),
                        if (arancel.isNotEmpty)
                          ExplorarDato(
                            icon: Icons.payments_rounded,
                            texto: t.explorarArancel(arancel),
                          ),
                        ExplorarDato(
                          icon: Icons.event_seat_rounded,
                          texto: t.lblCuposDeTotal(
                            item.disponibles,
                            o.cupoTotal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AtenaAvatar(
                    name: p.displayName,
                    imageBytes: widget.fotoAlumno,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.solAlAlumno, style: theme.textTheme.bodySmall),
                        Text(
                          [
                            p.displayName,
                            if (edad != null) t.lblEdadAnios(edad),
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (edad != null && fueraDeEdad) ...[
                const SizedBox(height: 16),
                AtenaBanner(
                  tone: AtenaBannerTone.warning,
                  title: t.solAlFueraDeEdadTitulo,
                  message: t.solAlFueraDeEdadMensaje(
                    primerNombre,
                    t.lblEdadAnios(edad),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _mensaje,
                enabled: !_enviando,
                maxLength: _maxMensaje,
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: t.solAlMensajeLabel,
                  helperText: t.solAlMensajeAyuda,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.solAlComoSigue,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 16),
                AtenaBanner(tone: AtenaBannerTone.error, message: error),
              ],
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: t.solAlEnviar,
                loadingLabel: t.commonSending,
                loading: _enviando,
                onPressed: _enviar,
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                child: Text(t.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
