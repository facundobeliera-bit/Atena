import 'package:flutter/material.dart';

/// Shared visual language. Contains no identity, routing or storage decisions.
abstract final class AtenaTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2454A4),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFA9C7FF) : const Color(0xFF2454A4),
          onPrimary: dark ? const Color(0xFF102B58) : Colors.white,
          secondary: dark ? const Color(0xFF72D9CF) : const Color(0xFF087E80),
          onSecondary: dark ? const Color(0xFF003735) : Colors.white,
          surface: dark ? const Color(0xFF142030) : const Color(0xFFF7F9FC),
          onSurface: dark ? const Color(0xFFE6EDF6) : const Color(0xFF192D46),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'PlusJakartaSans',
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
        space: 28,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: scheme.secondaryContainer.withValues(alpha: .45),
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1B2A3C) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1B2A3C) : Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AtenaWorkspace extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const AtenaWorkspace({super.key, required this.child, this.maxWidth = 1080});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.secondary.withValues(alpha: .07),
            cs.surface,
            cs.primary.withValues(alpha: .04),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class AtenaSectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  const AtenaSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.secondary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AtenaActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool prominent;
  final bool locked;
  final String? semanticsLabel;
  const AtenaActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.prominent = false,
    this.locked = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = prominent ? cs.primary : cs.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticsLabel,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: prominent ? .10 : .04),
                    Colors.transparent,
                  ],
                ),
                border: prominent
                    ? Border(left: BorderSide(color: accent, width: 4))
                    : null,
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: onTap == null ? cs.onSurfaceVariant : accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    locked ? Icons.lock_outline : Icons.arrow_forward_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AtenaLocalNotice extends StatelessWidget {
  const AtenaLocalNotice({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.devices_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Información de esta instalación. Los cambios de estos módulos todavía no se comparten entre dispositivos.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Fluid columns with natural heights: supports translated and enlarged text.
class AtenaResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  const AtenaResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 360,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns =
          (constraints.maxWidth / (minWidth * scale.clamp(1.0, 2.0)))
              .floor()
              .clamp(1, 3);
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class AtenaNavigationTile extends StatelessWidget {
  final Widget leading, title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  const AtenaNavigationTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(onTap == null ? Icons.lock_outline : Icons.chevron_right),
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class AtenaEmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const AtenaEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

/// Presentation only. Public terminology does not rename persisted enum values.
abstract final class AtenaOfferLabels {
  static const formal = 'Educación formal';
  static const activities = 'Actividades y formación';
  static const formalDescription =
      'Desde jardines y escuelas hasta institutos y universidades. Encontrá tu próximo lugar para aprender.';
  static const activitiesDescription =
      'Deportes, idiomas, arte, oficios y cursos para seguir aprendiendo.';
}

class AtenaWelcomeHero extends StatelessWidget {
  const AtenaWelcomeHero({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer.withValues(alpha: .55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ATENA',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Cinzel',
              letterSpacing: 4,
            ),
          ),
          const AtenaSectionHeader(
            eyebrow: 'Educación · Comunidad · Oportunidades',
            title: 'Tu próximo paso\nen educación.',
            subtitle:
                'Un lugar para descubrir propuestas, acompañar tu formación y organizar la vida de tu institución.',
          ),
          AtenaResponsiveGrid(
            minWidth: 350,
            children: [
              _OfferSummary(
                icon: Icons.school_outlined,
                title: AtenaOfferLabels.formal,
                description: AtenaOfferLabels.formalDescription,
              ),
              _OfferSummary(
                icon: Icons.auto_awesome_outlined,
                title: AtenaOfferLabels.activities,
                description: AtenaOfferLabels.activitiesDescription,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferSummary extends StatelessWidget {
  final IconData icon;
  final String title, description;
  const _OfferSummary({
    required this.icon,
    required this.title,
    required this.description,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(description),
    ],
  );
}
