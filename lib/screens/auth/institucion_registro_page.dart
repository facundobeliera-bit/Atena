// lib/screens/auth/institucion_registro_page.dart
//
// ATENA – Registro de instituciones (paso 1 de 2).
// Junta los datos de la institución y el acceso; el alta definitiva se hace
// en el paso 2 (InstitucionPlanPage), al confirmar el plan.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/auth_errors.dart';
import '../../services/institucion_service.dart';
import '../../ui/atena_ui.dart';
import '../instituciones/institucion_plan_page.dart';
import 'widgets/auth_shell.dart';

class InstitucionRegistroPage extends StatefulWidget {
  const InstitucionRegistroPage({super.key});

  @override
  State<InstitucionRegistroPage> createState() =>
      _InstitucionRegistroPageState();
}

class _InstitucionRegistroPageState extends State<InstitucionRegistroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _cuitCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController();
  final _paisCtrl = TextEditingController(text: 'Argentina');
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl,
      _cuitCtrl,
      _direccionCtrl,
      _ciudadCtrl,
      _provinciaCtrl,
      _paisCtrl,
      _emailCtrl,
      _telefonoCtrl,
      _passCtrl,
      _pass2Ctrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _continuar() async {
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
      // Verificamos el email antes del plan para no fallar al final.
      final existente = await InstitucionService.getInstitucionIdByEmail(email);
      if (existente != null && existente.trim().isNotEmpty) {
        throw const AuthException(AuthErrorCode.emailInUse);
      }

      TextInput.finishAutofillContext();
      if (!mounted) return;

      final draft = InstitucionRegistroDraft(
        nombre: _nombreCtrl.text.trim(),
        cuit: _cuitCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        direccion: _direccionCtrl.text.trim(),
        pais: _paisCtrl.text.trim().isEmpty
            ? 'Argentina'
            : _paisCtrl.text.trim(),
        provincia: _provinciaCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        modalidad: ModalidadCursado.presencial,
        email: email,
        telefono: _telefonoCtrl.text.trim(),
        pass: _passCtrl.text,
        tipo: TipoInstitucion.otra,
        nivelesSeleccionados: const <NivelCurricular>[],
        bloquesSeleccionados: const <BloqueExtracurricular>[],
      );

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InstitucionPlanPage(draft: draft)),
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
      role: AtenaRole.institucion,
      icon: Icons.domain_add_rounded,
      eyebrow: t.authStepOf('1', '2'),
      title: t.authInstRegisterTitle,
      subtitle: t.authInstRegisterSubtitle,
      maxWidth: 600,
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
              AuthFormSection(title: t.institucionRegistroSectionBasics),
              TextFormField(
                controller: _nombreCtrl,
                enabled: !_loading,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.organizationName],
                decoration: InputDecoration(
                  labelText: t.institucionRegistroInstitutionName,
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return t.commonFieldRequired;
                  if (s.length < 3) return t.commonTooShort;
                  return null;
                },
              ),
              gap,
              TextFormField(
                controller: _cuitCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [digitsOnly],
                decoration: InputDecoration(
                  labelText: t.institucionRegistroCuit,
                  helperText: t.authCuitHelper,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (v) => AuthValidators.cuit(t, v),
              ),
              const SizedBox(height: 24),
              AuthFormSection(title: t.institucionRegistroSectionLocation),
              TextFormField(
                controller: _direccionCtrl,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.streetAddressLine1],
                decoration: InputDecoration(
                  labelText: t.institucionRegistroAddress,
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
                validator: (v) => AuthValidators.required(t, v),
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ciudadCtrl,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.addressCity],
                      decoration: InputDecoration(
                        labelText: t.institucionRegistroCity,
                      ),
                      validator: (v) => AuthValidators.required(t, v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _provinciaCtrl,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.addressState],
                      decoration: InputDecoration(
                        labelText: t.institucionRegistroProvince,
                      ),
                      validator: (v) => AuthValidators.required(t, v),
                    ),
                  ),
                ],
              ),
              gap,
              TextFormField(
                controller: _paisCtrl,
                enabled: !_loading,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.countryName],
                decoration: InputDecoration(
                  labelText: t.institucionRegistroCountry,
                ),
                validator: (v) => AuthValidators.required(t, v),
              ),
              const SizedBox(height: 24),
              AuthFormSection(title: t.institucionRegistroSectionAccessContact),
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
                controller: _telefonoCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
                ],
                decoration: InputDecoration(
                  labelText: t.commonPhone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  if (d.isEmpty) return t.commonFieldRequired;
                  if (d.length < 8 || d.length > 15) {
                    return t.commonPhoneInvalid;
                  }
                  return null;
                },
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
                onSubmitted: (_) => _continuar(),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 14),
                AtenaBanner(tone: AtenaBannerTone.error, message: error),
              ],
              const SizedBox(height: 18),
              AuthSubmitButton(
                label: t.commonContinueToPlan,
                loadingLabel: t.commonContinuing,
                loading: _loading,
                onPressed: _continuar,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
