// lib/screens/auth/institucion_registro_page.dart
//
// ATENA – INSTITUCIÓN REGISTRO (FASE 2, CANÓNICO)
// -----------------------------------------------------------------------------
// Fase 2:
// - Registro institucional (datos básicos + ubicación + acceso/contacto).
// - La selección de ACTIVIDADES/MÓDULOS se gestiona en InstitucionPlanPage.
// - Persistencia/commit ocurre SOLO en InstitucionPlanPage (evita duplicación).
//
// ✅ CAMBIO (feb 2026 · request):
// - Se eliminan del registro:
//   • TipoInstitucion (dropdown)
//   • ModalidadCursado (dropdown)
//   • Selección de módulos (niveles curriculares + bloques extracurriculares)
// - El draft navega a PlanPage con selecciones vacías y defaults razonables.
//
// -----------------------------------------------------------------------------
// NOTAS:
// - Background theme-driven (ColorScheme).
// - i18n vía AppLocalizations (ARB-ready). Si faltan keys, agregarlas al final.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../models/instituciones/instituciones_integrado.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart'; // ✅ FIX: tipo correcto
import '../../ui/atena_assets.dart';

import '../instituciones/institucion_plan_page.dart';

// ✅ FIX (Flutter nuevo): withValues(alpha: ...) espera double 0..1, no int 0..255.
Color _withOpacitySafe(Color c, double opacity01) {
  final o = opacity01.clamp(0.0, 1.0);
  return c.withValues(alpha: o);
}

class InstitucionRegistroPage extends StatefulWidget {
  const InstitucionRegistroPage({super.key});

  @override
  State<InstitucionRegistroPage> createState() =>
      _InstitucionRegistroPageState();
}

