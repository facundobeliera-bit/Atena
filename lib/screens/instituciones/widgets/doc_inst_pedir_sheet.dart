// lib/screens/instituciones/widgets/doc_inst_pedir_sheet.dart
//
// ATENA – Hoja para pedirle un documento a un alumno.
// Paso 1: elegir el alumno (buscador). Paso 2: tipo de documento,
// indicaciones y fecha límite. Devuelve el PedidoDocumento creado.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';
import 'doc_inst_comunes.dart';

/// Abre la hoja de "Pedir documento". Devuelve el pedido creado o null.
Future<PedidoDocumento?> showDocInstPedirSheet(
  BuildContext context, {
  required String institucionId,
  required String institucionNombre,
  required List<DocInstAlumno> alumnos,
}) {
  return showModalBottomSheet<PedidoDocumento>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _PedirSheet(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      alumnos: alumnos,
    ),
  );
}

class _PedirSheet extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final List<DocInstAlumno> alumnos;

  const _PedirSheet({
    required this.institucionId,
    required this.institucionNombre,
    required this.alumnos,
  });

  @override
  State<_PedirSheet> createState() => _PedirSheetState();
}

class _PedirSheetState extends State<_PedirSheet> {
  final _formKey = GlobalKey<FormState>();
  final _buscar = TextEditingController();
  final _detalle = TextEditingController();
  final _limiteCtrl = TextEditingController();

