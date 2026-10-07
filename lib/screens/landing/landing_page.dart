import '../../ui/catalogo_publico.dart';
// Presentation refreshed without changing the existing session and navigation contract.

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../routes/atena_deeplink.dart';
import '../../services/cuenta_service.dart';
import '../../services/session_service.dart';
import '../../services/remote/atena_supabase_client.dart';
import '../../services/remote/multiuser_session.dart';
import '../../services/remote/pilot_remote_gateway.dart';
import '../../ui/atena_workspace.dart';

import '../auth/alumno_login_page.dart';
import '../auth/institucion_login_page.dart';
import '../cuentas/cuenta_home_page.dart';
import '../instituciones/institucion_menu_page.dart';
import '../pilot/pilot_remote_page.dart';

class LandingPage extends StatefulWidget {
  final Locale? locale;
  final ThemeMode themeMode;

  // ✅ Tipados correctamente (evita argument_type_not_assignable)
  final Future<void> Function(Locale? locale) onLocaleChanged;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;

  /// ✅ Opcional: deeplink raw (ej: "/calendario?perfilId=...&date=...").
  /// Si hay sesión, se pasa al Home como initialDeeplink.
  final String? deeplink;

  const LandingPage({
    super.key,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    this.deeplink,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late ThemeMode _selectedThemeMode;
  bool _booting = true;
  String? _errorBoot;

  // ✅ Hardening: evita doble pushReplacement por race
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.themeMode;

    // ignore: discarded_futures
    _boot();
  }

  // =====================================================
  // L10N SAFE (lookup best-effort)
  // =====================================================

  AppLocalizations? _tSafe(BuildContext context) {
    try {
      return Localizations.of<AppLocalizations>(context, AppLocalizations);
    } catch (_) {
      return null;
    }
  }

  String _l10n(AppLocalizations? t, String fallback) {
    if (t == null) return fallback;
    return fallback; // se reemplaza cuando estén los getters ARB
  }

  // Landing
  String _txtLandingStudents(AppLocalizations? t) => _l10n(t, 'Alumnos');
  String _txtLandingInstitutions(AppLocalizations? t) =>
      _l10n(t, 'Instituciones');
  // Theme / Language
  String _txtThemeSystem(AppLocalizations? t) => _l10n(t, 'Tema: Sistema');
  String _txtThemeLight(AppLocalizations? t) => _l10n(t, 'Tema: Claro');
  String _txtThemeDark(AppLocalizations? t) => _l10n(t, 'Tema: Oscuro');

  String _txtLanguageTooltip(AppLocalizations? t) => _l10n(t, 'Idioma');
  String _txtLanguageSystem(AppLocalizations? t) => _l10n(t, 'Sistema');
  String _txtLanguageEs(AppLocalizations? t) => _l10n(t, 'Español');
  String _txtLanguageEn(AppLocalizations? t) => _l10n(t, 'Inglés');
  String _txtLanguagePt(AppLocalizations? t) => _l10n(t, 'Português');

  String _txtInstitucionFallback(AppLocalizations? t) =>
      _l10n(t, 'Institución');

  // =====================================================
  // Deeplink canonical (fuente de verdad: AtenaDeeplink)
  // =====================================================

  String? _normalizeAllowedDeeplink(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;

    try {
      final dl = AtenaDeeplink.parse(s);

      // ✅ whitelist
      if (!(dl.isCalendario || dl.isDocumentos)) return null;

      // ✅ Siempre devolvemos ruta local canónica "/path?qp"
      final out = dl.toRouteString().trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _boot() async {
    if (MultiuserSession.enabled) {
      if (mounted) setState(() => _booting = false);
      return;
    }
    try {
      final session = await SessionService.getSession();
      final institutional = session?.role == SessionRole.institucion;
      final instOwner = institutional
          ? await SessionService.getInstitucionOwnerAccountIdLogueado()
          : null;
      final validInstitution =
          institutional &&
          instOwner != null &&
          await CuentaService.perfilInstitucionalPertenece(
            instOwner,
            session!.userId,
          );
      final cuentaId = session?.role == SessionRole.cuenta
          ? session!.userId
          : await CuentaService.getSesionCuentaId();
      final sid = (validInstitution ? instOwner : cuentaId)?.trim() ?? '';

      if (!mounted) return;

      if (sid.isNotEmpty) {
        final dl = _normalizeAllowedDeeplink(widget.deeplink);

        // ✅ HINT: si el role compat indica “institución”, vamos al HOME institucional
        final isInstRole = validInstitution;

        // ✅ Navegación segura post-frame (evita race en initState/build)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_navigated) return;
          _navigated = true;

          if (isInstRole) {
            // ✅ Evita la “pantalla azul” tipo selector de perfiles canónicos.
            // Best-effort: en prototipo legacy, instPerfilId suele coincidir con sid.
            final t = _tSafe(context);

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => InstitucionMenuPage(
                  ownerAccountId: instOwner,
                  institucionPerfilId: session.userId,
                  institucionNombre: _txtInstitucionFallback(t),
                ),
              ),
            );
            return;
          }

          // Default: gateway canónico de Cuenta (owner→perfiles)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  CuentaHomePage(cuentaId: sid, initialDeeplink: dl),
            ),
          );
        });

