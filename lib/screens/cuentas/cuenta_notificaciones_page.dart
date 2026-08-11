// lib/screens/cuentas/cuenta_notificaciones_page.dart
//
// ATENA – CENTRO DE NOTIFICACIONES (OWNER / PERFIL)
// Canónico: el owner recibe todo.
// - Lista owner (fuente de verdad)
// - Filtro por perfilId (opcional)
// - Marcar leída
// - Borrar una / borrar todas
// - Navegación por deeplink: ✅ IMPLEMENTADO (calendario + documentos)
//
// Nota canónica:
// - La navegación SIEMPRE usa ownerAccountId + perfilId.
// - AtenaDeeplink es la ÚNICA fuente de verdad del parsing + reconstrucción.
//
// HARDENING (enero 2026):
// - use_build_context_synchronously: captura messenger/nav antes de awaits.
// - showDialog: usa dialogContext (Navigator.pop) y revalida mounted post-await.
// - Owner mismatch guard: si el deeplink trae ownerAccountId distinto, no navega.
// - Filtro por perfil: UI real (Dropdown) + “solo no leídas” + persistencia local (PageStorage).
// - Borrar: update optimista local y rollback best-effort.
// - Toggle leída: lock por id, update optimista local y rollback best-effort.
// - ListTile: mejor contraste read/unread.
// - Deeplink: normaliza via ensureCanonico y usa toRouteString (solo calendario/documentos).
//
// i18n + Theme (enero 2026):
// - Strings via AppLocalizations (ARB).
// - Colores via Theme/ColorScheme.

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/notificaciones/notificacion_atena.dart';
import '../../routes/atena_deeplink.dart';
import '../../services/notificaciones_service.dart';

class CuentaNotificacionesPage extends StatefulWidget {
  final String ownerAccountId;
  final String? perfilIdFiltro;

  const CuentaNotificacionesPage({
    super.key,
    required this.ownerAccountId,
    this.perfilIdFiltro,
  });

  @override
  State<CuentaNotificacionesPage> createState() =>
      _CuentaNotificacionesPageState();
}

class _CuentaNotificacionesPageState extends State<CuentaNotificacionesPage> {
  bool _cargando = true;
  String? _error;

  List<NotificacionAtena> _all = <NotificacionAtena>[];

  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  String get _owner => _normIdKey(widget.ownerAccountId);

  bool _soloNoLeidas = false;
  String? _perfilFiltro;

  bool _restoredPageStorage = false;

  final Set<String> _lockToggle = <String>{};
  final Set<String> _lockBorrar = <String>{};
  final Set<String> _lockAbrir = <String>{};
  bool _lockBorrarTodas = false;

  int _alpha(double opacity) {
    final v = (opacity * 255).round();
    if (v < 0) return 0;
    if (v > 255) return 255;
    return v;
  }

  @override
  void initState() {
    super.initState();
    final pf = _normIdKey(widget.perfilIdFiltro ?? '');
    _perfilFiltro = pf.isNotEmpty ? pf : null;
    // ignore: discarded_futures
    _cargar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Persistencia en-session (tabs/back/forward) sin dependencias extra.
    if (_restoredPageStorage) return;
    _restoredPageStorage = true;

    try {
      final bucket = PageStorage.of(context);
      final solo = bucket.readState(context, identifier: _psKeySoloNoLeidas());
      final perfil = bucket.readState(
        context,
        identifier: _psKeyPerfilFiltro(),
      );

      final soloBool = (solo is bool) ? solo : null;
      final perfilStr = (perfil is String && perfil.trim().isNotEmpty)
          ? _normIdKey(perfil)
          : null;

      if (!mounted) return;
      setState(() {
        if (soloBool != null) _soloNoLeidas = soloBool;

        if (widget.perfilIdFiltro == null) {
          // Si el caller fuerza filtro, no lo sobrescribimos con PageStorage.
          _perfilFiltro = perfilStr;
        }
      });
    } catch (_) {
      // NO-OP
    }
  }

  String _psKeySoloNoLeidas() => 'noti_soloNoLeidas_owner_$_owner';
  String _psKeyPerfilFiltro() => 'noti_perfilFiltro_owner_$_owner';