  DocInstAlumno? _alumno;
  TipoDocumento? _tipo;
  DateTime? _limite;
  String _busqueda = '';
  bool _errorTipo = false;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _buscar.dispose();
    _detalle.dispose();
    _limiteCtrl.dispose();
    super.dispose();
  }

  List<DocInstAlumno> _filtrados() {
    final q = normalizarBusqueda(_busqueda);
    if (q.isEmpty) return widget.alumnos;
    return [
      for (final a in widget.alumnos)
        if (normalizarBusqueda(
          '${a.alumno.nombreCompleto} ${a.alumno.apellidoNombre} '
          '${a.alumno.dni}',
        ).contains(q))
          a,
    ];
  }

  Future<void> _elegirLimite() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _limite ?? DateUtils.addDaysToDate(hoy, 7),
      firstDate: hoy,
      lastDate: DateTime(hoy.year + 2, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _limite = elegida;
      _limiteCtrl.text = AtenaFormat.fechaCorta(context, elegida);
    });
  }

  void _quitarLimite() {
    setState(() {
      _limite = null;
      _limiteCtrl.clear();
    });
  }

  Future<void> _enviar() async {
    final alumno = _alumno?.alumno;
    if (_enviando || alumno == null) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    final formOk = _formKey.currentState?.validate() ?? false;
    final tipo = _tipo;
    setState(() => _errorTipo = tipo == null);
    if (!formOk || tipo == null) return;

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      // El listado pudo quedar viejo (por ejemplo, la familia eliminó su
      // cuenta): solo se pide si el alumno sigue teniendo una solicitud activa.
      final solicitudes = await SolicitudesRepo.instance.porInstitucion(
        widget.institucionId,
      );
      final sigue = solicitudes.any(
        (s) => s.alumno.perfilId == alumno.perfilId && s.estado.esActiva,
      );
      if (!sigue) throw const AtenaException(AtenaError.noEncontrado);

      final pedido = await DocumentosRepo.instance.solicitar(
        institucionId: widget.institucionId,
        institucionNombre: widget.institucionNombre,
        cuentaId: alumno.cuentaId,
        perfilId: alumno.perfilId,
        alumnoNombre: alumno.nombreCompleto,
        tipo: tipo,
        detalle: _detalle.text.trim(),
        fechaLimite: _limite,
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
    final alto = MediaQuery.sizeOf(context).height * 0.88;
    final alumno = _alumno;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: widget.alumnos.isEmpty
          ? _sinAlumnos(context)
          : alumno == null
          ? SizedBox(height: alto, child: _pasoAlumno(context))
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: alto),
              child: _pasoPedido(context, alumno),
            ),
    );
  }

  Widget _sinAlumnos(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtenaEmptyState(
            compact: true,
            icon: Icons.person_search_rounded,
            title: t.docInstSinAlumnosTitulo,
            message: t.docInstSinAlumnosMensaje,
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.uiClose),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pasoAlumno(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filtrados = _filtrados();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _Titulo(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
          child: Text(t.docInstElegirAlumno, style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _buscar,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: t.docInstBuscarAlumno,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: t.docInstLimpiarBusqueda,
                      onPressed: () {
                        _buscar.clear();
                        setState(() => _busqueda = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: (v) => setState(() => _busqueda = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtrados.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    t.docInstSinResultados,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, _) => const Divider(indent: 68),
                  itemBuilder: (_, i) => _AlumnoTile(
                    alumno: filtrados[i],
                    onTap: () => setState(() => _alumno = filtrados[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _pasoPedido(BuildContext context, DocInstAlumno alumno) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final esOtro = _tipo == TipoDocumento.otro;
    final error = (_error ?? '').trim();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Titulo(),
            const SizedBox(height: 18),
            AtenaCard(
              color: cs.surfaceContainerLow,
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
              child: _AlumnoTile(
                alumno: alumno,
                trailing: TextButton(
                  onPressed: _enviando
                      ? null
                      : () => setState(() {
                          _alumno = null;
                          _error = null;
                        }),
                  child: Text(t.docInstCambiarAlumno),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(t.docInstQueDocumento, style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final tipo in TipoDocumento.values)
                  ChoiceChip(
                    avatar: Icon(iconoDocumento(tipo)),
                    label: Text(t.tipoDocumento(tipo)),
                    selected: _tipo == tipo,
                    showCheckmark: false,
                    onSelected: _enviando
                        ? null
                        : (_) => setState(() {
                            _tipo = tipo;
                            _errorTipo = false;
                          }),
                  ),
              ],
            ),
            if (_errorTipo)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t.docInstErrorTipo,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                ),
              ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _detalle,
              enabled: !_enviando,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: InputDecoration(
                labelText: esOtro
                    ? t.docInstNombreOtroLabel
                    : t.docInstIndicacionesLabel,
                helperText: esOtro
                    ? t.docInstNombreOtroAyuda
                    : t.docInstIndicacionesAyuda,
                prefixIcon: Icon(
                  esOtro
                      ? Icons.drive_file_rename_outline_rounded
                      : Icons.notes_rounded,
                ),
              ),
              validator: (v) => esOtro ? AuthValidators.required(t, v) : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _limiteCtrl,
              enabled: !_enviando,
              readOnly: true,
              enableInteractiveSelection: false,
              onTap: _elegirLimite,
              decoration: InputDecoration(
                labelText: t.docInstFechaLimiteLabel,
                prefixIcon: const Icon(Icons.event_rounded),
                suffixIcon: _limite == null
                    ? const Icon(Icons.calendar_month_rounded)
                    : IconButton(
                        tooltip: t.docInstQuitarFechaLimite,
                        onPressed: _enviando ? null : _quitarLimite,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 14),
              AtenaBanner(tone: AtenaBannerTone.error, message: error),
            ],
            const SizedBox(height: 20),
            AuthSubmitButton(
              label: t.docInstPedirDocumento,
              loadingLabel: t.commonSending,
              loading: _enviando,
              onPressed: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtenaIconBadge(
          icon: Icons.note_add_rounded,
          color: AtenaColors.warning,
          size: 48,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.docInstPedirTitulo, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                t.docInstPedirAyuda,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Alumno con sus cursos o grupos (y si todavía tiene la solicitud pendiente).
class _AlumnoTile extends StatelessWidget {
  final DocInstAlumno alumno;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _AlumnoTile({required this.alumno, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final a = alumno.alumno;
    final detalle = [
      ...alumno.ofertas,
      if (!alumno.confirmado) t.docInstSolicitudPendiente,
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: AtenaAvatar(name: a.nombreCompleto, size: 40),
      title: Text(
        a.apellidoNombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: detalle.isEmpty
          ? null
          : Text(detalle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing:
          trailing ??
          (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    );
  }
}
