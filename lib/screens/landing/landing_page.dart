// lib/screens/landing/landing_page.dart
//
// ATENA – Bienvenida.
// Presenta la marca y deja elegir cómo ingresar: alumno/familia o institución.
// La sesión activa la resuelve el arranque (main.dart); acá no hay redirecciones.

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_ui.dart';
import '../../ui/widgets/atena_preferences_sheet.dart';
import '../auth/alumno_login_page.dart';
import '../auth/institucion_login_page.dart';
import 'demo_sheet.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  /// En una instalación nueva (sin instituciones) se ofrece el modo de ejemplo.
  bool _ofrecerDemo = false;

  @override
  void initState() {
    super.initState();
    _verificarDemo();
  }

  Future<void> _verificarDemo() async {
    try {
      final instituciones = await InstitucionesRepo.instance.listar();
      if (!mounted) return;
      setState(() => _ofrecerDemo = instituciones.isEmpty);
    } catch (_) {}
  }

  Future<void> _demo() async {
    await iniciarModoDemo(context);
    if (mounted) await _verificarDemo();
  }

  void _openAlumno(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlumnoLoginPage(deeplink: null)),
    );
  }

  void _openInstitucion(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InstitucionLoginPage(deeplink: null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AtenaLayout.isDesktop(context);

    return AtenaScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: desktop ? null : const SizedBox.shrink(),
        actions: const [AtenaPreferencesButton(), SizedBox(width: 8)],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: desktop
            ? _DesktopLayout(
                onAlumno: () => _openAlumno(context),
                onInstitucion: () => _openInstitucion(context),
                onDemo: _ofrecerDemo ? _demo : null,
              )
            : _PhoneLayout(
                onAlumno: () => _openAlumno(context),
                onInstitucion: () => _openInstitucion(context),
                onDemo: _ofrecerDemo ? _demo : null,
              ),
      ),
    );
  }
}

/// Enlace discreto para cargar datos de ejemplo.
class _DemoLink extends StatelessWidget {
  final VoidCallback onTap;

  const _DemoLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
      label: Text(t.demoLink),
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  final VoidCallback onAlumno;
  final VoidCallback onInstitucion;
  final VoidCallback? onDemo;

  const _PhoneLayout({
    required this.onAlumno,
    required this.onInstitucion,
    this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AtenaAppIcon(size: 84),
                    const SizedBox(height: 22),
                    const AtenaWordmark(fontSize: 34),
                    const SizedBox(height: 10),
                    Text(
                      t.landingTagline.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2.4,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      t.landingHeadline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t.landingSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _RoleCard(
                      role: AtenaRole.alumno,
                      icon: Icons.school_rounded,
                      title: t.landingStudentTitle,
                      subtitle: t.landingStudentSubtitle,
                      onTap: onAlumno,
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      role: AtenaRole.institucion,
                      icon: Icons.account_balance_rounded,
                      title: t.landingInstitutionTitle,
                      subtitle: t.landingInstitutionSubtitle,
                      onTap: onInstitucion,
                    ),
                    if (onDemo != null) ...[
                      const SizedBox(height: 12),
                      _DemoLink(onTap: onDemo!),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      t.landingFooter(DateTime.now().year.toString()),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final VoidCallback onAlumno;
  final VoidCallback onInstitucion;
  final VoidCallback? onDemo;

  const _DesktopLayout({
    required this.onAlumno,
    required this.onInstitucion,
    this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: AtenaGradientPanel(
                    padding: const EdgeInsets.fromLTRB(44, 44, 44, 40),
                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            AtenaMark(size: 52, color: Colors.white),
                            SizedBox(width: 14),
                            AtenaWordmark(fontSize: 30, color: Colors.white),
                          ],
                        ),
                        const SizedBox(height: 56),
                        Text(
                          t.landingHeadline,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.landingSubtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 36),
                        _Bullet(
                          icon: Icons.how_to_reg_rounded,
                          text: t.landingBulletRequests,
                        ),
                        _Bullet(
                          icon: Icons.picture_as_pdf_rounded,
                          text: t.landingBulletDocuments,
                        ),
                        _Bullet(
                          icon: Icons.event_available_rounded,
                          text: t.landingBulletCalendar,
                        ),
                        const Spacer(),
                        const SizedBox(height: 28),
                        Text(
                          t.landingFooter(DateTime.now().year.toString()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.landingChooseHowToEnter,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.landingChooseHowToEnterSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _RoleCard(
                        role: AtenaRole.alumno,
                        icon: Icons.school_rounded,
                        title: t.landingStudentTitle,
                        subtitle: t.landingStudentSubtitle,
                        onTap: onAlumno,
                        large: true,
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        role: AtenaRole.institucion,
                        icon: Icons.account_balance_rounded,
                        title: t.landingInstitutionTitle,
                        subtitle: t.landingInstitutionSubtitle,
                        onTap: onInstitucion,
                        large: true,
                      ),
                      if (onDemo != null) ...[
                        const SizedBox(height: 16),
                        _DemoLink(onTap: onDemo!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final AtenaRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool large;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return AtenaRoleTheme(
      role: role,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          final gradient = AtenaColors.roleGradient(role);

          return Semantics(
            button: true,
            child: AtenaCard(
              onTap: onTap,
              padding: EdgeInsets.all(large ? 22 : 18),
              child: Row(
                children: [
                  Container(
                    width: large ? 60 : 52,
                    height: large ? 60 : 52,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(large ? 18 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: large ? 30 : 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: large
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