  void _persistStateToPageStorage() {
    if (!mounted) return;
    try {
      final bucket = PageStorage.of(context);

      bucket.writeState(
        context,
        _soloNoLeidas,
        identifier: _psKeySoloNoLeidas(),
      );

      final pf = _normIdKey(_perfilFiltro ?? '');
      bucket.writeState(
        context,
        pf.isEmpty ? '' : pf,
        identifier: _psKeyPerfilFiltro(),
      );
    } catch (_) {
      // NO-OP
    }
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    if (_owner.isEmpty) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _cargando = false;
        _error = l10n.invalidOwner;
        _all = <NotificacionAtena>[];
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final list = await NotificacionesService.listarOwner(_owner);
      list.sort((a, b) => b.fecha.compareTo(a.fecha));

      if (!mounted) return;
      setState(() {
        _all = list;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  List<NotificacionAtena> get _filtradas {
    Iterable<NotificacionAtena> it = _all;

    final pid = _normIdKey(_perfilFiltro ?? '');
    if (pid.isNotEmpty) {
      it = it.where((n) => _normIdKey(n.perfilId ?? '') == pid);
    }

    if (_soloNoLeidas) {
      it = it.where((n) => !n.leida);
    }

    final out = it.toList();
    out.sort((a, b) => b.fecha.compareTo(a.fecha));
    return out;
  }

  List<String> get _perfilesPresentes {
    final s = <String>{};
    for (final n in _all) {
      final pid = _normIdKey(n.perfilId ?? '');
      if (pid.isNotEmpty) s.add(pid);
    }
    final out = s.toList()..sort();
    return out;
  }

  void _snack(ScaffoldMessengerState messenger, String msg) {
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      // NO-OP
    }
  }

  // =====================================================
  // INMUTABLE HELPERS (sin depender de copyWith)
  // =====================================================

  NotificacionAtena _withLeida(NotificacionAtena n, bool leida) {
    try {
      final m = Map<String, dynamic>.from(n.toMap());
      m['leida'] = leida;
      return NotificacionAtena.fromMap(m);
    } catch (_) {
      return n;
    }
  }

  void _setLocalLeidaByIdKey(String idKey, bool leida) {
    final target = _normIdKey(idKey);
    if (target.isEmpty) return;

    final idx = _all.indexWhere((x) => _normIdKey(x.id) == target);
    if (idx < 0) return;

    final cur = _all[idx];
    if (cur.leida == leida) return;

    final replaced = _withLeida(cur, leida);

    // Reemplazo inmutable de la lista para garantizar repaint consistente.
    final copy = List<NotificacionAtena>.from(_all);
    copy[idx] = replaced;
    _all = copy;
  }

  Future<void> _toggleLeidaByIdKey(String idKey) async {
    final key = _normIdKey(idKey);
    if (key.isEmpty || _lockToggle.contains(key)) return;

    _lockToggle.add(key);

    // Tomamos el snapshot actual desde la lista, no del objeto recibido (puede estar stale).
    final idx = _all.indexWhere((x) => _normIdKey(x.id) == key);
    if (idx < 0) {
      _lockToggle.remove(key);
      return;
    }

    final n = _all[idx];
    final nuevo = !n.leida;
    final antes = n.leida;

    if (mounted) {
      setState(() => _setLocalLeidaByIdKey(key, nuevo));
    }

    try {
      // ✅ Importante: usamos id “canónico” tal como lo serializa el modelo (ya normalizado).
      // Esto evita mismatch si el id original traía whitespace interno.
      final storageId = _normIdKey(n.id);

      final pid = _normIdKey(n.perfilId ?? '');
      await NotificacionesService.instance.setLeida(
        ownerAccountId: _owner,
        notificacionId: storageId,
        leida: nuevo,
        perfilId: pid.isEmpty ? null : pid,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _setLocalLeidaByIdKey(key, antes));
      }
    } finally {
      _lockToggle.remove(key);
    }
  }

  Future<void> _toggleLeida(NotificacionAtena n) async {
    final idKey = _normIdKey(n.id);
    if (idKey.isEmpty) return;
    return _toggleLeidaByIdKey(idKey);
  }

  Future<void> _borrar(NotificacionAtena n) async {
    final idKey = _normIdKey(n.id);
    if (idKey.isEmpty || _lockBorrar.contains(idKey)) return;

    _lockBorrar.add(idKey);

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deleteNotificationTitle),
          content: Text(l10n.deleteNotificationBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (ok != true) return;

      final snapshot = List<NotificacionAtena>.from(_all);

      setState(() => _all.removeWhere((x) => _normIdKey(x.id) == idKey));

      try {
        // ✅ Canónico: borrar SIEMPRE en OWNER.
        // Usamos id canónico.
        final storageId = _normIdKey(n.id);

        await NotificacionesService.instance.borrarOwner(
          ownerAccountId: _owner,
          notificacionId: storageId,
        );

        // ✅ Si existe duplicado de PERFIL, también lo removemos (best-effort).
        final pid = _normIdKey(n.perfilId ?? '');
        if (pid.isNotEmpty) {
          await NotificacionesService.instance.borrarPerfil(
            ownerAccountId: _owner,
            perfilId: pid,
            notificacionId: storageId,
          );
        }

        if (!mounted) return;
        _snack(messenger, l10n.notificationDeleted);
      } catch (e) {
        if (!mounted) return;
        setState(() => _all = snapshot);
        _snack(messenger, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _lockBorrar.remove(idKey);
    }
  }

  Future<void> _borrarTodasOwner() async {
    if (_lockBorrarTodas) return;
    _lockBorrarTodas = true;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deleteAllNotificationsTitle),
          content: Text(l10n.deleteAllNotificationsBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteAll),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (ok != true) return;

      final snapshot = List<NotificacionAtena>.from(_all);

      setState(() {
        _all = <NotificacionAtena>[];
        _perfilFiltro = null;
        _soloNoLeidas = false;
        _error = null;
      });
      _persistStateToPageStorage();

      try {
        await NotificacionesService.instance.borrarTodasOwnerYPerfiles(_owner);
        if (!mounted) return;
        _snack(messenger, l10n.notificationsDeleted);
      } catch (e) {
        if (!mounted) return;
        setState(() => _all = snapshot);
        _snack(messenger, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _lockBorrarTodas = false;
    }
  }

  Future<void> _abrirDeeplink(NotificacionAtena n) async {
    final idKey = _normIdKey(n.id);
    if (idKey.isNotEmpty && _lockAbrir.contains(idKey)) return;
    if (idKey.isNotEmpty) _lockAbrir.add(idKey);

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      final raw = (n.deeplink ?? '').trim();
      if (raw.isEmpty) {
        _snack(messenger, l10n.notificationNoDestination);
        return;
      }

      late AtenaDeeplink parsed;
      try {
        parsed = AtenaDeeplink.parse(raw);
      } catch (_) {
        _snack(messenger, l10n.invalidDeeplink);
        return;
      }

      // HARDENING: si el deeplink trae owner distinto, no navegamos.
      final ownerFromDl = _normIdKey(parsed.ownerAccountId ?? '');
      if (ownerFromDl.isNotEmpty && ownerFromDl != _owner) {
        _snack(messenger, l10n.deeplinkOwnerMismatch);
        return;
      }

      final pidFromDl = _normIdKey(parsed.perfilId ?? '');
      final pidFromNoti = _normIdKey(n.perfilId ?? '');
      final pid = pidFromDl.isNotEmpty ? pidFromDl : pidFromNoti;

      final ensured = parsed.ensureCanonico(
        ownerAccountId: _owner,
        perfilId: pid.isNotEmpty ? pid : null,
      );

      // Marcar leída (best-effort)
      if (!n.leida) {
        try {
          await _toggleLeidaByIdKey(_normIdKey(n.id));
        } catch (_) {
          // NO-OP
        }
      }

      if (!mounted) return;

      if (ensured.isCalendario || ensured.isDocumentos) {
        final ensuredPid = _normIdKey(ensured.perfilId ?? '');
        if (ensuredPid.isEmpty) {
          _snack(messenger, l10n.missingPerfilIdForOpen);
          return;
        }

        nav.pushNamed(
          ensured.toRouteString(),
          arguments: {'ownerAccountId': _owner, 'perfilId': ensuredPid},
        );
        return;
      }

      _snack(messenger, l10n.deeplinkNotSupported(ensured.path));
    } finally {
      if (idKey.isNotEmpty) _lockAbrir.remove(idKey);
    }
  }

  void _setPerfilFiltro(String? v) {
    if (!mounted) return;
    final nv = _normIdKey(v ?? '');
    setState(() => _perfilFiltro = nv.isEmpty ? null : nv);
    _persistStateToPageStorage();
  }

  void _toggleSoloNoLeidas() {
    if (!mounted) return;
    setState(() => _soloNoLeidas = !_soloNoLeidas);
    _persistStateToPageStorage();
  }

  void _clearFiltroPerfil() {
    if (!mounted) return;
    setState(() => _perfilFiltro = null);
    _persistStateToPageStorage();
  }

  @override
  Widget build(BuildContext context) {
    final owner = _owner;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (owner.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notificationsTitle)),
        body: Center(child: Text(l10n.invalidOwner)),
      );
    }

    final items = _filtradas;
    final perfiles = _perfilesPresentes;

    final forcedPerfil = _normIdKey(widget.perfilIdFiltro ?? '');
    final isPerfilForced = forcedPerfil.isNotEmpty;

    Widget body;
    if (_cargando) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    } else if (_all.isEmpty) {
      body = Center(child: Text(l10n.noNotifications));
    } else {
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _PerfilDropdown(
              perfiles: perfiles,
              value: _perfilFiltro,
              onChanged: isPerfilForced ? null : _setPerfilFiltro,
              forcedPerfilId: isPerfilForced ? forcedPerfil : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Text(l10n.onlyUnread),
                    selected: _soloNoLeidas,
                    onSelected: (_) => _toggleSoloNoLeidas(),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${items.length}/${_all.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(l10n.noResultsForFilter))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = items[i];

                      final unread = !n.leida;

                      // ✅ FIX: evitar withOpacity (deprecated)
                      // Usamos withAlpha(int) que es estable en tu SDK.
                      final cardBg = unread
                          ? cs.secondaryContainer
                          : cs.surfaceContainerHighest.withAlpha(_alpha(0.70));

                      final leadingColor = unread
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant;

                      final titleStyle = theme.textTheme.titleMedium?.copyWith(
                        fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                        color: unread ? cs.onSecondaryContainer : cs.onSurface,
                      );

                      final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
                        color: unread
                            ? cs.onSecondaryContainer.withAlpha(_alpha(0.88))
                            : cs.onSurfaceVariant,
                      );

                      final perfil = _normIdKey(n.perfilId ?? '');
                      final subtitleLines = <String>[
                        n.mensaje,
                        if (perfil.isNotEmpty)
                          l10n.notificationPerfilLine(perfil),
                      ];

                      return Card(
                        color: cardBg,
                        elevation: unread ? 1.5 : 0.5,
                        child: ListTile(
                          onTap: () => _abrirDeeplink(n),
                          leading: Icon(
                            unread
                                ? Icons.notifications_active
                                : Icons.notifications,
                            color: leadingColor,
                          ),
                          title: Text(n.titulo, style: titleStyle),
                          subtitle: Text(
                            subtitleLines.join('\n'),
                            style: subtitleStyle,
                          ),
                          isThreeLine: subtitleLines.length >= 2,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: n.leida
                                    ? l10n.markAsUnread
                                    : l10n.markAsRead,
                                icon: Icon(
                                  n.leida
                                      ? Icons.mark_email_unread
                                      : Icons.mark_email_read,
                                  color: leadingColor,
                                ),
                                onPressed: () => _toggleLeida(n),
                              ),
                              IconButton(
                                tooltip: l10n.delete,
                                icon: Icon(Icons.delete, color: leadingColor),
                                onPressed: () => _borrar(n),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') {
                // ignore: discarded_futures
                _borrarTodasOwner();
              }
              if (v == 'toggle') _toggleSoloNoLeidas();
              if (v == 'clearFilter') _clearFiltroPerfil();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(_soloNoLeidas ? l10n.showAll : l10n.onlyUnread),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clearFilter',
                child: Text(l10n.clearPerfilFilter),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'clear', child: Text(l10n.deleteAll)),
            ],
          ),
        ],
      ),
      body: body,
    );
  }
}

