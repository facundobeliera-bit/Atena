// lib/screens/auth/alumno_registro_page.dart
//
// ATENA – Registro de familias: crea la cuenta y el primer perfil de alumno.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../routes/atena_nav.dart';
import '../../services/auth_service.dart';
import '../../ui/atena_ui.dart';
import 'widgets/auth_shell.dart';

class AlumnoRegistroPage extends StatefulWidget {
  final String? deeplink;
  final String? initialEmail;

  const AlumnoRegistroPage({super.key, this.deeplink, this.initialEmail});

  @override
  State<AlumnoRegistroPage> createState() => _AlumnoRegistroPageState();
}

class _AlumnoRegistroPageState extends State<AlumnoRegistroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  DateTime? _fechaNac;
  bool _remember = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = (widget.initialEmail ?? '').trim();
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl,
      _apellidoCtrl,
      _dniCtrl,
      _telefonoCtrl,
      _fechaCtrl,
      _emailCtrl,
      _passCtrl,
      _pass2Ctrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFecha() async {
    if (_loading) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _fechaNac = picked;
      _fechaCtrl.text = MaterialLocalizations.of(
        context,
      ).formatCompactDate(picked);
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final fecha = _fechaNac;
    if (fecha == null) return;

    final t = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthService.registrarFamilia(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        remember: _remember,
        nombre: _nombreCtrl.text,
        apellido: _apellidoCtrl.text,
        dni: _dniCtrl.text,
        fechaNacimiento: fecha,
        telefono: _telefonoCtrl.text,
      );
      TextInput.finishAutofillContext();
      if (!mounted) return;
      await AtenaNav.toFamilia(
        context,
        res.cuenta.id,
        deeplink: widget.deeplink,
      );
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
      icon: Icons.person_add_alt_1_rounded,
      title: t.authFamiliaRegisterTitle,
      subtitle: t.authFamiliaRegisterSubtitle,
      maxWidth: 560,
      footer: AuthFooterLink(
        question: t.authHaveAccount,
        action: t.commonSignIn,
        onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthFormSection(
                title: t.authStudentSection,
                help: t.authStudentSectionHelp,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreCtrl,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: InputDecoration(labelText: t.commonNameLabel),
                      validator: (v) => AuthValidators.required(t, v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoCtrl,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      decoration: InputDecoration(
                        labelText: t.commonLastNameLabel,
                      ),
                      validator: (v) => AuthValidators.required(t, v),
                    ),
                  ),
                ],
              ),
              gap,
              TextFormField(
                controller: _dniCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [digitsOnly],
                decoration: InputDecoration(
                  labelText: t.authDniLabel,
                  helperText: t.authDniHelper,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (v) => AuthValidators.dni(t, v),
              ),
              gap,
              TextFormField(
                controller: _fechaCtrl,
                enabled: !_loading,
                readOnly: true,
                enableInteractiveSelection: false,
                onTap: _pickFecha,
                decoration: InputDecoration(
                  labelText: t.authBirthDate,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: const Icon(Icons.calendar_month_rounded),
                ),
                validator: (_) =>
                    _fechaNac == null ? t.authBirthDateRequired : null,
              ),
              gap,
              TextFormField(
                controller: _telefonoCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: InputDecoration(
                  labelText: t.commonPhoneOptionalLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),
              AuthFormSection(title: t.authAccessSection),
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
              AuthPasswordField(
                controller: _passCtrl,
                enabled: !_loading,
                isNew: true,
                label: t.commonPassword,
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
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _remember,
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _remember = v ?? true),
                title: Text(t.commonRememberMe),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 6),
                AtenaBanner(tone: AtenaBannerTone.error, message: error),
              ],
              const SizedBox(height: 16),
              AuthSubmitButton(
                label: t.commonCreateAccount,
                loadingLabel: t.commonCreating,
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
