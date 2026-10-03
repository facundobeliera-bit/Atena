// lib/screens/instituciones/institucion_menu_page.dart
//
// ATENA – Panel de la institución.
// Estado del plan, indicadores, primeros pasos, accesos a cada sección y
// solicitudes pendientes de revisión.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../routes/atena_nav.dart';
import '../../services/auth_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/session_service.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import '../../ui/widgets/atena_preferences_sheet.dart';
import '../comunes/eliminar_cuenta_dialog.dart';
import '../comunes/notificaciones_page.dart';
import 'alumnos_institucion_page.dart';
import 'comunicaciones_page.dart';
import 'croquis_page.dart';
import 'documentos_institucion_page.dart';
import 'institucion_perfil_page.dart';
import 'institucion_plan_page.dart';
import 'ofertas_page.dart';
import 'solicitudes_institucion_page.dart';

/// Abre el trámite relacionado con una notificación de la institución.
Future<void> abrirNotificacionInstitucion(
  BuildContext context,
  Notificacion n, {
  required String institucionId,
  required String institucionNombre,
}) async {
  final Widget? page = switch (n.destino) {
    DestinoNotificacion.solicitud => SolicitudesInstitucionPage(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      initialSolicitudId: n.destinoId,
    ),
    DestinoNotificacion.documento => DocumentosInstitucionPage(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      initialPedidoId: n.destinoId,
    ),
    DestinoNotificacion.evento => ComunicacionesPage(
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      initialEventoId: n.destinoId,
    ),
    _ => null,
  };
  if (page == null) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class InstitucionMenuPage extends StatefulWidget {
  final String ownerAccountId;
  final String institucionPerfilId;
  final String? institucionNombre;

  const InstitucionMenuPage({
    super.key,
    required this.ownerAccountId,
    required this.institucionPerfilId,
    this.institucionNombre,
  });

  @override
  State<InstitucionMenuPage> createState() => _InstitucionMenuPageState();
}

class _InstitucionMenuPageState extends State<InstitucionMenuPage> {
  Institucion? _inst;
  PerfilPublico _perfil = const PerfilPublico();
  Uint8List? _logo;
  List<OfertaConCupo> _ofertas = const [];
  List<Solicitud> _solicitudes = const [];
  int _docsParaRevisar = 0;
  int _noLeidas = 0;

  bool _loading = true;
  bool _sinAcceso = false;
  Object? _error;

  String get _instId => widget.institucionPerfilId;
  String get _nombre => _inst?.nombre.trim().isNotEmpty == true
      ? _inst!.nombre.trim()
      : (widget.institucionNombre ?? '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _tieneAcceso() async {
    try {
      if (await CuentaService.ownerTienePerfil(
        ownerAccountId: widget.ownerAccountId,
        perfilId: _instId,
      )) {
        return true;
      }
    } catch (_) {}
    try {
      final s = await SessionService.getSession();
      return s != null &&
          s.role == SessionRole.institucion &&
          s.userId == _instId;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    try {
      if (!await _tieneAcceso()) {
        if (!mounted) return;
        setState(() {
          _sinAcceso = true;
          _loading = false;
        });
        return;
      }

      final repo = InstitucionesRepo.instance;
      final inst = await repo.obtener(_instId);
      if (inst == null) throw const AtenaException(AtenaError.noEncontrado);
      await repo.asegurarIndexada(inst);

      final perfil = await repo.perfilPublico(_instId);
      final results = await Future.wait<Object?>([
        repo.imagen(perfil.logoId),
        OfertasRepo.instance.conCupo(_instId),
        SolicitudesRepo.instance.porInstitucion(_instId),
        DocumentosRepo.instance.porInstitucion(_instId),
        NotificacionesRepo.instance.noLeidas(
          widget.ownerAccountId,
          perfilId: _instId,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _inst = inst;
        _perfil = perfil;
        _logo = results[0] as Uint8List?;
        _ofertas = results[1] as List<OfertaConCupo>;
        _solicitudes = results[2] as List<Solicitud>;
        _docsParaRevisar = (results[3] as List<PedidoDocumento>)
            .where((d) => d.estado == EstadoPedidoDocumento.entregado)
            .length;
        _noLeidas = results[4] as int;
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

  void _solicitudesPage({String? id}) => _go(
    SolicitudesInstitucionPage(
      institucionId: _instId,
      institucionNombre: _nombre,
      initialSolicitudId: id,
    ),
  );

  void _ofertasPage() =>
      _go(OfertasPage(institucionId: _instId, institucionNombre: _nombre));

  void _alumnosPage() => _go(
    AlumnosInstitucionPage(institucionId: _instId, institucionNombre: _nombre),
  );

  void _comunicacionesPage() => _go(
    ComunicacionesPage(institucionId: _instId, institucionNombre: _nombre),
  );

  void _documentosPage() => _go(
    DocumentosInstitucionPage(
      institucionId: _instId,
      institucionNombre: _nombre,
    ),
  );

  void _croquisPage() =>
      _go(CroquisPage(institucionId: _instId, institucionNombre: _nombre));

  void _perfilPage() => _go(
    InstitucionPerfilPage(
      ownerAccountId: widget.ownerAccountId,
      institucionPerfilId: _instId,
      institucionInicial: _inst,
    ),
  );

  void _planPage() => _go(
    InstitucionPlanPage.manage(
      ownerAccountId: widget.ownerAccountId,
      institucionPerfilId: _instId,
      institucionNombre: _nombre,
    ),
  );

  void _notificaciones() => _go(
    NotificacionesPage(
      cuentaId: widget.ownerAccountId,
      perfilId: _instId,
      role: AtenaRole.institucion,
      onOpen: (ctx, n) => abrirNotificacionInstitucion(
        ctx,
        n,
        institucionId: _instId,
        institucionNombre: _nombre,
      ),
    ),
  );

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
      descripcion: t.deleteAccountInstitutionBody,
      eliminar: (password) => AuthService.eliminarCuentaInstitucion(
        sesion: InstitucionSesion(
          ownerAccountId: widget.ownerAccountId,
          institucionPerfilId: _instId,
        ),
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

    if (_sinAcceso) {
      return AtenaScaffold(
        role: AtenaRole.institucion,
        body: AtenaEmptyState(
          icon: Icons.lock_outline_rounded,
          title: t.authErrInvalidAccount,
          action: FilledButton(
            onPressed: () => AtenaNav.logout(context),
            child: Text(t.instSignInAgain),
          ),
        ),
      );
    }

    final pendientes = _solicitudes
        .where((s) => s.estado == EstadoSolicitud.pendiente)
        .toList();
    final confirmados = _solicitudes
        .where((s) => s.estado == EstadoSolicitud.confirmada)
        .map((s) => s.alumno.perfilId)
        .toSet()
        .length;
    final activas = _ofertas.where((o) => o.oferta.activa).toList();
    final libres = activas.fold<int>(0, (acc, o) => acc + o.disponibles);

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AtenaLogo(markSize: 30),
        actions: [
          IconButton(
            tooltip: t.notifTitle,
            onPressed: _loading ? null : _notificaciones,
            icon: Badge(
              isLabelVisible: _noLeidas > 0,
              label: Text(_noLeidas > 99 ? '99+' : '$_noLeidas'),
              child: const Icon(Icons.notifications_rounded),
            ),
          ),
          const AtenaPreferencesButton(),
          PopupMenuButton<String>(
            tooltip: t.uiMoreOptions,
            enabled: !_loading,
            onSelected: (v) {
              switch (v) {
                case 'perfil':
                  _perfilPage();
                case 'plan':
                  _planPage();
                case 'logout':
                  _logout();
                case 'delete':
                  _eliminarCuenta();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'perfil',
                child: ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: Text(t.instActionProfile),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'plan',
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_rounded),
                  title: Text(t.instActionPlan),
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
                    Icons.domain_disabled_rounded,
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
              title: t.instLoadError,
              message: coreErrorText(t, _error!),
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: atenaPagePadding(context, maxWidth: 1000),
                children: [
                  _Hero(
                    inst: _inst!,
                    logo: _logo,
                    pendientes: pendientes.length,
                    alumnos: confirmados,
                    libres: libres,
                    ofertas: activas.length,
                  ),
                  if (_perfil.descripcion.isEmpty ||
                      _ofertas.isEmpty ||
                      _solicitudes.isEmpty) ...[
                    const SizedBox(height: 16),
                    _PrimerosPasos(
                      perfilListo: _perfil.descripcion.isNotEmpty,
                      ofertaLista: _ofertas.isNotEmpty,
                      solicitudLista: _solicitudes.isNotEmpty,
                      onPerfil: _perfilPage,
                      onOferta: _ofertasPage,
                    ),
                  ],
                  const SizedBox(height: 24),
                  AtenaFeatureGrid(
                    minTileWidth: 170,
                    children: [
                      AtenaFeatureCard(
                        icon: Icons.move_to_inbox_rounded,
                        title: t.instActionRequests,
                        subtitle: t.instActionRequestsSub,
                        badgeCount: pendientes.length,
                        onTap: _solicitudesPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.event_seat_rounded,
                        title: t.instActionOffers,
                        subtitle: t.instActionOffersSub,
                        accent: AtenaColors.indigo,
                        onTap: _ofertasPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.groups_rounded,
                        title: t.instActionStudents,
                        subtitle: t.instActionStudentsSub,
                        accent: AtenaColors.blue,
                        onTap: _alumnosPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.campaign_rounded,
                        title: t.instActionComms,
                        subtitle: t.instActionCommsSub,
                        accent: AtenaColors.goldDeep,
                        onTap: _comunicacionesPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.folder_copy_rounded,
                        title: t.instActionDocs,
                        subtitle: t.instActionDocsSub,
                        accent: AtenaColors.warning,
                        badgeCount: _docsParaRevisar,
                        onTap: _documentosPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.grid_view_rounded,
                        title: t.instActionCroquis,
                        subtitle: t.instActionCroquisSub,
                        accent: AtenaColors.success,
                        onTap: _croquisPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.storefront_rounded,
                        title: t.instActionProfile,
                        subtitle: t.instActionProfileSub,
                        accent: AtenaColors.info,
                        onTap: _perfilPage,
                      ),
                      AtenaFeatureCard(
                        icon: Icons.workspace_premium_rounded,
                        title: t.instActionPlan,
                        subtitle: t.instActionPlanSub,
                        accent: AtenaColors.goldDeep,
                        onTap: _planPage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AtenaSectionHeader(
                    title: t.instToReview,
                    action: pendientes.isEmpty
                        ? null
                        : TextButton(
                            onPressed: _solicitudesPage,
                            child: Text(t.uiSeeAll),
                          ),
                  ),
                  if (pendientes.isEmpty)
                    AtenaCard(
                      child: Row(
                        children: [
                          AtenaIconBadge(
                            icon: Icons.task_alt_rounded,
                            color: AtenaBrand.of(context).success,
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(t.instNoPending)),
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
                            i < pendientes.length && i < 5;
                            i++
                          ) ...[
                            if (i > 0) const Divider(indent: 76),
                            _PendienteTile(
                              s: pendientes[i],
                              onTap: () =>
                                  _solicitudesPage(id: pendientes[i].id),
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
  final Institucion inst;
  final Uint8List? logo;
  final int pendientes;
  final int alumnos;
  final int libres;
  final int ofertas;

  const _Hero({
    required this.inst,
    required this.logo,
    required this.pendientes,
    required this.alumnos,
    required this.libres,
    required this.ofertas,
  });

  ({String label, IconData icon}) _plan(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vencido = DateTime.now().isAfter(inst.planFin);
    switch (inst.estadoPlan) {
      case EstadoPlanInstitucion.activo:
        return (label: t.instPlanActive, icon: Icons.verified_rounded);
      case EstadoPlanInstitucion.enPrueba:
        return vencido
            ? (label: t.instPlanTrialEnded, icon: Icons.timer_off_rounded)
            : (
                label: t.instPlanTrialUntil(
                  AtenaFormat.fechaCorta(context, inst.planFin),
                ),
                icon: Icons.hourglass_bottom_rounded,
              );
      case EstadoPlanInstitucion.vencido:
        return (label: t.instPlanTrialEnded, icon: Icons.timer_off_rounded);
      case EstadoPlanInstitucion.suspendido:
        return (label: t.instPlanSuspended, icon: Icons.pause_circle_rounded);
      case EstadoPlanInstitucion.sinPlan:
        return (label: t.instPlanNone, icon: Icons.info_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = _plan(context);
    final ubicacion = [
      inst.ciudad,
      inst.provincia,
    ].where((s) => s.trim().isNotEmpty).join(', ');

    return AtenaGradientPanel(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AtenaAvatar(
                name: inst.nombre,
                imageBytes: logo,
                size: 58,
                ring: true,
                fallbackIcon: Icons.account_balance_rounded,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inst.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ubicacion.isEmpty ? t.instHomeSubtitle : ubicacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(plan.icon, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  plan.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final stats = [
                AtenaStat(
                  value: '$pendientes',
                  label: t.instStatPendingN(pendientes),
                  onGradient: true,
                ),
                AtenaStat(
                  value: '$alumnos',
                  label: t.instStatStudentsN(alumnos),
                  onGradient: true,
                ),
                AtenaStat(
                  value: '$libres',
                  label: t.instStatFreeSpotsN(libres),
                  onGradient: true,
                ),
                AtenaStat(
                  value: '$ofertas',
                  label: t.instStatOffersN(ofertas),
                  onGradient: true,
                ),
              ];
              final perRow = c.maxWidth < 420 ? 2 : 4;
              final w = c.maxWidth / perRow;
              return Wrap(
                runSpacing: 12,
                children: [for (final s in stats) SizedBox(width: w, child: s)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrimerosPasos extends StatelessWidget {
  final bool perfilListo;
  final bool ofertaLista;
  final bool solicitudLista;
  final VoidCallback onPerfil;
  final VoidCallback onOferta;

  const _PrimerosPasos({
    required this.perfilListo,
    required this.ofertaLista,
    required this.solicitudLista,
    required this.onPerfil,
    required this.onOferta,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hechos = [perfilListo, ofertaLista, solicitudLista].where((x) => x);

    Widget paso(String texto, bool listo, VoidCallback? onTap) {
      final cs = theme.colorScheme;
      final ok = AtenaBrand.of(context).success;
      return InkWell(
        onTap: listo ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                listo
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: listo ? ok : cs.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: listo ? TextDecoration.lineThrough : null,
                    color: listo ? cs.onSurfaceVariant : cs.onSurface,
                  ),
                ),
              ),
              if (!listo && onTap != null)
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      );
    }

    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.instGettingStarted,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text('${hechos.length}/3', style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(t.instGettingStartedSub, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: hechos.length / 3),
          const SizedBox(height: 6),
          paso(t.instStepProfile, perfilListo, onPerfil),
          paso(t.instStepOffer, ofertaLista, onOferta),
          paso(t.instStepRequest, solicitudLista, null),
        ],
      ),
    );
  }
}

class _PendienteTile extends StatelessWidget {
  final Solicitud s;
  final VoidCallback onTap;

  const _PendienteTile({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final edad = s.alumno.edad;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            AtenaAvatar(name: s.alumno.nombreCompleto, size: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.alumno.apellidoNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      s.ofertaNombre,
                      if (edad != null) t.lblEdadAnios(edad),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              AtenaFormat.haceTiempo(context, s.creadaEl),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
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