class _PerfilDropdown extends StatelessWidget {
  final List<String> perfiles;
  final String? value;
  final ValueChanged<String?>? onChanged;

  /// Si viene, significa que el filtro fue forzado por el caller
  /// y el dropdown se muestra solo como indicador (disabled).
  final String? forcedPerfilId;

  const _PerfilDropdown({
    required this.perfiles,
    required this.value,
    required this.onChanged,
    this.forcedPerfilId,
  });

  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final forced = _normIdKey(forcedPerfilId ?? '');
    final isForced = forced.isNotEmpty;

    final shownPerfiles = isForced ? <String>[forced] : perfiles;

    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(value: null, child: Text(l10n.allProfiles)),
      ...shownPerfiles.map(
        (p) => DropdownMenuItem<String?>(value: p, child: Text(p)),
      ),
    ];

    // ✅ FIX (flutter 3.33 pre): DropdownButtonFormField.value está deprecated.
    // Usar initialValue. Además, hacemos que el key cambie si cambia el filtro,
    // para que el FormField tome el initialValue correctamente.
    final iv = (value != null && value!.trim().isNotEmpty) ? value : null;

    return DropdownButtonFormField<String?>(
      key: ValueKey<String>(
        'perfil_dd_${iv ?? 'all'}_${forced.isEmpty ? 'nf' : forced}',
      ),
      initialValue: iv,
      items: items,
      onChanged: (shownPerfiles.isEmpty || isForced) ? null : onChanged,
      decoration: InputDecoration(
        labelText: l10n.filterByProfile,
        border: const OutlineInputBorder(),
        isDense: true,
        helperText: isForced ? l10n.filterForcedByCaller : null,
      ),
    );
  }
}
