// lib/screens/alumnos/widgets/cal_al_nota_sheet.dart
//
// ATENA – Calendario del alumno: alta, edición y baja de notas personales
// (título, fecha, hora opcional y detalle).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';
import 'cal_al_items.dart';

/// Resultado de la hoja de notas.
sealed class CalAlNotaResultado {
  const CalAlNotaResultado();
}

final class CalAlNotaGuardada extends CalAlNotaResultado {
  final NotaPersonal nota;

  const CalAlNotaGuardada(this.nota);
}

final class CalAlNotaEliminada extends CalAlNotaResultado {
  const CalAlNotaEliminada();
}

/// Abre la hoja para crear una nota en [fecha] o editar [nota].
Future<CalAlNotaResultado?> mostrarCalAlNota(
  BuildContext context, {
  required String perfilId,
  required DateTime fecha,
  NotaPersonal? nota,
}) {
  return showModalBottomSheet<CalAlNotaResultado>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AtenaRoleTheme(
      role: AtenaRole.alumno,
      child: _NotaSheet(perfilId: perfilId, fecha: fecha, nota: nota),
    ),
  );
}

class _NotaSheet extends StatefulWidget {
  final String perfilId;
  final DateTime fecha;
  final NotaPersonal? nota;

  const _NotaSheet({required this.perfilId, required this.fecha, this.nota});

  @override
  State<_NotaSheet> createState() => _NotaSheetState();
}

class _NotaSheetState extends State<_NotaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _detalle;
  final _fechaCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();

  late DateTime _fecha;
  TimeOfDay? _hora;
  bool _guardando = false;
  bool _eliminando = false;
  String? _error;

  bool get _editando => widget.nota != null;
  bool get _ocupado => _guardando || _eliminando;

  @override
  void initState() {
    super.initState();
    final nota = widget.nota;
    _titulo = TextEditingController(text: nota?.titulo ?? '');
    _detalle = TextEditingController(text: nota?.detalle ?? '');
    _fecha = DateUtils.dateOnly(nota?.fecha ?? widget.fecha);
    _hora = nota == null ? null : calAlHoraNota(nota);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actualizarTextos();
  }

  @override
  void dispose() {
    for (final c in [_titulo, _detalle, _fechaCtrl, _horaCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _actualizarTextos() {
    final hora = _hora;
    // Fecha corta: la larga no entra en el campo en teléfonos angostos.
    _fechaCtrl.text = calAlCapitalizar(AtenaFormat.fechaCorta(context, _fecha));
    _horaCtrl.text = hora == null ? '' : calAlHoraTexto(context, hora);
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fecha = DateUtils.dateOnly(elegida);
      _actualizarTextos();
    });
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _hora = elegida;
      _actualizarTextos();
    });
  }

  void _quitarHora() {
    setState(() {
      _hora = null;
      _actualizarTextos();
    });
  }

  Future<void> _guardar() async {
    if (_ocupado) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context);
    final hora = _hora;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final nota = await CalendarioRepo.instance.guardarNota(
        NotaPersonal(
          id: widget.nota?.id ?? '',
          perfilId: widget.perfilId,
          titulo: _titulo.text.trim(),
          detalle: _detalle.text.trim(),
          fecha: _fecha,
          hora: hora == null
              ? ''
              : '${hora.hour.toString().padLeft(2, '0')}:'
                    '${hora.minute.toString().padLeft(2, '0')}',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(CalAlNotaGuardada(nota));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = coreErrorText(t, e);
      });
    }
  }

  Future<void> _eliminar() async {
    final nota = widget.nota;
    if (nota == null || _ocupado) return;
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.calAlEliminarNotaConfirm,
      message: t.calAlEliminarNotaMensaje(nota.titulo),
      confirmLabel: t.commonDelete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    setState(() {
      _eliminando = true;
      _error = null;
    });
    try {
      await CalendarioRepo.instance.eliminarNota(widget.perfilId, nota.id);
      if (!mounted) return;
      Navigator.of(context).pop(const CalAlNotaEliminada());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eliminando = false;
        _error = coreErrorText(t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final error = _error;
    const gap = SizedBox(height: 14);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AtenaIconBadge(
                      icon: Icons.sticky_note_2_rounded,
                      color: calAlColorNota,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editando ? t.calAlEditarNota : t.calAlNuevaNota,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            t.calAlNotaAyuda,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_editando)
                      IconButton(
                        tooltip: t.calAlEliminarNota,
                        onPressed: _ocupado ? null : _eliminar,
                        icon: _eliminando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                color: cs.error,
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titulo,
                  enabled: !_ocupado,
                  autofocus: !_editando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  decoration: InputDecoration(
                    labelText: t.commonTitle,
                    hintText: t.calAlNotaTituloHint,
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                  ),
                  validator: (v) => AuthValidators.required(t, v),
                ),
                gap,
                TextFormField(
                  controller: _fechaCtrl,
                  enabled: !_ocupado,
                  readOnly: true,
                  enableInteractiveSelection: false,
                  onTap: _elegirFecha,
                  decoration: InputDecoration(
                    labelText: t.commonDate,
                    prefixIcon: const Icon(Icons.event_rounded),
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                  ),
                ),
                gap,
                TextFormField(
                  controller: _horaCtrl,
                  enabled: !_ocupado,
                  readOnly: true,
                  enableInteractiveSelection: false,
                  onTap: _elegirHora,
                  decoration: InputDecoration(
                    labelText: t.calAlNotaHora,
                    prefixIcon: const Icon(Icons.schedule_rounded),
                    suffixIcon: _hora == null
                        ? const Icon(Icons.arrow_drop_down_rounded)
                        : IconButton(
                            tooltip: t.calAlNotaQuitarHora,
                            onPressed: _ocupado ? null : _quitarHora,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                gap,
                TextFormField(
                  controller: _detalle,
                  enabled: !_ocupado,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 500,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: t.calAlNotaDetalle,
                    alignLabelWithHint: true,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  AtenaBanner(tone: AtenaBannerTone.error, message: error),
                ],
                const SizedBox(height: 18),
                AuthSubmitButton(
                  label: t.commonSave,
                  loadingLabel: t.commonSaving,
                  loading: _guardando,
                  onPressed: _eliminando ? null : _guardar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
