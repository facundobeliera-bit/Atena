// lib/screens/landing/landing_page.dart
//
// ATENA – LANDING (pantalla inicial real post-splash)
//
// ✅ BOOT real (enero 2026):
// - Si existe sesión canónica de Cuenta (sesion_cuenta), redirige a CuentaHomePage.
// - Si NO hay sesión, muestra menú Alumno / Institución.
// - Soporte opcional de deeplink: si viene "/calendario?..." o "/documentos?...",
//   se pasa a CuentaHomePage(initialDeeplink: ...).
//
// ✅ AJUSTE CLAVE (FASE 2 · INSTITUCIONES):
// - Si la sesión activa es de “Institución” (role compat), NO pasa por CuentaHomePage.
//   Entra directo al HOME institucional (InstitucionMenuPage) para evitar la pantalla azul
//   tipo “selector de perfiles canónicos” (que es de Alumno/Cuenta).
//
// Blindaje (enero 2026):
// - NO crashea si faltan assets: usa errorBuilder (muestra placeholder + texto).
// - Evita "pantalla roja" por assets faltantes, para poder seguir probando flujo.
// - ✅ AppLocalizations SAFE: lookup best-effort (evita crash si faltan delegates).
// - Callbacks tipados Future<void> y wrappers async para evitar errores de asignación.
//
// ✅ FIX (enero 2026) – CANÓNICO:
// - Landing NO re-parsea deeplink con lógica propia.
// - Usa AtenaDeeplink.parse() como fuente de verdad (mismo parser del Router).
// - Whitelist: solo /calendario y /documentos.
//
// ✅ CIERRE ESTÉTICO (enero 2026):
// - Background wrapper alineado a Login/CuentaHome/Area:
//   bgLandingAtena + overlay + highlightGlow (best-effort, con errorBuilder).
// - Loader de boot también respeta el fondo.
//
// ✅ HARDENING (fase 2):
// - Toggle de tema: ciclo system → light → dark (no “pierde” system).
// - UI usa “isDark efectivo” (no confundir ThemeMode.system con brillo real).
// - Menú de idioma: marca el seleccionado (y system).
// - Consistencia: gradientes/alphas basados en brillo real del theme.
//
// ✅ Ajuste clave Fase 2 (global config):
// - Institución: también recibe deeplink normalizado, igual que Alumno.
// - Boot: evita doble navegación (guard con flag).
// - Mantiene todo canónico y tolerante.
//
// ✅ AJUSTE UI (enero 2026) – BOTONES REUBICADOS:
// - Título ATENA grande centrado.
// - Botones “Alumnos / Instituciones” en layout 2 columnas (izq/der).

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../routes/atena_deeplink.dart';
import '../../services/cuenta_service.dart';
import '../../services/session_service.dart';
import '../../ui/atena_assets.dart';

