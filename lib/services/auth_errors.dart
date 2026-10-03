// lib/services/auth_errors.dart
//
// Errores de autenticación y registro con código estable.
// La interfaz traduce el código (ver ui/auth_error_text.dart); los servicios
// nunca devuelven texto pensado para el usuario.

enum AuthErrorCode {
  invalidEmail,
  weakPassword,
  emailInUse,
  accountNotFound,
  wrongCredentials,
  invalidDni,
  duplicateDni,
  identityMismatch,
  invalidName,
  invalidAccount,
  unknown,
}

class AuthException implements Exception {
  final AuthErrorCode code;

  const AuthException(this.code);

  @override
  String toString() => 'AuthException(${code.name})';
}
