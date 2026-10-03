// lib/screens/instituciones/widgets/sol_inst_dialogos.dart
//
// ATENA – Diálogos para responder solicitudes: confirmar la vacante (con un
// mensaje opcional para la familia), no aceptarla (con motivo obligatorio y
// motivos frecuentes), dar de baja y aviso de vacante completa.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';

/// Mensaje opcional para la familia al confirmar. null = se canceló.
Future<String?> solInstDialogoConfirmar(BuildContext context, Solicitud s) {
  final t = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (_) => _NotaDialog(
      icono: Icons.check_circle_rounded,
      titulo: t.solInstConfirmarTitulo,
      mensaje: t.solInstConfirmarMsg(s.alumno.nombreCompleto, s.ofertaNombre),
      campo: t.solInstNotaFamiliaLabel,
      ayuda: t.solInstNotaConfirmarHelper,
      accion: t.solInstConfirmarVacante,
    ),
  );
}

/// Motivo (obligatorio) para no aceptar la solicitud. null = se canceló.
Future<String?> solInstDialogoRechazar(BuildContext context, Solicitud s) {
  final t = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (_) => _NotaDialog(
      icono: Icons.cancel_rounded,
      destructivo: true,
      titulo: t.solInstRechazarTitulo,
      mensaje: t.solInstRechazarMsg(s.alumno.nombreCompleto),
      campo: t.solInstMotivoLabel,
      obligatorio: true,
      sugerencias: [
        (
          etiqueta: t.solInstMotivoSinVacantes,
          texto: t.solInstMotivoSinVacantesTexto,
        ),
        (etiqueta: t.solInstMotivoEdad, texto: t.solInstMotivoEdadTexto),
        (
          etiqueta: t.solInstMotivoDocumentacion,
          texto: t.solInstMotivoDocumentacionTexto,
        ),
        (etiqueta: t.solInstMotivoOtro, texto: ''),
      ],
      accion: t.solInstNoAceptar,
    ),
  );
}

/// Confirmación para dar de baja, con mensaje opcional. null = se canceló.
Future<String?> solInstDialogoBaja(BuildContext context, Solicitud s) {
  final t = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (_) => _NotaDialog(
      icono: Icons.person_remove_rounded,
      destructivo: true,
      titulo: t.solInstBajaTitulo(s.alumno.nombreCompleto),
      mensaje: t.solInstBajaMsg(s.ofertaNombre),
      campo: t.solInstNotaFamiliaLabel,
      ayuda: t.solInstNotaBajaHelper,
      accion: t.solInstDarDeBaja,
    ),
  );
}

/// Explica que la vacante no tiene lugares libres. true = quiere ir a Vacantes.
Future<bool> solInstDialogoSinCupo(BuildContext context, Solicitud s) async {
  final t = AppLocalizations.of(context);
  final ir = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.event_busy_rounded,
        color: AtenaBrand.of(ctx).warning,
        size: 30,
      ),
      title: Text(t.solInstSinCupoTitulo),
      content: Text(t.solInstSinCupoMsg(s.ofertaNombre)),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(t.uiClose),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.event_seat_rounded),
          label: Text(t.solInstIrAVacantes),
        ),
      ],
    ),
  );
  return ir == true;
}

typedef _Sugerencia = ({String etiqueta, String texto});

/// Diálogo con un texto para la familia (nota o motivo).
class _NotaDialog extends StatefulWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String campo;
  final String? ayuda;
  final String accion;
  final bool destructivo;
  final bool obligatorio;
  final List<_Sugerencia> sugerencias;

  const _NotaDialog({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.campo,
    this.ayuda,
    required this.accion,
    this.destructivo = false,
    this.obligatorio = false,
    this.sugerencias = const [],
  });

  @override
  State<_NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends State<_NotaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _texto = TextEditingController();
  final _foco = FocusNode();
  int? _sugerencia;

  @override
  void dispose() {
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _elegir(int i) {
    final texto = widget.sugerencias[i].texto;
    setState(() => _sugerencia = i);
    _texto.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
    _foco.requestFocus();
  }

  void _aceptar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_texto.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      scrollable: true,
      icon: Icon(
        widget.icono,
        color: widget.destructivo ? cs.error : cs.primary,
        size: 30,
      ),
      title: Text(widget.titulo),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.mensaje),
              if (widget.sugerencias.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  t.solInstMotivosFrecuentes,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < widget.sugerencias.length; i++)
                      ChoiceChip(
                        label: Text(widget.sugerencias[i].etiqueta),
                        selected: _sugerencia == i,
                        onSelected: (_) => _elegir(i),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              TextFormField(
                controller: _texto,
                focusNode: _foco,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.campo,
                  helperText: widget.ayuda,
                  alignLabelWithHint: true,
                ),
                validator: widget.obligatorio
                    ? (v) => (v ?? '').trim().isEmpty
                          ? t.solInstMotivoRequerido
                          : null
                    : null,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonCancel),
        ),
        FilledButton(
          style: widget.destructivo
              ? FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                )
              : null,
          onPressed: _aceptar,
          child: Text(widget.accion),
        ),
      ],
    );
  }
}
