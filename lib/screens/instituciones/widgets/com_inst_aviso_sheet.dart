// lib/screens/instituciones/widgets/com_inst_aviso_sheet.dart
//
// ATENA – Hoja para redactar y enviar un aviso a las familias de los alumnos
// confirmados (todos o de cursos/grupos puntuales). Devuelve el Aviso enviado.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';
import 'com_inst_comunes.dart';

/// Abre la hoja de "Nuevo aviso". Devuelve el aviso enviado o null.
Future<Aviso?> showComInstAvisoSheet(
  BuildContext context, {
  required String institucionId,
  required String institucionNombre,
  required List<OfertaConCupo> ofertas,
}) {
  // Sin arrastre: cerrar por accidente perdería el mensaje escrito. El cierre
  // pasa siempre por el botón, la tecla atrás o el fondo, que piden confirmar.
  return showModalBottomSheet<Aviso>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    showDragHandle: false,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _AvisoSheet(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      ofertas: ofertas,
    ),
  );
}

class _AvisoSheet extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final List<OfertaConCupo> ofertas;

  const _AvisoSheet({
    required this.institucionId,
    required this.institucionNombre,
    required this.ofertas,
  });

  @override
  State<_AvisoSheet> createState() => _AvisoSheetState();
}

class _AvisoSheetState extends State<_AvisoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();
  late final ComInstAlcance _alcance = ComInstAlcance(widget.institucionId);

  bool _paraTodos = true;
  Set<String> _ofertaIds = <String>{};
  int? _alcanzados;
  bool _calculando = true;
  bool _errorDestinatarios = false;
  bool _intentado = false;
  bool _enviando = false;
  String? _error;

  bool get _seleccionVacia => !_paraTodos && _ofertaIds.isEmpty;

  bool get _conCambios =>
      _titulo.text.trim().isNotEmpty || _mensaje.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _contar();
  }

  @override
  void dispose() {
    _alcance.cancelar();
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  List<String> _ofertasElegidas() => [
    for (final o in widget.ofertas)
      if (_ofertaIds.contains(o.oferta.id)) o.oferta.id,
  ];

  Future<void> _contar() async {
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
      _calculando = !_seleccionVacia;
    });
    _contar();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() {
      _intentado = true;
      _errorDestinatarios = _seleccionVacia;
    });
    final n = _alcanzados;
    if (!formOk || _seleccionVacia || n == null || n == 0) return;

    final ok = await showAtenaConfirm(
      context,
      title: t.comInstConfirmarEnvio(n),
      message: t.comInstConfirmarEnvioMensaje,
      confirmLabel: t.comInstEnviarAviso,
      icon: Icons.campaign_rounded,
    );
    if (!ok || !mounted) return;

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final aviso = await CalendarioRepo.instance.enviarAviso(
        institucionId: widget.institucionId,
        institucionNombre: widget.institucionNombre,
        titulo: _titulo.text.trim(),
        mensaje: _mensaje.text.trim(),
        ofertaIds: _paraTodos ? const <String>[] : _ofertasElegidas(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(aviso);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
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
    final theme = Theme.of(context);
    final error = (_error ?? '').trim();
    final puedeEnviar =
        _seleccionVacia || (!_calculando && (_alcanzados ?? 0) > 0);

    return PopScope<Object?>(
      canPop: !_conCambios && !_enviando,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _enviando) return;
        _confirmarSalida();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _intentado
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AtenaIconBadge(
                      icon: Icons.campaign_rounded,
                      color: AtenaColors.goldDeep,
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.comInstNuevoAviso,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.comInstNuevoAvisoAyuda,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: t.uiClose,
                      onPressed: _enviando
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titulo,
                  enabled: !_enviando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  decoration: InputDecoration(
                    labelText: t.comInstCampoTitulo,
                    helperText: t.comInstAvisoCampoTituloAyuda,
                  ),
                  validator: (v) => AuthValidators.required(t, v),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _mensaje,
                  enabled: !_enviando,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: t.comInstAvisoCampoMensaje,
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => AuthValidators.required(t, v),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Text(
                  t.comInstSeccionDestinatarios,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                ComInstDestinatariosSelector(
                  ofertas: widget.ofertas,
                  paraTodos: _paraTodos,
                  seleccion: _ofertaIds,
                  mostrarError: _errorDestinatarios,
                  enabled: !_enviando,
                  onParaTodosChanged: (v) =>
                      _cambiarDestinatarios(paraTodos: v),
                  onSeleccionChanged: (s) =>
                      _cambiarDestinatarios(seleccion: s),
                ),
                if (!_seleccionVacia) ...[
                  const SizedBox(height: 16),
                  ComInstAlcanceBanner(
                    calculando: _calculando,
                    cantidad: _alcanzados,
                    texto: t.comInstLlegaraA,
                    sinAlumnos: t.comInstSinDestinatariosAviso,
                  ),
                ],
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AtenaBanner(tone: AtenaBannerTone.error, message: error),
                ],
                const SizedBox(height: 20),
                AuthSubmitButton(
                  label: t.comInstEnviarAviso,
                  loadingLabel: t.commonSending,
                  loading: _enviando,
                  onPressed: puedeEnviar ? _enviar : null,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
