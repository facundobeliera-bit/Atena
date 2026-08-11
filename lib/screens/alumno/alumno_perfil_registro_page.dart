// lib/screens/alumno/alumno_perfil_registro_page.dart
//
// ATENA – ALUMNO PERFIL REGISTRO (CANÓNICO)
// - Crea PerfilAlumno vía CuentaService (ownerAccountId = cuentaId)
// - Asegura ficha Alumno vía AlumnoService (por perfilId)
// - Devuelve `true` al pop para que CuentaHomePage haga refresh (CANÓNICO)
//
// ✅ CIERRE FASE 2:
// - ✅ i18n REAL: AppLocalizations.of(context).<key> (sin fallbacks)
// - ✅ Theme/ColorScheme real (sin Colors.* fijo; sin withValues)
// - ✅ Simplificación: elimina helpers i18n “safe”, elimina alpha manual
// - ✅ Accesibilidad/UX: error panel theme-driven, background robusto (errorBuilder)

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../services/cuenta_service.dart';
import '../../services/alumno_service.dart';
import '../../models/alumnos/alumnos_integrados.dart';

// ✅ Assets centralizados
import '../../ui/atena_assets.dart';

class AlumnoPerfilRegistroPage extends StatefulWidget {
  final String cuentaId;

  const AlumnoPerfilRegistroPage({super.key, required this.cuentaId});

  @override
  State<AlumnoPerfilRegistroPage> createState() =>
      _AlumnoPerfilRegistroPageState();
}

class _AlumnoPerfilRegistroPageState extends State<AlumnoPerfilRegistroPage> {
  final _formKey = GlobalKey<FormState>();

  bool _cargando = false;
  String? _error;

  final _dniCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();

    // Precache best-effort del fondo (no bloqueante)
    WidgetsBinding.instance.addPostFrameCallback((frameTime) {
      if (!mounted) return;
      try {
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome)),
          context,
        );
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow)),
          context,
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _dniCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim();
  String _normEmail(String s) => s.trim().toLowerCase();
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _pickFecha() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final initial = _fechaNacimiento ?? DateTime(now.year - 12, 1, 1);

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      initialDate: initial.isAfter(now) ? now : initial,
      helpText: l10n.commonSelectDate,
    );

    if (!mounted) return;

    if (picked != null) {
      if (picked.isAfter(now)) {
        setState(() => _error = l10n.alumnoFechaNacimientoNoFutura);
        return;
      }
      setState(() => _fechaNacimiento = picked);
    }
  }

  Future<void> _guardar() async {
    if (_cargando) return;

    final l10n = AppLocalizations.of(context);

    // Cerrar teclado
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _error = null;
      _cargando = true;
    });

    try {
      final cuentaId = widget.cuentaId.trim();
      if (cuentaId.isEmpty) {
        throw Exception(l10n.commonInvalidSessionAccountId);
      }

      final formState = _formKey.currentState;
      if (formState == null || !formState.validate()) {
        return;
      }

      final fechaNac = _fechaNacimiento;
      if (fechaNac == null) {
        throw Exception(l10n.alumnoSeleccionaFechaNacimiento);
      }

      final dni = _digitsOnly(_dniCtrl.text);
      final nombre = _norm(_nombreCtrl.text);
      final apellido = _norm(_apellidoCtrl.text);

      final emailRaw = _normEmail(_emailCtrl.text);
      final email = emailRaw.isEmpty ? '' : emailRaw;

      final telRaw = _norm(_telCtrl.text);
      final telefono = telRaw.isEmpty ? '' : telRaw;

      // 1) Crear PerfilAlumno (CuentaService)
      final perfil = await CuentaService.crearPerfilAlumno(
        cuentaId: cuentaId,
        documento: dni,
        nombre: nombre,
        apellido: apellido,
        fechaNacimiento: fechaNac,
        email: email,
        telefono: telefono,
      );

      final perfilId = perfil.id.trim();
      if (perfilId.isEmpty) {
        throw Exception(l10n.alumnoNoSePudoCrearPerfilPerfilIdVacio);
      }

      // 2) Crear ficha Alumno (AlumnoService) bajo perfilId
      final alumno = Alumno(
        documento: perfil.documento.trim(),
        nombre: perfil.nombre.trim(),
        apellido: perfil.apellido.trim(),
        fechaNacimiento: perfil.fechaNacimiento,
        email: perfil.email.trim(),
        telefono: perfil.telefono.trim(),
        fotoPerfilLocalPath: null,
      );

      await AlumnoService.instance.upsertPerfilAlumnoByPerfilId(
        ownerAccountId: cuentaId,
        perfilId: perfilId,
        alumno: alumno,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // =========================
  // UI – Background wrapper
  // =========================
  Widget _buildBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Widget bgFallback() => Container(color: cs.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => bgFallback(),
        ),

        // ✅ Deprecated fix: withOpacity -> withValues(alpha: ...)
        Container(color: cs.scrim.withValues(alpha: isDark ? 0.25 : 0.06)),

        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.35 : 0.20,
              child: Image.asset(
                AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fecha = _fechaNacimiento;
    final fechaTxt = (fecha == null)
        ? l10n.commonSelectDate
        : '${fecha.day.toString().padLeft(2, '0')}/'
              '${fecha.month.toString().padLeft(2, '0')}/'
              '${fecha.year}';

    final errorText = (_error ?? '').trim();
    final isDark = theme.brightness == Brightness.dark;

    // ✅ Deprecated fix: withOpacity -> withValues(alpha: ...)
    final errorBg = cs.errorContainer.withValues(alpha: isDark ? 0.35 : 0.20);
    final errorFg = cs.onErrorContainer;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alumnoPerfilRegistroTitle)),
      body: _buildBackground(
        context,
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      if (errorText.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: errorBg,
                            border: Border.all(
                              color: cs.outlineVariant.withValues(
                                alpha: isDark ? 0.65 : 0.45,
                              ),
                            ),
                          ),
                          child: Text(
                            errorText,
                            style: TextStyle(color: errorFg),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _dniCtrl,
                        enabled: !_cargando,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.alumnoDocumentoDniLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final t = _digitsOnly(v ?? '');
                          if (t.isEmpty) return l10n.alumnoIngresaDni;
                          if (!RegExp(r'^\d{7,9}$').hasMatch(t)) {
                            return l10n.alumnoDniInvalidoRango;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombreCtrl,
                        enabled: !_cargando,
                        decoration: InputDecoration(
                          labelText: l10n.commonNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return l10n.commonEnterName;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidoCtrl,
                        enabled: !_cargando,
                        decoration: InputDecoration(
                          labelText: l10n.commonLastNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return l10n.commonEnterLastName;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _cargando ? null : _pickFecha,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          '${l10n.alumnoFechaNacimientoPrefix}: $fechaTxt',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !_cargando,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.commonEmailOptionalLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null;
                          final email = t.toLowerCase();
                          if (!email.contains('@') || !email.contains('.')) {
                            return l10n.commonInvalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telCtrl,
                        enabled: !_cargando,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.commonPhoneOptionalLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _guardar,
                          child: _cargando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.commonSaveProfile),
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
    );
  }
}
