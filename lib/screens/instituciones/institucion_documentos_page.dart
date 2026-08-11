// lib/screens/instituciones/institucion_documentos_page.dart
//
// (mismo header que ya tenías…)
//
// ATENA – INSTITUCIÓN / DOCUMENTOS (TEMPORALES + SOLICITUDES)
// CANÓNICO (owner → perfiles) – UI institución
//
// FIX (Feb 2026) – “no quedar cargando” + hardening:
// - ✅ initState NO depende de l10n (post-frame bootstrap).
// - ✅ _loadSafe con timeout + token + finally => SIEMPRE corta loading.
// - ✅ Timeouts cortos en servicios (prototipo local) para evitar await colgado.
// - ✅ Prefill best-effort: RouteSettings.arguments (owner/perfil).
// - ✅ Registrar owner de institución best-effort (no bloquea pantalla).
// - ✅ Mantiene filtros por owner/perfil sin normalizaciones agresivas para DATA.
//
// ✅ FIX (Feb 2026) – cierre lint + robustez:
// - Captura l10n/messenger ANTES de awaits en _loadSafe (reduce use_build_context_synchronously).
// - _loadSafe no apaga _loading si el token ya quedó stale (token==_loadSeq).
// - Permite recargas “while loading” cuando se invoca desde mutaciones (allowWhileLoading=true).
//
// Nota:
// - Este screen es prototipo local (sin storage remoto real).
// - No asume que todos los métodos del service existan más allá de lo usado aquí.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/documentos_temporales_service.dart';
import '../../services/session_service.dart';

class InstitucionDocumentosPage extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  final String? initialOwnerAccountId;
  final String? initialPerfilId;

  final String? institucionOwnerAccountId;

  const InstitucionDocumentosPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    this.initialOwnerAccountId,
    this.initialPerfilId,
    this.institucionOwnerAccountId,
  });

  @override
  State<InstitucionDocumentosPage> createState() =>
      _InstitucionDocumentosPageState();
}

