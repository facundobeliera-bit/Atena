import 'package:flutter/material.dart';

/// Recovery is unavailable until a verified external channel exists.
class AlumnoForgotPasswordPage extends StatelessWidget {
  // Retained for compatibility with existing login routes; never queried.
  final String? initialEmail;

  const AlumnoForgotPasswordPage({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'La recuperación de contraseña todavía no está disponible en esta versión.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Por seguridad, no podemos cambiar tu contraseña sin verificar tu identidad mediante un canal externo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver al ingreso'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
