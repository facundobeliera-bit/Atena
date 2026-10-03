// lib/screens/instituciones/widgets/com_inst_evento_form_page.dart
//
// ATENA – Alta y edición de un evento del calendario de la institución.
// Al publicar un evento nuevo se avisa a los alumnos confirmados alcanzados;
// al editarlo no se vuelve a notificar. Devuelve el Evento guardado al cerrar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';
import 'com_inst_comunes.dart';

class ComInstEventoFormPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;
  final List<OfertaConCupo> ofertas;

  /// null = evento nuevo.
  final Evento? evento;

  const ComInstEventoFormPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.ofertas,
    this.evento,
  });

  @override
  Widget build(BuildContext context) => AtenaRoleTheme(
    role: AtenaRole.institucion,
    child: _EventoForm(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      ofertas: ofertas,
      evento: evento,
    ),
  );
}

class _EventoForm extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final List<OfertaConCupo> ofertas;
  final Evento? evento;

  const _EventoForm({
    required this.institucionId,
    required this.institucionNombre,
    required this.ofertas,
    required this.evento,
  });

  @override
  State<_EventoForm> createState() => _EventoFormState();
}

class _EventoFormState extends State<_EventoForm> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _lugar = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  late final ComInstAlcance _alcance = ComInstAlcance(widget.institucionId);

  TipoEvento _tipo = TipoEvento.general;
  DateTime? _fecha;
  DateTime? _fin;
  bool _todoElDia = true;
  TimeOfDay? _hora;
  bool _paraTodos = true;
  Set<String> _ofertaIds = <String>{};
  bool _pideConfirmacion = false;

  int? _alcanzados;
  bool _calculando = false;
  bool _errorDestinatarios = false;
  bool _intentado = false;
  bool _dirty = false;
  bool _saving = false;
  String? _error;

  bool get _editando => widget.evento != null;
  bool get _seleccionVacia => !_paraTodos && _ofertaIds.isEmpty;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    if (e == null) {
      _calculando = true;
      _contar();
      return;
    }
    final conocidas = {for (final o in widget.ofertas) o.oferta.id};
    final inicio = DateUtils.dateOnly(e.inicio);
    final fin = e.fin == null ? null : DateUtils.dateOnly(e.fin!);
    _tipo = e.tipo;
    _titulo.text = e.titulo;
    _descripcion.text = e.descripcion;
    _lugar.text = e.lugar;
    _fecha = inicio;
    _fin = fin != null && fin.isAfter(inicio) ? fin : null;
    _todoElDia = e.todoElDia;
    _hora = e.todoElDia ? null : TimeOfDay.fromDateTime(e.inicio);
    _paraTodos = e.ofertaIds.isEmpty;
    _ofertaIds = e.ofertaIds.where(conocidas.contains).toSet();
    _pideConfirmacion = e.pideConfirmacion;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actualizarTextos();
  }

  @override
  void dispose() {
    _alcance.cancelar();
    for (final c in [
      _titulo,
      _descripcion,
      _lugar,
      _fechaCtrl,
      _finCtrl,
      _horaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _actualizarTextos() {
    final fecha = _fecha;
    final fin = _fin;
    final hora = _hora;
    _fechaCtrl.text = fecha == null
        ? ''
        : AtenaFormat.fechaCorta(context, fecha);
    _finCtrl.text = fin == null ? '' : AtenaFormat.fechaCorta(context, fin);
    _horaCtrl.text = hora == null ? '' : hora.format(context);
  }

  void _marcar() {
    if (!_dirty) setState(() => _dirty = true);
  }

  /// Ofertas elegidas, en el orden en que se muestran.
  List<String> _ofertasElegidas() => [
    for (final o in widget.ofertas)
      if (_ofertaIds.contains(o.oferta.id)) o.oferta.id,
  ];

  Future<void> _contar() async {
    if (_editando) return;
    if (_seleccionVacia) {
      _alcance.cancelar();
      if (mounted) {
        setState(() {
          _alcanzados = null;
          _calculando = false;
        });
      }
      return;
    }
    try {
      final n = await _alcance.contar(
        _paraTodos ? const <String>[] : _ofertasElegidas(),
      );
      if (!mounted || n == null) return;
      setState(() {
        _alcanzados = n;
        _calculando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alcanzados = null;
        _calculando = false;
      });
    }
  }

  void _cambiarDestinatarios({bool? paraTodos, Set<String>? seleccion}) {
    setState(() {
      _paraTodos = paraTodos ?? _paraTodos;
      _ofertaIds = seleccion ?? _ofertaIds;
      _errorDestinatarios = _errorDestinatarios && _seleccionVacia;
      _calculando = !_editando && !_seleccionVacia;
      _dirty = true;
    });
    _contar();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final actual = _fecha;
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual ?? hoy,
      firstDate: actual != null && actual.isBefore(hoy) ? actual : hoy,
      lastDate: DateTime(hoy.year + 3, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fecha = elegida;
      _dirty = true;
      _actualizarTextos();
    });
  }

  Future<void> _elegirFin() async {
    final base = _fecha ?? DateUtils.dateOnly(DateTime.now());
    final primera = DateUtils.addDaysToDate(base, 1);
    final actual = _fin;
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual != null && !actual.isBefore(primera)
          ? actual
          : primera,
      firstDate: primera,
      lastDate: DateTime(primera.year + 3, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fin = elegida;
      _dirty = true;
      _actualizarTextos();
    });
  }

  void _quitarFin() {
    setState(() {
      _fin = null;
      _dirty = true;
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
      _dirty = true;
      _actualizarTextos();
    });
  }

  Future<void> _guardar() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    final formOk = _formKey.currentState?.validate() ?? false;
    final fecha = _fecha;
    setState(() {
      _intentado = true;
      _errorDestinatarios = _seleccionVacia;
    });
    if (!formOk || fecha == null || _seleccionVacia) return;

    final hora = _hora;
    final fin = _fin;
    final original = widget.evento;
    final nombre = widget.institucionNombre.trim();
    final evento = Evento(
      id: original?.id ?? '',
      institucionId: widget.institucionId,
      institucionNombre: nombre.isNotEmpty
          ? nombre
          : (original?.institucionNombre ?? ''),
      tipo: _tipo,
      titulo: _titulo.text.trim(),
      descripcion: _descripcion.text.trim(),
      lugar: _lugar.text.trim(),
      inicio: !_todoElDia && hora != null
          ? DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute)
          : fecha,
      fin: fin != null && fin.isAfter(fecha) ? fin : null,
      todoElDia: _todoElDia,
      ofertaIds: _paraTodos ? const <String>[] : _ofertasElegidas(),
      pideConfirmacion: _pideConfirmacion,
      creadoEl: original?.creadoEl ?? DateTime.now(),
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final cal = CalendarioRepo.instance;
      // Si el evento se eliminó mientras se editaba, no se vuelve a crear.
      if (original != null &&
          await cal.evento(widget.institucionId, original.id) == null) {
        throw const AtenaException(AtenaError.noEncontrado);
      }
      final guardado = await cal.guardarEvento(evento);
      if (!mounted) return;
      AtenaFeedback.success(
        context,
        _editando
            ? t.comInstEventoActualizado
            : t.comInstEventoPublicado(_alcanzados ?? 0),
      );
      Navigator.of(context).pop(guardado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = coreErrorText(t, e);
      });
    }
  }

  Future<void> _confirmarSalida() async {
    final salir = await comInstConfirmarDescarte(context);
    if (salir && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = (_error ?? '').trim();
    const gap = SizedBox(height: 14);

    return PopScope<Object?>(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        _confirmarSalida();
      },
      child: AtenaScaffold(
        role: AtenaRole.institucion,
        appBar: AtenaAppBar(
          title: _editando ? t.comInstEditarEvento : t.comInstNuevoEvento,
          subtitle: widget.institucionNombre,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: atenaPagePadding(context, maxWidth: AtenaLayout.narrow),
            child: Form(
              key: _formKey,
              autovalidateMode: _intentado
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Seccion(
                    title: t.comInstSeccionTipo,
                    help: t.comInstSeccionTipoAyuda,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final tipo in TipoEvento.values)
                          ChoiceChip(
                            avatar: Icon(
                              iconoTipoEvento(tipo),
                              color: AtenaTone.of(
                                context,
                                colorTipoEvento(tipo),
                              ).foreground,
                            ),
                            label: Text(t.tipoEvento(tipo)),
                            selected: _tipo == tipo,
                            showCheckmark: false,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() {
                                    _tipo = tipo;
                                    _dirty = true;
                                  }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Seccion(
                    title: t.comInstSeccionDatos,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titulo,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(80),
                          ],
                          decoration: InputDecoration(
                            labelText: t.comInstCampoTitulo,
                            helperText: t.comInstCampoTituloAyuda,
                          ),
                          validator: (v) => AuthValidators.required(t, v),
                          onChanged: (_) => _marcar(),
                        ),
                        gap,
                        TextFormField(
                          controller: _descripcion,
                          enabled: !_saving,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 7,
                          maxLength: 600,
                          decoration: InputDecoration(
                            labelText: t.comInstCampoDescripcion,
                            helperText: t.comInstCampoDescripcionAyuda,
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) => _marcar(),
                        ),
                        gap,
                        TextFormField(
                          controller: _lugar,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(80),
                          ],
                          decoration: InputDecoration(
                            labelText: t.comInstCampoLugar,
                            prefixIcon: const Icon(Icons.place_outlined),
                          ),
                          onChanged: (_) => _marcar(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Seccion(
                    title: t.comInstSeccionCuando,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _fechaCtrl,
                          enabled: !_saving,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          onTap: _elegirFecha,
                          decoration: InputDecoration(
                            labelText: t.comInstCampoFecha,
                            prefixIcon: const Icon(Icons.event_rounded),
                            suffixIcon: const Icon(
                              Icons.calendar_month_rounded,
                            ),
                          ),
                          validator: (_) =>
                              _fecha == null ? t.comInstErrorFecha : null,
                        ),
                        gap,
                        TextFormField(
                          controller: _finCtrl,
                          enabled: !_saving,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          onTap: _elegirFin,
                          decoration: InputDecoration(
                            labelText: t.comInstCampoFechaFin,
                            helperText: t.comInstCampoFechaFinAyuda,
                            prefixIcon: const Icon(Icons.date_range_rounded),
                            suffixIcon: _fin == null
                                ? const Icon(Icons.calendar_month_rounded)
                                : IconButton(
                                    tooltip: t.comInstQuitarFechaFin,
                                    onPressed: _saving ? null : _quitarFin,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                          validator: (_) {
                            final fecha = _fecha;
                            final fin = _fin;
                            if (fecha == null || fin == null) return null;
                            return fin.isAfter(fecha)
                                ? null
                                : t.comInstErrorFechaFin;
                          },
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.comInstTodoElDia),
                          subtitle: Text(t.comInstTodoElDiaAyuda),
                          value: _todoElDia,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                  _todoElDia = v;
                                  _dirty = true;
                                }),
                        ),
                        if (!_todoElDia) ...[
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _horaCtrl,
                            enabled: !_saving,
                            readOnly: true,
                            enableInteractiveSelection: false,
                            onTap: _elegirHora,
                            decoration: InputDecoration(
                              labelText: t.comInstCampoHora,
                              prefixIcon: const Icon(Icons.schedule_rounded),
                            ),
                            validator: (_) => !_todoElDia && _hora == null
                                ? t.comInstErrorHora
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Seccion(
                    title: t.comInstSeccionDestinatarios,
                    help: t.comInstSeccionDestinatariosAyuda,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ComInstDestinatariosSelector(
                          ofertas: widget.ofertas,
                          paraTodos: _paraTodos,
                          seleccion: _ofertaIds,
                          mostrarError: _errorDestinatarios,
                          enabled: !_saving,
                          onParaTodosChanged: (v) =>
                              _cambiarDestinatarios(paraTodos: v),
                          onSeleccionChanged: (s) =>
                              _cambiarDestinatarios(seleccion: s),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 4),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.comInstPedirConfirmacion),
                          subtitle: Text(t.comInstPedirConfirmacionAyuda),
                          value: _pideConfirmacion,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                  _pideConfirmacion = v;
                                  _dirty = true;
                                }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_editando)
                    AtenaBanner(message: t.comInstEditarSinAviso)
                  else if (!_seleccionVacia)
                    ComInstAlcanceBanner(
                      calculando: _calculando,
                      cantidad: _alcanzados,
                      texto: t.comInstSeAvisaraA,
                      ayuda: t.comInstSeAvisaraAyuda,
                      sinAlumnos: t.comInstSinDestinatariosEvento,
                    ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AtenaBanner(tone: AtenaBannerTone.error, message: error),
                  ],
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    label: _editando
                        ? t.comInstGuardarCambios
                        : t.comInstPublicar,
                    loadingLabel: _editando
                        ? t.commonSaving
                        : t.comInstPublicando,
                    loading: _saving,
                    onPressed: _guardar,
                    icon: _editando ? null : Icons.send_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con título (y ayuda) para cada bloque del formulario.
class _Seccion extends StatelessWidget {
  final String title;
  final String? help;
  final Widget child;

  const _Seccion({required this.title, this.help, required this.child});

  @override
  Widget build(BuildContext context) {
    return AtenaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormSection(title: title, help: help),
          child,
        ],
      ),
    );
  }
}
