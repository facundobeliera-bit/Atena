// lib/screens/alumnos/alumno_documentos_page.dart
//
// ATENA – ALUMNO / DOCUMENTOS (CANÓNICO)
//
// ✅ FASE 2 (CIERRE):
// - Flujo canónico ownerAccountId → perfilId
// - Filtra por ownerAccountId (evita cruces si storage está “sucio”)
// - Deeplink fallback robusto + guard por owner mismatch
// - Autoscroll best-effort (ensureVisible por id + fallback por offset) con retry controlado
// - Hardening: mounted checks consistentes + messenger capturado (maybeOf)
// - Refresh manual resetea flags de deeplink y reintenta limpio
// - UX: trailing de acciones sin overflow, snackbars sin cola
//
// ✅ i18n/dark-mode (general):
// - Dark-mode: Theme/ColorScheme (sin hardcodear colores)
// - i18n: AppLocalizations (keys ARB a consolidar al final)

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../services/documentos_temporales_service.dart';

class AlumnoDocumentosPage extends StatefulWidget {
  final String ownerAccountId;
  final String perfilId;

  /// Si viene por deeplink, puede usarse para resaltar/ubicar un documento.
  final String? initialDocumentoId;

  /// Si viene por deeplink, puede usarse para resaltar/ubicar una solicitud.
  final String? initialSolicitudId;

  const AlumnoDocumentosPage({
    super.key,
    required this.ownerAccountId,
    required this.perfilId,
    this.initialDocumentoId,
    this.initialSolicitudId,
  });

  @override
  State<AlumnoDocumentosPage> createState() => _AlumnoDocumentosPageState();
}

