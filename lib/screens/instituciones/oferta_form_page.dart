// lib/screens/instituciones/oferta_form_page.dart
//
// ATENA – Alta, edición y copia de una vacante (oferta) de la institución.
// Solo ofrece los tipos, niveles y categorías que habilita el plan.
// Devuelve la Oferta guardada al cerrar.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import '../auth/widgets/auth_shell.dart';
import 'widgets/ofertas_campos.dart';

class OfertaFormPage extends StatelessWidget {
  final Institucion institucion;

  /// Vacante a editar (null = vacante nueva).
  final Oferta? oferta;

  /// Vacante a copiar: se crea una nueva con sus datos.
  final Oferta? copiaDe;

  /// Valores iniciales de una vacante nueva.
  final TipoOferta? tipoInicial;
  final NivelCurricular? nivelInicial;
  final BloqueExtracurricular? bloqueInicial;

  /// Alumnos confirmados al abrir (solo edición): el cupo no puede ser menor.
  final int confirmados;

  const OfertaFormPage({
    super.key,
    required this.institucion,
    this.oferta,
    this.copiaDe,
    this.tipoInicial,
    this.nivelInicial,
    this.bloqueInicial,
    this.confirmados = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AtenaRoleTheme(
      role: AtenaRole.institucion,
      child: _OfertaForm(page: this),
    );
  }
}

class _OfertaForm extends StatefulWidget {
  final OfertaFormPage page;

  const _OfertaForm({required this.page});

  @override
  State<_OfertaForm> createState() => _OfertaFormState();
}

class _OfertaFormState extends State<_OfertaForm> {
  static const _gap = SizedBox(height: 14);

  final _formKey = GlobalKey<FormState>();
  final _categoriaKey = GlobalKey();
  final _cupoKey = GlobalKey();
  final _titulo = TextEditingController();
  final _grupo = TextEditingController();
  final _cupo = TextEditingController();
  final _edadMin = TextEditingController();
  final _edadMax = TextEditingController();
  final _arancel = TextEditingController();
  final _descripcion = TextEditingController();
  final _desdeCtrl = TextEditingController();
  final _hastaCtrl = TextEditingController();

  late TipoOferta _tipo;
  NivelCurricular? _nivel;
  BloqueExtracurricular? _bloque;
  Turno _turno = Turno.manana;
  TimeOfDay? _desde;
  TimeOfDay? _hasta;
  Set<int> _dias = <int>{};
  bool _activa = true;

  /// Horario y días ya guardados que no se pudieron interpretar: se conservan
  /// tal cual mientras no se elijan valores nuevos.
  String _horarioPrevio = '';
  String _diasPrevios = '';

  /// Lo que se interpretó del horario y los días guardados. Si no cambian se
  /// conserva el texto original (pudo guardarse con la app en otro idioma).
  (TimeOfDay, TimeOfDay)? _horarioLeido;
  Set<int>? _diasLeidos;

  late int _confirmados;
  bool _listo = false;
  String _firmaInicial = '';
  bool _cambios = false;
  bool _saving = false;
  bool _validarSiempre = false;
  String? _error;
  String? _errorCategoria;

  OfertaFormPage get _page => widget.page;
  Institucion get _inst => _page.institucion;
  bool get _editando => _page.oferta != null;
  bool get _curricular => _tipo == TipoOferta.curricular;

  List<TipoOferta> get _tiposDisponibles => [
    for (final tipo in TipoOferta.values)
      if (ofertasTipoHabilitado(_inst, tipo) || _page.oferta?.tipo == tipo)
        tipo,
  ];

  List<NivelCurricular> get _nivelesDisponibles {
    final habilitados = ofertasNivelesHabilitados(_inst);
    final actual = _page.oferta?.nivel;
    return [
      for (final n in NivelCurricular.values)
        if (habilitados.contains(n) || n == actual) n,
    ];
  }

  List<BloqueExtracurricular> get _bloquesDisponibles {
    final habilitados = ofertasBloquesHabilitados(_inst);
    final actual = _page.oferta?.bloque;
    return [
      for (final b in BloqueExtracurricularX.ordered())
        if (habilitados.contains(b) || b == actual) b,
    ];
  }

