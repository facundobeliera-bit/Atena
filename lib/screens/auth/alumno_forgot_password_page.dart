// lib/screens/auth/alumno_forgot_password_page.dart
//
// ATENA – Restablecer contraseña (familias).
// Sin servidor de correo, la identidad se confirma con el DNI de un alumno de
// la cuenta. Al terminar vuelve al login con el email completo.

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../ui/atena_ui.dart';
import 'widgets/auth_shell.dart';

class AlumnoForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const AlumnoForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<AlumnoForgotPasswordPage> createState() =>
      _AlumnoForgotPasswordPageState();
}

class _AlumnoForgotPasswordPageState extends State<AlumnoForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = (widget.initialEmail ?? '').trim();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _dniCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
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
      final email = _emailCtrl.text.trim().toLowerCase();
      await AuthService.restablecerPasswordFamilia(
        email: email,
        dni: _dniCtrl.text,
        nuevoPassword: _passCtrl.text,
      );
      if (!mounted) return;
      AtenaFeedback.success(context, t.authResetDone);
      Navigator.of(context).pop<String>(email);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorText(t, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = (_error ?? '').trim();
    const gap = SizedBox(height: 14);

    return AuthShell(
      role: AtenaRole.alumno,
      icon: Icons.lock_reset_rounded,
      title: t.authResetTitle,
      subtitle: t.authResetFamiliaSubtitle,
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
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: t.commonEmail,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) => AuthValidators.email(t, v),
              ),
              gap,
              TextFormField(
                controller: _dniCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [digitsOnly],
                decoration: InputDecoration(
                  labelText: t.authResetDniLabel,
                  helperText: t.authDniHelper,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (v) => AuthValidators.dni(t, v),
              ),
              gap,
              AuthPasswordField(
                controller: _passCtrl,
                enabled: !_loading,
                isNew: true,
                label: t.commonNewPassword,
                helperText: t.authPasswordHelper,
                textInputAction: TextInputAction.next,
                validator: (v) => AuthValidators.newPassword(t, v),
              ),
              gap,
              AuthPasswordField(
                controller: _pass2Ctrl,
                enabled: !_loading,
                isNew: true,
                label: t.authPasswordConfirm,
                validator: (v) {
                  if ((v ?? '').isEmpty) return t.commonPasswordRequired;
                  if (v != _passCtrl.text) return t.commonPasswordsDontMatch;
                  return null;
                },
                onSubmitted: (_) => _submit(),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 14),
                AtenaBanner(tone: AtenaBannerTone.error, message: error),
              ],
              const SizedBox(height: 18),
              AuthSubmitButton(
                label: t.authResetCta,
                loadingLabel: t.commonSaving,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
