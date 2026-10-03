// lib/screens/auth/alumno_login_page.dart
//
// ATENA – Ingreso de alumnos y familias.
// Al ingresar se abre el hub de la cuenta (perfiles de alumno) y se limpia la
// pila de navegación para que "Atrás" no vuelva al formulario.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../routes/atena_deeplink.dart';
import '../../routes/atena_nav.dart';
import '../../services/auth_service.dart';
import '../../ui/atena_ui.dart';
import 'alumno_forgot_password_page.dart';
import 'alumno_registro_page.dart';
import 'widgets/auth_shell.dart';

class AlumnoLoginPage extends StatefulWidget {
  /// Deeplink opcional (/calendario o /documentos) para abrir tras ingresar.
  final String? deeplink;

  const AlumnoLoginPage({super.key, this.deeplink});

  @override
  State<AlumnoLoginPage> createState() => _AlumnoLoginPageState();
}

class _AlumnoLoginPageState extends State<AlumnoLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? get _allowedDeeplink {
    final raw = (widget.deeplink ?? '').trim();
    if (raw.isEmpty) return null;
    try {
      final dl = AtenaDeeplink.parse(raw);
      if (!(dl.isCalendario || dl.isDocumentos)) return null;
      final out = dl.toRouteString().trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cuenta = await AuthService.loginFamilia(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        remember: _remember,
      );
      TextInput.finishAutofillContext();
      if (!mounted) return;
      await AtenaNav.toFamilia(context, cuenta.id, deeplink: _allowedDeeplink);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorText(t, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            AlumnoForgotPasswordPage(initialEmail: _emailCtrl.text.trim()),
      ),
    );
    if (!mounted || (email ?? '').trim().isEmpty) return;
    setState(() {
      _emailCtrl.text = email!.trim();
      _passCtrl.clear();
      _error = null;
    });
  }

  void _register() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlumnoRegistroPage(
          deeplink: _allowedDeeplink,
          initialEmail: _emailCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = (_error ?? '').trim();

    return AuthShell(
      role: AtenaRole.alumno,
      icon: Icons.school_rounded,
      eyebrow: t.authFamiliaLoginSubtitle,
      title: t.authFamiliaLoginTitle,
      footer: AuthFooterLink(
        question: t.authNoAccount,
        action: t.commonCreateAccount,
        onPressed: _loading ? null : _register,
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username,
                ],
                decoration: InputDecoration(
                  labelText: t.commonEmail,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) => AuthValidators.email(t, v),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 14),
              AuthPasswordField(
                controller: _passCtrl,
                enabled: !_loading,
                label: t.commonPassword,
                validator: (v) => AuthValidators.loginPassword(t, v),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
              AuthRememberRow(
                value: _remember,
                enabled: !_loading,
                onChanged: (v) => setState(() => _remember = v),
                onForgot: _forgot,
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                AtenaBanner(tone: AtenaBannerTone.error, message: error),
              ],
              const SizedBox(height: 16),
              AuthSubmitButton(
                label: t.commonSignIn,
                loadingLabel: t.commonSigningIn,
                loading: _loading,
                onPressed: _submit,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