  @override
  void initState() {
    super.initState();
    _confirmados = _page.confirmados;

    final base = _page.oferta ?? _page.copiaDe;
    final tipos = _tiposDisponibles;
    final inicial = _page.tipoInicial;
    _tipo =
        base?.tipo ??
        (inicial != null && tipos.contains(inicial)
            ? inicial
            : (tipos.isEmpty ? TipoOferta.curricular : tipos.first));

    if (base != null) {
      _nivel = base.nivel;
      _bloque = base.bloque;
      _titulo.text = base.titulo;
      _grupo.text = base.grupo;
      _turno = base.turno;
      _cupo.text = '${base.cupoTotal}';
      _edadMin.text = base.edadMinima?.toString() ?? '';
      _edadMax.text = base.edadMaxima?.toString() ?? '';
      _arancel.text = base.arancel;
      _descripcion.text = base.descripcion;
      _activa = _editando ? base.activa : true;
    } else {
      _nivel = _page.nivelInicial;
      _bloque = _page.bloqueInicial;
      _cupo.text = _curricular ? '25' : '15';
    }
    _ajustarCategoria();

    for (final c in [
      _titulo,
      _grupo,
      _cupo,
      _edadMin,
      _edadMax,
      _arancel,
      _descripcion,
    ]) {
      c.addListener(_alEscribir);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listo) return;
    _listo = true;

    // El horario y los días se guardan como texto legible: acá se vuelven a
    // leer para poder editarlos con los selectores (necesita el idioma).
    final t = AppLocalizations.of(context);
    final base = _page.oferta ?? _page.copiaDe;
    if (base != null) {
      final horario = ofertasLeerHorario(base.horario);
      if (horario != null) {
        _desde = horario.$1;
        _hasta = horario.$2;
        _horarioLeido = horario;
      } else {
        _horarioPrevio = base.horario.trim();
      }
      final dias = ofertasLeerDias(t, base.dias);
      if (dias != null) {
        _dias = dias;
        _diasLeidos = dias;
      } else {
        _diasPrevios = base.dias.trim();
      }
    } else if (_curricular) {
      _dias = {0, 1, 2, 3, 4};
    }
    _mostrarHoras();
    _firmaInicial = _firma();
  }

