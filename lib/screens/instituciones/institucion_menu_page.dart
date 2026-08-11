// lib/screens/instituciones/institucion_menu_page.dart
//
// ATENA – INSTITUCIÓN · HOME (FASE 2 · CANÓNICO · E2E)
//
// ✅ HARDENING (feb 2026 · anti-cuelgue):
// - Todos los awaits críticos tienen timeout.
// - Watchdog global: si _bootstrap no termina en X segundos, corta loader y muestra fatal.
// - Si algo no responde, NO queda spinner infinito: cae a fatal “cannotLoadInstitutionTryAgain”.
//
// ✅ FIX DEFINITIVO (feb 2026 · cierre “Sesión inválida”):
// - La sesión institucional (SessionService.role==institucion && userId==perfilId) es fuente válida
//   aunque ownerTienePerfil falle (persistencia / migraciones / WEB).
//
// ✅ FIX (feb 2026 · ADMIN – navegación canónica):
// - ✅ Alias de imports para evitar ambiguous_import:
//     * perfil_page.InstitucionPerfilPage
//     * selector_page.InstitucionPerfilesSelectorPage
//
// ✅ FIX (feb 2026 · analyzer):
// - Elimina warning de campo/variable sin uso.
// - Asegura que el selector se construye SIEMPRE como clase (no “función”)
//   usando el alias selector_page.* (evita undefined_function).
//
// ✅ ESTÉTICA CANÓNICA (feb 2026 · fondo institucional):
// - Fondo consistente: base (asset) + scrim por ColorScheme + glow sutil.
// - Dark mode: alpha/contraste ajustado SIN withOpacity deprecated (usa withValues).
// - Stack expand + Positioned.fill para evitar fondos “cortados”.
//

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

// ✅ Login real de institución (fase 2)
import '../auth/institucion_login_page.dart';

// ✅ Model + helpers canónicos (E2E)
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/instituciones_helpers.dart';

// ✅ Sesión canónica (legacy/compat CUENTA)
import '../../services/cuenta_service.dart';

// ✅ FIX: sesión v2 (institución / cuenta)
import '../../services/session_service.dart';

// ✅ Assets centralizados
import '../../ui/atena_assets.dart';

// ✅ PERFIL (screen) — alias para evitar colisión
import 'institucion_perfil_page.dart' as perfil_page;

// ✅ SELECTOR (Actividad → Perfiles → Área) — alias para evitar colisión
import 'institucion_perfiles_selector_page.dart' as selector_page;

// ✅ PLAN habilitación (canónico)
import '../../guards/plan_habilitacion_guard.dart';

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

enum _FatalReason {
  noSession,
  sessionMismatch,
  perfilNotInOwner,
  cannotLoadInstitution,
}

class _InstitucionMenuPageState extends State<InstitucionMenuPage> {
  bool _verificando = true;

  Institucion? _inst;

  String _nombreUI = '';

  String _ownerId = '';
  String _instPerfilId = '';

  _FatalReason? _fatalReason;

  bool _navPlan = false;
  bool _navPerfil = false;
  bool _navAdmin = false;

  bool _refreshing = false;

  Timer? _bootWatchdog;

  int _bootToken = 0;

