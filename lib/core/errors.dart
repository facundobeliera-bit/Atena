// lib/core/errors.dart
//
// Errores de negocio con código estable. La interfaz los traduce
// (ver ui/core_error_text.dart); nunca se muestra texto técnico al usuario.

enum AtenaError {
  noEncontrado,
  noAutorizado,
  datosInvalidos,
  ofertaInactiva,
  sinCupo,
  solicitudDuplicada,
  estadoInvalido,
  ofertaConSolicitudes,
  archivoMuyGrande,
  formatoNoSoportado,
  sinEspacio,
}

class AtenaException implements Exception {
  final AtenaError error;

  const AtenaException(this.error);

  @override
  String toString() => 'AtenaException(${error.name})';
}
