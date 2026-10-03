// lib/ui/widgets/atena_states.dart
//
// Estados de pantalla: cargando, vacío, error y banners de aviso.

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/atena_colors.dart';
import '../theme/atena_theme.dart';
import '../theme/atena_tokens.dart';

class AtenaLoading extends StatelessWidget {
  final String? label;

  const AtenaLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = (label ?? '').trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AtenaSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3.2),
            ),
            if (l.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AtenaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  const AtenaEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final msg = (message ?? '').trim();
    final size = compact ? 64.0 : 88.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AtenaSpace.xl,
            vertical: compact ? AtenaSpace.lg : AtenaSpace.huge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      cs.primaryContainer.withValues(alpha: 0.45),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: size * 0.46,
                  color: cs.onPrimaryContainer,
                ),
              ),
              SizedBox(height: compact ? 14 : 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (msg.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class AtenaErrorState extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;

  const AtenaErrorState({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AtenaEmptyState(
      icon: Icons.cloud_off_rounded,
      title: title ?? t.uiSomethingWentWrong,
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.retry),
            ),
    );
  }
}

enum AtenaBannerTone { info, success, warning, error }

class AtenaBanner extends StatelessWidget {
  final AtenaBannerTone tone;
  final String message;
  final String? title;
  final Widget? action;
  final IconData? icon;

  const AtenaBanner({
    super.key,
    this.tone = AtenaBannerTone.info,
    required this.message,
    this.title,
    this.action,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = AtenaBrand.of(context);
    final base = switch (tone) {
      AtenaBannerTone.info => brand.info,
      AtenaBannerTone.success => brand.success,
      AtenaBannerTone.warning => brand.warning,
      AtenaBannerTone.error => theme.colorScheme.error,
    };
    final t = AtenaTone.of(context, base);
    final ic =
        icon ??
        switch (tone) {
          AtenaBannerTone.info => Icons.info_outline_rounded,
          AtenaBannerTone.success => Icons.check_circle_outline_rounded,
          AtenaBannerTone.warning => Icons.warning_amber_rounded,
          AtenaBannerTone.error => Icons.error_outline_rounded,
        };
    final ttl = (title ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: base.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ic, color: t.foreground, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ttl.isNotEmpty) ...[
                  Text(
                    ttl,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: t.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.foreground,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