  @override
  void dispose() {
    for (final c in [
      _titulo,
      _grupo,
      _cupo,
      _edadMin,
      _edadMax,
      _arancel,
      _descripcion,
      _desdeCtrl,
      _hastaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Estado del formulario
  // ---------------------------------------------------------------------------

  /// Si la categoría elegida no está disponible se descarta; si hay una sola
  /// posible, queda elegida.
  void _ajustarCategoria() {
    if (_curricular) {
      final niveles = _nivelesDisponibles;
      if (!niveles.contains(_nivel)) _nivel = null;
      if (_nivel == null && niveles.length == 1) _nivel = niveles.single;
    } else {
      final bloques = _bloquesDisponibles;
      if (!bloques.contains(_bloque)) _bloque = null;
      if (_bloque == null && bloques.length == 1) _bloque = bloques.single;
    }
  }

  void _mostrarHoras() {
    final desde = _desde;
    final hasta = _hasta;
    _desdeCtrl.text = desde == null ? '' : ofertasHora(desde);
    _hastaCtrl.text = hasta == null ? '' : ofertasHora(hasta);
  }

  /// Resumen de todo lo cargado, para saber si hay cambios sin guardar.
  String _firma() {
    final desde = _desde;
    final hasta = _hasta;
    return [
      _tipo.name,
      _nivel?.name ?? '',
      _bloque?.name ?? '',
      _titulo.text.trim(),
      _grupo.text.trim(),
      _turno.name,
      desde == null ? '' : ofertasHora(desde),
      hasta == null ? '' : ofertasHora(hasta),
      _horarioPrevio,
      (_dias.toList()..sort()).join(','),
      _diasPrevios,
      _cupo.text.trim(),
      _edadMin.text.trim(),
      _edadMax.text.trim(),
      _arancel.text.trim(),
      _descripcion.text.trim(),
      '$_activa',
    ].join('\n');
  }

  void _alEscribir() {
    if (!_listo) return;
    final cambios = _firma() != _firmaInicial;
    if (cambios != _cambios) setState(() => _cambios = cambios);
  }

  void _set(VoidCallback cambio) {
    setState(() {
      cambio();
      _cambios = _firma() != _firmaInicial;
    });
  }

  int? _numero(TextEditingController c) => int.tryParse(c.text.trim());

  // ---------------------------------------------------------------------------
  // Horario
  // ---------------------------------------------------------------------------

  Future<void> _elegirHora({required bool desde}) async {
    if (_saving) return;
    final t = AppLocalizations.of(context);
    final inicio = _desde;
    final sugerida = desde
        ? (inicio ?? const TimeOfDay(hour: 8, minute: 0))
        : (_hasta ??
              (inicio == null
                  ? const TimeOfDay(hour: 12, minute: 0)
                  : TimeOfDay(
                      hour: math.min(23, inicio.hour + 4),
                      minute: inicio.minute,
                    )));

    final elegida = await showTimePicker(
      context: context,
      initialTime: sugerida,
      helpText: desde ? t.ofertasHoraDesde : t.ofertasHoraHasta,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (elegida == null || !mounted) return;
    _set(() {
      if (desde) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
      _horarioPrevio = '';
      _mostrarHoras();
    });
  }

  void _quitarHorario() {
    _set(() {
      _desde = null;
      _hasta = null;
      _horarioPrevio = '';
      _mostrarHoras();
    });
  }

  String? _validarHorario(AppLocalizations t) {
    final desde = _desde;
    final hasta = _hasta;
    if ((desde == null) != (hasta == null)) return t.ofertasHorarioIncompleto;
    if (desde != null &&
        hasta != null &&
        ofertasMinutos(hasta) <= ofertasMinutos(desde)) {
      return t.ofertasHorarioInvalido;
    }
    return null;
  }

  String _textoHorario(AppLocalizations t) {
    final desde = _desde;
    final hasta = _hasta;
    if (desde == null || hasta == null) return _horarioPrevio;
    final base = _page.oferta ?? _page.copiaDe;
    if (base != null && _horarioLeido == (desde, hasta)) {
      return base.horario.trim();
    }
    return t.ofertasHorarioRango(ofertasHora(desde), ofertasHora(hasta));
  }

  String _textoDias(AppLocalizations t) {
    if (_dias.isEmpty) return _diasPrevios;
    final base = _page.oferta ?? _page.copiaDe;
    final leidos = _diasLeidos;
    if (base != null && leidos != null && setEquals(leidos, _dias)) {
      return base.dias.trim();
    }
    return ofertasTextoDias(t, _dias);
  }

  // ---------------------------------------------------------------------------
  // Validación y guardado
  // ---------------------------------------------------------------------------

  String? _validarCupo(AppLocalizations t, String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return t.commonRequiredField;
    if (n < 1) return t.ofertasCupoMinimo;
    if (_editando && n < _confirmados) {
      return t.ofertasCupoMenorConfirmados(_confirmados);
    }
    return null;
  }

  String? _validarEdades(AppLocalizations t) {
    final min = _numero(_edadMin);
    final max = _numero(_edadMax);
    if (min != null && max != null && max < min) {
      return t.ofertasEdadRangoInvalido;
    }
    return null;
  }

  /// Lleva la vista hasta el primer dato a corregir.
  void _irA(BuildContext? destino) {
    if (destino == null) return;
    Scrollable.ensureVisible(
      destino,
      alignment: 0.2,
      duration: AtenaMotion.medium,
      curve: AtenaMotion.curve,
    );
  }

  Future<void> _guardar() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);

    final categoriaOk = _curricular ? _nivel != null : _bloque != null;
    final invalidos =
        _formKey.currentState?.validateGranularly() ??
        const <FormFieldState<Object?>>{};
    if (!categoriaOk || invalidos.isNotEmpty) {
      setState(() {
        _validarSiempre = true;
        _error = t.ofertasRevisaCampos;
        _errorCategoria = categoriaOk
            ? null
            : (_curricular ? t.ofertasElegiNivel : t.ofertasElegiCategoria);
      });
      _irA(
        categoriaOk ? invalidos.first.context : _categoriaKey.currentContext,
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final original = _page.oferta;
      final cupo = _numero(_cupo) ?? 1;

      // Puede haberse confirmado a alguien mientras el formulario estaba abierto.
      if (original != null) {
        final confirmadas = await SolicitudesRepo.instance.confirmadas(
          original.institucionId,
          ofertaId: original.id,
        );
        if (!mounted) return;
        if (cupo < confirmadas.length) {
          setState(() {
            _confirmados = confirmadas.length;
            _validarSiempre = true;
            _error = t.ofertasRevisaCampos;
          });
          _irA(_cupoKey.currentContext);
          return;
        }
      }

      final ahora = DateTime.now();
      final guardada = await OfertasRepo.instance.guardar(
        Oferta(
          id: original?.id ?? '',
          institucionId: original?.institucionId ?? _inst.id,
          tipo: _tipo,
          nivel: _curricular ? _nivel : null,
          bloque: _curricular ? null : _bloque,
          titulo: _titulo.text.trim(),
          grupo: _grupo.text.trim(),
          turno: _turno,
          horario: _textoHorario(t),
          dias: _textoDias(t),
          cupoTotal: cupo,
          edadMinima: _numero(_edadMin),
          edadMaxima: _numero(_edadMax),
          descripcion: _descripcion.text.trim(),
          arancel: _arancel.text.trim(),
          activa: _activa,
          creadaEl: original?.creadaEl ?? ahora,
          actualizadaEl: ahora,
        ),
      );
      if (!mounted) return;
      AtenaFeedback.success(
        context,
        original == null ? t.ofertasCreadaOk : t.ofertasGuardadaOk,
      );
      Navigator.of(context).pop(guardada);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = coreErrorText(t, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _alSalir(bool didPop) async {
    if (didPop || _saving) return;
    final t = AppLocalizations.of(context);
    final descartar = await showAtenaConfirm(
      context,
      title: t.ofertasDescartarTitulo,
      message: t.ofertasDescartarMensaje,
      confirmLabel: t.ofertasDescartar,
      destructive: true,
      icon: Icons.warning_amber_rounded,
    );
    if (descartar && mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Vista
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final copia = _page.copiaDe;
    final error = (_error ?? '').trim();
    final titulo = _editando
        ? t.ofertasFormEditar
        : (copia != null ? t.ofertasFormDuplicar : t.ofertasNueva);

    return PopScope<Object?>(
      canPop: !_cambios && !_saving,
      onPopInvokedWithResult: (didPop, _) => _alSalir(didPop),
      child: AtenaScaffold(
        role: AtenaRole.institucion,
        appBar: AtenaAppBar(title: titulo, subtitle: _inst.nombre),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: atenaPagePadding(
              context,
              maxWidth: AtenaLayout.narrow,
              top: 8,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _validarSiempre
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (copia != null) ...[
                    AtenaBanner(
                      icon: Icons.content_copy_rounded,
                      message: t.ofertasFormCopiaAviso(copia.nombreCompleto),
                    ),
                    _gap,
                  ],
                  if (_editando && _confirmados > 0) ...[
                    AtenaBanner(
                      message: t.ofertasFormConfirmadosAviso(_confirmados),
                    ),
                    _gap,
                  ],
                  if (!_editando && _tiposDisponibles.length > 1) ...[
                    _seccionTipo(t),
                    _gap,
                  ],
                  _seccionCategoria(t),
                  _gap,
                  _seccionDatos(t),
                  _gap,
                  _seccionHorario(t),
                  _gap,
                  _seccionCupo(t),
                  _gap,
                  _seccionPublicacion(t),
                  if (error.isNotEmpty) ...[
                    _gap,
                    AtenaBanner(tone: AtenaBannerTone.error, message: error),
                  ],
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    label: _editando ? t.commonSave : t.ofertasCrear,
                    loadingLabel: t.commonSaving,
                    loading: _saving,
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _seccion({
    Key? key,
    required String titulo,
    String? ayuda,
    required List<Widget> children,
  }) {
    return AtenaCard(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormSection(title: titulo, help: ayuda),
          ...children,
        ],
      ),
    );
  }

  Widget _subtitulo(String texto) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _nota(String texto) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(texto, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _seccionTipo(AppLocalizations t) {
    return _seccion(
      titulo: t.ofertasSeccionTipo,
      children: [
        OfertasSelector<TipoOferta>(
          anchoMinimo: 190,
          opciones: [
            for (final tipo in _tiposDisponibles)
              OfertasOpcion(
                valor: tipo,
                icono: ofertasIconoTipo(tipo),
                titulo: t.tipoOferta(tipo),
                detalle: tipo == TipoOferta.curricular
                    ? t.ofertasTipoCurricularDesc
                    : t.ofertasTipoExtraDesc,
              ),
          ],
          seleccion: _tipo,
          onChanged: _saving
              ? null
              : (tipo) => _set(() {
                  _tipo = tipo;
                  _errorCategoria = null;
                  _ajustarCategoria();
                }),
        ),
      ],
    );
  }

  Widget _seccionCategoria(AppLocalizations t) {
    final theme = Theme.of(context);
    final errorCategoria = _errorCategoria;

    return _seccion(
      key: _categoriaKey,
      titulo: _curricular ? t.ofertasSeccionNivel : t.ofertasSeccionCategoria,
      children: [
        Wrap(
          spacing: 8,
          children: _curricular
              ? [
                  for (final n in _nivelesDisponibles)
                    _chipCategoria(
                      icono: iconoNivel(n),
                      texto: t.nivel(n),
                      seleccionado: _nivel == n,
                      onTap: () => _set(() {
                        _nivel = n;
                        _errorCategoria = null;
                      }),
                    ),
                ]
              : [
                  for (final b in _bloquesDisponibles)
                    _chipCategoria(
                      icono: iconoBloque(b),
                      texto: t.bloque(b),
                      seleccionado: _bloque == b,
                      onTap: () => _set(() {
                        _bloque = b;
                        _errorCategoria = null;
                      }),
                    ),
                ],
        ),
        if (errorCategoria != null) ...[
          const SizedBox(height: 8),
          Text(
            errorCategoria,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _chipCategoria({
    required IconData icono,
    required String texto,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      avatar: Icon(
        icono,
        size: 18,
        color: seleccionado ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      ),
      label: Text(texto),
      selected: seleccionado,
      showCheckmark: false,
      side: BorderSide(
        color: seleccionado ? cs.primary : cs.outlineVariant,
        width: seleccionado ? 1.6 : 1,
      ),
      onSelected: _saving ? null : (_) => onTap(),
    );
  }

  Widget _seccionDatos(AppLocalizations t) {
    final nivel = _nivel;
    final bloque = _bloque;
    final icono = _curricular
        ? (nivel == null ? ofertasIconoTipo(_tipo) : iconoNivel(nivel))
        : (bloque == null ? ofertasIconoTipo(_tipo) : iconoBloque(bloque));

    return _seccion(
      titulo: t.ofertasSeccionDatos,
      children: [
        TextFormField(
          controller: _titulo,
          enabled: !_saving,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          decoration: InputDecoration(
            labelText: _curricular
                ? t.ofertasTituloCurricularLabel
                : t.ofertasTituloExtraLabel,
            helperText: _curricular
                ? (nivel == null ? null : t.ofertasSugerenciasAyuda)
                : ofertasEjemplos(t, bloque),
            prefixIcon: Icon(icono),
          ),
          validator: (v) => AuthValidators.required(t, v),
        ),
        if (_curricular && nivel != null) ...[
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: _titulo,
            builder: (context, _) {
              final actual = _titulo.text.trim();
              return Wrap(
                spacing: 8,
                children: [
                  for (final s in ofertasSugerencias(t, nivel))
                    ChoiceChip(
                      label: Text(s),
                      selected: actual == s,
                      onSelected: _saving
                          ? null
                          : (_) => _titulo.value = TextEditingValue(
                              text: s,
                              selection: TextSelection.collapsed(
                                offset: s.length,
                              ),
                            ),
                    ),
                ],
              );
            },
          ),
        ],
        _gap,
        TextFormField(
          controller: _grupo,
          enabled: !_saving,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          decoration: InputDecoration(
            labelText: t.ofertasGrupoLabel,
            helperText: t.ofertasGrupoHelper,
            prefixIcon: const Icon(Icons.groups_rounded),
          ),
        ),
      ],
    );
  }

  Widget _seccionHorario(AppLocalizations t) {
    final theme = Theme.of(context);
    final hayHoras = _desde != null || _hasta != null;

    return _seccion(
      titulo: t.ofertasSeccionHorario,
      children: [
        _subtitulo(t.ofertasTurnoLabel),
        OfertasSelector<Turno>(
          anchoMinimo: 150,
          opciones: [
            for (final x in Turno.values)
              OfertasOpcion(
                valor: x,
                icono: ofertasIconoTurno(x),
                titulo: t.turno(x),
              ),
          ],
          seleccion: _turno,
          onChanged: _saving ? null : (x) => _set(() => _turno = x),
        ),
        const SizedBox(height: 18),
        if (_horarioPrevio.isNotEmpty)
          _nota(t.ofertasHorarioActual(_horarioPrevio)),
        OfertasGrupoValidado(
          validar: () => _validarHorario(t),
          builder: (context, hayError, _) => Row(
            children: [
              Expanded(
                child: _campoHora(
                  _desdeCtrl,
                  t.ofertasHoraDesde,
                  desde: true,
                  hayError: hayError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _campoHora(
                  _hastaCtrl,
                  t.ofertasHoraHasta,
                  desde: false,
                  hayError: hayError,
                ),
              ),
            ],
          ),
        ),
        if (hayHoras)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _saving ? null : _quitarHorario,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(t.ofertasQuitarHorario),
            ),
          )
        else
          _gap,
        _subtitulo(t.ofertasDiasLabel),
        if (_diasPrevios.isNotEmpty) _nota(t.ofertasDiasActual(_diasPrevios)),
        OfertasDiasSelector(
          seleccion: _dias,
          onChanged: _saving
              ? null
              : (dias) => _set(() {
                  _dias = dias;
                  _diasPrevios = '';
                }),
        ),
        if (_dias.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(ofertasTextoDias(t, _dias), style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _campoHora(
    TextEditingController controller,
    String label, {
    required bool desde,
    required bool hayError,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      readOnly: true,
      enableInteractiveSelection: false,
      onTap: () => _elegirHora(desde: desde),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time_rounded),
        error: ofertasMarcaError(hayError),
      ),
    );
  }

  Widget _campoEdad(
    TextEditingController controller,
    String label,
    AppLocalizations t, {
    required bool hayError,
    required VoidCallback alCambiar,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [digitsOnly, LengthLimitingTextInputFormatter(2)],
      decoration: InputDecoration(
        labelText: label,
        suffixText: t.ofertasAniosSufijo,
        error: ofertasMarcaError(hayError),
      ),
      onChanged: (_) => alCambiar(),
    );
  }

  Widget _seccionCupo(AppLocalizations t) {
    return _seccion(
      titulo: t.ofertasSeccionCupo,
      children: [
        OfertasNumeroField(
          key: _cupoKey,
          controller: _cupo,
          label: t.ofertasCupoLabel,
          helperText: _editando && _confirmados > 0
              ? t.ofertasCupoConfirmadosHelper(_confirmados)
              : t.ofertasCupoHelper,
          minimo: _editando ? math.max(1, _confirmados) : 1,
          enabled: !_saving,
          validator: (v) => _validarCupo(t, v),
        ),
        const SizedBox(height: 18),
        OfertasGrupoValidado(
          validar: () => _validarEdades(t),
          ayuda: t.ofertasEdadHelper,
          builder: (context, hayError, alCambiar) => Row(
            children: [
              Expanded(
                child: _campoEdad(
                  _edadMin,
                  t.ofertasEdadMinLabel,
                  t,
                  hayError: false,
                  alCambiar: alCambiar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _campoEdad(
                  _edadMax,
                  t.ofertasEdadMaxLabel,
                  t,
                  hayError: hayError,
                  alCambiar: alCambiar,
                ),
              ),
            ],
          ),
        ),
        _gap,
        TextFormField(
          controller: _arancel,
          enabled: !_saving,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          decoration: InputDecoration(
            labelText: t.ofertasArancelLabel,
            helperText: t.ofertasArancelHelper,
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
        ),
        _gap,
        TextFormField(
          controller: _descripcion,
          enabled: !_saving,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: t.ofertasDescripcionLabel,
            helperText: t.ofertasDescripcionHelper,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _seccionPublicacion(AppLocalizations t) {
    return _seccion(
      titulo: t.ofertasSeccionPublicacion,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _activa,
          onChanged: _saving ? null : (v) => _set(() => _activa = v),
          secondary: AtenaIconBadge(
            icon: _activa
                ? Icons.play_circle_rounded
                : Icons.pause_circle_rounded,
            color: _activa
                ? AtenaBrand.of(context).success
                : AtenaColors.neutral,
            size: 40,
          ),
          title: Text(t.ofertasActivaLabel),
          subtitle: Text(_activa ? t.ofertasActivaOn : t.ofertasActivaOff),
        ),
      ],
    );
  }
}
