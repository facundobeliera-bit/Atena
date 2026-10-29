import 'package:supabase_flutter/supabase_flutter.dart';

/// Never display backend bodies, platform exceptions, URLs or file contents.
String documentError(Object error) {
  if (error is PostgrestException && error.code == '42501') {
    return 'No tenés autorización vigente para acceder a este documento.';
  }
  if (error is ArgumentError || error is FormatException) {
    return 'No se pudo procesar el archivo. Revisá su formato y tamaño.';
  }
  return 'No se pudo completar la operación documental. Actualizá el acceso y volvé a intentar.';
}
