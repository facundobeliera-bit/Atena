// lib/screens/alumno/alumno_home_page.dart
//
// ATENA – Inicio del alumno.
// Resumen del alumno, accesos a todas las funciones, últimas solicitudes y
// próximos eventos.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../routes/atena_nav.dart';
import '../../services/auth_service.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import '../../ui/widgets/atena_preferences_sheet.dart';
import '../alumnos/alumno_calendario_page.dart';
import '../alumnos/alumno_documentos_page.dart';
import '../alumnos/explorar_instituciones_page.dart';
import '../alumnos/mis_solicitudes_page.dart';
import '../comunes/eliminar_cuenta_dialog.dart';
import '../comunes/notificaciones_page.dart';
import '../cuentas/cuenta_home_page.dart';
import 'alumno_ficha_page.dart';
import 'alumno_perfil_form_page.dart';

/// Abre el trámite relacionado con una notificación del alumno.
Future<void> abrirNotificacionAlumno(
  BuildContext context,
  Notificacion n, {
  required String cuentaId,
  required String perfilId,
}) async {
  final perfil = n.perfilId.isNotEmpty ? n.perfilId : perfilId;
  final Widget? page = switch (n.destino) {
    DestinoNotificacion.solicitud => SolicitudAlumnoDetallePage(
      cuentaId: cuentaId,
      perfilId: perfil,
      solicitudId: n.destinoId,
    ),
    DestinoNotificacion.documento => AlumnoDocumentosPage(
      ownerAccountId: cuentaId,
      perfilId: perfil,
      initialDocumentoId: n.destinoId,
    ),
    DestinoNotificacion.evento => AlumnoCalendarioPage(
      ownerAccountId: cuentaId,
      perfilId: perfil,
      initialItemId: n.destinoId,
    ),
    _ => null,
  };
  if (page == null) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class AlumnoHomePage extends StatefulWidget {
  final String cuentaId;
  final String perfilId;

  const AlumnoHomePage({
    super.key,
    required this.cuentaId,
    required this.perfilId,
  });

  @override
  State<AlumnoHomePage> createState() => _AlumnoHomePageState();
}

class _AlumnoHomePageState extends State<AlumnoHomePage> {
  PerfilAlumno? _perfil;
  Uint8List? _foto;
  int _cantidadPerfiles = 1;
  List<Solicitud> _solicitudes = const [];
  List<Evento> _eventos = const [];
  int _docsPendientes = 0;
  int _noLeidas = 0;

  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final alumnos = AlumnosRepo.instance;
      final perfil = await alumnos.perfilDeCuenta(
        widget.cuentaId,
        widget.perfilId,
      );
      if (perfil == null) {
        throw const AtenaException(AtenaError.noEncontrado);
      }
      final results = await Future.wait<Object?>([
        alumnos.foto(widget.perfilId),
        alumnos.perfiles(widget.cuentaId),
        SolicitudesRepo.instance.porPerfil(widget.perfilId),
        CalendarioRepo.instance.eventosAlumno(widget.perfilId),
        DocumentosRepo.instance.porPerfil(widget.perfilId),
        NotificacionesRepo.instance.noLeidas(
          widget.cuentaId,
          perfilId: widget.perfilId,
        ),
      ]);

      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      final eventos = (results[3] as List<Evento>)
          .where((e) => !e.finEfectivo.isBefore(inicioHoy))
          .toList();
      final docs = results[4] as List<PedidoDocumento>;

      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _foto = results[0] as Uint8List?;
        _cantidadPerfiles = (results[1] as List).length;
        _solicitudes = results[2] as List<Solicitud>;
        _eventos = eventos;
        _docsPendientes = docs.where((d) => d.requiereAccionAlumno).length;
        _noLeidas = results[5] as int;
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

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  void _explorar() => _go(
    ExplorarInstitucionesPage(
      cuentaId: widget.cuentaId,
      perfilId: widget.perfilId,
    ),
  );

  void _solicitudesPage() => _go(
    MisSolicitudesPage(cuentaId: widget.cuentaId, perfilId: widget.perfilId),
  );

  void _calendario() => _go(
    AlumnoCalendarioPage(
      ownerAccountId: widget.cuentaId,
      perfilId: widget.perfilId,
    ),
  );

  void _documentos() => _go(
    AlumnoDocumentosPage(
      ownerAccountId: widget.cuentaId,
      perfilId: widget.perfilId,
    ),
  );

  void _ficha() => _go(
    AlumnoFichaPage(cuentaId: widget.cuentaId, perfilId: widget.perfilId),
  );

  void _notificaciones() => _go(
    NotificacionesPage(
      cuentaId: widget.cuentaId,
      perfilId: widget.perfilId,
      role: AtenaRole.alumno,
      onOpen: (ctx, n) => abrirNotificacionAlumno(
        ctx,
        n,
        cuentaId: widget.cuentaId,
        perfilId: widget.perfilId,
      ),
    ),
  );

  void _cambiarAlumno() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            CuentaHomePage(cuentaId: widget.cuentaId, seleccionar: true),
      ),
      (_) => false,
    );
  }

  Future<void> _agregarAlumno() async {
    final creado = await Navigator.of(context).push<PerfilAlumno>(
      MaterialPageRoute(
        builder: (_) => AlumnoPerfilFormPage(cuentaId: widget.cuentaId),
      ),
    );
    if (creado != null && mounted) _cambiarAlumno();
  }

  Future<void> _logout() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.uiLogoutConfirm,
      confirmLabel: t.commonLogout,
      icon: Icons.logout_rounded,
    );
    if (ok && mounted) await AtenaNav.logout(context);
  }

  Future<void> _eliminarCuenta() async {
    final t = AppLocalizations.of(context);
    final eliminada = await showEliminarCuentaDialog(
      context,
      descripcion: t.deleteAccountFamilyBody,
      eliminar: (password) => AuthService.eliminarCuentaFamilia(
        cuentaId: widget.cuentaId,
        password: password,
      ),
    );
    if (!eliminada || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    AtenaNav.toLanding(context);
    messenger.showSnackBar(SnackBar(content: Text(t.deleteAccountDone)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AppBar(
        title: const AtenaLogo(markSize: 30),
        actions: [
          IconButton(
            tooltip: t.notifTitle,
            onPressed: _notificaciones,
            icon: Badge(
              isLabelVisible: _noLeidas > 0,
              label: Text(_noLeidas > 99 ? '99+' : '$_noLeidas'),
              child: const Icon(Icons.notifications_rounded),
            ),
          ),
          const AtenaPreferencesButton(),
          PopupMenuButton<String>(
            tooltip: t.uiMoreOptions,
            onSelected: (v) {
              switch (v) {
                case 'switch':
                  _cambiarAlumno();
                case 'add':
                  _agregarAlumno();
                case 'logout':
                  _logout();
                case 'delete':
                  _eliminarCuenta();
              }
            },
            itemBuilder: (_) => [
              if (_cantidadPerfiles > 1)
                PopupMenuItem(
                  value: 'switch',
                  child: ListTile(
                    leading: const Icon(Icons.switch_account_rounded),
                    title: Text(t.homeSwitchStudent),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: 'add',
                child: ListTile(
                  leading: const Icon(Icons.person_add_alt_rounded),
                  title: Text(t.hubAddStudent),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(t.commonLogout),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.person_remove_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    t.deleteAccount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
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
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: atenaPagePadding(context),
                children: [
                  _Hero(
                    perfil: _perfil!,
                    foto: _foto,
                    activas: _solicitudes
                        .where((s) => s.estado.esActiva)
                        .length,
                    eventos: _eventos.length,
                    docs: _docsPendientes,
                    puedeCambiar: _cantidadPerfiles > 1,
                    onCambiar: _cambiarAlumno,
                    onFicha: _ficha,
                  ),
                  const SizedBox(height: 24),
                  AtenaFeatureGrid(
                    children: [
                      AtenaFeatureCard(
                        icon: Icons.travel_explore_rounded,
                        title: t.homeActionExplore,
                        subtitle: t.homeActionExploreSub,
                        onTap: _explorar,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.assignment_rounded,
                        title: t.homeActionRequests,
                        subtitle: t.homeActionRequestsSub,
                        accent: AtenaColors.indigo,
                        onTap: _solicitudesPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.calendar_month_rounded,
                        title: t.homeActionCalendar,
                        subtitle: t.homeActionCalendarSub,
                        accent: AtenaColors.violet,
                        onTap: _calendario,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.folder_shared_rounded,
                        title: t.homeActionDocuments,
                        subtitle: t.homeActionDocumentsSub,
                        accent: AtenaColors.warning,
                        badgeCount: _docsPendientes,
                        onTap: _documentos,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.notifications_rounded,
                        title: t.notifTitle,
                        subtitle: t.homeActionNotificationsSub,
                        accent: AtenaColors.info,
                        badgeCount: _noLeidas,
                        onTap: _notificaciones,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.badge_rounded,
                        title: t.homeActionProfile,
                        subtitle: t.homeActionProfileSub,
                        accent: AtenaColors.success,
                        onTap: _ficha,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AtenaSectionHeader(
                    title: t.homeRecentRequests,
                    action: _solicitudes.isEmpty
                        ? null
                        : TextButton(
                            onPressed: _solicitudesPage,
                            child: Text(t.uiSeeAll),
                          ),
                  ),
                  if (_solicitudes.isEmpty)
                    _EmptyRequestsCard(onExplore: _explorar)
                  else
                    AtenaCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < _solicitudes.length && i < 3;
                            i++
                          ) ...[
                            if (i > 0) const Divider(indent: 72),
                            _SolicitudTile(
                              s: _solicitudes[i],
                              onTap: () => _go(
                                SolicitudAlumnoDetallePage(
                                  cuentaId: widget.cuentaId,
                                  perfilId: widget.perfilId,
                                  solicitudId: _solicitudes[i].id,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  AtenaSectionHeader(
                    title: t.homeStatUpcomingEvents,
                    action: _eventos.isEmpty
                        ? null
                        : TextButton(
                            onPressed: _calendario,
                            child: Text(t.uiSeeAll),
                          ),
                  ),
                  if (_eventos.isEmpty)
                    AtenaCard(
                      child: Row(
                        children: [
                          const AtenaIconBadge(
                            icon: Icons.event_available_rounded,
                            color: AtenaColors.violet,
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(t.homeNoEvents)),
                        ],
                      ),
                    )
                  else
                    AtenaCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < _eventos.length && i < 3;
                            i++
                          ) ...[
                            if (i > 0) const Divider(indent: 76),
                            _EventoTile(
                              e: _eventos[i],
                              onTap: () => _go(
                                AlumnoCalendarioPage(
                                  ownerAccountId: widget.cuentaId,
                                  perfilId: widget.perfilId,
                                  initialItemId: _eventos[i].id,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  final PerfilAlumno perfil;
  final Uint8List? foto;
  final int activas;
  final int eventos;
  final int docs;
  final bool puedeCambiar;
  final VoidCallback onCambiar;
  final VoidCallback onFicha;

  const _Hero({
    required this.perfil,
    required this.foto,
    required this.activas,
    required this.eventos,
    required this.docs,
    required this.puedeCambiar,
    required this.onCambiar,
    required this.onFicha,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nombre = perfil.nombre.trim().isEmpty
        ? perfil.displayName
        : perfil.nombre.trim();

    return AtenaGradientPanel(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onFicha,
                customBorder: const CircleBorder(),
                child: AtenaAvatar(
                  name: perfil.displayName,
                  imageBytes: foto,
                  size: 58,
                  ring: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.homeHello(nombre),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.homeStudentSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (puedeCambiar)
                IconButton.filledTonal(
                  tooltip: t.homeSwitchStudent,
                  onPressed: onCambiar,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.switch_account_rounded),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AtenaStat(
                  value: '$activas',
                  label: t.homeStatActiveRequestsN(activas),
                  onGradient: true,
                ),
              ),
              Expanded(
                child: AtenaStat(
                  value: '$eventos',
                  label: t.homeStatUpcomingEventsN(eventos),
                  onGradient: true,
                ),
              ),
              Expanded(
                child: AtenaStat(
                  value: '$docs',
                  label: t.homeStatPendingDocsN(docs),
                  onGradient: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRequestsCard extends StatelessWidget {
  final VoidCallback onExplore;

  const _EmptyRequestsCard({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AtenaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AtenaIconBadge(icon: Icons.travel_explore_rounded, size: 48),
          const SizedBox(height: 14),
          Text(t.homeNoRequestsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            t.homeNoRequestsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.search_rounded),
            label: Text(t.homeActionExplore),
          ),
        ],
      ),
    );
  }
}

class _SolicitudTile extends StatelessWidget {
  final Solicitud s;
  final VoidCallback onTap;

  const _SolicitudTile({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            AtenaIconBadge(icon: iconoOferta(s.oferta), size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.institucionNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.ofertaNombre} · ${t.categoriaOferta(s.oferta)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AtenaStatusChip(
              label: t.estadoSolicitud(s.estado),
              color: colorEstadoSolicitud(s.estado),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  final Evento e;
  final VoidCallback onTap;

  const _EventoTile({required this.e, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = colorTipoEvento(e.tipo);
    final tone = AtenaTone.of(context, color);
    final mes = AtenaFormat.mesCorto(context, e.inicio);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${e.inicio.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tone.foreground,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    mes,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tone.foreground,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      t.tipoEvento(e.tipo),
                      e.institucionNombre,
                      if (!e.todoElDia) AtenaFormat.hora(context, e.inicio),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
