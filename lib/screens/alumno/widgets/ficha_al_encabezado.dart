// lib/screens/alumno/widgets/ficha_al_encabezado.dart
//
// ATENA – Ficha del alumno: encabezado con la foto (se toca para cambiarla),
// el nombre, la edad y el DNI.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/cuentas/cuenta.dart';
import '../../../ui/atena_ui.dart';

/// DNI con separador de miles ("45123456" → "45.123.456").
String fichaAlFormatearDni(String dni) {
  final digitos = dni.replaceAll(RegExp(r'[^0-9]'), '');
  final out = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) out.write('.');
    out.write(digitos[i]);
  }
  return out.toString();
}

/// Edad del alumno, o null si no tiene cargada la fecha de nacimiento.
int? fichaAlEdad(PerfilAlumno perfil) =>
    perfil.fechaNacimiento.millisecondsSinceEpoch == 0
    ? null
    : edadEnAnios(perfil.fechaNacimiento);

class FichaAlEncabezado extends StatelessWidget {
  final PerfilAlumno perfil;
  final Uint8List? foto;

  /// true mientras se guarda o se quita la foto.
  final bool guardando;

  final VoidCallback onFoto;

  const FichaAlEncabezado({
    super.key,
    required this.perfil,
    required this.foto,
    required this.guardando,
    required this.onFoto,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final edad = fichaAlEdad(perfil);
    final dni = fichaAlFormatearDni(perfil.documento);
    final datos = [
      if (edad != null) t.lblEdadAnios(edad),
      if (dni.isNotEmpty) t.fichaAlDni(dni),
    ].join(' · ');
    final accionFoto = foto == null
        ? t.fichaAlAgregarFoto
        : t.fichaAlCambiarFoto;

    return AtenaGradientPanel(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Semantics(
              button: true,
              child: Tooltip(
                message: accionFoto,
                child: InkWell(
                  onTap: guardando ? null : onFoto,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    children: [
                      ExcludeSemantics(
                        child: AtenaAvatar(
                          name: perfil.displayName,
                          imageBytes: foto,
                          size: 104,
                          ring: true,
                        ),
                      ),
                      if (guardando)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.scrim.withValues(alpha: 0.45),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            foto == null
                                ? Icons.add_a_photo_rounded
                                : Icons.photo_camera_rounded,
                            size: 18,
                            color: AtenaColors.roleAccent(AtenaRole.alumno),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              perfil.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (datos.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                datos,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