  // ✅ Glow overlay (solo overlay; el background base viene por backgroundForRole)
  String get _glow => AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow);

  static String _n(String? v) => (v ?? '').trim();

  static String _normIdKeyLocal(String v) =>
      v.trim().replaceAll(RegExp(r'\s+'), '');

  static String _safeStr(Object? v) => v == null ? '' : v.toString();

  Future<bool> _tryApplyVoidOrFuture(
    Function f, {
    List<dynamic> positional = const [],
    Map<Symbol, dynamic> named = const {},
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final res = Function.apply(f, positional, named);
      if (res is Future) {
        await res.timeout(timeout);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<T?> _tryApplyReturn<T>(
    Function f, {
    List<dynamic> positional = const [],
    Map<Symbol, dynamic> named = const {},
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final res = Function.apply(f, positional, named);
      if (res is Future) {
        final v = await res.timeout(timeout);
        return v is T ? v : null;
      }
      return res is T ? res : null;
    } catch (_) {
      return null;
    }
  }

  Color _cardColor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Superficie “glass” pero legible.
    return cs.surface.withValues(alpha: isDark ? 0.70 : 0.92);
  }

  Color _chipColor(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Chip con acento (no neón).
    return cs.primary.withValues(alpha: isDark ? 0.22 : 0.14);
  }

  // ✅ Scrim canónico para legibilidad (dark más fuerte, light suave).
  Color _overlayScrim(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return cs.scrim.withValues(alpha: isDark ? 0.60 : 0.16);
  }

  double _glowOpacity(BuildContext context) {
    final theme = Theme.of(context);
    // Glow sutil, más presente en dark sin “lavar” texto.
    return theme.brightness == Brightness.dark ? 0.16 : 0.08;
  }

  Color _transparentSurface(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.surface.withValues(alpha: 0.0);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // ✅ Background base: role institucional (mismo path que backgroundForRole)
        // ignore: discarded_futures
        precacheImage(
          AssetImage(
            AtenaAssets.ensureCanonical(
              AtenaAssets.backgroundPathForRole(
                AtenaBackgroundRole.institucion,
              ),
            ),
          ),
          context,
        );
        // ignore: discarded_futures
        precacheImage(AssetImage(_glow), context);
      } catch (_) {}
    });

    // ignore: discarded_futures
    _bootstrap();
  }

  @override
  void dispose() {
    _bootWatchdog?.cancel();
    _bootWatchdog = null;
    super.dispose();
  }

  void _startBootWatchdog({
    required int token,
    Duration timeout = const Duration(seconds: 10),
  }) {
    _bootWatchdog?.cancel();
    _bootWatchdog = null;

    _bootWatchdog = Timer(timeout, () {
      if (!mounted) return;
      if (_bootToken != token) return;
      if (!_verificando) return;

      debugPrint('[ATENA][INST-MENU][BOOT][WATCHDOG] timeout -> fatal');
      _setFatal(_FatalReason.cannotLoadInstitution);
    });
  }

  void _stopBootWatchdog() {
    _bootWatchdog?.cancel();
    _bootWatchdog = null;
  }

  Object? _tryResolvePlanStatusFromInstitucion(Institucion inst) {
    try {
      final dyn = inst as dynamic;
      final v = dyn.planStatus;
      return v;
    } catch (_) {
      return null;
    }
  }

  List<String> _candidateInstIdsForFetch() {
    final rawPerfil = _safeStr(widget.institucionPerfilId);
    final trimmedPerfil = rawPerfil.trim();
    final normalizedPerfil = _normIdKeyLocal(rawPerfil);

    final rawOwner = _safeStr(widget.ownerAccountId);
    final trimmedOwner = rawOwner.trim();
    final normalizedOwner = _normIdKeyLocal(rawOwner);

    final fromStatePerfil = _instPerfilId;
    final fromStateOwner = _ownerId;

    final set = <String>{};

    void addIfOk(String v) {
      if (v.trim().isEmpty) return;
      set.add(v);
    }

    addIfOk(fromStatePerfil);
    addIfOk(normalizedPerfil);
    addIfOk(trimmedPerfil);
    addIfOk(rawPerfil);
    addIfOk(_normIdKeyLocal(trimmedPerfil));

    if (fromStateOwner.isNotEmpty && fromStateOwner != fromStatePerfil) {
      addIfOk(fromStateOwner);
    }
    if (normalizedOwner.isNotEmpty && normalizedOwner != normalizedPerfil) {
      addIfOk(normalizedOwner);
    }
    if (trimmedOwner.isNotEmpty && trimmedOwner != trimmedPerfil) {
      addIfOk(trimmedOwner);
    }
    if (rawOwner.isNotEmpty && rawOwner != rawPerfil) {
      addIfOk(rawOwner);
    }
    addIfOk(_normIdKeyLocal(trimmedOwner));

    return set.toList(growable: false);
  }

  Future<Institucion?> _tryLoadInstitutionByIds(List<String> ids) async {
    if (ids.isEmpty) return null;

    for (final id in ids) {
      final idTrim = id.trim();
      if (idTrim.isEmpty) continue;

      try {
        final instCache = await cargarInstitucionCachePorId(
          idTrim,
        ).timeout(const Duration(seconds: 4));
        if (instCache != null) {
          debugPrint('[ATENA][INST-MENU][LOAD] cache hit id=$idTrim');
          return instCache;
        }
      } catch (e) {
        debugPrint('[ATENA][INST-MENU][LOAD] cache fail id=$idTrim err=$e');
      }

      try {
        final inst = await cargarInstitucionPorId(
          idTrim,
        ).timeout(const Duration(seconds: 6));
        if (inst != null) {
          debugPrint('[ATENA][INST-MENU][LOAD] primary hit id=$idTrim');
          return inst;
        }
      } catch (e) {
        debugPrint('[ATENA][INST-MENU][LOAD] primary fail id=$idTrim err=$e');
      }
    }

    return null;
  }

  Future<void> _ensureCuentaSesionBestEffort(String ownerId) async {
    final o = _normIdKeyLocal(ownerId);
    if (o.isEmpty) return;

    final fn = (CuentaService.setSesionCuentaId as Function);

    final ok1 = await _tryApplyVoidOrFuture(
      fn,
      positional: [o],
      named: const {#recordarme: true},
      timeout: const Duration(seconds: 2),
    );
    if (ok1) return;

    final ok2 = await _tryApplyVoidOrFuture(
      fn,
      named: {#cuentaId: o, #recordarme: true},
      timeout: const Duration(seconds: 2),
    );
    if (ok2) return;

    await _tryApplyVoidOrFuture(
      fn,
      named: {#ownerAccountId: o, #recordarme: true},
      timeout: const Duration(seconds: 2),
    );
  }

  Future<void> _ensureInstOwnerBestEffort(String ownerId) async {
    final o = _normIdKeyLocal(ownerId);
    if (o.isEmpty) return;

    final fn = (SessionService.setInstitucionOwnerAccountId as Function);

    final ok1 = await _tryApplyVoidOrFuture(
      fn,
      positional: [o],
      timeout: const Duration(seconds: 2),
    );
    if (ok1) return;

    await _tryApplyVoidOrFuture(
      fn,
      named: {#ownerAccountId: o},
      timeout: const Duration(seconds: 2),
    );
  }

  Future<bool> _sessionMatchesInstitutionPerfilSafe() async {
    final expected = _normIdKeyLocal(_instPerfilId);
    if (expected.isEmpty) return false;

    try {
      final s = await SessionService.getSession().timeout(
        const Duration(seconds: 2),
      );
      if (s == null) return false;
      if (s.role != SessionRole.institucion) return false;
      final userId = _normIdKeyLocal(_safeStr(s.userId));
      return userId.isNotEmpty && userId == expected;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _resolveSesionOwnerIdSafe({
    required String expectedInstPerfilId,
    required String fallbackOwnerIdFromWidget,
  }) async {
    final expected = _normIdKeyLocal(expectedInstPerfilId);
    final fallbackOwner = _normIdKeyLocal(fallbackOwnerIdFromWidget);

    try {
      final s = await SessionService.getSession().timeout(
        const Duration(seconds: 3),
      );

      if (s != null && s.role == SessionRole.institucion) {
        String? instOwner;

        try {
          final fn =
              (SessionService.getInstitucionOwnerAccountIdLogueado as Function);
          final v = await _tryApplyReturn<Object?>(
            fn,
            timeout: const Duration(seconds: 3),
          );
          instOwner = _safeStr(v);
        } catch (_) {
          instOwner = null;
        }

        final v = _normIdKeyLocal(_safeStr(instOwner));
        final userId = _normIdKeyLocal(_safeStr(s.userId));

        if (v.isNotEmpty && fallbackOwner.isNotEmpty && v == fallbackOwner) {
          return v;
        }

        final isSospechoso =
            v.isNotEmpty &&
            expected.isNotEmpty &&
            v == expected &&
            fallbackOwner.isNotEmpty &&
            expected != fallbackOwner;

        if (v.isNotEmpty && !isSospechoso) {
          return v;
        }

        if (fallbackOwner.isNotEmpty &&
            userId.isNotEmpty &&
            expected.isNotEmpty &&
            userId == expected) {
          return fallbackOwner;
        }
      }
    } catch (_) {}

    try {
      final id = await CuentaService.getSesionCuentaId().timeout(
        const Duration(seconds: 4),
      );
      final v = _normIdKeyLocal(_safeStr(id));
      if (v.isNotEmpty) return v;
    } catch (_) {}

    if (fallbackOwner.isNotEmpty) {
      await _ensureCuentaSesionBestEffort(fallbackOwner);
      try {
        final id = await CuentaService.getSesionCuentaId().timeout(
          const Duration(seconds: 2),
        );
        final v = _normIdKeyLocal(_safeStr(id));
        return v.isEmpty ? null : v;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  Future<void> _irAHomeHardReset() async {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _resetDespuesDeFail() async {
    try {
      await CuentaService.logoutCuenta().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await SessionService.logout().timeout(const Duration(seconds: 2));
    } catch (_) {}
    if (!mounted) return;
    await _irAHomeHardReset();
  }

  void _setFatal(_FatalReason reason) {
    if (!mounted) return;
    _stopBootWatchdog();
    _bootToken++;

    setState(() {
      _inst = null;
      _verificando = false;
      _fatalReason = reason;
    });
  }

  Future<bool> _ownerTienePerfilSafe({
    required String ownerAccountId,
    required String perfilId,
  }) async {
    final o = _normIdKeyLocal(ownerAccountId);
    final p = _normIdKeyLocal(perfilId);
    if (o.isEmpty || p.isEmpty) return false;

    final fn = (CuentaService.ownerTienePerfil as Function);

    final r1 = await _tryApplyReturn<bool>(
      fn,
      named: {#ownerAccountId: o, #perfilId: p},
      timeout: const Duration(seconds: 4),
    );
    if (r1 != null) return r1;

    final r2 = await _tryApplyReturn<bool>(
      fn,
      named: {#cuentaId: o, #perfilId: p},
      timeout: const Duration(seconds: 4),
    );
    if (r2 != null) return r2;

    final r3 = await _tryApplyReturn<bool>(
      fn,
      positional: [o, p],
      timeout: const Duration(seconds: 4),
    );
    if (r3 != null) return r3;

    return false;
  }

  Future<bool> _maybeAdoptSesionOwner({required String sesOwner}) async {
    final s = _normIdKeyLocal(sesOwner);
    if (s.isEmpty) return false;

    if (s == _ownerId) return true;

    final ok = await _ownerTienePerfilSafe(
      ownerAccountId: s,
      perfilId: _instPerfilId,
    );
    if (!ok) return false;

    debugPrint(
      '[ATENA][INST-MENU][BOOT] adopt sesOwner=$s (was owner=$_ownerId) for perfil=$_instPerfilId',
    );
    _ownerId = s;

    await _ensureCuentaSesionBestEffort(_ownerId);
    await _ensureInstOwnerBestEffort(_ownerId);

    return true;
  }

  Future<void> _bootstrap() async {
    final myToken = ++_bootToken;

    _ownerId = _normIdKeyLocal(widget.ownerAccountId);
    _instPerfilId = _normIdKeyLocal(widget.institucionPerfilId);
    _nombreUI = _n(widget.institucionNombre);

    debugPrint(
      '[ATENA][INST-MENU][BOOT] start owner=$_ownerId instPerfilId=$_instPerfilId',
    );

    if (mounted) {
      setState(() {
        _verificando = true;
        _fatalReason = null;
        _inst = null;
      });
    }

    _startBootWatchdog(token: myToken, timeout: const Duration(seconds: 12));

    bool stillValid() => mounted && _bootToken == myToken;

    try {
      if (_ownerId.isEmpty || _instPerfilId.isEmpty) {
        if (stillValid()) _setFatal(_FatalReason.cannotLoadInstitution);
        return;
      }

      final sesOwner = await _resolveSesionOwnerIdSafe(
        expectedInstPerfilId: _instPerfilId,
        fallbackOwnerIdFromWidget: _ownerId,
      );
      if (!stillValid()) return;

      final sesOwnerN = _normIdKeyLocal(_safeStr(sesOwner));

      if (sesOwnerN.isEmpty) {
        final okBySession = await _sessionMatchesInstitutionPerfilSafe();
        if (!stillValid()) return;

        if (!okBySession) {
          if (stillValid()) _setFatal(_FatalReason.noSession);
          return;
        }
        await _ensureInstOwnerBestEffort(_ownerId);
      } else {
        if (sesOwnerN != _ownerId) {
          final adopted = await _maybeAdoptSesionOwner(sesOwner: sesOwnerN);
          if (!stillValid()) return;

          if (!adopted) {
            final okBySession = await _sessionMatchesInstitutionPerfilSafe();
            if (!stillValid()) return;
            if (!okBySession) {
              if (stillValid()) _setFatal(_FatalReason.sessionMismatch);
              return;
            }

            _ownerId = sesOwnerN;
            await _ensureCuentaSesionBestEffort(_ownerId);
            await _ensureInstOwnerBestEffort(_ownerId);
          }
        } else {
          await _ensureInstOwnerBestEffort(_ownerId);
        }
      }

      bool pertenece = false;
      try {
        pertenece = await _ownerTienePerfilSafe(
          ownerAccountId: _ownerId,
          perfilId: _instPerfilId,
        );
      } catch (_) {
        pertenece = false;
      }
      if (!stillValid()) return;

      if (!pertenece) {
        final okBySession = await _sessionMatchesInstitutionPerfilSafe();
        if (!stillValid()) return;
        if (okBySession) pertenece = true;
      }

      if (!pertenece) {
        if (stillValid()) _setFatal(_FatalReason.perfilNotInOwner);
        return;
      }

      final ids = _candidateInstIdsForFetch();
      final inst = await _tryLoadInstitutionByIds(ids);
      if (!stillValid()) return;

      if (inst == null) {
        if (stillValid()) _setFatal(_FatalReason.cannotLoadInstitution);
        return;
      }

      final nombreReal = _n(inst.nombre);

      _stopBootWatchdog();

      if (!stillValid()) return;

      setState(() {
        _inst = inst;
        _nombreUI = nombreReal.isNotEmpty ? nombreReal : _nombreUI;
        _verificando = false;
        _fatalReason = null;
      });
    } catch (_) {
      if (stillValid()) _setFatal(_FatalReason.cannotLoadInstitution);
    }
  }

  Future<void> _refrescar() async {
    if (!mounted) return;
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _bootstrap();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _logout() async {
    try {
      await CuentaService.logoutCuenta().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await SessionService.logout().timeout(const Duration(seconds: 2));
    } catch (_) {}
    await _irAHomeHardReset();
  }

  void _toast(String msg) {
    if (!mounted) return;
    final clean = msg.trim();
    if (clean.isEmpty) return;
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(clean)));
    } catch (_) {}
  }

  // ✅ Fondo institucional canónico: base + scrim + glow + child.
  Widget _withBackground(BuildContext context, Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ✅ CANÓNICO: background centralizado (web fullscreen + fallback)
        Positioned.fill(
          child: AtenaAssets.backgroundForRole(
            context,
            role: AtenaBackgroundRole.institucion,
          ),
        ),

        // Scrim (legibilidad)
        Positioned.fill(child: Container(color: _overlayScrim(context))),

        // Glow sutil (estética)
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: _glowOpacity(context),
              child: Image.asset(
                _glow,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }

  Widget _bigActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      color: _cardColor(context),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _chipColor(context),
                ),
                child: Icon(icon, color: cs.onSurface),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _openLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InstitucionLoginPage()));
  }

  Future<bool> _validateSessionOrFailSnack() async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);

    final sesOwner = await _resolveSesionOwnerIdSafe(
      expectedInstPerfilId: _instPerfilId,
      fallbackOwnerIdFromWidget: _ownerId,
    );
    if (!mounted) return false;

    final sesOwnerN = _normIdKeyLocal(_safeStr(sesOwner));

    if (sesOwnerN.isEmpty) {
      final okBySession = await _sessionMatchesInstitutionPerfilSafe();
      if (!mounted) return false;
      if (!okBySession) {
        _toast(l10n.noActiveSessionGoBackToLogin);
        return false;
      }
      await _ensureInstOwnerBestEffort(_ownerId);
    } else {
      if (sesOwnerN != _ownerId) {
        final adopted = await _maybeAdoptSesionOwner(sesOwner: sesOwnerN);
        if (!mounted) return false;

        if (!adopted) {
          final okBySession = await _sessionMatchesInstitutionPerfilSafe();
          if (!mounted) return false;
          if (!okBySession) {
            _toast(l10n.invalidSessionForThisAccount);
            return false;
          }

          _ownerId = sesOwnerN;
          await _ensureCuentaSesionBestEffort(_ownerId);
          await _ensureInstOwnerBestEffort(_ownerId);
        }
      } else {
        await _ensureInstOwnerBestEffort(_ownerId);
      }
    }

    bool pertenece = false;
    try {
      pertenece = await _ownerTienePerfilSafe(
        ownerAccountId: _ownerId,
        perfilId: _instPerfilId,
      );
    } catch (_) {
      pertenece = false;
    }

    if (!pertenece) {
      final okBySession = await _sessionMatchesInstitutionPerfilSafe();
      if (!mounted) return false;
      if (okBySession) pertenece = true;
    }

    if (!mounted) return false;

    if (!pertenece) {
      _toast(l10n.invalidSessionForThisAccount);
      return false;
    }

    return true;
  }

  Future<void> _openPlan() async {
    if (_navPlan) return;
    _navPlan = true;

    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      final inst = _inst;
      if (inst == null) {
        _toast(l10n.institutionNotLoadedYet);
        return;
      }

      final ok = await _validateSessionOrFailSnack();
      if (!ok) return;
      if (!mounted) return;

      final args = <String, dynamic>{
        'ownerAccountId': _ownerId,
        'institucionPerfilId': _instPerfilId,
        if (_nombreUI.trim().isNotEmpty) 'institucionNombre': _nombreUI.trim(),
      };

      Navigator.of(context).pushNamed('/institucion/plan', arguments: args);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _toast('${l10n.commonError}: $e');
    } finally {
      _navPlan = false;
    }
  }

  Future<void> _openPerfil() async {
    if (_navPerfil) return;
    _navPerfil = true;

    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final inst = _inst;

      if (inst == null) {
        _toast(l10n.institutionNotLoadedYet);
        return;
      }

      final ok = await _validateSessionOrFailSnack();
      if (!ok) return;
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => perfil_page.InstitucionPerfilPage(
            ownerAccountId: _ownerId,
            institucionPerfilId: _instPerfilId,
            institucionInicial: inst,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _toast('${l10n.commonError}: $e');
    } finally {
      _navPerfil = false;
    }
  }

  Widget _buildSelectorPage({required Institucion inst}) {
    // ✅ CRÍTICO: SIEMPRE referenciar por alias para que NO se interprete como “función”.
    return selector_page.InstitucionPerfilesSelectorPage(
      ownerAccountId: _ownerId,
      institucionPerfilId: _instPerfilId,
      institucionId: _instPerfilId, // compat legacy
      institucionNombre: _nombreUI.trim().isEmpty ? inst.nombre : _nombreUI,
      institucion: inst,
    );
    // ignore: dead_code
  }

  Future<void> _openAdmin() async {
    if (_navAdmin) return;
    _navAdmin = true;

    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final inst = _inst;

      if (inst == null) {
        _toast(l10n.institutionNotLoadedYet);
        return;
      }

      final ok = await _validateSessionOrFailSnack();
      if (!ok) return;
      if (!mounted) return;

      final planStatusAny = _tryResolvePlanStatusFromInstitucion(inst);
      if (planStatusAny != null) {
        try {
          final fn = (PlanHabilitacionGuard.ensureOperativo as Function);
          final res = Function.apply(fn, const [], <Symbol, dynamic>{
            #context: context,
            #plan: planStatusAny,
          });
          if (res is Future) {
            await res.timeout(const Duration(seconds: 4));
          }
        } catch (_) {}
        if (!mounted) return;
      }

      final page = _buildSelectorPage(inst: inst);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _toast('${l10n.commonError}: $e');
    } finally {
      _navAdmin = false;
    }
  }

  String _fatalMessage(BuildContext context, _FatalReason reason) {
    final l10n = AppLocalizations.of(context);
    switch (reason) {
      case _FatalReason.noSession:
        return l10n.noActiveSessionGoBackToLogin;
      case _FatalReason.sessionMismatch:
        return l10n.invalidSessionForThisAccount;
      case _FatalReason.perfilNotInOwner:
        return l10n.invalidSessionForThisAccount;
      case _FatalReason.cannotLoadInstitution:
        return l10n.cannotLoadInstitutionTryAgain;
    }
  }

  Widget _fatalView(BuildContext context, String msg) {
    final l10n = AppLocalizations.of(context);

    final transparent = _transparentSurface(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.institutionsTitle),
        backgroundColor: transparent,
        surfaceTintColor: transparent,
        actions: [
          IconButton(
            onPressed: () {
              // ignore: discarded_futures
              _refrescar();
            },
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _withBackground(
        context,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 44),
                Card(
                  elevation: 0,
                  color: _cardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(msg, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openLogin,
                                icon: const Icon(Icons.login),
                                label: Text(l10n.signIn),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // ignore: discarded_futures
                                  _resetDespuesDeFail();
                                },
                                icon: const Icon(Icons.home),
                                label: Text(l10n.backToHome),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final transparentSurface = _transparentSurface(context);

    if (_verificando) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.institutionsTitle),
          backgroundColor: transparentSurface,
          surfaceTintColor: transparentSurface,
        ),
        extendBodyBehindAppBar: true,
        body: _withBackground(
          context,
          const SafeArea(child: Center(child: CircularProgressIndicator())),
        ),
      );
    }

    final fatal = _fatalReason;
    if (fatal != null) {
      return _fatalView(context, _fatalMessage(context, fatal));
    }

    final nombre = _nombreUI.trim().isNotEmpty
        ? _nombreUI.trim()
        : l10n.institutionGeneric;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.institutionsTitle),
        backgroundColor: transparentSurface,
        surfaceTintColor: transparentSurface,
        actions: [
          IconButton(
            onPressed: () {
              // ignore: discarded_futures
              _refrescar();
            },
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
          TextButton(
            onPressed: () {
              // ignore: discarded_futures
              _logout();
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _withBackground(
        context,
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              const SizedBox(height: 44),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: _cardColor(context),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.institutionProfileIdLabel(_instPerfilId),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.accountLabel(_ownerId),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _bigActionCard(
                icon: Icons.workspace_premium,
                title: l10n.planUpper,
                subtitle: l10n.planCardSubtitle,
                onTap: _navPlan
                    ? null
                    : () {
                        // ignore: discarded_futures
                        _openPlan();
                      },
              ),
              _bigActionCard(
                icon: Icons.badge,
                title: l10n.profileUpper,
                subtitle: l10n.profileCardSubtitle,
                onTap: _navPerfil
                    ? null
                    : () {
                        // ignore: discarded_futures
                        _openPerfil();
                      },
              ),
              _bigActionCard(
                icon: Icons.admin_panel_settings,
                title: l10n.administrationUpper,
                subtitle: l10n.administrationCardSubtitle,
                onTap: _navAdmin
                    ? null
                    : () {
                        // ignore: discarded_futures
                        _openAdmin();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