        // ✅ Hardening: si por algún motivo la navegación no ocurre,
        // liberamos el boot después de un breve lapso (evita “loader eterno”).
        Future<void>.delayed(const Duration(milliseconds: 900)).then((_) {
          if (!mounted) return;
          if (_navigated) return;
          setState(() {
            _booting = false;
            _errorBoot = null;
          });
        });

        // Mantener loader hasta navegar (evita flicker del menú)
        return;
      }

      // Sin sesión: mostrar menú normal
      setState(() {
        _booting = false;
        _errorBoot = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _booting = false;
        _errorBoot = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _cambiarIdioma(Locale? l) async {
    await widget.onLocaleChanged(l);
  }

  ThemeMode _nextThemeMode(ThemeMode current) {
    return switch (current) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  @override
  void didUpdateWidget(covariant LandingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _selectedThemeMode = widget.themeMode;
    }
  }

  Future<void> _cycleTema() async {
    // A pushed route retains its initial widget even when MaterialApp rebuilds.
    final next = _nextThemeMode(_selectedThemeMode);
    await widget.onThemeModeChanged(next);
    if (mounted) setState(() => _selectedThemeMode = next);
  }

  @override
  Widget build(BuildContext context) {
    final t = _tSafe(context);
    final cs = Theme.of(context).colorScheme;
    final deeplink = _normalizeAllowedDeeplink(widget.deeplink);
    final selectedLang = widget.locale?.languageCode ?? '';
    final themeTooltip = switch (_selectedThemeMode) {
      ThemeMode.system => _txtThemeSystem(t),
      ThemeMode.light => _txtThemeLight(t),
      ThemeMode.dark => _txtThemeDark(t),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ATENA',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
        actions: [
          IconButton(
            tooltip: themeTooltip,
            onPressed: _cycleTema,
            icon: Icon(switch (_selectedThemeMode) {
              ThemeMode.system => Icons.brightness_auto,
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
            }),
          ),
          PopupMenuButton<String>(
            tooltip: _txtLanguageTooltip(t),
            icon: const Icon(Icons.language),
            onSelected: (v) => _cambiarIdioma(v == 'system' ? null : Locale(v)),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'system',
                checked: selectedLang.isEmpty,
                child: Text(_txtLanguageSystem(t)),
              ),
              CheckedPopupMenuItem(
                value: 'es',
                checked: selectedLang == 'es',
                child: Text(_txtLanguageEs(t)),
              ),
              CheckedPopupMenuItem(
                value: 'en',
                checked: selectedLang == 'en',
                child: Text(_txtLanguageEn(t)),
              ),
              CheckedPopupMenuItem(
                value: 'pt',
                checked: selectedLang == 'pt',
                child: Text(_txtLanguagePt(t)),
              ),
            ],
          ),
        ],
      ),
      body: AtenaWorkspace(
        child: _booting
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    if (_errorBoot != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _errorBoot!,
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                      ),
                    const PortadaBuscadorPublico(),
                    const SizedBox(height: 28),
                    Text(
                      'Continuá con tu cuenta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          AtenaActionCard(
                            icon: Icons.school_rounded,
                            title: _txtLandingStudents(t),
                            subtitle:
                                'Encontrá instituciones, consultá actividades y seguí tus solicitudes.',
                            prominent: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AlumnoLoginPage(deeplink: deeplink),
                              ),
                            ),
                          ),
                          AtenaActionCard(
                            icon: Icons.account_balance_rounded,
                            title: _txtLandingInstitutions(t),
                            subtitle:
                                'Organizá tus áreas, vacantes, equipo y comunicaciones.',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InstitucionLoginPage(deeplink: deeplink),
                              ),
                            ),
                          ),
                        ];
                        if (constraints.maxWidth < 720) {
                          return Column(children: cards);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 20),
                            Expanded(child: cards[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    if (MultiuserSession.enabled)
                      const Text('Supabase compartido · Piloto de evaluación')
                    else
                      const AtenaLocalNotice(),
                    if (!MultiuserSession.enabled)
                      if (AtenaSupabaseClient.optionalClient case final client?)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PilotRemotePage(
                                  gateway: SupabasePilotRemoteGateway(client),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.science_outlined),
                            label: const Text('Abrir piloto remoto'),
                          ),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}
