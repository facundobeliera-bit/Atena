// lib/ui/widgets/atena_feedback.dart
//
// Mensajes breves (snackbars), confirmaciones y chips de estado.

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/atena_colors.dart';
import '../theme/atena_theme.dart';

enum AtenaFeedbackKind { info, success, error }

class AtenaFeedback {
  const AtenaFeedback._();

  static void show(
    BuildContext context,
    String message, {
    AtenaFeedbackKind kind = AtenaFeedbackKind.info,
    SnackBarAction? action,
  }) {
    final msg = message.trim();
    if (msg.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final brand = AtenaBrand.of(context);
    final (icon, color) = switch (kind) {
      AtenaFeedbackKind.success => (Icons.check_circle_rounded, brand.success),
      AtenaFeedbackKind.error => (Icons.error_rounded, theme.colorScheme.error),
      AtenaFeedbackKind.info => (
        Icons.info_rounded,
        theme.colorScheme.inversePrimary,
      ),
    };

    final width = MediaQuery.sizeOf(context).width;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          width: width > 640 ? 480 : null,
          action: action,
          content: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(msg)),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, kind: AtenaFeedbackKind.success);

  static void error(BuildContext context, String message) =>
      show(context, message, kind: AtenaFeedbackKind.error);

  static void info(BuildContext context, String message) =>
      show(context, message, kind: AtenaFeedbackKind.info);
}

/// Limpia un error para mostrarlo al usuario (sin "Exception:" ni trazas).
String atenaErrorText(Object error) {
  var s = error.toString().trim();
  for (final p in const ['Exception: ', 'Bad state: ', 'FormatException: ']) {
    if (s.startsWith(p)) s = s.substring(p.length);
  }
  final nl = s.indexOf('\n');
  if (nl > 0) s = s.substring(0, nl);
  return s.trim();
}

/// Diálogo de confirmación. Devuelve true si el usuario confirma.
Future<bool> showAtenaConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final t = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final accent = destructive ? cs.error : cs.primary;
      return AlertDialog(
        icon: icon == null ? null : Icon(icon, color: accent, size: 30),
        title: Text(title),
        content: (message ?? '').trim().isEmpty ? null : Text(message!.trim()),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? t.commonCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel ?? t.commonConfirm),
          ),
        ],
      );
    },
  );
  return result == true;
}

/// Chip de estado (pendiente, aceptada, rechazada…).
class AtenaStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  const AtenaStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = AtenaTone.of(context, color);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 13 : 15, color: tone.foreground),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: tone.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 11.5 : 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colores estándar para estados de trámites.
class AtenaStatusColors {
  const AtenaStatusColors._();

  static const Color pending = AtenaColors.warning;
  static const Color inReview = AtenaColors.info;
  static const Color approved = AtenaColors.success;
  static const Color rejected = AtenaColors.danger;
  static const Color cancelled = AtenaColors.neutral;
}
