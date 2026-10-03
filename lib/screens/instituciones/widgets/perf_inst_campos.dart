// lib/screens/instituciones/widgets/perf_inst_campos.dart
//
// Piezas del formulario del perfil de la institución: campos de texto,
// secciones, validación y formato de teléfonos y enlaces, y la barra de
// cambios sin guardar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';

/// Campos de texto del perfil: datos de la institución y perfil público.
class PerfInstCampos {
  // Datos de la institución.
  final nombre = TextEditingController();
  final cuit = TextEditingController();
  final direccion = TextEditingController();
  final ciudad = TextEditingController();
  final provincia = TextEditingController();
  final pais = TextEditingController();
  final email = TextEditingController();
  final telefono = TextEditingController();

  // Perfil público.
  final descripcion = TextEditingController();
  final horarioAtencion = TextEditingController();
  final horarioClases = TextEditingController();
  final telefonoPublico = TextEditingController();
  final whatsapp = TextEditingController();
  final emailPublico = TextEditingController();
  final web = TextEditingController();
  final instagram = TextEditingController();
  final facebook = TextEditingController();
  final youtube = TextEditingController();

  late final List<TextEditingController> todos = [
    nombre,
    cuit,
    direccion,
    ciudad,
    provincia,
    pais,
    email,
    telefono,
    descripcion,
    horarioAtencion,
    horarioClases,
    telefonoPublico,
    whatsapp,
    emailPublico,
    web,
    instagram,
    facebook,
    youtube,
  ];

  /// Avisa cada vez que cambia el texto de cualquier campo.
  late final Listenable cambios = Listenable.merge(todos);

  void dispose() {
    for (final c in todos) {
      c.dispose();
    }
  }
}

/// Campo de texto de una línea con el estilo del formulario.
class PerfInstCampo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helper;
  final String? hint;
  final IconData? icon;
  final bool habilitado;
  final TextInputType? teclado;
  final TextCapitalization mayusculas;
  final int? largoMaximo;
  final List<TextInputFormatter> formato;
  final Iterable<String>? autofill;
  final FormFieldValidator<String>? validator;

  const PerfInstCampo({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.hint,
    this.icon,
    required this.habilitado,
    this.teclado,
    this.mayusculas = TextCapitalization.none,
    this.largoMaximo,
    this.formato = const <TextInputFormatter>[],
    this.autofill,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: habilitado,
      keyboardType: teclado,
      textCapitalization: mayusculas,
      textInputAction: TextInputAction.next,
      // Solo se corrige el texto libre (no emails, teléfonos ni enlaces).
      autocorrect: teclado == null,
      inputFormatters: [
        ...formato,
        if (largoMaximo != null) LengthLimitingTextInputFormatter(largoMaximo),
      ],
      autofillHints: autofill,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
    );
  }
}

/// Tarjeta con título (y ayuda opcional) que agrupa campos relacionados.
class PerfInstSeccion extends StatelessWidget {
  final String titulo;
  final String? ayuda;
  final List<Widget> children;

  const PerfInstSeccion({
    super.key,
    required this.titulo,
    this.ayuda,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormSection(title: titulo, help: ayuda),
          ...children,
        ],
      ),
    );
  }
}

/// Validación y formato de teléfonos, sitios web y redes sociales.
class PerfInstFormato {
  const PerfInstFormato._();

  static final RegExp _esquema = RegExp(r'^https?://', caseSensitive: false);
  static final RegExp _web = RegExp(
    r'^(https?://)?([\p{L}\p{N}-]+\.)+\p{L}{2,}(:\d+)?([/?#]\S*)?$',
    unicode: true,
    caseSensitive: false,
  );
  static final RegExp _usuario = RegExp(
    r'^@?[\p{L}\p{N}._-]{2,60}$',
    unicode: true,
  );

  /// Caracteres admitidos al escribir un teléfono.
  static final TextInputFormatter teclasTelefono =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]'));

  static String soloDigitos(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');

  static String? telefono(
    AppLocalizations t,
    String? v, {
    bool requerido = false,
  }) {
    final texto = (v ?? '').trim();
    if (texto.isEmpty) return requerido ? t.commonRequiredField : null;
    final digitos = soloDigitos(texto).length;
    return digitos < 8 || digitos > 15 ? t.perfInstTelefonoInvalido : null;
  }

  static String? web(AppLocalizations t, String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty || _web.hasMatch(s) ? null : t.perfInstWebInvalida;
  }

  /// Antepone https:// cuando falta el esquema.
  static String normalizarWeb(String v) {
    final s = v.trim();
    return s.isEmpty || _esquema.hasMatch(s) ? s : 'https://$s';
  }

  static bool _esUsuario(String s) =>
      _usuario.hasMatch(s) && !s.toLowerCase().startsWith('www.');

  static String? red(AppLocalizations t, String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty || _esUsuario(s) || _web.hasMatch(s)) return null;
    return t.perfInstRedInvalida;
  }

  /// Deja la red como "@usuario" o como enlace completo.
  static String normalizarRed(String v) {
    final s = v.trim();
    if (s.isEmpty) return s;
    if (_esUsuario(s)) return s.startsWith('@') ? s : '@$s';
    return normalizarWeb(s);
  }
}

/// Barra inferior que aparece cuando hay cambios sin guardar.
class PerfInstBarraGuardar extends StatelessWidget {
  final bool guardando;

  /// false mientras se sube una imagen (no se puede guardar ni descartar).
  final bool habilitada;

  final VoidCallback onGuardar;
  final VoidCallback onDescartar;

  const PerfInstBarraGuardar({
    super.key,
    required this.guardando,
    required this.habilitada,
    required this.onGuardar,
    required this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activa = habilitada && !guardando;

    final descartar = OutlinedButton(
      onPressed: activa ? onDescartar : null,
      child: Text(t.perfInstDescartar),
    );
    final guardar = FilledButton(
      onPressed: activa ? onGuardar : null,
      child: guardando
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(t.commonSaving, maxLines: 1)),
              ],
            )
          : Text(t.commonSave),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: atenaPagePadding(
            context,
            maxWidth: AtenaLayout.narrow,
            top: 12,
            bottom: 12,
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 460) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.perfInstCambiosPendientes,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: descartar),
                        const SizedBox(width: 12),
                        Expanded(child: guardar),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.perfInstCambiosPendientes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  descartar,
                  const SizedBox(width: 12),
                  guardar,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
