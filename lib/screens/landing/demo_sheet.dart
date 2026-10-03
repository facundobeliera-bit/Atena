// lib/screens/landing/demo_sheet.dart
//
// Modo de ejemplo: carga datos de demostración y muestra las cuentas de prueba
// con accesos directos para entrar como familia o como institución.

import 'package:flutter/material.dart';

import '../../core/demo/demo_seeder.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../routes/atena_nav.dart';
import '../../services/auth_service.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';

/// Confirma, carga los datos de ejemplo y muestra las credenciales.
Future<void> iniciarModoDemo(BuildContext context) async {
  final t = AppLocalizations.of(context);
  final ok = await showAtenaConfirm(
    context,
    title: t.demoConfirmTitle,
    message: t.demoConfirmBody,
    confirmLabel: t.demoConfirmCta,
    icon: Icons.auto_awesome_rounded,
  );
  if (!ok || !context.mounted) return;

  final nav = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: AtenaLoading(label: AppLocalizations.of(ctx).demoLoading),
        ),
      ),
    ),
  );

  Object? error;
  var nuevos = false;
  try {
    nuevos = await DemoSeeder.cargar();
  } catch (e) {
    error = e;
  }
  nav.pop();
  if (!context.mounted) return;

  if (error != null) {
    AtenaFeedback.error(context, coreErrorText(t, error));
    return;
  }
  if (!nuevos) AtenaFeedback.info(context, t.demoAlreadyLoaded);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _DemoCredencialesSheet(),
  );
}

class _DemoCredencialesSheet extends StatefulWidget {
  const _DemoCredencialesSheet();

  @override
  State<_DemoCredencialesSheet> createState() => _DemoCredencialesSheetState();
}

class _DemoCredencialesSheetState extends State<_DemoCredencialesSheet> {
  bool _entrando = false;

  Future<void> _entrarFamilia() async {
    setState(() => _entrando = true);
    try {
      final cuenta = await AuthService.loginFamilia(
        email: DemoCredenciales.familia,
        password: DemoCredenciales.password,
        remember: true,
      );
      if (!mounted) return;
      await AtenaNav.toFamilia(context, cuenta.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _entrando = false);
      AtenaFeedback.error(
        context,
        coreErrorText(AppLocalizations.of(context), e),
      );
    }
  }

  Future<void> _entrarInstitucion() async {
    setState(() => _entrando = true);
    try {
      final sesion = await AuthService.loginInstitucion(
        email: DemoCredenciales.colegio,
        password: DemoCredenciales.password,
        remember: true,
      );
      if (!mounted) return;
      await AtenaNav.toInstitucion(context, sesion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _entrando = false);
      AtenaFeedback.error(
        context,
        coreErrorText(AppLocalizations.of(context), e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget cuenta(
      IconData icon,
      Color color,
      String titulo,
      List<String> emails,
    ) {
      return AtenaCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AtenaIconBadge(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final e in emails)
                    SelectableText(e, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AtenaAppIcon(size: 56)),
            const SizedBox(height: 16),
            Text(
              t.demoReadyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              t.demoReadyBody(DemoCredenciales.password),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            cuenta(
              Icons.family_restroom_rounded,
              AtenaColors.blue,
              t.demoFamilyLabel,
              const [DemoCredenciales.familia],
            ),
            const SizedBox(height: 10),
            cuenta(
              Icons.account_balance_rounded,
              AtenaColors.violet,
              t.demoInstitutionsLabel,
              const [
                DemoCredenciales.colegio,
                DemoCredenciales.jardin,
                DemoCredenciales.club,
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _entrando ? null : _entrarFamilia,
              icon: const Icon(Icons.school_rounded),
              label: Text(t.demoEnterFamily),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _entrando ? null : _entrarInstitucion,
              icon: const Icon(Icons.account_balance_rounded),
              label: Text(t.demoEnterInstitution),
            ),
          ],
        ),
      ),
    );
  }
}
