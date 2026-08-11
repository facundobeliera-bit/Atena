// lib/screens/auth/alumno_registro_page.dart
//
// ATENA – AUTH / ALUMNO REGISTRO (CANÓNICO)
//
// ✅ FIX DEFINITIVO:
// - NO se pasa NUNCA DateTime? a ningún servicio
// - fechaNacimiento queda sellado como DateTime ANTES de cualquier await
//
// Nota: strings hardcode mientras cerramos flujo; i18n después.

import 'package:flutter/material.dart';

import '../../services/cuenta_service.dart';
import '../cuentas/cuenta_home_page.dart';

class AlumnoRegistroPage extends StatefulWidget {
  final String? deeplink;

  const AlumnoRegistroPage({super.key, this.deeplink});

  @override
  State<AlumnoRegistroPage> createState() => _AlumnoRegistroPageState();
}

class _AlumnoRegistroPageState extends State<AlumnoRegistroPage> {
  final _formKey = GlobalKey<FormState>();

  // PERFIL
  final _nombreC = TextEditingController();
  final _apellidoC = TextEditingController();
  final _dniC = TextEditingController();
  final _telefonoC = TextEditingController();
  final _fechaNacC = TextEditingController();
  DateTime? _fechaNac; // ← solo UI

  // CUENTA
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _recordarme = true;
  bool _cargando = false;

  bool _verPassword = false;

  String? _error;

  @override
  void dispose() {
    _nombreC.dispose();
    _apellidoC.dispose();
    _dniC.dispose();
    _telefonoC.dispose();
    _fechaNacC.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    final clean = msg.trim();
    if (clean.isEmpty) return;
    final m = ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(clean)));
  }

  String _dniDigits(String v) => v.replaceAll(RegExp(r'[^0-9]'), '').trim();

  bool _looksLikeEmail(String v) {
    final t = v.trim().toLowerCase();
    if (t.isEmpty) return false;
    final at = t.indexOf('@');
    final dot = t.lastIndexOf('.');
    return at > 0 && dot > at + 1 && dot < t.length - 1;
  }

  bool _looksLikeDni(String v) => RegExp(r'^\d{7,9}$').hasMatch(_dniDigits(v));

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickFechaNacimiento() async {
    if (_cargando) return;

    final now = DateTime.now();
    final initial = _fechaNac ?? DateTime(now.year - 12);

    DateTime? picked;
    try {
      picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: now,
      );
    } catch (_) {
      picked = null;
    }

    if (!mounted || picked == null) return;

    // ✅ SELLADO para evitar DateTime? en _dateKey(...)
    final DateTime p = picked;

    setState(() {
      _fechaNac = p;
      _fechaNacC.text = _dateKey(p);
      _error = null;
    });
  }

  Future<void> _registrar() async {
    if (_cargando) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    // 🔒 SELLADO DEFINITIVO (ANTES DE ANY await)
    if (_fechaNac == null) {
      if (mounted) {
        setState(() => _error = 'Seleccioná la fecha de nacimiento.');
      }
      _snack('Seleccioná la fecha de nacimiento.');
      return;
    }
    final DateTime fechaNacimiento = _fechaNac!;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);

    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final email = _emailC.text.trim().toLowerCase();
      final pass = _passC.text; // no trim

      final cuenta = await CuentaService.registrarCuenta(
        email: email,
        password: pass,
        recordarme: _recordarme,
      );

      final perfil = await CuentaService.crearPerfilAlumno(
        cuentaId: cuenta.id,
        documento: _dniDigits(_dniC.text),
        nombre: _nombreC.text.trim(),
        apellido: _apellidoC.text.trim(),
        fechaNacimiento: fechaNacimiento, // ✅ DateTime puro
        email: email,
        telefono: _telefonoC.text.trim(),
      );

      await CuentaService.setUltimoPerfil(cuenta.id, 'A|${perfil.id}');

      if (!mounted) return;

      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) => CuentaHomePage(
            cuentaId: cuenta.id,
            initialDeeplink: widget.deeplink,
          ),
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      final clean = msg.isEmpty ? 'Error al registrar.' : msg;

      if (mounted) {
        setState(() => _error = clean);
      }

      if (messenger != null) {
        final s = clean.trim();
        if (s.isNotEmpty) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(s)));
        }
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro Alumno')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if ((_error ?? '').trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (_error ?? '').trim(),
                          style: TextStyle(
                            color: cs.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Datos del perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nombreC,
                      enabled: !_cargando,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Ingresá tu nombre.';
                        if (s.length < 2) return 'Nombre demasiado corto.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _apellidoC,
                      enabled: !_cargando,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Ingresá tu apellido.';
                        if (s.length < 2) return 'Apellido demasiado corto.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _dniC,
                      enabled: !_cargando,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'DNI (7 a 9 dígitos)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Ingresá tu DNI.';
                        if (!_looksLikeDni(s)) return 'DNI inválido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _telefonoC,
                      enabled: !_cargando,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Ingresá un teléfono.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _fechaNacC,
                      enabled: !_cargando,
                      readOnly: true,
                      onTap: _pickFechaNacimiento,
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          onPressed: _cargando ? null : _pickFechaNacimiento,
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ),
                      validator: (_) => _fechaNac == null
                          ? 'Seleccioná tu fecha de nacimiento.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Datos de la cuenta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailC,
                      enabled: !_cargando,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Ingresá tu email.';
                        if (!_looksLikeEmail(s)) return 'Email inválido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passC,
                      enabled: !_cargando,
                      obscureText: !_verPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña (mínimo 4)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          onPressed: _cargando
                              ? null
                              : () => setState(
                                  () => _verPassword = !_verPassword,
                                ),
                          icon: Icon(
                            _verPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (v) {
                        final s = (v ?? '');
                        if (s.trim().isEmpty) return 'Ingresá una contraseña.';
                        if (s.length < 4) return 'Mínimo 4 caracteres.';
                        return null;
                      },
                      onFieldSubmitted: (_) => _registrar(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _recordarme,
                          onChanged: _cargando
                              ? null
                              : (v) => setState(() => _recordarme = v ?? true),
                        ),
                        const Expanded(child: Text('Recordarme')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : _registrar,
                        icon: _cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(
                          _cargando ? 'Creando...' : 'Crear cuenta y perfil',
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
    );
  }
}