class _InstitucionDocumentosPageState extends State<InstitucionDocumentosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _ownerCtrl = TextEditingController();
  final _perfilCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  final _refCtrl = TextEditingController(text: 'local://archivo_demo.pdf');
  final _ttlCtrl = TextEditingController(text: '5');

  late final List<TipoDocumento> _tipos;

  TipoDocumento? _tipo;

  bool _loading = false;
  String? _error;

  List<SolicitudDocumento> _sols = const <SolicitudDocumento>[];
  List<DocumentoTemporal> _docs = const <DocumentoTemporal>[];

  String? _institucionOwnerResolved;

  List<SolicitudDocumento> _solsPrev = const <SolicitudDocumento>[];
  List<DocumentoTemporal> _docsPrev = const <DocumentoTemporal>[];

  // Hardening anti-cargas simultáneas / stale results
  bool _booting = false;
  int _loadSeq = 0;

  static String _n(String v) => v.trim();
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');
  static String _normOrEmpty(String? v) => _normIdKey((v ?? '').trim());

  String get _instIdCanon => _normIdKey(widget.institucionId);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    final o = _normIdKey(widget.initialOwnerAccountId ?? '');
    final p = _normIdKey(widget.initialPerfilId ?? '');
    if (o.isNotEmpty) _ownerCtrl.text = o;
    if (p.isNotEmpty) _perfilCtrl.text = p;

    _tipos = (() {
      try {
        return List<TipoDocumento>.from(TipoDocumento.values);
      } catch (_) {
        return <TipoDocumento>[];
      }
    })();

    _tipo = _tipos.isNotEmpty ? _tipos.first : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _tryApplyArgsPrefillBestEffort();

      // ignore: discarded_futures
      _resolveAndRegisterInstitucionOwnerBestEffort();

      // ignore: discarded_futures
      _loadSafe();
    });
  }

  void _tryApplyArgsPrefillBestEffort() {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final owner = _normIdKey('${args['ownerAccountId'] ?? ''}');
        final perfil = _normIdKey('${args['perfilId'] ?? ''}');
        if (owner.isNotEmpty && _normIdKey(_ownerCtrl.text) != owner) {
          _ownerCtrl.text = owner;
        }
        if (perfil.isNotEmpty && _normIdKey(_perfilCtrl.text) != perfil) {
          _perfilCtrl.text = perfil;
        }
      }
    } catch (_) {
      // NO-OP
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _ownerCtrl.dispose();
    _perfilCtrl.dispose();
    _mensajeCtrl.dispose();
    _refCtrl.dispose();
    _ttlCtrl.dispose();
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
    final clean = msg.trim();
    if (clean.isEmpty) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(clean)));
    } catch (_) {
      // NO-OP
    }
  }

  Color _cardTint(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = theme.colorScheme.surface;
    final alpha = (isDark ? 0.70 : 0.94);
    final a = (alpha * 255).round().clamp(0, 255);
    return base.withAlpha(a);
  }

  int _ttlDaysSafe() {
    final s = _n(_ttlCtrl.text);
    final v = int.tryParse(s);
    if (v == null) return 5;
    if (v < 1) return 1;
    if (v > 30) return 30;
    return v;
  }

  bool _canOperateOverAlumno() {
    final ownerId = _normIdKey(_ownerCtrl.text);
    final perfilId = _normIdKey(_perfilCtrl.text);
    return ownerId.isNotEmpty && perfilId.isNotEmpty;
  }

  bool _canSolicitar() => !_loading && _tipo != null && _canOperateOverAlumno();

  bool _canSimularSubida() =>
      !_loading &&
      _tipo != null &&
      _canOperateOverAlumno() &&
      _n(_refCtrl.text).isNotEmpty;

  bool _canLimpiarExpirados() =>
      !_loading && _normIdKey(_perfilCtrl.text).isNotEmpty;

  void _warnIfPartialAlumnoContext(
    AppLocalizations l10n,
    ScaffoldMessengerState? messenger,
  ) {
    final ownerId = _normIdKey(_ownerCtrl.text);
    final perfilId = _normIdKey(_perfilCtrl.text);

    if (ownerId.isEmpty && perfilId.isNotEmpty) {
      _snackMaybe(messenger, l10n.institucionDocsWarnPerfilButNoOwner);
    } else if (ownerId.isNotEmpty && perfilId.isEmpty) {
      _snackMaybe(messenger, l10n.institucionDocsWarnOwnerButNoPerfil);
    }
  }

  Future<void> _resolveAndRegisterInstitucionOwnerBestEffort() async {
    final instPid = _instIdCanon;
    if (instPid.isEmpty) return;

    var instOwner = _normIdKey(widget.institucionOwnerAccountId ?? '');

    if (instOwner.isEmpty) {
      try {
        instOwner = _normIdKey(
          (await SessionService.getInstitucionOwnerAccountIdLogueado()) ?? '',
        );
      } catch (_) {
        instOwner = '';
      }
    }

    if (instOwner.isEmpty) return;

    _institucionOwnerResolved = instOwner;
    if (mounted) setState(() {});

    try {
      await DocumentosTemporalesService.registrarOwnerDeInstitucion(
        institucionPerfilId: instPid,
        ownerAccountId: instOwner,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      // NO-OP (best-effort)
    }
  }

  // ─────────────────────────────────────────────
  // Load SAFE (token + timeout + finally)
  // ─────────────────────────────────────────────

  Future<void> _loadSafe({bool allowWhileLoading = false}) async {
    if (!mounted) return;
    if (_booting && !allowWhileLoading) return;

    final int token = ++_loadSeq;
    _booting = true;

    // ✅ Capturar referencias ANTES del async gap (reduce lint).
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      await _load(token).timeout(const Duration(seconds: 10));
    } on TimeoutException catch (_) {
      if (!mounted) return;
      if (token != _loadSeq) return;

      setState(() {
        _error = l10n.institucionDocsErrorTimeout;
        _sols = _solsPrev;
        _docs = _docsPrev;
        _loading = false; // ✅ corto loading también aquí
      });
      _snackMaybe(messenger, l10n.institucionDocsErrorTimeout);
    } catch (e) {
      if (!mounted) return;
      if (token != _loadSeq) return;

      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = msg;
        _sols = _solsPrev;
        _docs = _docsPrev;
        _loading = false; // ✅ corto loading también aquí
      });
      _snackMaybe(messenger, msg);
    } finally {
      // ✅ FIX CANÓNICO: NO liberar _booting si este load quedó stale.
      final bool stillCurrent = mounted && token == _loadSeq;

      if (stillCurrent) {
        _booting = false;
        if (_loading) {
          setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _load(int token) async {
    if (!mounted) return;

    // ✅ Capturas antes de awaits
    final l10n = AppLocalizations.of(context);
    final instId = _instIdCanon;
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (instId.isEmpty) {
      if (!mounted) return;
      if (token != _loadSeq) return;

      setState(() {
        _error = l10n.institucionDocsErrorInvalidInstitutionId;
        _loading = false;

        _sols = const <SolicitudDocumento>[];
        _docs = const <DocumentoTemporal>[];
        _solsPrev = const <SolicitudDocumento>[];
        _docsPrev = const <DocumentoTemporal>[];
      });
      _snackMaybe(messenger, l10n.institucionDocsErrorInvalidInstitutionId);
      return;
    }

    final filtroOwner = _normOrEmpty(_ownerCtrl.text);
    final filtroPerfil = _normOrEmpty(_perfilCtrl.text);

    if (!mounted) return;
    if (token != _loadSeq) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    _warnIfPartialAlumnoContext(l10n, messenger);

    try {
      final solsAll = List<SolicitudDocumento>.from(
        await DocumentosTemporalesService.listarSolicitudesInstitucion(
          institucionId: instId,
        ).timeout(const Duration(seconds: 6)),
      );

      final docsAll = List<DocumentoTemporal>.from(
        await DocumentosTemporalesService.listarDocumentosInstitucion(
          institucionId: instId,
        ).timeout(const Duration(seconds: 6)),
      );

      if (!mounted) return;
      if (token != _loadSeq) return;

      final solsFiltered = solsAll
          .where((s) {
            if (filtroOwner.isNotEmpty &&
                _normOrEmpty(s.ownerAccountId) != filtroOwner) {
              return false;
            }
            if (filtroPerfil.isNotEmpty &&
                _normOrEmpty(s.perfilId) != filtroPerfil) {
              return false;
            }
            return true;
          })
          .toList(growable: false);

      final docsFiltered = docsAll
          .where((d) {
            if (filtroOwner.isNotEmpty &&
                _normOrEmpty(d.ownerAccountId) != filtroOwner) {
              return false;
            }
            if (filtroPerfil.isNotEmpty &&
                _normOrEmpty(d.perfilId) != filtroPerfil) {
              return false;
            }
            return true;
          })
          .toList(growable: false);

      final solsSorted = List<SolicitudDocumento>.from(solsFiltered)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final docsSorted = List<DocumentoTemporal>.from(docsFiltered)
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      if (!mounted) return;
      if (token != _loadSeq) return;

      setState(() {
        _solsPrev = solsSorted;
        _docsPrev = docsSorted;
        _sols = solsSorted;
        _docs = docsSorted;
      });
    } catch (e) {
      if (!mounted) return;
      if (token != _loadSeq) return;

      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = msg;
        _sols = _solsPrev;
        _docs = _docsPrev;
      });
      _snackMaybe(messenger, msg);
    } finally {
      if (mounted && token == _loadSeq) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _solicitar() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final instId = _instIdCanon;
    if (instId.isEmpty) {
      _snackMaybe(
        messenger,
        l10n.institucionDocsSnackInvalidInstitutionEmptyId,
      );
      return;
    }

    final owner = _normIdKey(_ownerCtrl.text);
    final perfil = _normIdKey(_perfilCtrl.text);

    if (owner.isEmpty || perfil.isEmpty) {
      _snackMaybe(messenger, l10n.institucionDocsSnackNeedOwnerAndPerfil);
      return;
    }

    final tipo = _tipo;
    if (tipo == null) {
      _snackMaybe(messenger, l10n.institucionDocsSnackNoDocTypes);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final msg = _n(_mensajeCtrl.text);

      await DocumentosTemporalesService.solicitar(
        institucionId: instId,
        ownerAccountId: owner,
        perfilId: perfil,
        tipo: tipo,
        mensaje: msg.isEmpty ? null : msg,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      _snackMaybe(messenger, l10n.institucionDocsSnackSolicitudCreated);

      // ✅ Permitir recarga aunque _loading esté true.
      await _loadSafe(allowWhileLoading: true);

      if (!mounted) return;
      if (_tab.index != 0) _tab.animateTo(0);
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.institucionDocsErrorTimeout);
      _snackMaybe(messenger, l10n.institucionDocsErrorTimeout);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      _snackMaybe(messenger, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simularSubida() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final instId = _instIdCanon;
    if (instId.isEmpty) {
      _snackMaybe(
        messenger,
        l10n.institucionDocsSnackInvalidInstitutionEmptyId,
      );
      return;
    }

    final owner = _normIdKey(_ownerCtrl.text);
    final perfil = _normIdKey(_perfilCtrl.text);

    if (owner.isEmpty || perfil.isEmpty) {
      _snackMaybe(
        messenger,
        l10n.institucionDocsSnackNeedOwnerAndPerfilToUpload,
      );
      return;
    }

    final tipo = _tipo;
    if (tipo == null) {
      _snackMaybe(messenger, l10n.institucionDocsSnackNoDocTypes);
      return;
    }

    final ref = _n(_refCtrl.text);
    if (ref.isEmpty) {
      _snackMaybe(messenger, l10n.institucionDocsSnackMissingRef);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await DocumentosTemporalesService.subirDocumentoTemporal(
        institucionSolicitanteId: instId,
        ownerAccountId: owner,
        perfilId: perfil,
        tipo: tipo,
        ref: ref,
        ttlDays: _ttlDaysSafe(),
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      _snackMaybe(messenger, l10n.institucionDocsSnackTempDocSaved);

      await _loadSafe(allowWhileLoading: true);

      if (!mounted) return;
      if (_tab.index != 1) _tab.animateTo(1);
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.institucionDocsErrorTimeout);
      _snackMaybe(messenger, l10n.institucionDocsErrorTimeout);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      _snackMaybe(messenger, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _limpiarExpirados() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final perfil = _normIdKey(_perfilCtrl.text);
    if (perfil.isEmpty) {
      _snackMaybe(messenger, l10n.institucionDocsSnackNeedPerfilToCleanup);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final removed = await DocumentosTemporalesService.limpiarExpiradosPerfil(
        perfilId: perfil,
        notify: true,
        duplicarEnPerfil: true,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _snackMaybe(
        messenger,
        removed <= 0
            ? l10n.institucionDocsSnackNoExpiredToRemove
            : l10n.institucionDocsSnackExpiredRemoved(removed),
      );

      await _loadSafe(allowWhileLoading: true);
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.institucionDocsErrorTimeout);
      _snackMaybe(messenger, l10n.institucionDocsErrorTimeout);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      _snackMaybe(messenger, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirmEliminarDoc({required DocumentoTemporal d}) async {
    if (!mounted) return false;

    final l10n = AppLocalizations.of(context);
    final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;

    // ✅ FIX: evitamos llamar a l10n.institucionDocsDialogDeleteBody(...) con posicionales.
    final body = <String>[
      _n(d.id),
      _n(d.perfilId),
      exp ? l10n.estadoDocumentoExpirado : l10n.estadoDocumentoActivo,
    ].where((x) => x.trim().isNotEmpty).join('\n');

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final material = MaterialLocalizations.of(dialogContext);

        return AlertDialog(
          title: Text(l10n.institucionDocsDialogDeleteTitle),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(material.cancelButtonLabel),
            ),
            ElevatedButton(
              onPressed: exp
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.actionDelete),
            ),
          ],
        );
      },
    );

    if (!mounted) return false;
    return ok == true;
  }

  Future<void> _eliminarDocumento(DocumentoTemporal d) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final perfil = _normIdKey(d.perfilId);
    final docId = _normIdKey(d.id);

    if (perfil.isEmpty || docId.isEmpty) return;

    final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;

    if (exp) {
      _snackMaybe(messenger, l10n.institucionDocsSnackExpiredUseCleanup);
      return;
    }

    final ok = await _confirmEliminarDoc(d: d);
    if (!mounted) return;
    if (!ok) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await DocumentosTemporalesService.eliminarDocumento(
        perfilId: perfil,
        documentoId: docId,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      _snackMaybe(messenger, l10n.institucionDocsSnackDeleted);

      await _loadSafe(allowWhileLoading: true);
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.institucionDocsErrorTimeout);
      _snackMaybe(messenger, l10n.institucionDocsErrorTimeout);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      _snackMaybe(messenger, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _abrirEnAlumno(SolicitudDocumento s) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final owner = _normIdKey(s.ownerAccountId);
    final perfil = _normIdKey(s.perfilId);
    final sid = _normIdKey(s.id);

    if (owner.isEmpty || perfil.isEmpty || sid.isEmpty) {
      _snackMaybe(messenger, l10n.institucionDocsSnackCannotOpenMissingIds);
      return;
    }

    final route = Uri(
      path: '/documentos',
      queryParameters: {
        'ownerAccountId': owner,
        'perfilId': perfil,
        'solicitudId': sid,
      },
    ).toString();

    if (route.length > 1500) {
      _snackMaybe(messenger, l10n.institucionDocsSnackDeeplinkTooLong);
      return;
    }

    try {
      Navigator.of(context).pushReplacementNamed(
        route,
        arguments: <String, dynamic>{
          'ownerAccountId': owner,
          'perfilId': perfil,
          'solicitudId': sid,
        },
      );
    } catch (_) {
      _snackMaybe(messenger, l10n.institucionDocsSnackRouteNotRegistered);
    }
  }

  String _tipoLabel(TipoDocumento t) {
    try {
      // ignore: avoid_dynamic_calls
      final v = (t as dynamic).label;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {
      // NO-OP
    }
    return t.name;
  }

  String _labelEstadoSolicitud(
    AppLocalizations l10n,
    EstadoSolicitudDocumento e,
  ) {
    switch (e) {
      case EstadoSolicitudDocumento.pendiente:
        return l10n.estadoSolicitudPendiente;
      case EstadoSolicitudDocumento.cumplida:
        return l10n.estadoSolicitudCumplida;
      case EstadoSolicitudDocumento.cancelada:
        return l10n.estadoSolicitudCancelada;
    }
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _chipEstadoSolicitud(
    AppLocalizations l10n,
    EstadoSolicitudDocumento e,
  ) {
    return Chip(label: Text(_labelEstadoSolicitud(l10n, e)));
  }

  Widget _chipEstadoDoc(AppLocalizations l10n, DocumentoTemporal d) {
    final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;
    return Chip(
      label: Text(
        exp ? l10n.estadoDocumentoExpirado : l10n.estadoDocumentoActivo,
      ),
    );
  }

  Widget _buildTrailingSolicitudActions(
    AppLocalizations l10n,
    SolicitudDocumento s,
  ) {
    final canOpen =
        _normIdKey(s.ownerAccountId).isNotEmpty &&
        _normIdKey(s.perfilId).isNotEmpty &&
        _normIdKey(s.id).isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 112),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _chipEstadoSolicitud(l10n, s.estado),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.institucionDocsTooltipOpenAlumno,
              icon: const Icon(Icons.open_in_new),
              onPressed: _loading || !canOpen ? null : () => _abrirEnAlumno(s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingDocActions(AppLocalizations l10n, DocumentoTemporal d) {
    final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 112),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _chipEstadoDoc(l10n, d),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: exp
                  ? l10n.institucionDocsTooltipExpiredUseCleanup
                  : l10n.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _loading
                  ? null
                  : () {
                      // ignore: discarded_futures
                      _eliminarDocumento(d);
                    },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: removemos l10n porque no se usa (evita unused_parameter).
  String _subtitleSolicitudDataOnly(
    SolicitudDocumento s,
    String estado,
    String msg,
  ) {
    final parts = <String>[
      _n(s.id),
      estado,
      _fmt(s.createdAt),
      _n(s.ownerAccountId),
      _n(s.perfilId),
    ];
    if (msg.isNotEmpty) parts.add(msg);
    return parts.where((x) => x.trim().isNotEmpty).join('\n');
  }

  String _subtitleDocumentoDataOnly(
    AppLocalizations l10n,
    DocumentoTemporal d,
    String solicitudLabel,
    bool exp,
  ) {
    final parts = <String>[
      _n(d.id),
      _n(d.perfilId),
      _fmt(d.uploadedAt),
      _fmt(d.expiresAt),
      solicitudLabel,
      _n(d.ref),
      exp ? l10n.estadoDocumentoExpirado : l10n.estadoDocumentoActivo,
    ];
    return parts.where((x) => x.trim().isNotEmpty).join('\n');
  }

  Widget _buildHeaderCard() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final filtroPerfil = _n(_perfilCtrl.text);
    final filtroOwner = _n(_ownerCtrl.text);

    final filtroInfo = () {
      if (filtroOwner.isEmpty && filtroPerfil.isEmpty) {
        return l10n.institucionDocsViewAllInstitution;
      }
      if (filtroOwner.isNotEmpty && filtroPerfil.isNotEmpty) {
        return l10n.institucionDocsViewFilteredOwnerPerfil;
      }
      if (filtroPerfil.isNotEmpty) {
        return l10n.institucionDocsViewFilteredPerfil;
      }
      return l10n.institucionDocsViewFilteredOwner;
    }();

    final instOwnerInfo = _n(_institucionOwnerResolved ?? '');
    final instName = widget.institucionNombre.trim().isEmpty
        ? l10n.institucionGeneric
        : widget.institucionNombre.trim();

    final TipoDocumento? safeTipo = (_tipo != null && _tipos.contains(_tipo))
        ? _tipo
        : (_tipos.isNotEmpty ? _tipos.first : null);

    final isDark = theme.brightness == Brightness.dark;
    final a = ((isDark ? 0.72 : 0.94) * 255).round().clamp(0, 255);
    final cardColor = cs.surface.withAlpha(a);

    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              instName,
              style:
                  (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
                      .copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(_instIdCanon.isEmpty ? l10n.valueEmpty : _instIdCanon),
            if (instOwnerInfo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(instOwnerInfo),
            ],
            const SizedBox(height: 6),
            Text(filtroInfo),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerCtrl,
              decoration: InputDecoration(
                labelText: l10n.institucionDocsFieldOwnerAlumnoLabel,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                // ignore: discarded_futures
                _loadSafe();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _perfilCtrl,
              decoration: InputDecoration(
                labelText: l10n.institucionDocsFieldPerfilAlumnoLabel,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                // ignore: discarded_futures
                _loadSafe();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TipoDocumento>(
              key: ValueKey<String>('tipo_${safeTipo?.name ?? 'none'}'),
              initialValue: safeTipo,
              items: _tipos
                  .map(
                    (t) => DropdownMenuItem<TipoDocumento>(
                      value: t,
                      child: Text(_tipoLabel(t)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _loading || _tipos.isEmpty
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _tipo = v);
                    },
              decoration: InputDecoration(
                labelText: l10n.institucionDocsFieldTipoDocumentoLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _mensajeCtrl,
              decoration: InputDecoration(
                labelText: l10n.institucionDocsFieldMensajeOpcionalLabel,
                border: const OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canSolicitar()
                        ? () {
                            // ignore: discarded_futures
                            _solicitar();
                          }
                        : null,
                    icon: const Icon(Icons.assignment),
                    label: Text(l10n.actionRequest),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () {
                            // ignore: discarded_futures
                            _loadSafe();
                          },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.actionList),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            TextField(
              controller: _refCtrl,
              decoration: InputDecoration(
                labelText: l10n.institucionDocsFieldRefLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ttlCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.institucionDocsFieldTtlDaysLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canSimularSubida()
                        ? () {
                            // ignore: discarded_futures
                            _simularSubida();
                          }
                        : null,
                    icon: const Icon(Icons.upload_file),
                    label: Text(l10n.institucionDocsActionSimulateUpload),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canLimpiarExpirados()
                        ? () {
                            // ignore: discarded_futures
                            _limpiarExpirados();
                          }
                        : null,
                    icon: const Icon(Icons.cleaning_services),
                    label: Text(l10n.institucionDocsActionCleanupExpired),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabSolicitudes() {
    final l10n = AppLocalizations.of(context);

    if (_sols.isEmpty) {
      return _buildEmpty(l10n.institucionDocsEmptySolicitudes);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _sols.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = _sols[i];
        final msg = (s.mensaje ?? '').trim();

        return Card(
          elevation: 0,
          color: _cardTint(context),
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(_tipoLabel(s.tipo)),
            subtitle: Text(
              _subtitleSolicitudDataOnly(
                s,
                _labelEstadoSolicitud(l10n, s.estado),
                msg,
              ),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: _buildTrailingSolicitudActions(l10n, s),
          ),
        );
      },
    );
  }

  Widget _tabDocumentos() {
    final l10n = AppLocalizations.of(context);

    if (_docs.isEmpty) {
      return _buildEmpty(l10n.institucionDocsEmptyDocumentos);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final d = _docs[i];
        final exp = d.expirado || d.estado == EstadoDocumentoTemporal.expirado;

        final solicitudId = (d.solicitudId ?? '').trim();
        final solicitudLabel = solicitudId.isEmpty
            ? l10n.valueNone
            : solicitudId;

        return Card(
          elevation: 0,
          color: _cardTint(context),
          child: ListTile(
            leading: Icon(
              exp ? Icons.hourglass_disabled : Icons.insert_drive_file,
            ),
            title: Text(_tipoLabel(d.tipo)),
            subtitle: Text(
              _subtitleDocumentoDataOnly(l10n, d, solicitudLabel, exp),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: _buildTrailingDocActions(l10n, d),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;

    final instName = widget.institucionNombre.trim().isNotEmpty
        ? widget.institucionNombre.trim()
        : l10n.institucionGeneric;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.institucionDocsAppBarTitle(instName)),
        actions: [
          IconButton(
            onPressed: _loading
                ? null
                : () {
                    // ignore: discarded_futures
                    _loadSafe();
                  },
            icon: const Icon(Icons.refresh),
            tooltip: l10n.actionRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l10n.tabSolicitudes),
            Tab(text: l10n.tabDocumentos),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _buildHeaderCard(),
            ),
            if (_loading) ...[
              const SizedBox(height: 8),
              const Center(child: CircularProgressIndicator()),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [_tabSolicitudes(), _tabDocumentos()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
