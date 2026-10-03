// lib/screens/alumnos/mis_solicitudes_page.dart
//
// ATENA – Solicitudes de vacante del alumno.
// - MisSolicitudesPage: pestañas "Activas" (pendientes y confirmadas) e
//   "Historial" (el resto), con acceso a Explorar cuando no hay ninguna.
// - SolicitudAlumnoDetallePage: estado explicado, datos de la vacante,
//   mensajes, seguimiento, comprobante y cancelación.

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../pdf/atena_pdf.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'alumno_calendario_page.dart';
import 'alumno_documentos_page.dart';
import 'explorar_instituciones_page.dart';
import 'institucion_publica_page.dart';
import 'widgets/explorar_comun.dart';
import 'widgets/sol_al_widgets.dart';

// -----------------------------------------------------------------------------
// Lista
// -----------------------------------------------------------------------------

class MisSolicitudesPage extends StatefulWidget {
  final String cuentaId;
  final String perfilId;

  const MisSolicitudesPage({
    super.key,
    required this.cuentaId,
    required this.perfilId,
  });

  @override
  State<MisSolicitudesPage> createState() => _MisSolicitudesPageState();
}

class _MisSolicitudesPageState extends State<MisSolicitudesPage> {
  static const double _ancho = 760;

  List<Solicitud> _activas = const [];
  List<Solicitud> _historial = const [];
  String _alumno = '';
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait<Object?>([
        SolicitudesRepo.instance.porPerfil(widget.perfilId),
        AlumnosRepo.instance.perfilDeCuenta(widget.cuentaId, widget.perfilId),
      ]);
      final todas = [...r[0] as List<Solicitud>]
        ..sort((a, b) => b.actualizadaEl.compareTo(a.actualizadaEl));
      final perfil = r[1] as PerfilAlumno?;
      if (!mounted) return;
      setState(() {
        _activas = todas.where((s) => s.estado.esActiva).toList();
        _historial = todas.where((s) => !s.estado.esActiva).toList();
        _alumno = perfil?.displayName ?? '';
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _recargar() {
    setState(() => _loading = true);
    _load();
  }

  Future<void> _abrir(Solicitud s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SolicitudAlumnoDetallePage(
          cuentaId: widget.cuentaId,
          perfilId: widget.perfilId,
          solicitudId: s.id,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _explorar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExplorarInstitucionesPage(
          cuentaId: widget.cuentaId,
          perfilId: widget.perfilId,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final contar = !_loading && _error == null;

    return DefaultTabController(
      length: 2,
      child: AtenaScaffold(
        role: AtenaRole.alumno,
        appBar: AtenaAppBar(
          title: t.solAlTitulo,
          subtitle: _alumno.isEmpty ? null : _alumno,
          actions: [
            IconButton(
              tooltip: t.commonRefresh,
              onPressed: _loading ? null : _recargar,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _ancho),
                child: TabBar(
                  tabs: [
                    Tab(
                      child: _EtiquetaTab(
                        texto: t.solAlTabActivas,
                        cantidad: contar ? _activas.length : null,
                      ),
                    ),
                    Tab(
                      child: _EtiquetaTab(
                        texto: t.solAlTabHistorial,
                        cantidad: contar ? _historial.length : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _loading
            ? const AtenaLoading()
            : _error != null
            ? AtenaErrorState(
                message: coreErrorText(t, _error!),
                onRetry: _recargar,
              )
            : TabBarView(
                children: [
                  _ListaSolicitudes(
                    items: _activas,
                    onRefresh: _load,
                    onOpen: _abrir,
                    vacio: AtenaEmptyState(
                      icon: Icons.assignment_outlined,
                      title: t.solAlActivasVacioTitulo,
                      message: t.solAlActivasVacioMensaje,
                      action: FilledButton.icon(
                        onPressed: _explorar,
                        icon: const Icon(Icons.travel_explore_rounded),
                        label: Text(t.homeActionExplore),
                      ),
                    ),
                  ),
                  _ListaSolicitudes(
                    items: _historial,
                    onRefresh: _load,
                    onOpen: _abrir,
                    vacio: AtenaEmptyState(
                      icon: Icons.history_rounded,
                      title: t.solAlHistorialVacioTitulo,
                      message: t.solAlHistorialVacioMensaje,
                      action: OutlinedButton.icon(
                        onPressed: _explorar,
                        icon: const Icon(Icons.travel_explore_rounded),
                        label: Text(t.homeActionExplore),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EtiquetaTab extends StatelessWidget {
  final String texto;
  final int? cantidad;

  const _EtiquetaTab({required this.texto, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final estilo = DefaultTextStyle.of(context).style;
    final color = estilo.color ?? Theme.of(context).colorScheme.onSurface;
    final n = cantidad;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (n != null && n > 0) ...[
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AtenaRadius.pill,
            ),
            child: Text(
              '$n',
              textAlign: TextAlign.center,
              style: estilo.copyWith(fontSize: 12, color: color),
            ),
          ),
        ],
      ],
    );
  }
}

class _ListaSolicitudes extends StatelessWidget {
  final List<Solicitud> items;
  final Future<void> Function() onRefresh;
  final ValueChanged<Solicitud> onOpen;
  final Widget vacio;

  const _ListaSolicitudes({
    required this.items,
    required this.onRefresh,
    required this.onOpen,
    required this.vacio,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: atenaPagePadding(
          context,
          maxWidth: _MisSolicitudesPageState._ancho,
          top: AtenaSpace.md,
        ),
        children: items.isEmpty
            ? [vacio]
            : [
                for (final s in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtenaSpace.sm),
                    child: SolAlSolicitudCard(
                      solicitud: s,
                      onTap: () => onOpen(s),
                    ),
                  ),
              ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Detalle
// -----------------------------------------------------------------------------

class SolicitudAlumnoDetallePage extends StatefulWidget {
  final String cuentaId;
  final String perfilId;
  final String solicitudId;

  const SolicitudAlumnoDetallePage({
    super.key,
    required this.cuentaId,
    required this.perfilId,
    required this.solicitudId,
  });

  @override
  State<SolicitudAlumnoDetallePage> createState() =>
      _SolicitudAlumnoDetallePageState();
}

class _SolicitudAlumnoDetallePageState
    extends State<SolicitudAlumnoDetallePage> {
  Solicitud? _s;

  /// false si la institución ya no está en ATENA (se dio de baja).
  bool _institucionDisponible = true;
  bool _loading = true;
  Object? _error;
  bool _cancelando = false;
  bool _generando = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final leida = await SolicitudesRepo.instance.obtener(widget.solicitudId);
      // Solo se muestra si pertenece al alumno activo.
      final s = leida != null && leida.alumno.perfilId == widget.perfilId
          ? leida
          : null;
      final disponible = s != null && await _existeInstitucion(s.institucionId);
      if (!mounted) return;
      setState(() {
        _s = s;
        _institucionDisponible = disponible;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// Una institución dada de baja deja sus solicitudes en el historial de las
  /// familias: si ya no existe, no se ofrece abrir su ficha.
  static Future<bool> _existeInstitucion(String institucionId) async {
    try {
      final inst = await InstitucionesRepo.instance.obtener(institucionId);
      return inst != null && inst.nombre.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ir(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  void _verInstitucion(Solicitud s) => _ir(
    InstitucionPublicaPage(
      cuentaId: widget.cuentaId,
      perfilId: widget.perfilId,
      institucionId: s.institucionId,
    ),
  );

  void _documentos() => _ir(
    AlumnoDocumentosPage(
      ownerAccountId: widget.cuentaId,
      perfilId: widget.perfilId,
    ),
  );

  void _calendario() => _ir(
    AlumnoCalendarioPage(
      ownerAccountId: widget.cuentaId,
      perfilId: widget.perfilId,
    ),
  );

  void _explorar() => _ir(
    ExplorarInstitucionesPage(
      cuentaId: widget.cuentaId,
      perfilId: widget.perfilId,
    ),
  );

  /// [desde] es el contexto del botón (dentro de la página), para que el
  /// diálogo herede los colores del área del alumno.
  Future<void> _cancelar(BuildContext desde) async {
    final s = _s;
    if (s == null || _cancelando) return;
    final t = AppLocalizations.of(context);
    final confirmada = s.estado == EstadoSolicitud.confirmada;
    final inst = solAlInstitucion(t, s);
    final ok = await showAtenaConfirm(
      desde,
      title: t.solAlCancelarTitulo,
      message: confirmada
          ? t.solAlCancelarMsgConfirmada(s.ofertaNombre, inst)
          : t.solAlCancelarMsgPendiente(s.ofertaNombre, inst),
      confirmLabel: t.solAlCancelarConfirmar,
      cancelLabel: t.solAlMantener,
      destructive: true,
      icon: Icons.block_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _cancelando = true);
    try {
      final actualizada = await SolicitudesRepo.instance.cancelar(
        s.id,
        perfilId: widget.perfilId,
      );
      if (!mounted) return;
      setState(() {
        _s = actualizada;
        _cancelando = false;
      });
      AtenaFeedback.success(context, t.solAlCanceladaOk);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      AtenaFeedback.error(context, coreErrorText(t, e));
      await _load();
    }
  }

  Future<void> _comprobante() async {
    final s = _s;
    if (s == null || _generando) return;
    final t = AppLocalizations.of(context);
    setState(() => _generando = true);
    try {
      final bytes = await AtenaPdf.comprobanteSolicitud(t: t, solicitud: s);
      if (!mounted) return;
      await AtenaPdf.compartir(context, bytes, 'comprobante-${_codigo(s)}.pdf');
    } catch (_) {
      if (mounted) AtenaFeedback.error(context, t.solAlComprobanteError);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  /// Código corto para el nombre del archivo: los últimos 8 caracteres del
  /// identificador, igual que el código impreso en el comprobante.
  static String _codigo(Solicitud s) {
    final limpio = s.id.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    final desde = limpio.length > 8 ? limpio.length - 8 : 0;
    return limpio.substring(desde).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = _s;

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AtenaAppBar(
        title: t.solAlDetalleTitulo,
        subtitle: s == null ? null : solAlInstitucion(t, s, inicio: true),
      ),
      body: _loading
          ? const AtenaLoading()
          : _error != null
          ? AtenaErrorState(
              message: coreErrorText(t, _error!),
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : s == null
          ? AtenaEmptyState(
              icon: Icons.search_off_rounded,
              title: t.solAlNoEncontradaTitulo,
              message: t.solAlNoEncontradaMensaje,
              action: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(t.commonBack),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: atenaPagePadding(context, maxWidth: 760),
                children: _contenido(context, s),
              ),
            ),
    );
  }

  List<Widget> _contenido(BuildContext context, Solicitud s) {
    final t = AppLocalizations.of(context);
    final respuesta = s.respuesta.trim();
    final mensaje = s.mensaje.trim();
    final hitos = s.historial.isNotEmpty
        ? ([...s.historial]..sort((a, b) => a.fecha.compareTo(b.fecha)))
        : [CambioEstado(estado: s.estado, fecha: s.actualizadaEl)];
    const gap = SizedBox(height: AtenaSpace.md);

    return [
      _EstadoPanel(
        solicitud: s,
        institucionDisponible: _institucionDisponible,
        onDocumentos: _documentos,
        onCalendario: _calendario,
        onExplorar: _explorar,
      ),
      if (respuesta.isNotEmpty) ...[
        gap,
        SolAlCita(
          titulo: t.solAlRespuestaDe(solAlInstitucion(t, s)),
          texto: respuesta,
          color: colorEstadoSolicitud(s.estado),
          icon: Icons.forum_rounded,
        ),
      ],
      gap,
      AtenaSectionHeader(title: t.solAlLaVacante),
      _VacanteCard(
        solicitud: s,
        onVerInstitucion: _institucionDisponible
            ? () => _verInstitucion(s)
            : null,
      ),
      if (mensaje.isNotEmpty) ...[
        gap,
        AtenaSectionHeader(title: t.solAlTuMensaje),
        AtenaCard(
          child: Text(mensaje, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
      gap,
      AtenaSectionHeader(title: t.solAlSeguimiento),
      AtenaCard(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: SolAlLineaDeTiempo(hitos: hitos),
      ),
      const SizedBox(height: AtenaSpace.xl),
      OutlinedButton.icon(
        onPressed: _generando ? null : _comprobante,
        icon: _generando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(_generando ? t.commonGenerating : t.solAlComprobante),
      ),
      if (s.estado.esActiva) ...[
        const SizedBox(height: AtenaSpace.sm),
        _BotonCancelar(cargando: _cancelando, onPressed: _cancelar),
      ],
    ];
  }
}

/// Estado actual con una explicación clara y los próximos pasos.
class _EstadoPanel extends StatelessWidget {
  final Solicitud solicitud;

  /// false si la institución ya no está en ATENA.
  final bool institucionDisponible;
  final VoidCallback onDocumentos;
  final VoidCallback onCalendario;
  final VoidCallback onExplorar;

  const _EstadoPanel({
    required this.solicitud,
    required this.institucionDisponible,
    required this.onDocumentos,
    required this.onCalendario,
    required this.onExplorar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = solicitud;
    final inst = solAlInstitucion(t, s, inicio: true);
    final tono = AtenaTone.of(context, colorEstadoSolicitud(s.estado));
    final bajaSinInstitucion =
        s.estado == EstadoSolicitud.canceladaPorInstitucion &&
        !institucionDisponible;

    final (IconData icono, String titulo, String mensaje) = switch (s.estado) {
      EstadoSolicitud.pendiente => (
        Icons.hourglass_top_rounded,
        t.solAlEstadoPendienteTitulo,
        t.solAlEstadoPendienteMensaje(inst),
      ),
      EstadoSolicitud.confirmada => (
        Icons.celebration_rounded,
        t.solAlEstadoConfirmadaTitulo,
        t.solAlEstadoConfirmadaMensaje(inst),
      ),
      EstadoSolicitud.rechazada => (
        Icons.cancel_rounded,
        t.solAlEstadoRechazadaTitulo,
        t.solAlEstadoRechazadaMensaje(inst),
      ),
      EstadoSolicitud.canceladaPorAlumno => (
        Icons.block_rounded,
        t.solAlEstadoCanceladaTitulo,
        t.solAlEstadoCanceladaMensaje,
      ),
      EstadoSolicitud.canceladaPorInstitucion => (
        Icons.person_remove_rounded,
        t.solAlEstadoBajaTitulo,
        bajaSinInstitucion
            ? t.solAlEstadoBajaSinInstMensaje(inst)
            : t.solAlEstadoBajaMensaje(inst),
      ),
    };

    // Botones claros sobre el panel teñido (se leen bien en claro y oscuro).
    final estilo = FilledButton.styleFrom(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
    );
    final acciones = <Widget>[
      if (s.estado == EstadoSolicitud.confirmada) ...[
        FilledButton.tonalIcon(
          onPressed: onDocumentos,
          style: estilo,
          icon: const Icon(Icons.folder_shared_rounded),
          label: Text(t.homeActionDocuments),
        ),
        FilledButton.tonalIcon(
          onPressed: onCalendario,
          style: estilo,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(t.homeActionCalendar),
        ),
      ],
      if (s.estado == EstadoSolicitud.rechazada || bajaSinInstitucion)
        FilledButton.tonalIcon(
          onPressed: onExplorar,
          style: estilo,
          icon: const Icon(Icons.travel_explore_rounded),
          label: Text(t.homeActionExplore),
        ),
    ];

    return AtenaCard(
      color: Color.alphaBlend(tono.background, theme.colorScheme.surface),
      borderColor: tono.color.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tono.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: tono.foreground, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AtenaStatusChip(
                      label: t.estadoSolicitud(s.estado),
                      color: tono.color,
                      icon: iconoEstadoSolicitud(s.estado),
                      dense: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titulo,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: tono.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(mensaje, style: theme.textTheme.bodyLarge),
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            // En teléfono, botones a todo el ancho; en pantallas anchas, en fila.
            LayoutBuilder(
              builder: (context, c) => c.maxWidth < 420
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, a) in acciones.indexed) ...[
                          if (i > 0) const SizedBox(height: 10),
                          a,
                        ],
                      ],
                    )
                  : Wrap(spacing: 10, runSpacing: 10, children: acciones),
            ),
          ],
        ],
      ),
    );
  }
}

/// Datos de la vacante pedida y de la institución.
class _VacanteCard extends StatelessWidget {
  final Solicitud solicitud;

  /// null = la institución ya no está en ATENA (no se puede abrir su ficha).
  final VoidCallback? onVerInstitucion;

  const _VacanteCard({required this.solicitud, required this.onVerInstitucion});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final o = solicitud.oferta;
    final alumno = solicitud.alumno;
    final horario = o.horario.trim();
    final dias = o.dias.trim();
    final rango = explorarRangoEdad(t, o.edadMinima, o.edadMaxima);
    final arancel = o.arancel.trim();
    final edad = alumno.edad;
    final nombreAlumno = alumno.nombre.trim().isEmpty
        ? alumno.nombreCompleto
        : alumno.nombre.trim();
    final institucion = solAlInstitucion(t, solicitud, inicio: true);

    return AtenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                AtenaIconBadge(icon: iconoOferta(o), size: 48),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 2),
                      Text(
                        '${t.categoriaOferta(o)} · ${t.tipoOferta(o.tipo)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                AtenaInfoRow(
                  icon: Icons.schedule_rounded,
                  label: t.solAlTurnoHorario,
                  value: [
                    t.turno(o.turno),
                    if (horario.isNotEmpty) horario,
                  ].join(' · '),
                ),
                if (dias.isNotEmpty)
                  AtenaInfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: t.solAlDias,
                    value: dias,
                  ),
                if (rango.isNotEmpty)
                  AtenaInfoRow(
                    icon: Icons.cake_rounded,
                    label: t.solAlEdad,
                    value: edad == null || nombreAlumno.isEmpty
                        ? rango
                        : '$rango · ${t.solAlEdadAlumno(nombreAlumno, t.lblEdadAnios(edad))}',
                  ),
                if (arancel.isNotEmpty)
                  AtenaInfoRow(
                    icon: Icons.payments_rounded,
                    label: t.solAlArancel,
                    value: arancel,
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 14),
            child: Row(
              children: [
                AtenaAvatar(
                  name: solicitud.institucionNombre,
                  size: 40,
                  fallbackIcon: Icons.account_balance_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        onVerInstitucion == null
                            ? t.solAlInstNoDisponible
                            : t.commonInstitution,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        institucion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                if (onVerInstitucion != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onVerInstitucion,
                    child: Text(t.explorarVerInstitucion),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonCancelar extends StatelessWidget {
  final bool cargando;

  /// Recibe el contexto del botón para abrir el diálogo desde la página.
  final void Function(BuildContext context) onPressed;

  const _BotonCancelar({required this.cargando, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: cargando ? null : () => onPressed(context),
      style: TextButton.styleFrom(
        foregroundColor: cs.error,
        minimumSize: const Size.fromHeight(48),
      ),
      icon: cargando
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: cs.error,
              ),
            )
          : const Icon(Icons.block_rounded),
      label: Text(t.solAlCancelar),
    );
  }
}
