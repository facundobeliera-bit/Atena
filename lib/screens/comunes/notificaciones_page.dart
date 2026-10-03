// lib/screens/comunes/notificaciones_page.dart
//
// ATENA – Notificaciones (familias e instituciones).
// Agrupadas por día, con filtro de no leídas, deslizar para eliminar y
// navegación al trámite relacionado (la decide quien abre la pantalla).

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';

typedef AbrirNotificacion =
    Future<void> Function(BuildContext context, Notificacion notificacion);

class NotificacionesPage extends StatefulWidget {
  final String cuentaId;

  /// Perfil a mostrar (alumno o institución). Null = toda la cuenta.
  final String? perfilId;

  final AtenaRole role;

  /// Navega al trámite relacionado. Si es null o la notificación no tiene
  /// destino, se muestra el detalle en una hoja.
  final AbrirNotificacion? onOpen;

  const NotificacionesPage({
    super.key,
    required this.cuentaId,
    this.perfilId,
    this.role = AtenaRole.brand,
    this.onOpen,
  });

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final _repo = NotificacionesRepo.instance;

  List<Notificacion> _items = const [];
  bool _loading = true;
  Object? _error;
  bool _soloNoLeidas = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.listar(
        widget.cuentaId,
        perfilId: widget.perfilId,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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

  int get _noLeidas => _items.where((n) => !n.leida).length;

  Future<void> _abrir(Notificacion n) async {
    if (!n.leida) {
      await _repo.marcarLeida(widget.cuentaId, n.id);
      await _load();
    }
    if (!mounted) return;

    final conDestino =
        n.destino != DestinoNotificacion.ninguno &&
        n.destino != DestinoNotificacion.aviso;
    if (conDestino && widget.onOpen != null) {
      await widget.onOpen!(context, n);
      await _load();
      return;
    }
    await _verDetalle(n);
  }

  Future<void> _verDetalle(Notificacion n) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final vista = vistaNotificacion(ctx, n);
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AtenaIconBadge(icon: vista.icono, color: vista.color, size: 52),
                const SizedBox(height: 16),
                Text(vista.titulo, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  '${AtenaFormat.fechaLarga(ctx, n.fecha)} · ${AtenaFormat.hora(ctx, n.fecha)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(vista.cuerpo, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(AppLocalizations.of(ctx).uiClose),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleLeida(Notificacion n) async {
    await _repo.marcarLeida(widget.cuentaId, n.id, leida: !n.leida);
    await _load();
  }

  Future<void> _eliminar(Notificacion n) async {
    final t = AppLocalizations.of(context);
    setState(() => _items = _items.where((x) => x.id != n.id).toList());
    await _repo.eliminar(widget.cuentaId, n.id);
    if (!mounted) return;
    AtenaFeedback.show(
      context,
      t.notifDeleted,
      action: SnackBarAction(
        label: t.uiUndo,
        onPressed: () async {
          await _repo.enviar(n);
          await _load();
        },
      ),
    );
  }

  Future<void> _marcarTodas() async {
    await _repo.marcarTodasLeidas(widget.cuentaId, perfilId: widget.perfilId);
    await _load();
  }

  Future<void> _eliminarTodas() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.notifDeleteAllConfirm,
      confirmLabel: t.notifDeleteAll,
      destructive: true,
      icon: Icons.delete_sweep_rounded,
    );
    if (!ok) return;
    await _repo.eliminarTodas(widget.cuentaId, perfilId: widget.perfilId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final visibles = _soloNoLeidas
        ? _items.where((n) => !n.leida).toList()
        : _items;

    return AtenaScaffold(
      role: widget.role,
      appBar: AtenaAppBar(
        title: t.notifTitle,
        subtitle: _noLeidas > 0 ? t.notifUnreadCount(_noLeidas) : null,
        actions: [
          IconButton(
            tooltip: t.notifMarkAllRead,
            onPressed: _noLeidas == 0 ? null : _marcarTodas,
            icon: const Icon(Icons.done_all_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: t.uiMoreOptions,
            enabled: _items.isNotEmpty,
            onSelected: (_) => _eliminarTodas(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete_all',
                child: ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded),
                  title: Text(t.notifDeleteAll),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const AtenaLoading()
          : _error != null
          ? AtenaErrorState(message: coreErrorText(t, _error!), onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: atenaPagePadding(context, maxWidth: 720),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(t.notifFilterAll),
                        selected: !_soloNoLeidas,
                        onSelected: (_) =>
                            setState(() => _soloNoLeidas = false),
                      ),
                      ChoiceChip(
                        label: Text(
                          _noLeidas > 0
                              ? '${t.notifFilterUnread} ($_noLeidas)'
                              : t.notifFilterUnread,
                        ),
                        selected: _soloNoLeidas,
                        onSelected: (_) => setState(() => _soloNoLeidas = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibles.isEmpty)
                    AtenaEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: t.notifEmptyTitle,
                      message: t.notifEmptyBody,
                    )
                  else
                    ..._grupos(context, visibles),
                ],
              ),
            ),
    );
  }

  List<Widget> _grupos(BuildContext context, List<Notificacion> items) {
    final t = AppLocalizations.of(context);
    final hoy = DateTime.now();
    DateTime dia(DateTime d) => DateTime(d.year, d.month, d.day);
    final dHoy = dia(hoy);
    final dAyer = dHoy.subtract(const Duration(days: 1));

    final grupos = <String, List<Notificacion>>{};
    for (final n in items) {
      final d = dia(n.fecha);
      final key = d == dHoy
          ? t.uiToday
          : d == dAyer
          ? t.uiYesterday
          : t.notifOlder;
      grupos.putIfAbsent(key, () => <Notificacion>[]).add(n);
    }

    final out = <Widget>[];
    for (final entry in grupos.entries) {
      out.add(
        AtenaSectionHeader(
          title: entry.key,
          padding: const EdgeInsets.only(top: 10, bottom: 8),
        ),
      );
      out.add(
        AtenaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < entry.value.length; i++) ...[
                if (i > 0) const Divider(indent: 72),
                _NotificacionTile(
                  n: entry.value[i],
                  onTap: () => _abrir(entry.value[i]),
                  onToggle: () => _toggleLeida(entry.value[i]),
                  onDelete: () => _eliminar(entry.value[i]),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return out;
  }
}

class _NotificacionTile extends StatelessWidget {
  final Notificacion n;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NotificacionTile({
    required this.n,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vista = vistaNotificacion(context, n);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: cs.errorContainer,
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtenaIconBadge(icon: vista.icono, color: vista.color, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vista.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: n.leida ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vista.cuerpo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: n.leida ? cs.onSurfaceVariant : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AtenaFormat.haceTiempo(context, n.fecha),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  PopupMenuButton<int>(
                    tooltip: t.uiMoreOptions,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onSelected: (v) => v == 0 ? onToggle() : onDelete(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 0,
                        child: Text(
                          n.leida ? t.notifMarkUnread : t.notifMarkRead,
                        ),
                      ),
                      PopupMenuItem(value: 1, child: Text(t.notifDelete)),
                    ],
                  ),
                  if (!n.leida)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
