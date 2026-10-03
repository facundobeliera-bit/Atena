// lib/screens/auth/widgets/auth_shell.dart
//
// Piezas compartidas de las pantallas de acceso (login, registro, recuperación).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../services/auth_errors.dart';
import '../../../ui/atena_ui.dart';
import '../../../ui/widgets/atena_preferences_sheet.dart';

/// Traduce errores de autenticación a un mensaje para el usuario.
String authErrorText(AppLocalizations t, Object error) {
  if (error is AuthException) {
    return switch (error.code) {
      AuthErrorCode.invalidEmail => t.authErrInvalidEmail,
      AuthErrorCode.weakPassword => t.authErrWeakPassword,
      AuthErrorCode.emailInUse => t.authErrEmailInUse,
      AuthErrorCode.accountNotFound => t.authErrAccountNotFound,
      AuthErrorCode.wrongCredentials => t.authErrWrongCredentials,
      AuthErrorCode.invalidDni => t.authErrInvalidDni,
      AuthErrorCode.duplicateDni => t.authErrDuplicateDni,
      AuthErrorCode.identityMismatch => t.authErrIdentityMismatch,
      AuthErrorCode.invalidName => t.authErrInvalidName,
      AuthErrorCode.invalidAccount => t.authErrInvalidAccount,
      AuthErrorCode.unknown => t.uiSomethingWentWrong,
    };
  }
  return t.uiSomethingWentWrong;
}

/// Validaciones comunes de formularios de acceso.
class AuthValidators {
  const AuthValidators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(AppLocalizations t, String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return t.commonEmailRequired;
    if (!_email.hasMatch(s)) return t.authErrInvalidEmail;
    return null;
  }

  static String? loginPassword(AppLocalizations t, String? v) {
    if ((v ?? '').isEmpty) return t.commonPasswordRequired;
    return null;
  }

  static String? newPassword(AppLocalizations t, String? v) {
    final s = v ?? '';
    if (s.isEmpty) return t.commonPasswordRequired;
    if (s.length < 8) return t.authErrWeakPassword;
    return null;
  }

  static String? required(AppLocalizations t, String? v) {
    if ((v ?? '').trim().isEmpty) return t.commonFieldRequired;
    return null;
  }

  static String? dni(AppLocalizations t, String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return t.commonFieldRequired;
    if (d.length < 7 || d.length > 9) return t.authErrInvalidDni;
    return null;
  }

  static String? cuit(AppLocalizations t, String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return t.commonFieldRequired;
    if (d.length != 11) return t.institucionRegistroCuitInvalid;
    return null;
  }
}

/// Estructura de las pantallas de acceso: encabezado con el ícono del área,
/// formulario en tarjeta y acciones secundarias al pie.
class AuthShell extends StatelessWidget {
  final AtenaRole role;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget child;
  final Widget? footer;
  final double maxWidth;

  const AuthShell({
    super.key,
    required this.role,
    required this.icon,
    required this.title,
    this.subtitle,
    this.eyebrow,
    required this.child,
    this.footer,
    this.maxWidth = 460,
  });

  @override
  Widget build(BuildContext context) {
    return AtenaScaffold(
      role: role,
      appBar: AppBar(
        actions: const [AtenaPreferencesButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final sub = (subtitle ?? '').trim();
                  final eb = (eyebrow ?? '').trim();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AtenaColors.roleGradient(role),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (eb.isNotEmpty) ...[
                        Text(
                          eb.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          sub,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AtenaCard(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        child: child,
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 18),
                        footer!,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de sección dentro de un formulario.
class AuthFormSection extends StatelessWidget {
  final String title;
  final String? help;

  const AuthFormSection({super.key, required this.title, this.help});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = (help ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (h.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(h, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Campo de contraseña con botón para mostrar/ocultar.
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool enabled;
  final bool isNew;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.enabled = true,
    this.isNew = false,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      autofillHints: [
        widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _visible ? t.commonHidePassword : t.commonShowPassword,
          icon: Icon(
            _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}

/// Botón principal de formulario con estado de carga.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AuthSubmitButton({
    super.key,
    required this.label,
    this.loadingLabel,
    required this.loading,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      loadingLabel ?? label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Fila "¿Pregunta? Acción" al pie de los formularios.
class AuthFooterLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback? onPressed;

  const AuthFooterLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}

/// Fila "Recordarme" + "¿Olvidaste tu contraseña?" (se acomoda si no entra).
class AuthRememberRow extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onForgot;

  const AuthRememberRow({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? () => onChanged(!value) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: value,
                  onChanged: enabled ? (v) => onChanged(v ?? true) : null,
                ),
                Text(t.commonRememberMe, softWrap: false),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: enabled ? onForgot : null,
          child: Text(t.authForgotPassword),
        ),
      ],
    );
  }
}

/// Formateador: solo dígitos.
final digitsOnly = FilteringTextInputFormatter.digitsOnly;
