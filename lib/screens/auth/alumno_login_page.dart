// lib/screens/auth/alumno_login_page.dart
//
// ATENA – AUTH / ALUMNO LOGIN (CANÓNICO)
//
// ✅ CANÓNICO:
// - Post-login SIEMPRE navega a CuentaHomePage (gateway owner→perfil).
// - Deeplink: se preserva y se pasa como initialDeeplink al gateway.
// - Fuente de verdad deeplinks: AtenaDeeplink.parse() (mismo parser que Router/Main).
//
// ✅ HARDENING:
// - No rompe si faltan assets (background fallback).
// - precache best-effort.
// - Manejo de mounted consistente.
// - Evita doble submit (guard por _cargando).
//
// ✅ FASE 2 (i18n + theme):
// - Textos via AppLocalizations.of(context).<key> (sin fallbacks).
// - Accesibilidad: semantics + autofill + toggle de visibilidad de contraseña.
// - Limpieza: normalización de email más estricta.
//
// ✅ AJUSTE UX (pedido):
// - “Registrarme” navega por ruta nombrada (pantalla separada).
//
// ✅ CIERRE “OLVIDÉ MI CONTRASEÑA” (enero 2026):
// - Navega por ruta nombrada /alumno_forgot_password y pasa initialEmail.
// - Recibe retorno pop<String>(email) desde forgot y re-seedea el campo email.
//
// Nota:
// - Este screen NO crea sesión directa fuera del flujo canónico; CuentaService maneja sesión de cuenta.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../models/alumnos/alumnos_integrados.dart';
import '../../models/cuentas/cuenta.dart';
import '../../routes/atena_deeplink.dart';
import '../../services/alumno_service.dart';
import '../../services/cuenta_service.dart';
import '../../ui/atena_assets.dart';
import '../cuentas/cuenta_home_page.dart';

class AlumnoLoginPage extends StatefulWidget {
  /// ✅ Soporte deeplink (canónico).
  final String? deeplink;

  const AlumnoLoginPage({super.key, this.deeplink});

  @override
  State<AlumnoLoginPage> createState() => _AlumnoLoginPageState();
}

class _AlumnoLoginPageState extends State<AlumnoLoginPage> {
  final _formKey = GlobalKey<FormState>();

  bool _cargando = false;

  bool _recordarme = true;
  bool _verPass = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _error;

