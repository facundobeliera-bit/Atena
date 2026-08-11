// lib/screens/auth/alumno_forgot_password_page.dart
//
// ATENA – ALUMNO / OLVIDÉ MI CONTRASEÑA (PROTOTIPO, CANÓNICO)
//
// Objetivo (prototipo local):
// - Permite “restablecer” contraseña de un ALUMNO en storage local.
// - NO envía emails (sin backend).
// - Mantiene hardening (no context async, loading robusto, mounted checks).
//
// Canon:
// - Este screen NO crea sesión.
// - Solo actualiza credenciales en CuentaService (auth local de cuenta).
// - Luego vuelve al login (pop), devolviendo el email.
//
// Nota de seguridad (prototipo):
// - En producción: reemplazar por flujo real con email/OTP/backend.
// - Aquí se permite reset local para poder avanzar en Fase 2.
//
// Importante (coherencia con login alumno):
// - Usa background/overlay de Alumno (bgAlumnoHome + highlightGlow).
// - Layout: card + 2 botones.
//
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../services/cuenta_service.dart';
import '../../ui/atena_assets.dart';

class AlumnoForgotPasswordPage extends StatefulWidget {
  /// ✅ Permite seed desde login para autocompletar.
  final String? initialEmail;

  const AlumnoForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<AlumnoForgotPasswordPage> createState() =>
      _AlumnoForgotPasswordPageState();
}