import '../auth/alumno_login_page.dart';
import '../auth/institucion_login_page.dart';
import '../cuentas/cuenta_home_page.dart';
import '../instituciones/institucion_menu_page.dart';

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
  bool _booting = true;
  String? _errorBoot;

  // ✅ Hardening: evita doble pushReplacement por race
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Precache best-effort del fondo (no bloqueante)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.bgLandingAtena)),
          context,
        );
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow)),
          context,
        );
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.iconWhite)),
          context,
        );
      } catch (_) {
        // NO-OP
      }
    });

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
  String _txtLandingEnter(AppLocalizations? t) => _l10n(t, 'Ingresar');

  String _txtLandingHeadingStudents(AppLocalizations? t) => _l10n(t, 'alumnos');
  String _txtLandingHeadingInstitutions(AppLocalizations? t) =>
      _l10n(t, 'instituciones');

  // Theme / Language
  String _txtThemeSystem(AppLocalizations? t) => _l10n(t, 'Tema: Sistema');
  String _txtThemeLight(AppLocalizations? t) => _l10n(t, 'Tema: Claro');
  String _txtThemeDark(AppLocalizations? t) => _l10n(t, 'Tema: Oscuro');

  String _txtLanguageTooltip(AppLocalizations? t) => _l10n(t, 'Idioma');
  String _txtLanguageSystem(AppLocalizations? t) => _l10n(t, 'Sistema');
  String _txtLanguageEs(AppLocalizations? t) => _l10n(t, 'Español');
  String _txtLanguageEn(AppLocalizations? t) => _l10n(t, 'Inglés');
  String _txtLanguagePt(AppLocalizations? t) => _l10n(t, 'Português');

  // Assets
  String _txtAssetMissing(AppLocalizations? t, String path) =>
      _l10n(t, 'ASSET FALTANTE:\n$path');

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

  Future<bool> _isInstitucionRoleHint() async {
    try {
      return await SessionService.isRole(SessionRole.institucion);
    } catch (_) {
      return false;
    }
  }

  Future<void> _boot() async {
    try {
      final cuentaId = await CuentaService.getSesionCuentaId();
      final sid = (cuentaId ?? '').trim();

      if (!mounted) return;

      if (sid.isNotEmpty) {
        final dl = _normalizeAllowedDeeplink(widget.deeplink);

        // ✅ HINT: si el role compat indica “institución”, vamos al HOME institucional
        final isInstRole = await _isInstitucionRoleHint();

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
                  ownerAccountId: sid,
                  institucionPerfilId: sid,
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

  Future<void> _cycleTema() async {
    final next = _nextThemeMode(widget.themeMode);
    await widget.onThemeModeChanged(next);
  }

  bool _isDarkEffective(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  int _alphaFromOpacity(double v) {
    final x = (v * 255).round();
    if (x < 0) return 0;
    if (x > 255) return 255;
    return x;
  }

  Widget _assetImageSafe(
    BuildContext context,
    String path, {
    BoxFit? fit,
    double? width,
    double? height,
    FilterQuality filterQuality = FilterQuality.low,
  }) {
    final safePath = AtenaAssets.ensureCanonical(path);

    return Image.asset(
      safePath,
      fit: fit,
      width: width,
      height: height,
      filterQuality: filterQuality,
      errorBuilder: (context, error, stack) {
        final t = _tSafe(context);
        final cs = Theme.of(context).colorScheme;

        return Container(
          color: cs.scrim.withAlpha(_alphaFromOpacity(0.22)),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          child: Text(
            _txtAssetMissing(t, safePath),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // UI – Background wrapper (alineado a Login/CuentaHome/Area)
  // =====================================================
  Widget _buildBackground(BuildContext context, Widget child) {
    final isDark = _isDarkEffective(context);
    final overlayAlpha = _alphaFromOpacity(isDark ? 0.22 : 0.06);
    final cs = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        _assetImageSafe(context, AtenaAssets.bgLandingAtena, fit: BoxFit.cover),
        Container(color: cs.scrim.withAlpha(overlayAlpha)),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.35 : 0.20,
              child: _assetImageSafe(
                context,
                AtenaAssets.highlightGlow,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _tSafe(context);
    final isDark = _isDarkEffective(context);
    final cs = Theme.of(context).colorScheme;

    // ✅ Boot screen con fondo (no queda “vacío”)
    if (_booting) {
      return Scaffold(
        body: _buildBackground(
          context,
          const SafeArea(child: Center(child: CircularProgressIndicator())),
        ),
      );
    }

    final aTop = _alphaFromOpacity(isDark ? 0.35 : 0.18);
    final aBottom = _alphaFromOpacity(isDark ? 0.55 : 0.28);

    final ingresar = _txtLandingEnter(t);

    // ✅ Deeplink normalizado (solo si es /calendario o /documentos)
    final deeplink = _normalizeAllowedDeeplink(widget.deeplink);

    final selectedLang = (widget.locale?.languageCode ?? '')
        .trim()
        .toLowerCase();
    final useSystemLocale = selectedLang.isEmpty;

    String themeTooltip;
    switch (widget.themeMode) {
      case ThemeMode.system:
        themeTooltip = _txtThemeSystem(t);
        break;
      case ThemeMode.light:
        themeTooltip = _txtThemeLight(t);
        break;
      case ThemeMode.dark:
        themeTooltip = _txtThemeDark(t);
        break;
    }

    IconData themeIcon;
    switch (widget.themeMode) {
      case ThemeMode.system:
        themeIcon = Icons.brightness_auto;
        break;
      case ThemeMode.light:
        themeIcon = Icons.light_mode;
        break;
      case ThemeMode.dark:
        themeIcon = Icons.dark_mode;
        break;
    }

    return Scaffold(
      body: _buildBackground(
        context,
        Stack(
          fit: StackFit.expand,
          children: [
            // Gradiente más dramático: transparente arriba, sólido abajo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    cs.scrim.withAlpha(_alphaFromOpacity(isDark ? 0.10 : 0.04)),
                    cs.scrim.withAlpha(_alphaFromOpacity(isDark ? 0.38 : 0.18)),
                    cs.scrim.withAlpha(_alphaFromOpacity(isDark ? 0.75 : 0.50)),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // TOP BAR (iconos tema + idioma)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        const Spacer(),
                        IconButton(
                          tooltip: themeTooltip,
                          onPressed: _cycleTema,
                          icon: Icon(themeIcon, color: cs.onSurface),
                        ),
                        PopupMenuButton<String>(
                          tooltip: _txtLanguageTooltip(t),
                          onSelected: (v) async {
                            if (v == 'system') {
                              await _cambiarIdioma(null);
                            } else {
                              await _cambiarIdioma(Locale(v));
                            }
                          },
                          itemBuilder: (_) => [
                            CheckedPopupMenuItem(
                              value: 'system',
                              checked: useSystemLocale,
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.language, color: cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorBoot != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: cs.errorContainer.withAlpha(
                            _alphaFromOpacity(isDark ? 0.28 : 0.22),
                          ),
                          border: Border.all(
                            color: cs.onErrorContainer.withAlpha(
                              _alphaFromOpacity(0.18),
                            ),
                          ),
                        ),
                        child: Text(
                          _errorBoot!,
                          style: TextStyle(color: cs.onErrorContainer),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // CONTENIDO CENTRAL (ATENA centrado)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícono con glow
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withAlpha(
                                    _alphaFromOpacity(isDark ? 0.45 : 0.30),
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                              gradient: RadialGradient(
                                colors: [
                                  cs.primary.withAlpha(
                                    _alphaFromOpacity(isDark ? 0.22 : 0.14),
                                  ),
                                  cs.primary.withAlpha(0),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Opacity(
                                opacity: isDark ? 0.90 : 0.95,
                                child: _assetImageSafe(
                                  context,
                                  AtenaAssets.iconWhite,
                                  width: 54,
                                  height: 54,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Título principal con estilo refinado
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cs.onSurface,
                                cs.onSurface.withAlpha(
                                  _alphaFromOpacity(isDark ? 0.70 : 0.80),
                                ),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'ATENA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 10.0,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Línea decorativa
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 1,
                                color: cs.onSurface.withAlpha(
                                  _alphaFromOpacity(0.30),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Plataforma educativa',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurface.withAlpha(
                                    _alphaFromOpacity(isDark ? 0.55 : 0.65),
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 32,
                                height: 1,
                                color: cs.onSurface.withAlpha(
                                  _alphaFromOpacity(0.30),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // BOTONES REUBICADOS (2 columnas) — mejorados
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _LandingColumn(
                            title: _txtLandingHeadingStudents(t),
                            buttonTitle: _txtLandingStudents(t),
                            subtitle: ingresar,
                            icon: Icons.school_rounded,
                            isPrimary: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AlumnoLoginPage(deeplink: deeplink),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _LandingColumn(
                            title: _txtLandingHeadingInstitutions(t),
                            buttonTitle: _txtLandingInstitutions(t),
                            subtitle: ingresar,
                            icon: Icons.account_balance_rounded,
                            isPrimary: false,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      InstitucionLoginPage(deeplink: deeplink),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingColumn extends StatelessWidget {
  final String title;
  final String buttonTitle;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _LandingColumn({
    required this.title,
    required this.buttonTitle,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  int _alphaFromOpacity(double v) {
    final x = (v * 255).round();
    if (x < 0) return 0;
    if (x > 255) return 255;
    return x;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final cardBg = isPrimary
        ? cs.primary.withAlpha(_alphaFromOpacity(isDark ? 0.28 : 0.22))
        : cs.surface.withAlpha(_alphaFromOpacity(isDark ? 0.18 : 0.14));
    final borderColor = isPrimary
        ? cs.primary.withAlpha(_alphaFromOpacity(isDark ? 0.55 : 0.45))
        : cs.onSurface.withAlpha(_alphaFromOpacity(0.18));
    final iconBg = isPrimary
        ? cs.primary.withAlpha(_alphaFromOpacity(isDark ? 0.35 : 0.25))
        : cs.onSurface.withAlpha(_alphaFromOpacity(0.08));
    final iconColor = isPrimary
        ? (isDark ? cs.primaryContainer : cs.primary)
        : cs.onSurface.withAlpha(_alphaFromOpacity(0.75));
    final labelColor = isPrimary
        ? (isDark ? cs.primaryContainer : cs.primary)
        : cs.onSurface.withAlpha(_alphaFromOpacity(0.90));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface.withAlpha(_alphaFromOpacity(0.50)),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: buttonTitle,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: cardBg,
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: (isPrimary ? cs.primary : cs.scrim).withAlpha(
                        _alphaFromOpacity(isDark ? 0.18 : 0.10),
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBg,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      buttonTitle,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: cs.onSurface.withAlpha(
                              _alphaFromOpacity(isDark ? 0.50 : 0.55),
                            ),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: cs.onSurface.withAlpha(
                            _alphaFromOpacity(isDark ? 0.45 : 0.50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/*
✅ NOTA:
- FIX aplicado: se eliminó el parámetro inexistente `institucionId` al construir InstitucionMenuPage.
  Ahora se usa el constructor canónico: (ownerAccountId + institucionPerfilId + institucionNombre).
*/