  @override
  void initState() {
    super.initState();

    // Precache best-effort (no bloqueante)
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
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  int _alpha(double v) => (v * 255).round().clamp(0, 255).toInt();

  String _normalizeEmail(String raw) => raw.trim().toLowerCase();

  bool _looksLikeEmail(String value) {
    final t = _normalizeEmail(value);
    if (t.isEmpty) return false;

    final at = t.indexOf('@');
    if (at <= 0) return false;
    if (at == t.length - 1) return false;

    final dot = t.lastIndexOf('.');
    if (dot <= at + 1) return false;
    if (dot == t.length - 1) return false;

    return true;
  }

  // =====================================================
  // Deeplink CANÓNICO (fuente de verdad: AtenaDeeplink)
  // =====================================================
  String? _normalizeAllowedDeeplink(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;

    try {
      final dl = AtenaDeeplink.parse(s);
      if (!(dl.isCalendario || dl.isDocumentos)) return null;

      final out = dl.toRouteString().trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _asegurarFichaAlumnoDesdePerfil({
    required String cuentaId,
    required PerfilAlumno perfil,
  }) async {
    final ownerId = cuentaId.trim();
    final perfilId = perfil.id.trim();
    if (ownerId.isEmpty || perfilId.isEmpty) return;

    final existente = await AlumnoService.instance.getPerfilAlumnoByPerfilId(
      ownerAccountId: ownerId,
      perfilId: perfilId,
    );
    if (existente != null) return;

    final alumno = Alumno(
      documento: perfil.documento,
      nombre: perfil.nombre,
      apellido: perfil.apellido,
      fechaNacimiento: perfil.fechaNacimiento,
      email: perfil.email.trim(),
      telefono: perfil.telefono.trim(),
      fotoPerfilLocalPath: null,
    );

    await AlumnoService.instance.upsertPerfilAlumnoByPerfilId(
      ownerAccountId: ownerId,
      perfilId: perfilId,
      alumno: alumno,
    );
  }

  /// ✅ Post-login canónico:
  Future<void> _goAfterLogin(Cuenta cuenta) async {
    final dl = _normalizeAllowedDeeplink(widget.deeplink);

    // Best-effort: si NO hay deeplink, aseguramos ficha del último perfil.
    if (dl == null) {
      try {
        final ultimoPerfilId = await CuentaService.getUltimoPerfil(cuenta.id);
        final up = (ultimoPerfilId ?? '').trim();
        if (up.isNotEmpty) {
          final perfil = await CuentaService.getPerfilAlumnoById(up);
          if (perfil != null) {
            await _asegurarFichaAlumnoDesdePerfil(
              cuentaId: cuenta.id,
              perfil: perfil,
            );
          }
        }
      } catch (_) {
        // NO-OP
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            CuentaHomePage(cuentaId: cuenta.id, initialDeeplink: dl),
      ),
    );
  }

  Future<void> _submit() async {
    if (_cargando) return;

    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (!mounted) return;
    setState(() {
      _error = null;
      _cargando = true;
    });

    try {
      final email = _normalizeEmail(_emailCtrl.text);
      final pass = _passCtrl.text.trim();

      final cuenta = await CuentaService.loginCuenta(
        email: email,
        password: pass,
        recordarme: _recordarme,
      );

      if (!mounted) return;
      // Navegación canónica (no depende del await, pero lo dejamos secuencial).
      await _goAfterLogin(cuenta);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  // =====================================================
  // “Olvidé mi contraseña” (canónico con seed + retorno)
  // =====================================================
  Future<void> _goForgotPassword() async {
    final t = AppLocalizations.of(context);
    final seedEmail = _normalizeEmail(_emailCtrl.text);

    try {
      final result = await Navigator.of(context).pushNamed(
        '/alumno_forgot_password',
        arguments: {'initialEmail': seedEmail},
      );

      if (!mounted) return;

      final returnedEmail = (result is String) ? result.trim() : '';
      if (returnedEmail.isNotEmpty) {
        setState(() {
          _emailCtrl.text = returnedEmail;
          _error = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AlumnoLogin] pushNamed(/alumno_forgot_password) FAILED: $e',
        );
      }
      _showSnack(t.commonFeatureUnavailablePrototype);
    }
  }

  // =====================================================
  // Registro (pantalla separada)
  // =====================================================
  Future<void> _goRegistro() async {
    if (_cargando) return;

    final t = AppLocalizations.of(context);
    final seedEmail = _normalizeEmail(_emailCtrl.text);

    try {
      await Navigator.of(
        context,
      ).pushNamed('/alumno_registro', arguments: {'initialEmail': seedEmail});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AlumnoLogin] pushNamed(/alumno_registro) FAILED: $e');
      }
      _showSnack(t.alumnoLoginRegistroNoDisponible);
    }
  }

  // =========================
  // UI – Background wrapper
  // =========================
  Widget _buildBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final overlayAlpha = _alpha(isDark ? 0.30 : 0.10);

    Widget bgFallback() => Container(color: cs.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (ctx, err, stk) => bgFallback(),
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
                errorBuilder: (ctx, err, stk) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  // =====================================================
  // UI – Card (ListView overflow-safe)
  // =====================================================
  Widget _buildAuthCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final errorText = (_error ?? '').trim();

    final cardBg = cs.surface.withAlpha(_alpha(isDark ? 0.86 : 0.94));
    final border = cs.outlineVariant.withAlpha(_alpha(isDark ? 0.35 : 0.40));

    final errorBg = cs.errorContainer.withAlpha(_alpha(0.92));
    final errorFg = cs.onErrorContainer;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
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
                    child: Icon(Icons.school, size: 56, color: cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.alumnoLoginTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (errorText.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: errorBg,
                        border: Border.all(
                          color: cs.error.withAlpha(_alpha(0.35)),
                        ),
                      ),
                      child: Text(
                        errorText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: errorFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !_cargando,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    decoration: InputDecoration(
                      labelText: t.commonEmail,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      final raw = (v ?? '');
                      if (raw.trim().isEmpty) return t.commonEmailRequired;
                      if (!_looksLikeEmail(raw)) return t.commonEmailInvalid;
                      return null;
                    },
                    onChanged: (_) {
                      if (!mounted) return;
                      if ((_error ?? '').trim().isEmpty) return;
                      setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    enabled: !_cargando,
                    obscureText: !_verPass,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) {
                      if (_cargando) return;
                      // ignore: discarded_futures
                      _submit();
                    },
                    decoration: InputDecoration(
                      labelText: t.commonPassword,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        tooltip: _verPass
                            ? t.commonHidePassword
                            : t.commonShowPassword,
                        onPressed: _cargando
                            ? null
                            : () {
                                if (!mounted) return;
                                setState(() => _verPass = !_verPass);
                              },
                        icon: Icon(
                          _verPass ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.length < 4) return t.commonPasswordMinLength4;
                      return null;
                    },
                    onChanged: (_) {
                      if (!mounted) return;
                      if ((_error ?? '').trim().isEmpty) return;
                      setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _cargando ? null : _goForgotPassword,
                      child: Text(t.alumnoLoginForgotPassword),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _recordarme,
                        onChanged: _cargando
                            ? null
                            : (v) {
                                if (!mounted) return;
                                setState(() => _recordarme = v ?? true);
                              },
                      ),
                      Expanded(
                        child: Text(
                          t.commonRememberMe,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: Semantics(
                      button: true,
                      enabled: !_cargando,
                      label: _cargando ? t.commonSigningIn : t.commonSignIn,
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : _submit,
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
                          _cargando ? t.commonSigningIn : t.commonSignIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _cargando ? null : _goRegistro,
                      child: Text(t.commonRegister),
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
        title: Text(t.alumnoLoginAppBar),
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
              child: _buildAuthCard(context),
            ),
          ),
        ),
      ),
    );
  }
}