class _InstitucionRegistroPageState extends State<InstitucionRegistroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _cuitCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  // 📍 Ubicación (canónica)
  final _paisCtrl = TextEditingController(text: 'Argentina');
  final _provinciaCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();

  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _cargando = false;
  bool _ocultarPass = true;

  static const int _minPassLen = 4;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      try {
        // ignore: discarded_futures
        precacheImage(
          AssetImage(
            AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionHome),
          ),
          context,
        );
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow)),
          context,
        );
      } catch (_) {
        // NO-OP
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cuitCtrl.dispose();
    _direccionCtrl.dispose();
    _paisCtrl.dispose();
    _provinciaCtrl.dispose();
    _ciudadCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ----------------------------
  // Helpers / validaciones
  // ----------------------------

  String _soloDigitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
  String _normEmail(String s) => s.trim().toLowerCase();

  bool _emailBasicoValido(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) {
      return false;
    }
    final at = e.indexOf('@');
    if (at <= 0 || at == e.length - 1) {
      return false;
    }
    final dot = e.lastIndexOf('.');
    if (dot <= at + 1 || dot == e.length - 1) {
      return false;
    }
    return true;
  }

  bool _cuitValidoBasico(String raw) {
    final d = _soloDigitos(raw);
    // Argentina CUIT: 11 dígitos (validación simple; checksum se puede agregar luego)
    return d.length == 11;
  }

  bool _telefonoValidoBasico(String raw) {
    final d = _soloDigitos(raw);
    // rango “humano” (incluye 10-13 por +54 + área + número)
    return d.length >= 8 && d.length <= 15;
  }

  void _snack(String msg) {
    if (!mounted) {
      return;
    }
    final clean = msg.trim();
    if (clean.isEmpty) {
      return;
    }
    try {
      final m = ScaffoldMessenger.of(context);
      m.hideCurrentSnackBar();
      m.showSnackBar(SnackBar(content: Text(clean)));
    } catch (_) {
      // NO-OP
    }
  }

  // ----------------------------
  // Continuar → Plan
  // ----------------------------

  Future<void> _continuarAPlan() async {
    if (_cargando) {
      return;
    }

    final t = AppLocalizations.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    // Cerrar autofill context (iOS/Android) best-effort.
    try {
      TextInput.finishAutofillContext();
    } catch (_) {
      // NO-OP
    }

    // ✅ Selecciones de módulos se hacen en PlanPage.
    //    Dejamos defaults razonables para no romper el modelo.
    final draft = InstitucionRegistroDraft(
      nombre: _nombreCtrl.text.trim(),
      cuit: _cuitCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      pais: _paisCtrl.text.trim().isEmpty ? 'Argentina' : _paisCtrl.text.trim(),
      provincia: _provinciaCtrl.text.trim(),
      ciudad: _ciudadCtrl.text.trim(),
      modalidad: ModalidadCursado.presencial, // default (UI lo eliminó)
      email: _normEmail(_emailCtrl.text),
      telefono: _telefonoCtrl.text.trim(),
      pass: _passCtrl.text.trim(),
      tipo: TipoInstitucion.otra, // default (UI lo eliminó)
      nivelesSeleccionados: const <NivelCurricular>[], // se elige en Plan
      bloquesSeleccionados: const <BloqueExtracurricular>[], // se elige en Plan
    );

    if (!mounted) {
      return;
    }
    setState(() => _cargando = true);

    try {
      final nav = Navigator.of(context);
      await nav.push(
        MaterialPageRoute(
          builder: (BuildContext ctx) => InstitucionPlanPage(draft: draft),
        ),
      );
    } catch (_) {
      _snack(t.commonError);
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // ----------------------------
  // UI helpers
  // ----------------------------

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        text,
        style:
            theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ) ??
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Widget _buildBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final overlayColor = _withOpacitySafe(cs.scrim, isDark ? 0.28 : 0.06);

    Widget bgFallback() => Container(color: cs.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionHome),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (BuildContext ctx, Object err, StackTrace? stk) =>
              bgFallback(),
        ),
        Container(color: overlayColor),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.35 : 0.20,
              child: Image.asset(
                AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (BuildContext ctx, Object err, StackTrace? stk) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  // ----------------------------
  // UI
  // ----------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = _withOpacitySafe(cs.surface, isDark ? 0.86 : 0.94);
    final border = _withOpacitySafe(cs.outlineVariant, isDark ? 0.35 : 0.40);

    final transparentSurface = _withOpacitySafe(cs.surface, 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.institucionRegistroAppBar),
        backgroundColor: transparentSurface,
        surfaceTintColor: transparentSurface,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _buildBackground(
        context,
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Material(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t.institucionRegistroIntro,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _sectionTitle(
                              context,
                              t.institucionRegistroSectionBasics,
                            ),
                            TextFormField(
                              controller: _nombreCtrl,
                              enabled: !_cargando,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(
                                t.institucionRegistroInstitutionName,
                              ),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return t.commonFieldRequired;
                                }
                                if (s.length < 3) {
                                  return t.commonTooShort;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cuitCtrl,
                              enabled: !_cargando,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _dec(t.institucionRegistroCuit),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return t.commonFieldRequired;
                                }
                                if (!_cuitValidoBasico(s)) {
                                  return t.institucionRegistroCuitInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _direccionCtrl,
                              enabled: !_cargando,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(t.institucionRegistroAddress),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return t.commonFieldRequired;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),
                            _sectionTitle(
                              context,
                              t.institucionRegistroSectionLocation,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _paisCtrl,
                                    enabled: !_cargando,
                                    textInputAction: TextInputAction.next,
                                    decoration: _dec(
                                      t.institucionRegistroCountry,
                                    ),
                                    validator: (v) {
                                      final s = (v ?? '').trim();
                                      if (s.isEmpty) {
                                        return t.commonFieldRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _provinciaCtrl,
                                    enabled: !_cargando,
                                    textInputAction: TextInputAction.next,
                                    decoration: _dec(
                                      t.institucionRegistroProvince,
                                    ),
                                    validator: (v) {
                                      final s = (v ?? '').trim();
                                      if (s.isEmpty) {
                                        return t.commonFieldRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _ciudadCtrl,
                              enabled: !_cargando,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(t.institucionRegistroCity),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return t.commonFieldRequired;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),
                            _sectionTitle(
                              context,
                              t.institucionRegistroSectionAccessContact,
                            ),

                            TextFormField(
                              controller: _emailCtrl,
                              enabled: !_cargando,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                                AutofillHints.username,
                              ],
                              decoration: _dec(t.commonEmail),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return t.commonFieldRequired;
                                }
                                if (!_emailBasicoValido(s)) {
                                  return t.commonEmailInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _telefonoCtrl,
                              enabled: !_cargando,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _dec(t.commonPhone),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return t.commonFieldRequired;
                                }
                                if (!_telefonoValidoBasico(s)) {
                                  return t.commonPhoneInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // ✅ Contraseña al final (como pediste)
                            Semantics(
                              label: t.commonPassword,
                              textField: true,
                              child: TextFormField(
                                controller: _passCtrl,
                                enabled: !_cargando,
                                obscureText: _ocultarPass,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: _dec(t.commonPassword).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _ocultarPass
                                        ? t.commonShowPassword
                                        : t.commonHidePassword,
                                    onPressed: _cargando
                                        ? null
                                        : () {
                                            if (!mounted) {
                                              return;
                                            }
                                            setState(() {
                                              _ocultarPass = !_ocultarPass;
                                            });
                                          },
                                    icon: Icon(
                                      _ocultarPass
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty) {
                                    return t.commonFieldRequired;
                                  }
                                  if (s.length < _minPassLen) {
                                    return t.commonPasswordMinLength4;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  // ignore: discarded_futures
                                  _continuarAPlan();
                                },
                              ),
                            ),

                            const SizedBox(height: 18),

                            SizedBox(
                              height: 48,
                              child: Semantics(
                                button: true,
                                enabled: !_cargando,
                                label: _cargando
                                    ? t.commonContinuing
                                    : t.commonContinue,
                                child: ElevatedButton.icon(
                                  onPressed: _cargando ? null : _continuarAPlan,
                                  icon: _cargando
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward),
                                  label: Text(
                                    _cargando
                                        ? t.commonContinuing
                                        : t.commonContinueToPlan,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
✅ ARB KEYS A AGREGAR (acumular, NO editar ARB todavía):
- institucionRegistroAppBar
- institucionRegistroIntro
- institucionRegistroSectionBasics
- institucionRegistroInstitutionName
- institucionRegistroCuit
- institucionRegistroCuitInvalid
- institucionRegistroAddress
- institucionRegistroSectionLocation
- institucionRegistroCountry
- institucionRegistroProvince
- institucionRegistroCity
- institucionRegistroSectionAccessContact
- commonFieldRequired
- commonTooShort
- commonEmail
- commonEmailInvalid
- commonPhone
- commonPhoneInvalid
- commonPassword
- commonShowPassword
- commonHidePassword
- commonPasswordMinLength4
- commonContinue
- commonContinuing
- commonContinueToPlan
- commonError
*/
