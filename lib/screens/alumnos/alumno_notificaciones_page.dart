// lib/screens/alumnos/alumno_notificaciones_page.dart
//
// ATENA – CENTRO DE NOTIFICACIONES (ALUMNOS)
// Canónico (owner → perfiles → perfil alumno)
//
// ✅ HARDENING / FIX (enero 2026):
// - ✅ Alinea Card/legibilidad con AlumnoArea: color adaptativo (dark/light).
// - ✅ Evita “setState después de dispose” en bootstrap/cargar (guardias).
// - ✅ Dropdown: corrige manejo de null (onChanged puede enviar null).
// - ✅ Deeplink: pushNamed SOLO con route string canónico.
// - ✅ Evita doble tap / doble navegación (guardia _navegando).
// - ✅ PopupMenu: “Borrar” visible y seguro (con confirmación).
// - ✅ Subtitle: maxLines/overflow.
// - ✅ Normaliza ids (trim + remove whitespace) para filtros y deletes.
// - ✅ No limpia _items fuera de setState (consistencia UI).
// - ✅ separatorBuilder: sin unnecessary_underscores.
// - ✅ Deeplink parse hardening: try/catch + owner mismatch guard + perfilId requerido.
//
// Nota canónica (importante):
// - Fuente de verdad: inbox OWNER.
// - Esta pantalla filtra por perfilId (si llega) para mostrar solo lo del perfil alumno.
// - Mutaciones: siempre en OWNER; duplicado en PERFIL best-effort si existe.

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../models/notificaciones/notificacion_atena.dart';
import '../../routes/atena_deeplink.dart';
import '../../services/cuenta_service.dart';
import '../../services/notificaciones_service.dart';
import '../../ui/atena_assets.dart';

class AlumnoNotificacionesPage extends StatefulWidget {
  /// ⚠️ Legacy eliminado: NO usamos DNI para nada.
  /// Se mantiene el parámetro para no romper rutas existentes del prototipo,
  /// pero no se usa en la lógica interna.
  final String alumnoDocumento;

  /// Si viene, filtra la inbox para un perfil específico.
  /// Canon: perfilId del perfil Alumno colgado del owner.
  final String? perfilIdFiltro;

  const AlumnoNotificacionesPage({
    super.key,
    required this.alumnoDocumento,
    this.perfilIdFiltro,
  });

  @override
  State<AlumnoNotificacionesPage> createState() =>
      _AlumnoNotificacionesPageState();
}

class _AlumnoNotificacionesPageState extends State<AlumnoNotificacionesPage> {
  bool _cargando = true;

  /// ✅ Guardia anti-doble navegación / multi taps
  bool _navegando = false;

  List<_NotiUi> _items = <_NotiUi>[];

  String? _ownerAccountId;
  String? _perfilFiltro;

  // Filtros UI
  _FiltroLeidas _filtroLeidas = _FiltroLeidas.todas;
  TipoNotificacionAtena? _filtroTipo; // null = todas

  static String _normId(String s) => s.trim().replaceAll(RegExp(r'\s+'), '');

  int _alpha(double opacity) {
    final v = (opacity * 255).round();
    if (v < 0) return 0;
    if (v > 255) return 255;
    return v;
  }

