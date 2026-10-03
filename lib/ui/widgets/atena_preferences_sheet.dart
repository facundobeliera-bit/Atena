// lib/ui/widgets/atena_preferences_sheet.dart
//
// Hoja de preferencias (tema e idioma), disponible desde cualquier pantalla.

import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../routes/atena_nav.dart';
import '../../services/app_settings_controller.dart';
import '../../services/app_settings_service.dart';
import 'atena_feedback.dart';
import 'atena_logo.dart';

Future<void> showAtenaPreferencesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PreferencesSheet(),
  );
}

/// Botón estándar para abrir las preferencias desde una AppBar.
class AtenaPreferencesButton extends StatelessWidget {
  const AtenaPreferencesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return IconButton(
      tooltip: t.prefsTitle,
      icon: const Icon(Icons.tune_rounded),
      onPressed: () => showAtenaPreferencesSheet(context),
    );
  }
}

class _PreferencesSheet extends StatelessWidget {
  const _PreferencesSheet();

  Future<void> _borrarDatos(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.prefsDeleteDataConfirmTitle,
      message: t.prefsDeleteDataConfirm,
      confirmLabel: t.prefsDeleteDataCta,
      destructive: true,
      icon: Icons.delete_forever_rounded,
    );
    if (!ok || !context.mounted) return;

    final settings = AppSettingsController.instance;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await AtenaStore.instance.borrarTodo();
    // Las preferencias de idioma y tema se conservan.
    await AppSettingsService.saveLocale(settings.locale);
    await AppSettingsService.saveThemeMode(settings.themeMode);
    if (!context.mounted) return;
    await AtenaNav.toLanding(context);
    messenger?.showSnackBar(SnackBar(content: Text(t.prefsDeleteDataDone)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = AppSettingsController.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final code = settings.locale?.languageCode ?? '';
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.prefsTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 20),
                Text(t.prefsTheme, style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, c) {
                    // En pantallas angostas, sin íconos para que entren los textos.
                    final conIconos = c.maxWidth >= 440;
                    return SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: conIconos
                                ? const Icon(Icons.brightness_auto_rounded)
                                : null,
                            label: Text(t.prefsThemeSystem, softWrap: false),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: conIconos
                                ? const Icon(Icons.light_mode_rounded)
                                : null,
                            label: Text(t.prefsThemeLight, softWrap: false),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: conIconos
                                ? const Icon(Icons.dark_mode_rounded)
                                : null,
                            label: Text(t.prefsThemeDark, softWrap: false),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (s) =>
                            settings.setThemeMode(s.first),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(t.prefsLanguage, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                RadioGroup<String>(
                  groupValue: code,
                  onChanged: (v) =>
                      settings.setLocale((v ?? '').isEmpty ? null : Locale(v!)),
                  child: Column(
                    children: [
                      _LangOption(value: '', label: t.prefsLanguageSystem),
                      const _LangOption(value: 'es', label: 'Español'),
                      const _LangOption(value: 'en', label: 'English'),
                      const _LangOption(value: 'pt', label: 'Português'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(t.prefsAbout, style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const AtenaMark(size: 36),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AtenaWordmark(fontSize: 16),
                        const SizedBox(height: 4),
                        Text(
                          t.prefsVersion(kAtenaVersion),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(t.prefsPrivacyTitle),
                    children: [
                      Text(
                        t.prefsPrivacyBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _borrarDatos(context),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: Text(t.prefsDeleteData),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LangOption extends StatelessWidget {
  final String value;
  final String label;

  const _LangOption({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(label),
    );
  }
}
