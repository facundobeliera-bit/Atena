// lib/screens/cuentas/cuenta_home_page.dart
//
// ATENA – Selector de alumnos de una cuenta familiar.
// - Un solo alumno: entra directo a su inicio.
// - Varios alumnos: muestra el selector (destaca el último usado).
// - Sin alumnos: invita a cargar el primero.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../routes/atena_deeplink.dart';
import '../../routes/atena_nav.dart';
import '../../services/cuenta_service.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import '../../ui/widgets/atena_preferences_sheet.dart';
import '../alumno/alumno_home_page.dart';
import '../alumno/alumno_perfil_form_page.dart';
import '../alumnos/alumno_calendario_page.dart';
import '../alumnos/alumno_documentos_page.dart';
import '../comunes/notificaciones_page.dart';

class CuentaHomePage extends StatefulWidget {
  final String cuentaId;

  /// Deeplink web opcional (/calendario o /documentos).
  final String? initialDeeplink;

  /// true = mostrar el selector aunque haya un solo alumno.
  final bool seleccionar;

  const CuentaHomePage({
    super.key,
    required this.cuentaId,
    this.initialDeeplink,
    this.seleccionar = false,
  });

  @override
  State<CuentaHomePage> createState() => _CuentaHomePageState();
}

class _PerfilItem {
  final PerfilAlumno perfil;
  final Uint8List? foto;
  const _PerfilItem(this.perfil, this.foto);
}

