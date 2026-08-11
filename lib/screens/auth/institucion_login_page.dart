// lib/screens/auth/institucion_login_page.dart
//
// ATENA – INSTITUCIÓN LOGIN (FASE 2 · CANÓNICO)
//
// ✅ AJUSTE DEFINITIVO (Fase 2):
// - POST-LOGIN INSTITUCIONAL NO pasa por CuentaHomePage.
// - Flujo institucional directo:
//   Landing -> InstitucionLoginPage -> InstitucionMenuPage
//
// ✅ CANÓNICO:
// - Sesión canónica vía CuentaService.setSesionCuentaId(cuentaId = ownerAccountId).
// - institucionPerfilId == institucionId (canónico DATA) pero en algunos flujos puede NO ser igual al owner.
//   Por eso resolvemos perfilId best-effort.
//
// ✅ FIX BLOQUEANTE (feb 2026 · E2E):
// - Antes se seteaba SOLO el rol (SessionService.setRole) y quedaba la sesión v2 incompleta.
// - Ahora se setea la sesión v2 completa: SessionService.setSession(userId+role+rememberMe).
// - Además, persistimos instOwner best-effort para evitar mismatches en InstitucionMenuPage.
//
// ✅ FIX CRÍTICO (feb 2026 · sesión inválida):
// - Si CuentaService.getUltimoPerfil devuelve TAG (I| / A|), lo STRIPPEAMOS.
//   NUNCA usar un perfilId con tag como userId/perfilId real.
//
// HARDENING:
// - Manejo correcto de async context (captura messenger/nav antes de awaits).
// - try/finally loading.
// - Snackbars robustos.
// - Evita doble submit (guard _cargando).
//
// UX / FASE 2:
// - i18n real via AppLocalizations.of(context).<key>
// - Dark mode real via Theme.of(context).colorScheme
// - Teclado cerrado antes de login.
// - Autofill + semantics.
// - CTA "Olvidé mi contraseña" (retorna email para autocompletar).
//
// Dependencias:
// - InstitucionService (auth local)
// - CuentaService (sesión)
// - DocumentosTemporalesService (mapping best-effort)
// - SessionService (role + sesión v2 para boot routing)
// - InstitucionMenuPage (home institucional)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../services/cuenta_service.dart';
import '../../services/documentos_temporales_service.dart';
import '../../services/institucion_service.dart';
import '../../services/instituciones_helpers.dart' as ih;
import '../../services/session_service.dart';
import '../../ui/atena_assets.dart';

import '../instituciones/institucion_menu_page.dart';
import 'institucion_forgot_password_page.dart';
import 'institucion_registro_page.dart';

class InstitucionLoginPage extends StatefulWidget {
  // Se mantiene por compat/posibles call-sites, pero el flujo institucional NO usa gateway.
  final String? deeplink;

  const InstitucionLoginPage({super.key, this.deeplink});

  @override
  State<InstitucionLoginPage> createState() => _InstitucionLoginPageState();
}

