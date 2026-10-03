// lib/screens/comunes/eliminar_cuenta_dialog.dart
//
// Confirmación para eliminar la cuenta: explica qué se borra y pide la
// contraseña. Devuelve true si la cuenta se eliminó.

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/auth_errors.dart';
import '../../ui/atena_labels.dart';

Future<bool> showEliminarCuentaDialog(
  BuildContext context, {
  required String descripcion,
  required Future<void> Function(String password) eliminar,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _EliminarCuentaDialog(descripcion: descripcion, eliminar: eliminar),
  );
  return ok == true;
}

class _EliminarCuentaDialog extends StatefulWidget {
  final String descripcion;
  final Future<void> Function(String password) eliminar;

  const _EliminarCuentaDialog({
    required this.descripcion,
    required this.eliminar,
  });

  @override
  State<_EliminarCuentaDialog> createState() => _EliminarCuentaDialogState();
}

class _EliminarCuentaDialogState extends State<_EliminarCuentaDialog> {
  final _password = TextEditingController();
  bool _oculta = true;
  bool _trabajando = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final t = AppLocalizations.of(context);
    if (_password.text.isEmpty) {
      setState(() => _error = t.commonPasswordRequired);
      return;
    }
    setState(() {
      _trabajando = true;
      _error = null;
    });
    try {
      await widget.eliminar(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _trabajando = false;
        _error = e is AuthException && e.code == AuthErrorCode.wrongCredentials
            ? t.deleteAccountWrongPassword
            : coreErrorText(t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: cs.error, size: 32),
      title: Text(t.deleteAccountTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.descripcion),
              const SizedBox(height: 10),
              Text(
                t.deleteAccountIrreversible,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _password,
                obscureText: _oculta,
                autofocus: true,
                enabled: !_trabajando,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirmar(),
                decoration: InputDecoration(
                  labelText: t.commonPassword,
                  helperText: t.deleteAccountPasswordHelper,
                  errorText: _error,
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    tooltip: _oculta
                        ? t.commonShowPassword
                        : t.commonHidePassword,
                    onPressed: () => setState(() => _oculta = !_oculta),
                    icon: Icon(
                      _oculta
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: _trabajando
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(t.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          onPressed: _trabajando ? null : _confirmar,
          child: _trabajando
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: cs.onError,
                  ),
                )
              : Text(t.deleteAccountConfirm),
        ),
      ],
    );
  }
}
