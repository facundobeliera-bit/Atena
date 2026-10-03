// lib/screens/alumno/alumno_perfil_form_page.dart
//
// ATENA – Alta y edición de un alumno de la cuenta.
// Devuelve el PerfilAlumno creado o actualizado al cerrar.

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import '../auth/widgets/auth_shell.dart';

class AlumnoPerfilFormPage extends StatefulWidget {
  final String cuentaId;

  /// null = alta de un alumno nuevo.
  final PerfilAlumno? perfil;

  const AlumnoPerfilFormPage({super.key, required this.cuentaId, this.perfil});

  @override
  State<AlumnoPerfilFormPage> createState() => _AlumnoPerfilFormPageState();
}

class _AlumnoPerfilFormPageState extends State<AlumnoPerfilFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _dni;
  late final TextEditingController _email;
  late final TextEditingController _telefono;
  final _fechaCtrl = TextEditingController();

  DateTime? _fecha;
  bool _saving = false;
  String? _error;

  bool get _editando => widget.perfil != null;

  @override
  void initState() {
    super.initState();
    final p = widget.perfil;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _apellido = TextEditingController(text: p?.apellido ?? '');
    _dni = TextEditingController(text: p?.documento ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _telefono = TextEditingController(text: p?.telefono ?? '');
    if (p != null && p.fechaNacimiento.millisecondsSinceEpoch != 0) {
      _fecha = p.fechaNacimiento;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final f = _fecha;
    if (f != null) {
      _fechaCtrl.text = MaterialLocalizations.of(context).formatCompactDate(f);
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _dni, _email, _telefono, _fechaCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fecha = picked;
      _fechaCtrl.text = MaterialLocalizations.of(
        context,
      ).formatCompactDate(picked);
    });
  }

  Future<void> _guardar() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final fecha = _fecha;
    if (fecha == null) return;

    final t = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = AlumnosRepo.instance;
      PerfilAlumno? resultado;
      if (_editando) {
        await repo.actualizar(
          cuentaId: widget.cuentaId,
          perfil: widget.perfil!,
          nombre: _nombre.text,
          apellido: _apellido.text,
          dni: _dni.text,
          fechaNacimiento: fecha,
          email: _email.text,
          telefono: _telefono.text,
        );
        resultado = await repo.perfil(widget.perfil!.id);
      } else {
        resultado = await repo.crear(
          cuentaId: widget.cuentaId,
          nombre: _nombre.text,
          apellido: _apellido.text,
          dni: _dni.text,
          fechaNacimiento: fecha,
          email: _email.text.trim(),
          telefono: _telefono.text.trim(),
        );
      }
      if (!mounted) return;
      AtenaFeedback.success(
        context,
        _editando ? t.studentFormSaved : t.studentFormCreated,
      );
      Navigator.of(context).pop(resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = coreErrorText(t, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = (_error ?? '').trim();
    const gap = SizedBox(height: 14);

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AtenaAppBar(
        title: _editando ? t.studentFormTitleEdit : t.studentFormTitleNew,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: atenaPagePadding(context, maxWidth: AtenaLayout.narrow),
          child: AtenaCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthFormSection(
                    title: t.authStudentSection,
                    help: _editando ? null : t.authStudentSectionHelp,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nombre,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: t.commonNameLabel,
                          ),
                          validator: (v) => AuthValidators.required(t, v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _apellido,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: t.commonLastNameLabel,
                          ),
                          validator: (v) => AuthValidators.required(t, v),
                        ),
                      ),
                    ],
                  ),
                  gap,
                  TextFormField(
                    controller: _dni,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.authDniLabel,
                      helperText: t.authDniHelper,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => AuthValidators.dni(t, v),
                  ),
                  gap,
                  TextFormField(
                    controller: _fechaCtrl,
                    enabled: !_saving,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    onTap: _pickFecha,
                    decoration: InputDecoration(
                      labelText: t.authBirthDate,
                      prefixIcon: const Icon(Icons.cake_outlined),
                      suffixIcon: const Icon(Icons.calendar_month_rounded),
                    ),
                    validator: (_) =>
                        _fecha == null ? t.authBirthDateRequired : null,
                  ),
                  gap,
                  TextFormField(
                    controller: _email,
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.commonEmailOptionalLabel,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? null
                        : AuthValidators.email(t, v),
                  ),
                  gap,
                  TextFormField(
                    controller: _telefono,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: t.commonPhoneOptionalLabel,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    onFieldSubmitted: (_) => _guardar(),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AtenaBanner(tone: AtenaBannerTone.error, message: error),
                  ],
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    label: _editando ? t.commonSave : t.hubAddStudent,
                    loadingLabel: t.commonSaving,
                    loading: _saving,
                    onPressed: _guardar,
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
