// lib/screens/alumnos/alumno_area_page.dart
//
// FIX: Buscar Instituciones ahora abre la pantalla real de búsqueda.
// La pantalla placeholder queda eliminada de este archivo.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/alumnos/alumnos_integrados.dart';
import '../../services/alumno_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/notificaciones_service.dart';

import '../alumnos/alumno_buscar_instituciones_page.dart';
import '../alumnos/alumno_calendario_page.dart';
import '../alumnos/alumno_notificaciones_page.dart';
import '../alumnos/alumno_pdfs_page.dart';

import '../auth/alumno_login_page.dart';
import '../cuentas/cuenta_home_page.dart';

import '../../ui/atena_assets.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

class AlumnoAreaPage extends StatefulWidget {
  final String documentoAlumno;
  final String cuentaId;
  final String perfilId;

  const AlumnoAreaPage({
    super.key,
    required this.documentoAlumno,
    required this.cuentaId,
    required this.perfilId,
  });

  @override
  State<AlumnoAreaPage> createState() => _AlumnoAreaPageState();
}

class _AlumnoAreaPageState extends State<AlumnoAreaPage>
    with WidgetsBindingObserver {
  bool _cargando = true;
  bool _perfilInvalido = false;
  bool _navegando = false;

  Alumno? _perfil;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _fotoBytesCache;

  int _notiNoLeidas = 0;
  bool _cargandoBadge = false;

  String get _ownerAccountId => _normId(widget.cuentaId);
  String get _perfilId => _normId(widget.perfilId);

  static String _normId(String s) => s.trim().replaceAll(RegExp(r'\s+'), '');

  Future<void> _runNavigation(Future<void> Function() fn) async {
    if (!mounted || _navegando) return;
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
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome)),
          context,
        );
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow)),
          context,
        );
      } catch (_) {}
    });

    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refrescarBadge();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _perfilInvalido = false;
      _perfil = null;
      _fotoBytesCache = null;
    });

    try {
      final owner = _ownerAccountId;
      final perfilId = _perfilId;
      if (owner.isEmpty || perfilId.isEmpty) {
        throw StateError('Sesión inválida (owner/perfil vacío).');
      }

      final p = await AlumnoService.instance.getPerfilAlumnoByPerfilId(
        ownerAccountId: owner,
        perfilId: perfilId,
      );

      if (!mounted) return;
      if (p == null) {
        setState(() {
          _cargando = false;
          _perfilInvalido = true;
          _perfil = null;
          _fotoBytesCache = null;
        });
        return;
      }

      setState(() {
        _perfil = p;
        _cargando = false;
        _perfilInvalido = false;
        _fotoBytesCache = null;
      });

      await _refrescarBadge();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _perfil = null;
        _perfilInvalido = true;
        _cargando = false;
        _fotoBytesCache = null;
      });
    }
  }

  Future<void> _refrescarBadge() async {
    if (_cargandoBadge || !mounted) return;
    setState(() => _cargandoBadge = true);

    try {
      final owner = _ownerAccountId;
      final perfilId = _perfilId;
      if (owner.isEmpty || perfilId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _notiNoLeidas = 0;
          _cargandoBadge = false;
        });
        return;
      }

      final list = await NotificacionesService.listarOwner(owner);
      final count = list
          .where((n) => !n.leida && _normId(n.perfilId ?? '') == perfilId)
          .length;

      if (!mounted) return;
      setState(() {
        _notiNoLeidas = count;
        _cargandoBadge = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notiNoLeidas = 0;
        _cargandoBadge = false;
      });
    }
  }

  Future<void> _abrirNotificaciones() async {
    if (_navegando) return;
    await _runNavigation(() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlumnoNotificacionesPage(
            alumnoDocumento: widget.documentoAlumno,
            perfilIdFiltro: _perfilId,
          ),
        ),
      );
    });
    if (mounted) await _refrescarBadge();
  }

  void _abrirPdfs() {
    final perfil = _perfil;
    if (perfil == null || _navegando) return;

    _runNavigation(() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlumnoPdfsPage(
            ownerAccountId: _ownerAccountId,
            perfilId: _perfilId,
            alumno: perfil,
          ),
        ),
      );
    });
  }

  /// Abre la pantalla REAL de búsqueda de instituciones.
  ///
  /// Antes este botón abría _AlumnoBuscarInstitucionesPlaceholderPage,
  /// por lo que el alumno nunca llegaba a la búsqueda/paginación real.
  void _abrirBuscarInstituciones() {
    if (_navegando) return;

    _runNavigation(() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlumnoBuscarInstitucionesPage(
            alumnoDni: widget.documentoAlumno,
            ownerAccountId: _ownerAccountId,
            perfilId: _perfilId,
          ),
        ),
      );
    });
  }

  Uint8List? _decodeB64(String? s) {
    final t = (s ?? '').trim();
    if (t.isEmpty || !t.startsWith('b64:')) return null;
    try {
      return base64Decode(t.substring(4));
    } catch (_) {
      return null;
    }
  }

  bool _tieneFoto(Alumno a) => (a.fotoPerfilLocalPath ?? '').trim().isNotEmpty;

  ImageProvider? _fotoProviderSync(Alumno a) {
    final bytes = _decodeB64(a.fotoPerfilLocalPath);
    if (bytes != null) return MemoryImage(bytes);
    return null;
  }

  Future<void> _cambiarFoto() async {
    final perfil = _perfil;
    if (perfil == null || _navegando) return;

    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;

      final bytes = await x.readAsBytes();
      if (bytes.isEmpty) return;

      final actualizado = perfil.copyWith(
        fotoPerfilLocalPath: 'b64:${base64Encode(bytes)}',
      );

      await AlumnoService.instance.upsertPerfilAlumnoByPerfilId(
        ownerAccountId: _ownerAccountId,
        perfilId: _perfilId,
        alumno: actualizado,
      );

      if (!mounted) return;
      setState(() {
        _perfil = actualizado;
        _fotoBytesCache = bytes;
      });
    } catch (_) {}
  }

  Future<void> _borrarFoto() async {
    final perfil = _perfil;
    if (perfil == null || _navegando || !_tieneFoto(perfil)) return;

    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.commonDeletePhotoTitle),
        content: Text(l10n.commonDeletePhotoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelar),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.eliminar),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final actualizado = perfil.copyWith(clearFotoPerfilLocalPath: true);
    await AlumnoService.instance.upsertPerfilAlumnoByPerfilId(
      ownerAccountId: _ownerAccountId,
      perfilId: _perfilId,
      alumno: actualizado,
    );

    if (!mounted) return;
    setState(() {
      _perfil = actualizado;
      _fotoBytesCache = null;
    });
  }

  void _irASelectorPerfiles() {
    if (_navegando) return;
    _runNavigation(() async {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CuentaHomePage(cuentaId: _ownerAccountId),
        ),
        (_) => false,
      );
    });
  }

  Future<void> _logout() async {
    if (_navegando) return;
    await _runNavigation(() async {
      await CuentaService.logoutCuenta();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AlumnoLoginPage()),
        (_) => false,
      );
    });
  }

  Widget _buildBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    Widget bgFallback() => Container(color: cs.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => bgFallback(),
        ),
        Container(color: cs.scrim.withValues(alpha: isDark ? 0.25 : 0.06)),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.35 : 0.20,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final perfil = _perfil;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final ImageProvider? provider = () {
      if (_fotoBytesCache != null) return MemoryImage(_fotoBytesCache!);
      if (perfil == null) return null;
      return _fotoProviderSync(perfil);
    }();

    final cardColor = cs.surface.withValues(alpha: isDark ? 0.25 : 0.92);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alumnoAreaTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: l10n.actualizar,
            icon: const Icon(Icons.refresh),
            onPressed: (_cargando || _navegando) ? null : _cargar,
          ),
          IconButton(
            tooltip: l10n.perfiles,
            icon: const Icon(Icons.switch_account),
            onPressed: (_cargando || _navegando) ? null : _irASelectorPerfiles,
          ),
          _Bell(
            tooltip: l10n.commonNotificationsTooltip,
            count: _notiNoLeidas,
            loading: _cargandoBadge,
            onTap: _abrirNotificaciones,
            disabled: _cargando || _navegando,
          ),
          IconButton(
            tooltip: l10n.cerrarSesion,
            icon: const Icon(Icons.logout),
            onPressed: (_cargando || _navegando) ? null : _logout,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _buildBackground(
        context,
        SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : (perfil == null
                    ? _buildPerfilInvalido(context, cardColor)
                    : _contenido(context, perfil, provider, cardColor)),
        ),
      ),
    );
  }

  Widget _buildPerfilInvalido(BuildContext context, Color cardColor) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48),
                const SizedBox(height: 12),
                Text(
                  _perfilInvalido
                      ? l10n.alumnoPerfilInvalido
                      : l10n.errorGenerico,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _navegando ? null : _irASelectorPerfiles,
                  icon: const Icon(Icons.switch_account),
                  label: Text(l10n.commonBackToProfiles),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido(
    BuildContext context,
    Alumno perfil,
    ImageProvider? provider,
    Color cardColor,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final tieneFoto = _tieneFoto(perfil);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          color: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundImage: provider,
                  child: provider == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfil.nombreCompleto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.commonEmailLabel}: ${perfil.email}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.commonPhoneLabel}: ${perfil.telefono}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: (_cargando || _navegando)
                                ? null
                                : _cambiarFoto,
                            icon: const Icon(Icons.photo),
                            label: Text(l10n.commonChangePhoto),
                          ),
                          TextButton.icon(
                            onPressed: (_cargando || _navegando || !tieneFoto)
                                ? null
                                : _borrarFoto,
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.commonDeletePhoto),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(l10n.alumnoBuscarInstituciones),
                subtitle: Text(l10n.alumnoBuscarInstitucionesSub),
                onTap: (_cargando || _navegando)
                    ? null
                    : _abrirBuscarInstituciones,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(l10n.commonCalendar),
                onTap: (_cargando || _navegando)
                    ? null
                    : () {
                        _runNavigation(() async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlumnoCalendarioPage(
                                ownerAccountId: _ownerAccountId,
                                perfilId: _perfilId,
                              ),
                            ),
                          );
                        });
                      },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(l10n.commonDocumentsPdf),
                subtitle: Text(l10n.commonStudentPdfSub),
                onTap: (_cargando || _navegando) ? null : _abrirPdfs,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(l10n.commonNotifications),
                onTap: (_cargando || _navegando) ? null : _abrirNotificaciones,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bell extends StatelessWidget {
  final String tooltip;
  final int count;
  final bool loading;
  final VoidCallback onTap;
  final bool disabled;

  const _Bell({
    required this.tooltip,
    required this.count,
    required this.loading,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final badgeBg = cs.errorContainer;
    final badgeFg = cs.onErrorContainer;
    final badgeBorder = cs.outlineVariant.withValues(
      alpha: isDark ? 0.75 : 0.9,
    );

    return IconButton(
      tooltip: tooltip,
      onPressed: disabled ? null : onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications),
          if (loading)
            const Positioned(
              right: -2,
              top: -2,
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (!loading && count > 0)
            Positioned(
              right: -8,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(color: badgeBorder, width: 1),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