class _AlumnoForgotPasswordPageState extends State<AlumnoForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _pass1Ctrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _cargando = false;
  bool _verPass = false;

  String? _errorBanner;

  @override
  void initState() {
    super.initState();

    final seed = (widget.initialEmail ?? '').trim();
    if (seed.isNotEmpty) {
      _emailCtrl.text = seed;
    }

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
    _pass1Ctrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  String _normalizeEmail(String v) => v.trim().toLowerCase();

  bool _emailValido(String v) {
    final e = _normalizeEmail(v);
    if (e.isEmpty) return false;
    final at = e.indexOf('@');
    if (at <= 0) return false;
    if (at == e.length - 1) return false;
    final dot = e.lastIndexOf('.');
    if (dot <= at + 1) return false;
    if (dot == e.length - 1) return false;
    return true;
  }

  int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

  void _snack(ScaffoldMessengerState m, String msg) {
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  Widget _buildBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final overlayAlpha = _alpha(isDark ? 0.30 : 0.08);

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

  Widget _buildErrorBanner(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.errorContainer.withAlpha(_alpha(0.90)),
        border: Border.all(color: cs.error.withAlpha(_alpha(0.35))),
      ),
      child: Text(
        msg,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Validators
  // ------------------------------------------------------------

  String? _validateEmail(BuildContext context, String? v) {
    final t = AppLocalizations.of(context);
    final v0 = (v ?? '').trim();
    if (v0.isEmpty) return t.alumnoForgotPasswordEnterEmailError;
    if (!_emailValido(v0)) return t.alumnoForgotPasswordInvalidEmailError;
    return null;
  }

  String? _validatePass(BuildContext context, String? v) {
    final t = AppLocalizations.of(context);
    final v0 = (v ?? '').trim();
    if (v0.isEmpty) return t.alumnoForgotPasswordEnterPasswordError;
    if (v0.length < 4) return t.alumnoForgotPasswordPasswordTooShortError;
    return null;
  }

  String? _validateConfirm(BuildContext context, String? v) {
    final t = AppLocalizations.of(context);
    final base = _validatePass(context, v);
    if (base != null) return base;

    final p1 = _pass1Ctrl.text.trim();
    final p2 = (v ?? '').trim();
    if (p1.isNotEmpty && p2.isNotEmpty && p1 != p2) {
      return t.alumnoForgotPasswordPasswordsDontMatchError;
    }
    return null;
  }

  // ------------------------------------------------------------
  // Action
  // ------------------------------------------------------------

  Future<void> _guardarReset() async {
    if (_cargando) return;

    FocusScope.of(context).unfocus();

    if (mounted && (_errorBanner ?? '').trim().isNotEmpty) {
      setState(() => _errorBanner = null);
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);

    final email = _normalizeEmail(_emailCtrl.text);
    final p1 = _pass1Ctrl.text.trim();
    final p2 = _pass2Ctrl.text.trim();

    if (p1 != p2) {
      if (mounted) {
        setState(() => _errorBanner = t.alumnoForgotPasswordPasswordsDontMatch);
      }
      _snack(messenger, t.alumnoForgotPasswordPasswordsDontMatch);
      return;
    }

    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final cuentaId = await CuentaService.getCuentaIdByEmail(email);
      if (cuentaId == null || cuentaId.trim().isEmpty) {
        if (mounted) {
          setState(() => _errorBanner = t.alumnoForgotPasswordAccountNotFound);
        }
        _snack(messenger, t.alumnoForgotPasswordAccountNotFound);
        return;
      }

      await CuentaService.actualizarPasswordCuenta(
        cuentaId: cuentaId.trim(),
        nuevoPassword: p1,
      );

      if (!mounted) return;

      _snack(messenger, t.alumnoForgotPasswordPasswordUpdatedPrototype);
      Navigator.of(context).pop<String>(email);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) setState(() => _errorBanner = msg);
      _snack(messenger, msg);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _navPop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;
    final cardAlpha = _alpha(isDark ? 0.40 : 0.92);
    final panelBg = cs.surface.withAlpha(cardAlpha);

    final banner = (_errorBanner ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.alumnoForgotPasswordTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _buildBackground(
        context,
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  borderRadius: BorderRadius.circular(18),
                  color: panelBg,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Semantics(
                            header: true,
                            child: Icon(
                              Icons.lock_reset,
                              size: 56,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.alumnoForgotPasswordIntro,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (banner.isNotEmpty) ...[
                            _buildErrorBanner(context, banner),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _emailCtrl,
                            enabled: !_cargando,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: t.alumnoForgotPasswordEmailLabel,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => _validateEmail(context, v),
                            onChanged: (_) {
                              if (!mounted) return;
                              if ((_errorBanner ?? '').trim().isEmpty) return;
                              setState(() => _errorBanner = null);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass1Ctrl,
                            enabled: !_cargando,
                            obscureText: !_verPass,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: t.alumnoForgotPasswordNewPasswordLabel,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _verPass
                                    ? t.alumnoForgotPasswordHidePassword
                                    : t.alumnoForgotPasswordShowPassword,
                                onPressed: _cargando
                                    ? null
                                    : () {
                                        if (!mounted) return;
                                        setState(() => _verPass = !_verPass);
                                      },
                                icon: Icon(
                                  _verPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) => _validatePass(context, v),
                            onChanged: (_) {
                              if (!mounted) return;
                              if ((_errorBanner ?? '').trim().isEmpty) return;
                              setState(() => _errorBanner = null);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass2Ctrl,
                            enabled: !_cargando,
                            obscureText: !_verPass,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText:
                                  t.alumnoForgotPasswordConfirmPasswordLabel,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => _validateConfirm(context, v),
                            onChanged: (_) {
                              if (!mounted) return;
                              if ((_errorBanner ?? '').trim().isEmpty) return;
                              setState(() => _errorBanner = null);
                            },
                            onFieldSubmitted: (_) {
                              if (_cargando) return;
                              // ignore: discarded_futures
                              _guardarReset();
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _cargando ? null : _navPop,
                                  icon: const Icon(Icons.arrow_back),
                                  label: Text(t.commonBack),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  enabled: !_cargando,
                                  label: _cargando
                                      ? t.commonSaving
                                      : t.commonSave,
                                  child: ElevatedButton.icon(
                                    onPressed: _cargando ? null : _guardarReset,
                                    icon: _cargando
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(
                                      _cargando ? t.commonSaving : t.commonSave,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
