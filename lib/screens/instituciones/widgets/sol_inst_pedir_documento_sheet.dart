// lib/screens/instituciones/widgets/sol_inst_pedir_documento_sheet.dart
//
// ATENA – Pedido de un documento a un alumno: tipo, detalle (obligatorio si
// es "otro") y fecha límite opcional. La familia recibe el aviso al instante.
// Hoja inferior en teléfono y diálogo en escritorio.

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';

/// Abre el formulario para pedir un documento. Devuelve el pedido creado, o
/// null si se cerró sin enviar.
///
/// Con [solicitudId] se comprueba antes de enviar que la solicitud siga
/// existiendo (la familia pudo haber eliminado su cuenta).
Future<PedidoDocumento?> showSolInstPedirDocumento(
  BuildContext context, {
  required String institucionId,
  required String institucionNombre,
  required AlumnoSnapshot alumno,
  String? solicitudId,
}) {
  _PedirDocumentoForm form({required bool dialogo}) => _PedirDocumentoForm(
    institucionId: institucionId,
    institucionNombre: institucionNombre,
    alumno: alumno,
    solicitudId: solicitudId,
    dialogo: dialogo,
  );

  if (AtenaLayout.isDesktop(context)) {
    return showDialog<PedidoDocumento>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AtenaLayout.narrow),
          child: form(dialogo: true),
        ),
      ),
    );
  }

  return showModalBottomSheet<PedidoDocumento>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: form(dialogo: false),
    ),
  );
}

class _PedirDocumentoForm extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final AlumnoSnapshot alumno;
  final String? solicitudId;
  final bool dialogo;

  const _PedirDocumentoForm({
    required this.institucionId,
    required this.institucionNombre,
    required this.alumno,
    required this.solicitudId,
    required this.dialogo,
  });

  @override
  State<_PedirDocumentoForm> createState() => _PedirDocumentoFormState();
}

class _PedirDocumentoFormState extends State<_PedirDocumentoForm> {
  final _formKey = GlobalKey<FormState>();
  final _detalle = TextEditingController();
  final _fechaTexto = TextEditingController();

  TipoDocumento? _tipo;
  DateTime? _fechaLimite;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _detalle.dispose();
    _fechaTexto.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? hoy.add(const Duration(days: 7)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 366)),
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fechaLimite = elegida;
      _fechaTexto.text = AtenaFormat.fechaCorta(context, elegida);
    });
  }

  void _quitarFecha() {
    setState(() {
      _fechaLimite = null;
      _fechaTexto.clear();
    });
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final tipo = _tipo;
    if (tipo == null) return;

    final t = AppLocalizations.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final solicitudId = widget.solicitudId;
      if (solicitudId != null &&
          await SolicitudesRepo.instance.obtener(solicitudId) == null) {
        if (!mounted) return;
        setState(() {
          _enviando = false;
          _error = t.solInstYaNoExiste;
        });
        return;
      }

      final pedido = await DocumentosRepo.instance.solicitar(
        institucionId: widget.institucionId,
        institucionNombre: widget.institucionNombre,
        cuentaId: widget.alumno.cuentaId,
        perfilId: widget.alumno.perfilId,
        alumnoNombre: widget.alumno.nombreCompleto,
        tipo: tipo,
        detalle: _detalle.text.trim(),
        fechaLimite: _fechaLimite,
      );
      if (!mounted) return;
      Navigator.of(context).pop(pedido);
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
    final otro = _tipo == TipoDocumento.otro;
    final error = (_error ?? '').trim();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, widget.dialogo ? 20 : 0, 12, 8),
            child: Row(
              children: [
                const AtenaIconBadge(
                  icon: Icons.upload_file_rounded,
                  color: AtenaColors.warning,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.solInstPedirDocumento,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.solInstDocPara(widget.alumno.apellidoNombre),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t.uiClose,
                  onPressed: _enviando
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.solInstDocAyuda,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.solInstDocTipoLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  FormField<TipoDocumento>(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (_) =>
                        _tipo == null ? t.solInstDocTipoRequerido : null,
                    builder: (campo) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final tipo in TipoDocumento.values)
                              ChoiceChip(
                                avatar: Icon(iconoDocumento(tipo)),
                                label: Text(t.tipoDocumento(tipo)),
                                selected: _tipo == tipo,
                                onSelected: _enviando
                                    ? null
                                    : (_) {
                                        setState(() => _tipo = tipo);
                                        campo.didChange(tipo);
                                      },
                              ),
                          ],
                        ),
                        if (campo.hasError) ...[
                          const SizedBox(height: 8),
                          Text(
                            campo.errorText ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _detalle,
                    enabled: !_enviando,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: otro
                          ? t.solInstDocNombreLabel
                          : t.solInstDocDetalleLabel,
                      helperText: otro ? null : t.solInstDocDetalleHelper,
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                    validator: (v) => otro && (v ?? '').trim().isEmpty
                        ? t.solInstDocNombreRequerido
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _fechaTexto,
                    enabled: !_enviando,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    onTap: _elegirFecha,
                    decoration: InputDecoration(
                      labelText: t.solInstDocFechaLimite,
                      prefixIcon: const Icon(Icons.event_rounded),
                      suffixIcon: _fechaLimite == null
                          ? const Icon(Icons.calendar_month_rounded)
                          : IconButton(
                              tooltip: t.solInstDocQuitarFecha,
                              onPressed: _enviando ? null : _quitarFecha,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AtenaBanner(tone: AtenaBannerTone.error, message: error),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: AuthSubmitButton(
                label: t.solInstDocEnviar,
                loadingLabel: t.commonSending,
                loading: _enviando,
                onPressed: _enviar,
                icon: Icons.send_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