class _AlumnoDocumentosPageState extends State<AlumnoDocumentosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final ScrollController _solsScroll = ScrollController();
  final ScrollController _docsScroll = ScrollController();

  bool _loading = true;
  String? _error;

  List<SolicitudDocumento> _solicitudes = const <SolicitudDocumento>[];
  List<DocumentoTemporal> _documentos = const <DocumentoTemporal>[];

  bool _didAutoScrollToInitialDoc = false;
  bool _didAutoScrollToInitialSol = false;

  bool _shownSnackInitialDocNotFound = false;
  bool _shownSnackInitialSolNotFound = false;

  bool _didCacheDeeplinkParams = false;
  String _initialDocId = '';
  String _initialSolId = '';
  String _initialOwnerFromRoute = '';
  bool _initialOwnerFromRoutePresent = false;

  bool _blockAutoscrollByOwnerMismatch = false;
  bool _shownSnackOwnerMismatch = false;

  int _retrySolLeft = 0;
  int _retryDocLeft = 0;

  bool _didAttemptAutoscrollFromDeps = false;

  final Map<String, GlobalKey> _solKeyById = <String, GlobalKey>{};
  final Map<String, GlobalKey> _docKeyById = <String, GlobalKey>{};

  AppLocalizations get _l10n => AppLocalizations.of(context);

  // =====================================================
  // Helpers canónicos de IDs (evita comparaciones frágiles)
  // =====================================================

  String _n(String v) => v.trim();
  String _ns(String? v) => (v ?? '').trim();

  /// ID/Key canónica para comparar: trim + colapsa whitespace interno.
  String _kid(String v) => _n(v).replaceAll(RegExp(r'\s+'), '');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    _tab.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _load();
    });
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tab.indexIsChanging) return;
    if (_blockAutoscrollByOwnerMismatch) return;

    if (_tab.index == 0) {
      final sol = _initialSolicitudId();
      if (sol.isNotEmpty && !_didAutoScrollToInitialSol) {
        _retrySolLeft = _retrySolLeft > 0 ? _retrySolLeft : 3;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeScrollToInitialSolicitud(force: true);
        });
      }
    } else if (_tab.index == 1) {
      final doc = _initialDocumentoId();
      if (doc.isNotEmpty && !_didAutoScrollToInitialDoc) {
        _retryDocLeft = _retryDocLeft > 0 ? _retryDocLeft : 3;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeScrollToInitialDocumento(force: true);
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final wasCached = _didCacheDeeplinkParams;
    _cacheDeeplinkParamsIfNeeded();

    _applyOwnerMismatchGuardIfNeeded();

    if (_didAttemptAutoscrollFromDeps) return;

    if (!wasCached && _didCacheDeeplinkParams && !_loading) {
      if (_blockAutoscrollByOwnerMismatch) return;

      final sol = _initialSolicitudId();
      final doc = _initialDocumentoId();

      if (sol.isNotEmpty && !_didAutoScrollToInitialSol) {
        _didAttemptAutoscrollFromDeps = true;
        _retrySolLeft = _retrySolLeft > 0 ? _retrySolLeft : 3;
        if (_tab.index != 0) _tab.animateTo(0);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await Future<void>.delayed(const Duration(milliseconds: 60));
          if (!mounted) return;
          _maybeScrollToInitialSolicitud(force: true);
        });
      } else if (doc.isNotEmpty && !_didAutoScrollToInitialDoc) {
        _didAttemptAutoscrollFromDeps = true;
        _retryDocLeft = _retryDocLeft > 0 ? _retryDocLeft : 3;
        if (_tab.index != 1) _tab.animateTo(1);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await Future<void>.delayed(const Duration(milliseconds: 60));
          if (!mounted) return;
          _maybeScrollToInitialDocumento(force: true);
        });
      }
    }
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _solsScroll.dispose();
    _docsScroll.dispose();
    _tab.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
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

  Color? _highlightTileColor(BuildContext context, {required bool highlight}) {
    if (!highlight) return null;
    final cs = Theme.of(context).colorScheme;
    // ✅ Theme-driven highlight (no hardcode)
    return cs.primaryContainer.withValues(alpha: 0.35);
  }

  // =====================================================
  // Deeplink fallback (por si el router no pudo pasar args)
  // =====================================================

  String _stripHashRoute(String raw) {
    final idx = raw.lastIndexOf('#');
    if (idx < 0) return raw;

    final before = raw.substring(0, idx).trim();
    final after = raw.substring(idx + 1).trim();

    if (after.isEmpty) return before.isEmpty ? raw : before;

    var out = after.startsWith('/') ? after : '/$after';
    out = out.replaceAll('/#/', '/');

    while (out.contains('//')) {
      out = out.replaceAll('//', '/');
    }
    return out;
  }

  Uri? _parseLocalUriFromSettingsName(String? name) {
    var raw = (name ?? '').trim();
    if (raw.isEmpty) return null;

    raw = _stripHashRoute(raw);

    if (raw.contains('://')) {
      try {
        final uAbs = Uri.parse(raw);

        final frag = (uAbs.fragment).trim();
        if (frag.isNotEmpty) {
          final f = frag.startsWith('/') ? frag : '/$frag';
          try {
            return Uri.parse(_stripHashRoute(f));
          } catch (_) {}
        }

        final rebuilt = '${uAbs.path}${uAbs.hasQuery ? '?${uAbs.query}' : ''}';
        try {
          return Uri.parse(rebuilt);
        } catch (_) {
          return Uri(path: uAbs.path, queryParameters: uAbs.queryParameters);
        }
      } catch (_) {
        return null;
      }
    }

    if (!raw.startsWith('/') && raw.contains('?')) raw = '/$raw';

    try {
      return Uri.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _qpLowerAll(Uri? u) {
    if (u == null) return const <String, String>{};
    final out = <String, String>{};

    final qpAll = u.queryParametersAll;
    qpAll.forEach((k, list) {
      final kk = k.trim().toLowerCase();
      if (kk.isEmpty) return;

      String chosen = '';
      for (final v in list) {
        final vv = v.trim();
        if (vv.isNotEmpty) {
          chosen = vv;
          break;
        }
      }

      final prev = (out[kk] ?? '').trim();
      if (!out.containsKey(kk) || (prev.isEmpty && chosen.isNotEmpty)) {
        out[kk] = chosen;
      }
    });

    return out;
  }

  String _qpFirstCI(Uri? u, List<String> keys) {
    if (u == null) return '';
    final qp = _qpLowerAll(u);
    for (final k in keys) {
      final v = (qp[k.toLowerCase()] ?? '').trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  bool _looksLikeDocumentosRoute(Uri? u) {
    if (u == null) return false;
    final p = u.path.trim().toLowerCase();
    if (p.isEmpty) return false;
    return p.contains('documentos');
  }

  void _cacheDeeplinkParamsIfNeeded() {
    if (_didCacheDeeplinkParams) return;

    final directDoc = _ns(widget.initialDocumentoId);
    final directSol = _ns(widget.initialSolicitudId);
    final hasDirect = directDoc.isNotEmpty || directSol.isNotEmpty;

    final routeName = ModalRoute.of(context)?.settings.name;
    final hasRouteName = _ns(routeName).isNotEmpty;

    if (!hasDirect && !hasRouteName) {
      return;
    }

    final u = _parseLocalUriFromSettingsName(routeName);

    final routeIsRelevant = _looksLikeDocumentosRoute(u);

    final fallbackOwner = routeIsRelevant
        ? _qpFirstCI(u, const [
            'ownerAccountId',
            'owneraccountid',
            'ownerId',
            'ownerid',
            'cuentaId',
            'cuentaid',
          ]).trim()
        : '';

    final fallbackDoc = routeIsRelevant
        ? _qpFirstCI(u, const [
            'documentoId',
            'documentoid',
            'docId',
            'docid',
            'initialDocumentoId',
            'initialDocumentoID',
            'initialdocumentoid',
          ]).trim()
        : '';

    final fallbackSol = routeIsRelevant
        ? _qpFirstCI(u, const [
            'solicitudId',
            'solicitudid',
            'initialSolicitudId',
            'initialSolicitudID',
            'initialsolicitudid',
            'sid',
          ]).trim()
        : '';

    final resolvedDoc = directDoc.isNotEmpty ? directDoc : fallbackDoc;
    final resolvedSol = directSol.isNotEmpty ? directSol : fallbackSol;

    final relevantByRoute =
        hasRouteName &&
        (routeIsRelevant ||
            fallbackOwner.isNotEmpty ||
            fallbackDoc.isNotEmpty ||
            fallbackSol.isNotEmpty);

    if (!hasDirect && !relevantByRoute) {
      return;
    }

    _initialOwnerFromRoute = fallbackOwner;
    _initialOwnerFromRoutePresent = fallbackOwner.trim().isNotEmpty;

    _initialDocId = resolvedDoc;
    _initialSolId = resolvedSol;

    _didCacheDeeplinkParams = true;
  }

  void _applyOwnerMismatchGuardIfNeeded() {
    if (_blockAutoscrollByOwnerMismatch) return;

    _cacheDeeplinkParamsIfNeeded();

    final ownerRoute = _kid(_initialOwnerFromRoute);
    final ownerWidget = _kid(widget.ownerAccountId);

    if (ownerRoute.isEmpty) return;
    if (ownerWidget.isEmpty) return;
    if (ownerRoute == ownerWidget) return;

    _blockAutoscrollByOwnerMismatch = true;

    if (_shownSnackOwnerMismatch) return;
    _shownSnackOwnerMismatch = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      _snackMaybe(
        messenger,
        _l10n.alumnoDocumentosOwnerMismatchAutoscrollIgnored,
      );
    });
  }

  String _initialDocumentoId() {
    _cacheDeeplinkParamsIfNeeded();
    return _initialDocId.trim();
  }

  String _initialSolicitudId() {
    _cacheDeeplinkParamsIfNeeded();
    return _initialSolId.trim();
  }

  // =====================================================
  // Autoscroll retry (controlado)
  // =====================================================

  void _retryAutoScrollSol() {
    if (!mounted) return;
    if (_retrySolLeft <= 0) return;
    _retrySolLeft--;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      _maybeScrollToInitialSolicitud(force: true);
    });
  }

  void _retryAutoScrollDoc() {
    if (!mounted) return;
    if (_retryDocLeft <= 0) return;
    _retryDocLeft--;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      _maybeScrollToInitialDocumento(force: true);
    });
  }

  // =====================================================
  // Scroll preciso (ensureVisible) con fallback por offset
  // =====================================================

  Future<bool> _ensureVisibleById({
    required Map<String, GlobalKey> map,
    required String id,
  }) async {
    final k = map[_kid(id)];
    final ctx = k?.currentContext;
    if (ctx == null) return false;

    try {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ownerId = _n(widget.ownerAccountId);
      final perfilId = _n(widget.perfilId);

      if (ownerId.isEmpty) {
        throw Exception(_l10n.alumnoDocumentosInvalidOwner);
      }
      if (perfilId.isEmpty) {
        throw Exception(_l10n.alumnoDocumentosInvalidPerfil);
      }

      final solsAll = List<SolicitudDocumento>.from(
        await DocumentosTemporalesService.listarSolicitudesPerfil(
          perfilId: perfilId,
        ),
      );
      final docsAll = List<DocumentoTemporal>.from(
        await DocumentosTemporalesService.listarDocumentosPerfil(
          perfilId: perfilId,
        ),
      );

      final oKey = _kid(ownerId);

      final sols = solsAll
          .where((s) => _kid(s.ownerAccountId) == oKey)
          .toList(growable: false);

      final docs = docsAll
          .where((d) => _kid(d.ownerAccountId) == oKey)
          .toList(growable: false);

      final solsSorted = List<SolicitudDocumento>.from(sols)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final docsSorted = List<DocumentoTemporal>.from(docs)
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      _solKeyById
        ..clear()
        ..addEntries(solsSorted.map((s) => MapEntry(_kid(s.id), GlobalKey())));

      _docKeyById
        ..clear()
        ..addEntries(docsSorted.map((d) => MapEntry(_kid(d.id), GlobalKey())));

      if (!mounted) return;

      setState(() {
        _solicitudes = solsSorted;
        _documentos = docsSorted;
      });

      _cacheDeeplinkParamsIfNeeded();
      _applyOwnerMismatchGuardIfNeeded();
      if (_blockAutoscrollByOwnerMismatch) return;

      final initialSol = _initialSolicitudId();
      final initialDoc = _initialDocumentoId();

      if (initialSol.isNotEmpty) {
        _retrySolLeft = 3;
        if (_tab.index != 0) _tab.animateTo(0);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await Future<void>.delayed(const Duration(milliseconds: 60));
          if (!mounted) return;
          _maybeScrollToInitialSolicitud(force: true);
        });
      } else if (initialDoc.isNotEmpty) {
        _retryDocLeft = 3;
        if (_tab.index != 1) _tab.animateTo(1);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await Future<void>.delayed(const Duration(milliseconds: 60));
          if (!mounted) return;
          _maybeScrollToInitialDocumento(force: true);
        });
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      _snackMaybe(messenger, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _maybeScrollToInitialSolicitud({bool force = false}) {
    if (!mounted) return;
    if (_blockAutoscrollByOwnerMismatch) return;

    final initial = _initialSolicitudId();
    if (initial.isEmpty) return;

    if (!force && _didAutoScrollToInitialSol) return;

    if (_solicitudes.isEmpty && _retrySolLeft > 0) {
      _retryAutoScrollSol();
      return;
    }

    final iKey = _kid(initial);
    final idx = _solicitudes.indexWhere((s) => _kid(s.id) == iKey);

    if (idx < 0) {
      if (_solicitudes.isEmpty && _retrySolLeft > 0) {
        _retryAutoScrollSol();
        return;
      }

      _didAutoScrollToInitialSol = true;

      if (_shownSnackInitialSolNotFound) return;
      _shownSnackInitialSolNotFound = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        _snackMaybe(messenger, _l10n.alumnoDocumentosDeeplinkSolicitudNotFound);
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final ok = await _ensureVisibleById(map: _solKeyById, id: initial);
      if (ok) {
        _didAutoScrollToInitialSol = true;
        return;
      }

      if (!_solsScroll.hasClients) {
        if (_retrySolLeft > 0) _retryAutoScrollSol();
        return;
      }

      _didAutoScrollToInitialSol = true;

      const estimatedItemExtent = 154.0;
      const separator = 10.0;
      final offset = (estimatedItemExtent + separator) * idx;

      if (!_solsScroll.hasClients) return;

      _solsScroll.animateTo(
        offset.clamp(0.0, _solsScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _maybeScrollToInitialDocumento({bool force = false}) {
    if (!mounted) return;
    if (_blockAutoscrollByOwnerMismatch) return;

    final initial = _initialDocumentoId();
    if (initial.isEmpty) return;

    if (!force && _didAutoScrollToInitialDoc) return;

    if (_documentos.isEmpty && _retryDocLeft > 0) {
      _retryAutoScrollDoc();
      return;
    }

    final iKey = _kid(initial);
    final idx = _documentos.indexWhere((d) => _kid(d.id) == iKey);

    if (idx < 0) {
      if (_documentos.isEmpty && _retryDocLeft > 0) {
        _retryAutoScrollDoc();
        return;
      }

      _didAutoScrollToInitialDoc = true;

      if (_shownSnackInitialDocNotFound) return;
      _shownSnackInitialDocNotFound = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        _snackMaybe(messenger, _l10n.alumnoDocumentosDeeplinkDocumentoNotFound);
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final ok = await _ensureVisibleById(map: _docKeyById, id: initial);
      if (ok) {
        _didAutoScrollToInitialDoc = true;
        return;
      }

      if (!_docsScroll.hasClients) {
        if (_retryDocLeft > 0) _retryAutoScrollDoc();
        return;
      }

      _didAutoScrollToInitialDoc = true;

      const estimatedItemExtent = 132.0;
      const separator = 10.0;
      final offset = (estimatedItemExtent + separator) * idx;

      if (!_docsScroll.hasClients) return;

      _docsScroll.animateTo(
        offset.clamp(0.0, _docsScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _limpiarExpirados() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final removed = await DocumentosTemporalesService.limpiarExpiradosPerfil(
        perfilId: _n(widget.perfilId),
        notify: true,
        duplicarEnPerfil: true,
      );

      if (!mounted) return;

      _snackMaybe(
        messenger,
        removed <= 0
            ? _l10n.alumnoDocumentosNoExpiredToClean
            : _l10n.alumnoDocumentosExpiredCleanedCount(removed),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      _snackMaybe(messenger, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminarDoc(DocumentoTemporal d) async {
    if (!mounted) return;

    final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;
    if (exp) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      _snackMaybe(messenger, _l10n.alumnoDocumentosDocExpiredUseClean);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_l10n.alumnoDocumentosDeleteDocTitle),
        content: Text(_l10n.alumnoDocumentosDeleteDocBody(d.id)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_l10n.commonDelete),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      await DocumentosTemporalesService.eliminarDocumento(
        perfilId: _n(widget.perfilId),
        documentoId: _n(d.id),
      );

      if (!mounted) return;
      _snackMaybe(messenger, _l10n.alumnoDocumentosDocDeleted);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snackMaybe(messenger, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    _resetDeeplinkAutoscrollState();
    await _load();
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }

  String _labelEstadoSolicitud(EstadoSolicitudDocumento e) {
    switch (e) {
      case EstadoSolicitudDocumento.pendiente:
        return _l10n.commonPending;
      case EstadoSolicitudDocumento.cumplida:
        return _l10n.commonCompleted;
      case EstadoSolicitudDocumento.cancelada:
        return _l10n.commonCancelled;
    }
  }

  Widget _chipEstadoSolicitud(EstadoSolicitudDocumento e) {
    return Chip(label: Text(_labelEstadoSolicitud(e)));
  }

  Widget _chipEstadoDoc(DocumentoTemporal d) {
    final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;
    return Chip(label: Text(exp ? _l10n.commonExpired : _l10n.commonActive));
  }

  void _resetDeeplinkAutoscrollState() {
    _didAutoScrollToInitialDoc = false;
    _didAutoScrollToInitialSol = false;

    _shownSnackInitialDocNotFound = false;
    _shownSnackInitialSolNotFound = false;

    _retryDocLeft = 0;
    _retrySolLeft = 0;

    _didAttemptAutoscrollFromDeps = false;

    final hadOwnerFromRoute = _initialOwnerFromRoutePresent;

    _didCacheDeeplinkParams = false;
    _initialDocId = '';
    _initialSolId = '';
    _initialOwnerFromRoute = '';
    _initialOwnerFromRoutePresent = false;

    if (!hadOwnerFromRoute) {
      _blockAutoscrollByOwnerMismatch = false;
      _shownSnackOwnerMismatch = false;
    }
  }

  Widget _buildTrailingDocActions(DocumentoTemporal d) {
    final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 112),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(alignment: Alignment.centerRight, child: _chipEstadoDoc(d)),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: exp
                  ? _l10n.alumnoDocumentosExpiredTooltip
                  : _l10n.commonDelete,
              onPressed: exp
                  ? null
                  : () {
                      // ignore: discarded_futures
                      _eliminarDoc(d);
                    },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }

  String _tipoLabel(TipoDocumento t) {
    try {
      final v = (t as dynamic).label;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {
      // NO-OP
    }
    return t.name;
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = _n(widget.ownerAccountId);
    final perfilId = _n(widget.perfilId);

    if (ownerId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.alumnoDocumentosTitle)),
        body: _buildError(_l10n.alumnoDocumentosInvalidOwner),
      );
    }

    if (perfilId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.alumnoDocumentosTitle)),
        body: _buildError(_l10n.alumnoDocumentosInvalidPerfil),
      );
    }

    final initialSol = _blockAutoscrollByOwnerMismatch
        ? ''
        : _initialSolicitudId();
    final initialDoc = _blockAutoscrollByOwnerMismatch
        ? ''
        : _initialDocumentoId();

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = _buildError(_error!);
    } else {
      body = TabBarView(
        controller: _tab,
        children: [
          _solicitudes.isEmpty
              ? _buildEmpty(_l10n.alumnoDocumentosEmptySolicitudes)
              : ListView.separated(
                  controller: _solsScroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _solicitudes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = _solicitudes[i];

                    final msg = _ns(s.mensaje);
                    final msgLine = msg.isEmpty
                        ? ''
                        : '${_l10n.alumnoDocumentosFieldMensaje}: $msg\n';

                    final highlight =
                        initialSol.isNotEmpty && _kid(s.id) == _kid(initialSol);

                    final keyId = _kid(s.id);
                    final tileKey = _solKeyById[keyId] ?? GlobalKey();
                    _solKeyById[keyId] = tileKey;

                    return Card(
                      key: tileKey,
                      child: ListTile(
                        tileColor: _highlightTileColor(
                          context,
                          highlight: highlight,
                        ),
                        leading: const Icon(Icons.assignment),
                        title: Text(
                          '${_l10n.alumnoDocumentosFieldTipo}: ${_tipoLabel(s.tipo)}',
                        ),
                        subtitle: Text(
                          '${_l10n.alumnoDocumentosFieldId}: ${s.id}\n'
                          '${_l10n.alumnoDocumentosFieldEstado}: ${_labelEstadoSolicitud(s.estado)}\n'
                          '${_l10n.alumnoDocumentosFieldInstitucion}: ${s.institucionId}\n'
                          '${_l10n.alumnoDocumentosFieldCreada}: ${_fmt(s.createdAt)}\n'
                          '$msgLine'
                          '${_l10n.alumnoDocumentosFieldOwner}: ${s.ownerAccountId}\n'
                          '${_l10n.alumnoDocumentosFieldPerfil}: ${s.perfilId}',
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: _chipEstadoSolicitud(s.estado),
                      ),
                    );
                  },
                ),
          _documentos.isEmpty
              ? _buildEmpty(_l10n.alumnoDocumentosEmptyDocumentos)
              : ListView.separated(
                  controller: _docsScroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _documentos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = _documentos[i];
                    final exp =
                        d.expirado ||
                        d.estado == EstadoDocumentoTemporal.expirado;

                    final highlight =
                        initialDoc.isNotEmpty && _kid(d.id) == _kid(initialDoc);

                    final solicitudId = _ns(d.solicitudId);
                    final solicitudLabel = solicitudId.isEmpty
                        ? _l10n.commonNone
                        : solicitudId;

                    final expLine = exp
                        ? '${_l10n.alumnoDocumentosFieldEstado}: ${_l10n.commonExpired} (${_l10n.alumnoDocumentosExpiredWillBeDeletedOnClean})\n'
                        : '';

                    final keyId = _kid(d.id);
                    final tileKey = _docKeyById[keyId] ?? GlobalKey();
                    _docKeyById[keyId] = tileKey;

                    return Card(
                      key: tileKey,
                      child: ListTile(
                        tileColor: _highlightTileColor(
                          context,
                          highlight: highlight,
                        ),
                        leading: Icon(
                          exp
                              ? Icons.hourglass_disabled
                              : Icons.insert_drive_file,
                        ),
                        title: Text(
                          '${_l10n.alumnoDocumentosFieldTipo}: ${_tipoLabel(d.tipo)}',
                        ),
                        subtitle: Text(
                          '${_l10n.alumnoDocumentosFieldId}: ${d.id}\n'
                          '${_l10n.alumnoDocumentosFieldSubido}: ${_fmt(d.uploadedAt)}\n'
                          '${_l10n.alumnoDocumentosFieldExpira}: ${_fmt(d.expiresAt)}\n'
                          '$expLine'
                          '${_l10n.alumnoDocumentosFieldInstitucion}: ${d.institucionSolicitanteId}\n'
                          '${_l10n.alumnoDocumentosFieldSolicitud}: $solicitudLabel\n'
                          '${_l10n.alumnoDocumentosFieldRef}: ${d.ref}',
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: _buildTrailingDocActions(d),
                      ),
                    );
                  },
                ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.alumnoDocumentosTitle),
        actions: [
          IconButton(
            onPressed: _loading
                ? null
                : () {
                    // ignore: discarded_futures
                    _refresh();
                  },
            icon: const Icon(Icons.refresh),
            tooltip: _l10n.commonRefresh,
          ),
          IconButton(
            onPressed: _loading
                ? null
                : () {
                    // ignore: discarded_futures
                    _limpiarExpirados();
                  },
            icon: const Icon(Icons.cleaning_services),
            tooltip: _l10n.alumnoDocumentosCleanExpired,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: _l10n.alumnoDocumentosTabSolicitudes),
            Tab(text: _l10n.alumnoDocumentosTabDocumentos),
          ],
        ),
      ),
      body: body,
    );
  }
}
