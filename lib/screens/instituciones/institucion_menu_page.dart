import '../../ui/catalogo_publico.dart';
// Presentation refreshed without changing the existing session and navigation contract.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

// ✅ Login real de institución (fase 2)
import '../auth/institucion_login_page.dart';

// ✅ Model + helpers canónicos (E2E)
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/instituciones_helpers.dart';

// ✅ CuentaService: operaciones heredadas de cuenta/perfil y logout.
// NO se utiliza para resolver la identidad institucional.
import '../../services/cuenta_service.dart';

// ✅ Sesión canónica (institución / cuenta)
import '../../services/session_service.dart';
import '../../services/institucion_operadores_service.dart';

// ✅ Assets centralizados
import '../../ui/atena_workspace.dart';

// ✅ PERFIL (screen) — alias para evitar colisión
import 'institucion_perfil_page.dart' as perfil_page;

// ✅ SELECTOR (Actividad → Perfiles → Área) — alias para evitar colisión
import 'institucion_areas_operadores_selector_page.dart' as selector_page;

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

  static String _n(String? v) => (v ?? '').trim();

  static String _normIdKeyLocal(String v) =>
      v.trim().replaceAll(RegExp(r'\s+'), '');

  static String _safeStr(Object? v) => v == null ? '' : v.toString();

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

  Color _cardColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  Color _transparentSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  @override
  void initState() {
    super.initState();

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

  Future<String?> _resolveSesionOwnerIdSafe() async {
    try {
      final s = await SessionService.getSession().timeout(
        const Duration(seconds: 3),
      );

      if (s == null) return null;
      if (s.role != SessionRole.institucion) return null;

      final expectedPerfil = _normIdKeyLocal(_instPerfilId);
      final userId = _normIdKeyLocal(_safeStr(s.userId));

      if (expectedPerfil.isEmpty || userId.isEmpty) return null;
      if (userId != expectedPerfil) return null;

      final owner = await SessionService.getInstitucionOwnerAccountIdLogueado()
          .timeout(const Duration(seconds: 3));

      final ownerN = _normIdKeyLocal(_safeStr(owner));

      return ownerN.isEmpty ? null : ownerN;
    } catch (_) {
      return null;
    }
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

      // La identidad institucional es estrictamente canónica:
      //   SessionService.role == institucion
      //   SessionService.userId == institucionPerfilId
      //   SessionService.institucionOwnerAccountId == ownerAccountId
      final session = await SessionService.getSession().timeout(
        const Duration(seconds: 3),
      );
      if (!stillValid()) return;

      if (session == null) {
        _setFatal(_FatalReason.noSession);
        return;
      }

      if (session.role != SessionRole.institucion) {
        _setFatal(_FatalReason.sessionMismatch);
        return;
      }

      final sessionPerfilId = _normIdKeyLocal(_safeStr(session.userId));

      if (sessionPerfilId.isEmpty || sessionPerfilId != _instPerfilId) {
        _setFatal(_FatalReason.sessionMismatch);
        return;
      }

      final sesOwner = await _resolveSesionOwnerIdSafe();
      if (!stillValid()) return;

      final sesOwnerN = _normIdKeyLocal(_safeStr(sesOwner));

      if (sesOwnerN.isEmpty) {
        _setFatal(_FatalReason.sessionMismatch);
        return;
      }

      // El owner de la sesión NO se adopta ni se reemplaza.
      // Debe coincidir exactamente con el owner recibido por navegación.
      if (sesOwnerN != _ownerId) {
        debugPrint(
          '[ATENA][INST-MENU][BOOT] owner mismatch '
          'session=$sesOwnerN widget=$_ownerId perfil=$_instPerfilId',
        );
        _setFatal(_FatalReason.sessionMismatch);
        return;
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

      // La sesión institucional válida es suficiente aunque la relación
      // owner -> perfil no pueda resolverse por una migración/persistencia.
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

      await InstitucionOperadoresService.instance.asegurarPropietario(
        institucionId: _instPerfilId,
        ownerAccountId: _ownerId,
        perfilInstitucionId: _instPerfilId,
        nombreVisible:
            '${nombreReal.isEmpty ? 'Institución' : nombreReal} · Propietario',
      );

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
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InstitucionLoginPage()),
      (_) => false,
    );
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

  Widget _withBackground(BuildContext context, Widget child) =>
      AtenaWorkspace(child: child);

  void _openLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InstitucionLoginPage()));
  }

  Future<bool> _validateSessionOrFailSnack() async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);

    final session = await SessionService.getSession().timeout(
      const Duration(seconds: 3),
    );
    if (!mounted) return false;

    if (session == null || session.role != SessionRole.institucion) {
      _toast(l10n.noActiveSessionGoBackToLogin);
      return false;
    }

    final sessionPerfilId = _normIdKeyLocal(_safeStr(session.userId));
    if (sessionPerfilId.isEmpty || sessionPerfilId != _instPerfilId) {
      _toast(l10n.invalidSessionForThisAccount);
      return false;
    }

    final sessionOwner =
        await SessionService.getInstitucionOwnerAccountIdLogueado().timeout(
          const Duration(seconds: 3),
        );
    if (!mounted) return false;

    final sessionOwnerN = _normIdKeyLocal(_safeStr(sessionOwner));

    if (sessionOwnerN.isEmpty || sessionOwnerN != _ownerId) {
      _toast(l10n.invalidSessionForThisAccount);
      return false;
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
      final okBySession = sessionPerfilId == _instPerfilId;
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
    return selector_page.InstitucionAreasOperadoresSelectorPage(
      ownerAccountId: _ownerId,
      institucionId: _instPerfilId,
      institucionNombre: _nombreUI.trim().isEmpty ? inst.nombre : _nombreUI,
      institucion: inst,
    );
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
          const AccesoBuscadorPublico(),
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
      extendBodyBehindAppBar: false,
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
    final transparentSurface = _transparentSurface(context);

    if (_verificando) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.institutionsTitle),
          backgroundColor: transparentSurface,
          surfaceTintColor: transparentSurface,
        ),
        extendBodyBehindAppBar: false,
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
          const AccesoBuscadorPublico(),
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
      extendBodyBehindAppBar: false,
      body: _withBackground(
        context,
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              AtenaSectionHeader(
                eyebrow: l10n.institutionsTitle,
                title: nombre,
                subtitle:
                    'Tu espacio de gestión. Ingresá a un área para trabajar con sus solicitudes, vacantes y comunicaciones.',
              ),
              AtenaResponsiveGrid(
                children: [
                  AtenaActionCard(
                    icon: Icons.admin_panel_settings,
                    title: l10n.administrationUpper,
                    subtitle:
                        'Elegí el área y tu operador para acceder a las funciones habilitadas.',
                    prominent: true,
                    onTap: _navAdmin ? null : _openAdmin,
                  ),
                  AtenaActionCard(
                    icon: Icons.badge,
                    title: l10n.profileUpper,
                    subtitle: l10n.profileCardSubtitle,
                    onTap: _navPerfil ? null : _openPerfil,
                  ),
                  AtenaActionCard(
                    icon: Icons.workspace_premium,
                    title: l10n.planUpper,
                    subtitle: l10n.planCardSubtitle,
                    onTap: _navPlan ? null : _openPlan,
                  ),
                ],
              ),
              const AtenaLocalNotice(),
            ],
          ),
        ),
      ),
    );
  }
}
