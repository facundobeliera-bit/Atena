// lib/screens/auth/institucion_login_page.dart
//
// ATENA – Ingreso de instituciones.
// Al ingresar se abre directamente el inicio de la institución.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../routes/atena_nav.dart';
import '../../services/auth_service.dart';
import '../../ui/atena_ui.dart';
import 'institucion_forgot_password_page.dart';
import 'institucion_registro_page.dart';
import 'widgets/auth_shell.dart';

class InstitucionLoginPage extends StatefulWidget {
  /// Se conserva por compatibilidad con llamadas existentes; no se usa.
  final String? deeplink;

  const InstitucionLoginPage({super.key, this.deeplink});

  @override
  State<InstitucionLoginPage> createState() => _InstitucionLoginPageState();
}

class _InstitucionLoginPageState extends State<InstitucionLoginPage> {
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
      final sesion = await AuthService.loginInstitucion(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        remember: _remember,
      );
      TextInput.finishAutofillContext();
      if (!mounted) return;
      await AtenaNav.toInstitucion(context, sesion);
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
            InstitucionForgotPasswordPage(initialEmail: _emailCtrl.text.trim()),
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InstitucionRegistroPage()));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = (_error ?? '').trim();

    return AuthShell(
      role: AtenaRole.institucion,
      icon: Icons.account_balance_rounded,
      title: t.authInstitucionLoginTitle,
      subtitle: t.authInstitucionLoginSubtitle,
      footer: AuthFooterLink(
        question: t.authNoInstitution,
        action: t.authRegisterInstitution,
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
