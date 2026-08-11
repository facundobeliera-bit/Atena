// lib/screens/auth/institucion_forgot_password_page.dart
//
// ATENA – INSTITUCIÓN / OLVIDÉ MI CONTRASEÑA (PROTOTIPO, CANÓNICO)
//
// Objetivo (prototipo local):
// - Permite “restablecer” contraseña de una institución en storage local.
// - NO envía emails (sin backend).
// - Mantiene hardening (no context async, loading robusto, mounted checks).
//
// Canon:
// - Este screen NO crea sesión.
// - Solo actualiza credenciales en InstitucionService (auth local).
// - Luego vuelve al login (pop), devolviendo el email.
//
// Nota de seguridad (prototipo):
// - En producción: reemplazar por flujo real con email/OTP/backend.
// - Aquí se permite reset local para poder avanzar en Fase 2.
//
// ✅ IMPORTANTE (canónico):
// - Mantiene InstitucionService como fuente de verdad en prototipo.
//
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../services/institucion_service.dart';
import '../../ui/atena_assets.dart';

class InstitucionForgotPasswordPage extends StatefulWidget {
  /// ✅ Permite seed desde login para autocompletar.
  final String? initialEmail;

  const InstitucionForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<InstitucionForgotPasswordPage> createState() =>
      _InstitucionForgotPasswordPageState();
}

class _InstitucionForgotPasswordPageState
    extends State<InstitucionForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _pass1Ctrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _cargando = false;
  bool _verPass = false;

  String? _errorBanner;

  static const int _minPassLen = 4;

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

  void _snack(String msg) {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  void _clearBannerIfAny() {
    if (!mounted) return;
    if ((_errorBanner ?? '').trim().isEmpty) return;
    setState(() => _errorBanner = null);
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // Validators
  // ------------------------------------------------------------

  String? _validateEmail(BuildContext context, String? v) {
    final t = AppLocalizations.of(context);
    final v0 = (v ?? '').trim();
    if (v0.isEmpty) return t.institucionForgotPasswordEnterEmailError;
    if (!_emailValido(v0)) return t.institucionForgotPasswordInvalidEmailError;
    return null;
  }

  String? _validatePass(BuildContext context, String? v) {
    final t = AppLocalizations.of(context);
    final v0 = (v ?? '').trim();
    if (v0.isEmpty) return t.institucionForgotPasswordEnterPasswordError;
    if (v0.length < _minPassLen) {
      return t.institucionForgotPasswordPasswordTooShortError;
    }
    return null;
  }

  String? _validateConfirm(BuildContext context, String? v) {
    final t = AppLocalizations.of(context);
    final base = _validatePass(context, v);
    if (base != null) return base;

    final p1 = _pass1Ctrl.text.trim();
    final p2 = (v ?? '').trim();
    if (p1.isNotEmpty && p2.isNotEmpty && p1 != p2) {
      return t.institucionForgotPasswordPasswordsDontMatchError;
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

    final t = AppLocalizations.of(context);

    final email = _normalizeEmail(_emailCtrl.text);
    final p1 = _pass1Ctrl.text.trim();
    final p2 = _pass2Ctrl.text.trim();

    if (p1 != p2) {
      if (mounted) {
        setState(() => _errorBanner = t.commonPasswordsDontMatch);
      }
      _snack(t.commonPasswordsDontMatch);
      return;
    }

    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final instId = await InstitucionService.getInstitucionIdByEmail(email);
      if (instId == null || instId.trim().isEmpty) {
        if (mounted) {
          setState(
            () => _errorBanner = t.institucionForgotPasswordAccountNotFound,
          );
        }
        _snack(t.institucionForgotPasswordAccountNotFound);
        return;
      }

      await InstitucionService.actualizarCredenciales(
        institucionId: instId.trim(),
        nuevoPassword: p1,
      );

      // Cerrar autofill context (iOS/Android) best-effort
      try {
        TextInput.finishAutofillContext();
      } catch (_) {
        // NO-OP
      }

      if (!mounted) return;

      _snack(t.institucionForgotPasswordPasswordUpdatedPrototype);
      Navigator.of(context).pop<String>(email);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() => _errorBanner = msg);
      }
      _snack(msg);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardAlpha = _alpha(isDark ? 0.35 : 0.92);
    final panelBg = cs.surface.withAlpha(cardAlpha);

    final banner = (_errorBanner ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.institucionForgotPasswordTitle),
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
                            t.institucionForgotPasswordIntro,
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
                              labelText: t.commonEmail,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => _validateEmail(context, v),
                            onChanged: (_) => _clearBannerIfAny(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass1Ctrl,
                            enabled: !_cargando,
                            obscureText: !_verPass,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: t.commonNewPassword,
                              border: const OutlineInputBorder(),
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
                                  _verPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) => _validatePass(context, v),
                            onChanged: (_) => _clearBannerIfAny(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass2Ctrl,
                            enabled: !_cargando,
                            obscureText: !_verPass,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: t.commonConfirmPassword,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => _validateConfirm(context, v),
                            onChanged: (_) => _clearBannerIfAny(),
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
                                  onPressed: _cargando
                                      ? null
                                      : () => Navigator.of(context).pop(),
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