class _CuentaHomePageState extends State<CuentaHomePage> {
  List<_PerfilItem> _perfiles = const [];
  String _email = '';
  String _ultimo = '';
  int _noLeidas = 0;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(primeraVez: true);
  }

  Future<void> _load({bool primeraVez = false}) async {
    try {
      final cuenta = await CuentaService.getCuentaById(widget.cuentaId);
      if (cuenta == null) throw const AtenaException(AtenaError.noEncontrado);

      final perfiles = await AlumnosRepo.instance.perfiles(widget.cuentaId);
      final fotos = await Future.wait(
        perfiles.map((p) => AlumnosRepo.instance.foto(p.id)),
      );
      final ultimoRaw =
          (await CuentaService.getUltimoPerfil(widget.cuentaId) ?? '').trim();
      final noLeidas = await NotificacionesRepo.instance.noLeidas(
        widget.cuentaId,
      );

      if (!mounted) return;

      if (primeraVez && await _resolverEntradaDirecta(perfiles)) return;

      setState(() {
        _email = cuenta.email;
        _perfiles = [
          for (var i = 0; i < perfiles.length; i++)
            _PerfilItem(perfiles[i], fotos[i]),
        ];
        _ultimo = ultimoRaw.startsWith('A|')
            ? ultimoRaw.substring(2)
            : ultimoRaw;
        _noLeidas = noLeidas;
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

  /// Entra directo al inicio del alumno cuando corresponde.
  Future<bool> _resolverEntradaDirecta(List<PerfilAlumno> perfiles) async {
    AtenaDeeplink? dl;
    final raw = (widget.initialDeeplink ?? '').trim();
    if (raw.isNotEmpty) {
      try {
        dl = AtenaDeeplink.parse(raw);
      } catch (_) {
        dl = null;
      }
    }

    PerfilAlumno? destino;
    final pidDl = (dl?.perfilId ?? '').trim();
    if (pidDl.isNotEmpty) {
      for (final p in perfiles) {
        if (p.id == pidDl) destino = p;
      }
    }
    if (destino == null && !widget.seleccionar && perfiles.length == 1) {
      destino = perfiles.single;
    }
    if (destino == null) return false;

    await _abrir(destino, deeplink: dl);
    return true;
  }

  Future<void> _abrir(PerfilAlumno p, {AtenaDeeplink? deeplink}) async {
    await CuentaService.setUltimoPerfil(widget.cuentaId, 'A|${p.id}');
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AtenaMotion.medium,
        pageBuilder: (_, _, _) =>
            AlumnoHomePage(cuentaId: widget.cuentaId, perfilId: p.id),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );

    final dl = deeplink;
    if (dl == null || !(dl.isCalendario || dl.isDocumentos)) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => dl.isCalendario
            ? AlumnoCalendarioPage(
                ownerAccountId: widget.cuentaId,
                perfilId: p.id,
                initialDateKey: dl.dateKey,
                initialItemId: dl.itemId,
              )
            : AlumnoDocumentosPage(
                ownerAccountId: widget.cuentaId,
                perfilId: p.id,
                initialDocumentoId: dl.documentoId,
                initialSolicitudId: dl.solicitudId,
              ),
      ),
    );
  }

  Future<void> _agregar() async {
    final creado = await Navigator.of(context).push<PerfilAlumno>(
      MaterialPageRoute(
        builder: (_) => AlumnoPerfilFormPage(cuentaId: widget.cuentaId),
      ),
    );
    if (creado == null || !mounted) return;
    if (_perfiles.isEmpty) {
      await _abrir(creado);
    } else {
      await _load();
    }
  }

  Future<void> _notificaciones() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificacionesPage(
          cuentaId: widget.cuentaId,
          role: AtenaRole.alumno,
          onOpen: (ctx, n) => abrirNotificacionAlumno(
            ctx,
            n,
            cuentaId: widget.cuentaId,
            perfilId: n.perfilId,
          ),
        ),
      ),
    );
    if (mounted) await _load();
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AtenaLogo(markSize: 30),
        actions: [
          IconButton(
            tooltip: t.notifTitle,
            onPressed: _notificaciones,
            icon: Badge(
              isLabelVisible: _noLeidas > 0,
              label: Text('$_noLeidas'),
              child: const Icon(Icons.notifications_rounded),
            ),
          ),
          const AtenaPreferencesButton(),
          IconButton(
            tooltip: t.commonLogout,
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
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
          : _perfiles.isEmpty
          ? AtenaEmptyState(
              icon: Icons.person_add_alt_1_rounded,
              title: t.hubEmptyTitle,
              message: t.hubEmptyBody,
              action: FilledButton.icon(
                onPressed: _agregar,
                icon: const Icon(Icons.add_rounded),
                label: Text(t.hubAddStudent),
              ),
            )
          : ListView(
              padding: atenaPagePadding(context, maxWidth: 760, top: 16),
              children: [
                Text(t.hubTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  t.hubSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                AtenaFeatureGrid(
                  minTileWidth: 200,
                  children: [
                    for (final item in _perfiles)
                      _PerfilCard(
                        item: item,
                        ultimo: item.perfil.id == _ultimo,
                        onTap: () => _abrir(item.perfil),
                      ),
                    _AgregarCard(onTap: _agregar),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    t.hubAccountLine(_email),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }
}

class _PerfilCard extends StatelessWidget {
  final _PerfilItem item;
  final bool ultimo;
  final VoidCallback onTap;

  const _PerfilCard({
    required this.item,
    required this.ultimo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = item.perfil;
    final edad = p.fechaNacimiento.millisecondsSinceEpoch == 0
        ? null
        : edadEnAnios(p.fechaNacimiento);

    return AtenaCard(
      onTap: onTap,
      borderColor: ultimo ? theme.colorScheme.primary : null,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        children: [
          AtenaAvatar(name: p.displayName, imageBytes: item.foto, size: 72),
          const SizedBox(height: 12),
          Text(
            p.displayName,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            edad == null ? '' : t.lblEdadAnios(edad),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (ultimo)
            AtenaStatusChip(
              label: t.hubLastUsed,
              color: theme.colorScheme.primary,
              icon: Icons.history_rounded,
              dense: true,
            )
          else
            const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _AgregarCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AgregarCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AtenaCard(
      onTap: onTap,
      color: cs.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary, width: 1.6),
            ),
            child: Icon(Icons.add_rounded, size: 34, color: cs.primary),
          ),
          const SizedBox(height: 12),
          Text(
            t.hubAddStudent,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 4),
          Text(
            t.hubAddStudentSub,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