  void _snackMaybe(ScaffoldMessengerState? messenger, String msg) {
    if (messenger == null) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      // NO-OP
    }
  }

  Future<void> _runNavigation(Future<void> Function() fn) async {
    if (!mounted) return;
    if (_navegando) return;

    setState(() => _navegando = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _navegando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final pf = _normId(widget.perfilIdFiltro ?? '');
    _perfilFiltro = pf.isEmpty ? null : pf;

    // Precache best-effort del fondo (no bloqueante)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome)),
          context,
        );
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow)),
          context,
        );
      } catch (_) {
        // NO-OP
      }
    });

    // ignore: discarded_futures
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cuentaId = await CuentaService.getSesionCuentaId();
    final owner = _normId(cuentaId ?? '');

    if (!mounted) return;

    setState(() {
      _ownerAccountId = owner;
    });

    // Canónico: si no hay sesión owner, no hay notificaciones (sin fallback legacy).
    await _cargar();
  }

  // =====================================================
  // LOAD
  // =====================================================

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _items = <_NotiUi>[];
    });

    try {
      final ownerId = _normId(_ownerAccountId ?? '');
      if (ownerId.isEmpty) {
        if (!mounted) return;
        setState(() => _cargando = false);
        return;
      }

      final pf = _normId(_perfilFiltro ?? '');

      // Inbox owner (canónico)
      final list = pf.isEmpty
          ? await NotificacionesService.listarOwner(ownerId)
          : await NotificacionesService.listarOwnerFiltradoPorPerfil(
              ownerAccountId: ownerId,
              perfilId: pf,
            );

      final ui = list.map(_NotiUi.fromCore).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha)); // ✅ UX: recientes primero

      if (!mounted) return;
      setState(() {
        _items = ui;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = <_NotiUi>[];
        _cargando = false;
      });
    }
  }

  // =====================================================
  // MUTACIONES
  // =====================================================

  Future<void> _marcarLeida(_NotiUi n, bool leida) async {
    if (n.leida == leida) return;

    // UI inmediata
    if (mounted) {
      setState(() => n.leida = leida);
    }

    // Persistencia canónica
    try {
      final ownerId = _normId(_ownerAccountId ?? '');
      if (ownerId.isEmpty) return;

      final pid = _normId(n.perfilId ?? '');
      await NotificacionesService.instance.setLeida(
        ownerAccountId: ownerId,
        notificacionId: _normId(n.id),
        leida: leida,
        perfilId: pid.isEmpty ? null : pid,
      );
    } catch (_) {
      // NO-OP (best-effort)
    }
  }

  Future<void> _borrar(_NotiUi n) async {
    final l = AppLocalizations.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.alumnoNotificacionesDeleteOneTitle),
        content: Text(l.alumnoNotificacionesDeleteOneBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    final backup = List<_NotiUi>.from(_items);

    setState(() {
      final id = _normId(n.id);
      _items = _items.where((x) => _normId(x.id) != id).toList();
    });

    try {
      final ownerId = _normId(_ownerAccountId ?? '');
      if (ownerId.isEmpty) return;

      final nid = _normId(n.id);

      await NotificacionesService.instance.borrarOwner(
        ownerAccountId: ownerId,
        notificacionId: nid,
      );

      // Si además existe inbox por perfil, borramos ahí también (consistencia).
      final pid = _normId(n.perfilId ?? '');
      if (pid.isNotEmpty) {
        await NotificacionesService.instance.borrarPerfil(
          ownerAccountId: ownerId,
          perfilId: pid,
          notificacionId: nid,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = backup);
    }
  }

  Future<void> _borrarTodas() async {
    final l = AppLocalizations.of(context);

    // ✅ Capturar messenger antes del await
    final messenger = ScaffoldMessenger.maybeOf(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.alumnoNotificacionesDeleteAllTitle),
        content: Text(l.alumnoNotificacionesDeleteAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.alumnoNotificacionesDeleteAllCta),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    final ownerId = _normId(_ownerAccountId ?? '');
    if (ownerId.isEmpty) {
      _snackMaybe(messenger, l.commonInvalidSession);
      return;
    }

    // Copia para borrado selectivo en owner cuando hay filtro por perfil
    final pf = _normId(_perfilFiltro ?? '');
    final snapshot = List<_NotiUi>.from(_items);

    setState(() => _items = <_NotiUi>[]);

    try {
      // ✅ Regla canónica:
      // - Si hay filtro por perfil: borrar SOLO notis owner asociadas a ese perfil + purgar inbox perfil.
      // - Si NO hay filtro: purga total owner + perfiles.
      if (pf.isNotEmpty) {
        // 1) Borrado selectivo en owner
        final aBorrar = snapshot
            .where((n) => _normId(n.perfilId ?? '') == pf)
            .map((n) => _normId(n.id))
            .where((id) => id.isNotEmpty)
            .toSet();

        for (final id in aBorrar) {
          try {
            await NotificacionesService.instance.borrarOwner(
              ownerAccountId: ownerId,
              notificacionId: id,
            );
          } catch (_) {
            // NO-OP
          }
        }

        // 2) Borrado total del inbox de ese perfil (si existe duplicado)
        await NotificacionesService.instance.borrarTodasPerfil(
          ownerAccountId: ownerId,
          perfilId: pf,
        );
      } else {
        await NotificacionesService.instance.borrarTodasOwnerYPerfiles(ownerId);
      }
    } catch (_) {
      _snackMaybe(messenger, l.alumnoNotificacionesDeleteAllFailed);
    }
  }

  // =====================================================
  // FILTROS
  // =====================================================

  List<_NotiUi> get _filtradas {
    Iterable<_NotiUi> it = _items;

    switch (_filtroLeidas) {
      case _FiltroLeidas.todas:
        break;
      case _FiltroLeidas.noLeidas:
        it = it.where((n) => !n.leida);
        break;
      case _FiltroLeidas.leidas:
        it = it.where((n) => n.leida);
        break;
    }

    final t = _filtroTipo;
    if (t != null) {
      it = it.where((n) => n.tipo == t);
    }

    final out = it.toList();
    out.sort((a, b) => b.fecha.compareTo(a.fecha));
    return out;
  }

  int get _noLeidas => _items.where((e) => !e.leida).length;

  // =====================================================
  // UI HELPERS
  // =====================================================

  IconData _iconoTipo(_NotiUi n) {
    switch (n.tipo) {
      case TipoNotificacionAtena.confirmada:
        return Icons.check_circle;
      case TipoNotificacionAtena.rechazada:
        return Icons.cancel;

      case TipoNotificacionAtena.documentos:
        return Icons.folder;
      case TipoNotificacionAtena.documentacionActualizada:
        return Icons.verified;
      case TipoNotificacionAtena.documentoSolicitado:
        return Icons.upload_file;
      case TipoNotificacionAtena.documentoSubido:
        return Icons.file_present;
      case TipoNotificacionAtena.documentoExpirado:
        return Icons.timer_off;
      case TipoNotificacionAtena.documentoEliminado:
        return Icons.delete_outline;

      case TipoNotificacionAtena.calendario:
        return Icons.event;

      case TipoNotificacionAtena.sistema:
        return Icons.security;
      case TipoNotificacionAtena.info:
        return Icons.notifications;

      case TipoNotificacionAtena.perfilActualizado:
        return Icons.person;
      case TipoNotificacionAtena.solicitudCreada:
        return Icons.send;
      case TipoNotificacionAtena.solicitudCancelada:
        return Icons.undo;

      case TipoNotificacionAtena.boletinActualizado:
        return Icons.assignment;
      case TipoNotificacionAtena.tituloEmitido:
        return Icons.school;

      case TipoNotificacionAtena.becaActualizada:
        return Icons.workspace_premium;
      case TipoNotificacionAtena.sancionActualizada:
        return Icons.gavel;
      case TipoNotificacionAtena.equivalenciaActualizada:
        return Icons.swap_horiz;
    }
  }

  Color? _colorTipo(BuildContext context, _NotiUi n) {
    final cs = Theme.of(context).colorScheme;
    switch (n.tipo) {
      case TipoNotificacionAtena.confirmada:
        return cs.primary;
      case TipoNotificacionAtena.rechazada:
        return cs.error;

      case TipoNotificacionAtena.documentoEliminado:
        return cs.error;

      case TipoNotificacionAtena.documentos:
      case TipoNotificacionAtena.documentacionActualizada:
      case TipoNotificacionAtena.documentoSolicitado:
      case TipoNotificacionAtena.documentoSubido:
      case TipoNotificacionAtena.documentoExpirado:
        return cs.tertiary;

      case TipoNotificacionAtena.calendario:
        return cs.secondary;

      case TipoNotificacionAtena.sistema:
        return cs.outline;

      default:
        return null;
    }
  }

  String _labelTipo(TipoNotificacionAtena t) {
    // Usamos el label del enum si existe (modelo canónico), pero mantenemos fallback.
    try {
      // ignore: avoid_dynamic_calls
      return (t as dynamic).label as String;
    } catch (_) {
      return t.name;
    }
  }

  // =====================================================
  // DEEPLINK ROUTER (CANÓNICO + BACKEND-READY)
  // =====================================================

  String _resolverPerfilIdParaNavegacion(_NotiUi n) {
    final fromNoti = _normId(n.perfilId ?? '');
    if (fromNoti.isNotEmpty) return fromNoti;

    final fromFiltro = _normId(_perfilFiltro ?? '');
    if (fromFiltro.isNotEmpty) return fromFiltro;

    return '';
  }

  /// Devuelve true si navegó por deeplink canónico.
  Future<bool> _tryOpenDeeplink(_NotiUi n) async {
    final ownerId = _normId(_ownerAccountId ?? '');
    if (ownerId.isEmpty) return false;

    final raw = (n.deeplink ?? '').trim();
    if (raw.isEmpty) return false;

    final pid = _resolverPerfilIdParaNavegacion(n);
    if (pid.isEmpty) return false;

    late AtenaDeeplink parsed;
    try {
      parsed = AtenaDeeplink.parse(raw);
    } catch (_) {
      return false;
    }

    // Guard: si el deeplink trae otro owner, no navegar.
    final ownerFromDl = _normId(parsed.ownerAccountId ?? '');
    if (ownerFromDl.isNotEmpty && ownerFromDl != ownerId) return false;

    final ensured = parsed.ensureCanonico(
      ownerAccountId: ownerId,
      perfilId: pid,
    );

    if (!ensured.isCalendario && !ensured.isDocumentos) return false;

    final route = ensured.toRouteString();
    if (!mounted) return true;

    await _runNavigation(() async {
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        route,
        arguments: {'ownerAccountId': ownerId, 'perfilId': pid},
      );
    });

    return true;
  }

  _NotiAction _actionFor(_NotiUi n) {
    final l = AppLocalizations.of(context);

    switch (n.tipo) {
      case TipoNotificacionAtena.documentos:
      case TipoNotificacionAtena.documentacionActualizada:
      case TipoNotificacionAtena.documentoSolicitado:
      case TipoNotificacionAtena.documentoSubido:
      case TipoNotificacionAtena.documentoExpirado:
      case TipoNotificacionAtena.documentoEliminado:
        return _NotiAction(
          label: l.alumnoNotificacionesActionOpenDocumentos,
          intent: _NotiIntent.documentos,
        );

      case TipoNotificacionAtena.calendario:
        return _NotiAction(
          label: l.alumnoNotificacionesActionOpenCalendario,
          intent: _NotiIntent.calendario,
        );

      case TipoNotificacionAtena.boletinActualizado:
        return _NotiAction(
          label: l.alumnoNotificacionesActionOpenBoletines,
          intent: _NotiIntent.boletines,
        );

      case TipoNotificacionAtena.becaActualizada:
        return _NotiAction(
          label: l.alumnoNotificacionesActionOpenBecas,
          intent: _NotiIntent.becas,
        );

      case TipoNotificacionAtena.sancionActualizada:
        return _NotiAction(
          label: l.alumnoNotificacionesActionOpenConvivencia,
          intent: _NotiIntent.sanciones,
        );

      case TipoNotificacionAtena.equivalenciaActualizada:
        return _NotiAction(
          label: l.alumnoNotificacionesActionOpenEquivalencias,
          intent: _NotiIntent.equivalencias,
        );

      default:
        return _NotiAction(
          label: l.alumnoNotificacionesActionViewDetail,
          intent: _NotiIntent.detalle,
        );
    }
  }

  Future<void> _runFallbackAction(_NotiUi n) async {
    final ownerId = _normId(_ownerAccountId ?? '');
    if (ownerId.isEmpty) return;

    final a = _actionFor(n);

    if (a.intent == _NotiIntent.calendario ||
        a.intent == _NotiIntent.documentos) {
      final pid = _resolverPerfilIdParaNavegacion(n);
      if (pid.isEmpty) return;

      if (!mounted) return;

      AtenaDeeplink d;
      try {
        d = AtenaDeeplink.parse(
          a.intent == _NotiIntent.calendario ? '/calendario' : '/documentos',
        ).ensureCanonico(ownerAccountId: ownerId, perfilId: pid);
      } catch (_) {
        return;
      }

      final route = d.toRouteString();

      await _runNavigation(() async {
        if (!mounted) return;
        Navigator.of(context).pushNamed(
          route,
          arguments: {'ownerAccountId': ownerId, 'perfilId': pid},
        );
      });
      return;
    }

    final l = AppLocalizations.of(context);
    _snackMaybe(
      ScaffoldMessenger.maybeOf(context),
      l.alumnoNotificacionesSectionNotReady,
    );
  }

  Future<void> _abrirAccionFallbackDialog(_NotiUi n) async {
    final l = AppLocalizations.of(context);
    final a = _actionFor(n);

    final cs = Theme.of(context).colorScheme;
    final subtle = cs.onSurfaceVariant.withAlpha(_alpha(0.85));

    final pid = _normId(n.perfilId ?? '');
    final pidShow = pid.isEmpty ? l.commonDash : pid;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(n.titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.mensaje),
            const SizedBox(height: 12),
            Text(
              l.alumnoNotificacionesDialogActionLine(a.intent.name),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(l.alumnoNotificacionesDialogProfileLine(pidShow)),
            const SizedBox(height: 6),
            Text(l.alumnoNotificacionesDialogDateLine(_fmtFecha(n.fecha))),
            const SizedBox(height: 10),
            if ((n.deeplink ?? '').trim().isNotEmpty)
              Text(
                l.alumnoNotificacionesDialogDeeplinkLine(n.deeplink!.trim()),
                style: TextStyle(color: subtle, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonClose),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(a.label),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok == true) {
      await _runFallbackAction(n);
    }
  }

  // =====================================================
  // UI – Background wrapper (alineado a AlumnoArea/CuentaHome)
  // =====================================================

  Widget _buildBackground(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;

    // Overlay leve para que la UI sea legible sobre imagen (dark/light).
    final overlayAlpha = _alpha(
      Theme.of(context).brightness == Brightness.dark ? 0.26 : 0.08,
    );

    Widget bgFallback() {
      // 100% theme-driven (sin hardcode de colores)
      return Container(color: cs.surface);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => bgFallback(),
        ),
        Container(color: cs.scrim.withAlpha(overlayAlpha)),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.35
                  : 0.20,
              child: Image.asset(
                AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final ownerId = _normId(_ownerAccountId ?? '');
    final filtradas = _filtradas;

    final cs = Theme.of(context).colorScheme;

    // Card adaptativa sin hardcode: surfaceContainer + alpha leve para integrar con fondo.
    final cardColor = cs.surfaceContainerHigh.withAlpha(
      _alpha(Theme.of(context).brightness == Brightness.dark ? 0.92 : 0.96),
    );

    final title = ownerId.isEmpty
        ? l.alumnoNotificacionesTitle
        : l.alumnoNotificacionesTitleWithUnread(_noLeidas);

    final transparent = cs.surface.withAlpha(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: transparent,
        surfaceTintColor: transparent,
        actions: [
          IconButton(
            onPressed: (_cargando || _navegando) ? null : _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: l.commonRefresh,
          ),
          IconButton(
            onPressed: (_items.isEmpty || _navegando) ? null : _borrarTodas,
            icon: const Icon(Icons.delete_forever),
            tooltip: l.alumnoNotificacionesDeleteAllTooltip,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _buildBackground(
        context,
        SafeArea(
          child: ownerId.isEmpty
              ? _EmptyState(
                  title: l.commonInvalidSession,
                  subtitle: l.alumnoNotificacionesNoOwnerBody,
                  icon: Icons.lock,
                )
              : _cargando
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _FiltroBar(
                      filtroLeidas: _filtroLeidas,
                      filtroTipo: _filtroTipo,
                      onChangeLeidas: (v) => setState(() => _filtroLeidas = v),
                      onChangeTipo: (v) => setState(() => _filtroTipo = v),
                      tipoLabel: _labelTipo,
                      total: _items.length,
                      totalMostrado: filtradas.length,
                      perfilFiltro: _normId(_perfilFiltro ?? ''),
                    ),
                    Expanded(
                      child: filtradas.isEmpty
                          ? _EmptyState(
                              title: l.alumnoNotificacionesEmptyTitle,
                              subtitle: l.alumnoNotificacionesEmptyBody,
                              icon: Icons.filter_alt_off,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtradas.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final n = filtradas[i];

                                return Card(
                                  color: cardColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      _iconoTipo(n),
                                      color: _colorTipo(context, n),
                                    ),
                                    title: Text(
                                      n.titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: n.leida
                                            ? FontWeight.w500
                                            : FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${_fmtFecha(n.fecha)}\n${n.mensaje}',
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    isThreeLine: true,
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'leer') {
                                          await _marcarLeida(n, true);
                                        } else if (v == 'no_leer') {
                                          await _marcarLeida(n, false);
                                        } else if (v == 'borrar') {
                                          await _borrar(n);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        if (!n.leida)
                                          PopupMenuItem(
                                            value: 'leer',
                                            child: Text(
                                              l.alumnoNotificacionesMarkRead,
                                            ),
                                          ),
                                        if (n.leida)
                                          PopupMenuItem(
                                            value: 'no_leer',
                                            child: Text(
                                              l.alumnoNotificacionesMarkUnread,
                                            ),
                                          ),
                                        PopupMenuItem(
                                          value: 'borrar',
                                          child: Text(l.commonDelete),
                                        ),
                                      ],
                                    ),
                                    onTap: _navegando
                                        ? null
                                        : () async {
                                            if (!n.leida) {
                                              await _marcarLeida(n, true);
                                            }
                                            if (!mounted) return;

                                            final opened =
                                                await _tryOpenDeeplink(n);
                                            if (!mounted) return;

                                            if (!opened) {
                                              await _abrirAccionFallbackDialog(
                                                n,
                                              );
                                            }
                                          },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static String _fmtFecha(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

// =====================================================
// UI MODEL
// =====================================================

class _NotiUi {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  bool leida;

  final String? ownerAccountId;
  final String? perfilId;

  final TipoNotificacionAtena tipo;

  // ✅ Deeplink canónico
  final String? deeplink;

  _NotiUi({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.leida,
    required this.tipo,
    this.ownerAccountId,
    this.perfilId,
    this.deeplink,
  });

  factory _NotiUi.fromCore(NotificacionAtena n) => _NotiUi(
    id: n.id,
    titulo: n.titulo,
    mensaje: n.mensaje,
    fecha: n.fecha,
    leida: n.leida,
    ownerAccountId: n.ownerAccountId,
    perfilId: n.perfilId,
    tipo: n.tipo,
    deeplink: n.deeplink,
  );
}

// =====================================================
// FILTROS UI
// =====================================================

enum _FiltroLeidas { todas, noLeidas, leidas }

class _FiltroBar extends StatelessWidget {
  final _FiltroLeidas filtroLeidas;
  final TipoNotificacionAtena? filtroTipo;

  final ValueChanged<_FiltroLeidas> onChangeLeidas;
  final ValueChanged<TipoNotificacionAtena?> onChangeTipo;

  final String Function(TipoNotificacionAtena) tipoLabel;

  final int total;
  final int totalMostrado;
  final String perfilFiltro;

  const _FiltroBar({
    required this.filtroLeidas,
    required this.filtroTipo,
    required this.onChangeLeidas,
    required this.onChangeTipo,
    required this.tipoLabel,
    required this.total,
    required this.totalMostrado,
    required this.perfilFiltro,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tipos = TipoNotificacionAtena.values;

    final cs = Theme.of(context).colorScheme;
    final transparent = cs.surface.withAlpha(0);

    return Material(
      elevation: 0,
      color: transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ChipSelect<_FiltroLeidas>(
                  label: l.alumnoNotificacionesFilterStatusLabel,
                  value: filtroLeidas,
                  items: [
                    _ChipItem(value: _FiltroLeidas.todas, label: l.commonAll),
                    _ChipItem(
                      value: _FiltroLeidas.noLeidas,
                      label: l.commonUnread,
                    ),
                    _ChipItem(value: _FiltroLeidas.leidas, label: l.commonRead),
                  ],
                  onChanged: onChangeLeidas,
                ),
                _ChipSelect<TipoNotificacionAtena?>(
                  label: l.alumnoNotificacionesFilterTypeLabel,
                  value: filtroTipo,
                  items: [
                    _ChipItem<TipoNotificacionAtena?>(
                      value: null,
                      label: l.commonAll,
                    ),
                    ...tipos.map(
                      (t) => _ChipItem<TipoNotificacionAtena?>(
                        value: t,
                        label: tipoLabel(t),
                      ),
                    ),
                  ],
                  onChanged: onChangeTipo,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ✅ FIX analyzer (extra_positional_arguments):
            // Las keys actuales en ARB esperan menos argumentos.
            // No inventamos keys nuevas: compactamos los datos en 1 solo argumento string.
            Text(
              perfilFiltro.isEmpty
                  ? l.alumnoNotificacionesShowingCount('$totalMostrado/$total')
                  : l.alumnoNotificacionesShowingCountWithPerfil(
                      perfilFiltro,
                      '$totalMostrado/$total',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSelect<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<_ChipItem<T>> items;
  final ValueChanged<T> onChanged;

  const _ChipSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.value,
                  child: Text(e.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            // ✅ onChanged puede enviar null en tipos nullable.
            if (v == null) {
              if (null is T) onChanged(v as T);
              return;
            }
            onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ChipItem<T> {
  final T value;
  final String label;
  const _ChipItem({required this.value, required this.label});
}

// =====================================================
// EMPTY STATE
// =====================================================

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 10),
            Text(
              title,
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: t.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// DEEPLINK / INTENTS (BACKEND-READY)
// =====================================================

enum _NotiIntent {
  detalle,
  documentos,
  calendario,
  boletines,
  becas,
  sanciones,
  equivalencias,
}

class _NotiAction {
  final String label;
  final _NotiIntent intent;

  const _NotiAction({required this.label, required this.intent});
}