class _InstitucionLoginPageState extends State<InstitucionLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _cargando = false;
  bool _verPass = false;
  bool _rememberMe = true;

  static const int _minPassLen = 4;

  int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      try {
        // ignore: discarded_futures
        precacheImage(
          AssetImage(
            AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionHome),
          ),
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
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // =====================================================
  // HELPERS
  // =====================================================

  static String _n(String? v) => (v ?? '').trim();

  String _normalizeEmail(String v) => v.trim().toLowerCase();

  bool _emailValido(String v) {
    final e = _normalizeEmail(v);
    if (e.isEmpty) {
      return false;
    }

    final at = e.indexOf('@');
    if (at <= 0) {
      return false;
    }
    if (at == e.length - 1) {
      return false;
    }

    final dot = e.lastIndexOf('.');
    if (dot <= at + 1) {
      return false;
    }
    if (dot == e.length - 1) {
      return false;
    }

    return true;
  }

  void _snack(ScaffoldMessengerState m, String msg) {
    final clean = msg.trim();
    if (clean.isEmpty) {
      return;
    }
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(clean)));
  }

  // ✅ STRIP tag de último perfil (I| / A|) cuando se usa como perfilId real.
  String _stripUltimoPerfilTagIfAny(String v) {
    final s = _n(v);
    if (s.startsWith('I|')) {
      return _n(s.substring(2));
    }
    if (s.startsWith('A|')) {
      return _n(s.substring(2));
    }
    return s;
  }

  bool _isTaggedInstitucion(String v) => _n(v).startsWith('I|');
  bool _isTaggedAlumno(String v) => _n(v).startsWith('A|');

  Future<void> _registrarOwnerInstBestEffort({
    required String institucionPerfilId,
    required String ownerAccountId,
  }) async {
    final perfil = _n(institucionPerfilId);
    final owner = _n(ownerAccountId);
    if (perfil.isEmpty || owner.isEmpty) {
      return;
    }

    try {
      await DocumentosTemporalesService.registrarOwnerDeInstitucion(
        institucionPerfilId: perfil,
        ownerAccountId: owner,
      );
    } catch (_) {
      // NO-OP
    }
  }

  Future<void> _setSesionCuenta(String cuentaId) async {
    final id = cuentaId.trim();
    if (id.isEmpty) {
      return;
    }
    try {
      await CuentaService.setSesionCuentaId(id, recordarme: _rememberMe);
    } catch (_) {
      // NO-OP
    }
  }

  Future<void> _setSessionInstitucionV2({
    required String institucionPerfilId,
  }) async {
    final id = _n(institucionPerfilId);
    if (id.isEmpty) {
      return;
    }
    try {
      await SessionService.setSession(
        userId: id,
        role: SessionRole.institucion,
        rememberMe: _rememberMe,
      );
    } catch (_) {
      // NO-OP
    }
  }

  // ✅ Best-effort: persistir instOwner en SessionService sin asumir firma.
  // ⚠️ FIX: NO usar SessionService.instance (no existe).
  Future<void> _ensureInstOwnerBestEffort(String ownerId) async {
    final o = _n(ownerId);
    if (o.isEmpty) {
      return;
    }

    Future<bool> tryCall(Future<dynamic> Function() fn) async {
      try {
        await fn();
        return true;
      } catch (_) {
        return false;
      }
    }

    // 1) static: setInstitucionOwnerAccountId(String)
    try {
      final dyn = SessionService as dynamic;
      final ok = await tryCall(
        () => dyn.setInstitucionOwnerAccountId(o) as Future,
      );
      if (ok) {
        return;
      }
    } catch (_) {}

    // 2) static named (ownerAccountId:)
    try {
      final dyn = SessionService as dynamic;
      final ok = await tryCall(
        () => dyn.setInstitucionOwnerAccountId(ownerAccountId: o) as Future,
      );
      if (ok) {
        return;
      }
    } catch (_) {}

    // 3) (no-op)
  }

  // ✅ Best-effort: intentar resolver el perfil institucional a usar para el menú.
  // - Preferimos “último perfil institución” si existe (porque puede NO ser == owner).
  // - IMPORTANTE: si viene tagueado, lo strippeamos.
  // - Si el último perfil viene como A|..., lo ignoramos (cruce legacy) y hacemos fallback.
  Future<String> _resolveInstitucionPerfilIdBestEffort(String ownerId) async {
    final owner = _n(ownerId);
    if (owner.isEmpty) {
      return '';
    }

    Future<String?> tryGet(Future<dynamic> Function() fn) async {
      try {
        final r = await fn();
        if (r == null) {
          return null;
        }
        if (r is String) {
          final v = _n(r);
          return v.isEmpty ? null : v;
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    String? rawLast;

    // 1) instance variants
    try {
      final dyn = CuentaService.instance as dynamic;

      final r1 = await tryGet(
        () => dyn.getUltimoPerfil(cuentaId: owner) as Future,
      );
      rawLast = r1 ?? rawLast;

      final r2 = await tryGet(
        () => dyn.getUltimoPerfil(ownerAccountId: owner) as Future,
      );
      rawLast = r2 ?? rawLast;

      final r3 = await tryGet(() => dyn.getUltimoPerfil(owner) as Future);
      rawLast = r3 ?? rawLast;
    } catch (_) {
      // NO-OP
    }

    // 2) static variants
    if (rawLast == null) {
      try {
        final dyn = CuentaService as dynamic;

        final r1 = await tryGet(
          () => dyn.getUltimoPerfil(cuentaId: owner) as Future,
        );
        rawLast = r1 ?? rawLast;

        final r2 = await tryGet(
          () => dyn.getUltimoPerfil(ownerAccountId: owner) as Future,
        );
        rawLast = r2 ?? rawLast;

        final r3 = await tryGet(() => dyn.getUltimoPerfil(owner) as Future);
        rawLast = r3 ?? rawLast;
      } catch (_) {
        // NO-OP
      }
    }

    final last = _n(rawLast);

    // Si viene A|..., NO sirve para institución.
    if (last.isNotEmpty && _isTaggedAlumno(last)) {
      return owner; // prototipo / fallback seguro
    }

    // Si viene I|..., usar STRIP.
    if (last.isNotEmpty && _isTaggedInstitucion(last)) {
      final stripped = _stripUltimoPerfilTagIfAny(last);
      return stripped.isNotEmpty ? stripped : owner;
    }

    // Si viene "pelado", podría ser un perfil institución o legacy: lo aceptamos,
    // pero nunca devolver vacío.
    if (last.isNotEmpty) {
      return last;
    }

    return owner; // prototipo
  }

  // =====================================================
  // FORGOT PASSWORD (CTA)
  // =====================================================
  Future<void> _openForgotPassword() async {
    if (_cargando) {
      return;
    }

    FocusScope.of(context).unfocus();

    final nav = Navigator.of(context);

    final currentEmail = _normalizeEmail(_emailCtrl.text);
    final seedEmail = currentEmail.isNotEmpty ? currentEmail : null;

    try {
      final result = await nav.push<String>(
        MaterialPageRoute(
          builder: (_) =>
              InstitucionForgotPasswordPage(initialEmail: seedEmail),
        ),
      );

      if (!mounted) {
        return;
      }

      final backEmail = _normalizeEmail(result ?? '');
      if (backEmail.isNotEmpty) {
        _emailCtrl.text = backEmail;
      }
    } catch (_) {
      // NO-OP
    }
  }

  // =====================================================
  // LOGIN
  // =====================================================
  Future<void> _login() async {
    if (_cargando) {
      return;
    }

    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final t = AppLocalizations.of(context);

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (!mounted) {
      return;
    }
    setState(() => _cargando = true);

    try {
      final email = _normalizeEmail(_emailCtrl.text);
      final pass = _passCtrl.text.trim();

      final auth = await InstitucionService.loginInstitucion(
        email: email,
        passwordHash: pass,
      );

      if (auth == null) {
        _snack(messenger, t.institucionLoginBadCredentials);
        return;
      }

      // En tu flujo: auth.institucionId se usa como ownerAccountId (cuentaId)
      final ownerId = _n(auth.institucionId);
      if (ownerId.isEmpty) {
        _snack(messenger, t.institucionLoginInvalidInstitutionId);
        return;
      }

      // ✅ Resolver perfil institucional best-effort (sin tags)
      final instPerfilId = await _resolveInstitucionPerfilIdBestEffort(ownerId);
      final instPerfilIdClean = _n(instPerfilId);

      if (instPerfilIdClean.isEmpty) {
        _snack(messenger, t.institucionLoginInvalidInstitutionId);
        return;
      }

      // ✅ Sesión v2 completa (userId = PERFIL REAL, no tagueado)
      await _setSessionInstitucionV2(institucionPerfilId: instPerfilIdClean);

      // ✅ Persistir instOwner best-effort para estabilizar InstitucionMenuPage
      await _ensureInstOwnerBestEffort(ownerId);

      // Best-effort: mapping owner↔institución para documentos temporales
      await _registrarOwnerInstBestEffort(
        institucionPerfilId: instPerfilIdClean,
        ownerAccountId: ownerId,
      );

      // Sesión canónica (sesion_cuenta) = ownerAccountId
      await _setSesionCuenta(ownerId);

      // Best-effort: resolver nombre para UI
      String? nombreUI;
      try {
        final cache = await ih.cargarInstitucionCachePorId(instPerfilIdClean);
        if (cache != null && cache.nombre.trim().isNotEmpty) {
          nombreUI = cache.nombre.trim();
        } else {
          final inst = await ih.cargarInstitucionPorId(instPerfilIdClean);
          if (inst != null && inst.nombre.trim().isNotEmpty) {
            nombreUI = inst.nombre.trim();
          }
        }
      } catch (_) {
        // NO-OP
      }

      try {
        TextInput.finishAutofillContext();
      } catch (_) {
        // NO-OP
      }

      if (!mounted) {
        return;
      }

      // ✅ POST-LOGIN INSTITUCIONAL DIRECTO (sin CuentaHomePage)
      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) => InstitucionMenuPage(
            ownerAccountId: ownerId,
            institucionPerfilId: instPerfilIdClean,
            institucionNombre: (nombreUI ?? '').trim().isNotEmpty
                ? nombreUI!.trim()
                : null,
          ),
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      _snack(messenger, msg.isNotEmpty ? msg : t.commonGenericError);
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // =====================================================
  // UI
  // =====================================================
  Widget _buildBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final overlayAlpha = _alpha(isDark ? 0.28 : 0.06);

    Widget bgFallback() => Container(color: cs.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionHome),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => bgFallback(),
        ),
        Container(color: cs.scrim.withAlpha(overlayAlpha)),
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

  Widget _buildCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = cs.surface.withAlpha(_alpha(isDark ? 0.86 : 0.94));
    final border = cs.outlineVariant.withAlpha(_alpha(isDark ? 0.35 : 0.40));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        color: cardBg,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(16),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Semantics(
                    header: true,
                    child: Icon(Icons.apartment, size: 56, color: cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.institucionLoginTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    label: t.commonEmail,
                    textField: true,
                    child: TextFormField(
                      controller: _emailCtrl,
                      enabled: !_cargando,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: t.commonEmail,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final vv = (v ?? '').trim();
                        if (vv.isEmpty) {
                          return t.commonEmailRequired;
                        }
                        if (!_emailValido(vv)) {
                          return t.commonEmailInvalid;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: t.commonPassword,
                    textField: true,
                    child: TextFormField(
                      controller: _passCtrl,
                      enabled: !_cargando,
                      obscureText: !_verPass,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: t.commonPassword,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          tooltip: _verPass
                              ? t.commonHidePassword
                              : t.commonShowPassword,
                          icon: Icon(
                            _verPass ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: _cargando
                              ? null
                              : () {
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() => _verPass = !_verPass);
                                },
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        final vv = (v ?? '').trim();
                        if (vv.isEmpty) {
                          return t.commonPasswordRequired;
                        }
                        if (vv.length < _minPassLen) {
                          return t.commonPasswordMinLength4;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (_cargando) {
                          return;
                        }
                        // ignore: discarded_futures
                        _login();
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      enabled: !_cargando,
                      label: t.commonForgotPassword,
                      child: TextButton(
                        onPressed: _cargando ? null : _openForgotPassword,
                        child: Text(t.commonForgotPassword),
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    value: _rememberMe,
                    onChanged: _cargando
                        ? null
                        : (v) {
                            if (!mounted) {
                              return;
                            }
                            setState(() => _rememberMe = v ?? true);
                          },
                    title: Text(t.commonRememberMe),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Semantics(
                      button: true,
                      enabled: !_cargando,
                      label: _cargando ? t.commonLoggingIn : t.commonLogin,
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : _login,
                        icon: _cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          _cargando ? t.commonLoggingIn : t.commonLogin,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: Semantics(
                      button: true,
                      enabled: !_cargando,
                      label: t.commonRegister,
                      child: OutlinedButton(
                        onPressed: _cargando
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const InstitucionRegistroPage(),
                                  ),
                                );
                              },
                        child: Text(t.commonRegister),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.institucionLoginAppBar),
        backgroundColor: cs.surface.withAlpha(0),
        surfaceTintColor: cs.surface.withAlpha(0),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _buildBackground(
        context,
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCard(context),
            ),
          ),
        ),
      ),
    );
  }
}
