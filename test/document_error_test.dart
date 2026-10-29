import 'package:atena_app/ui/document_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('document errors never expose backend bodies, URLs, bytes or secrets', () {
    const sensitive =
        'TEST_ONLY access_token=fictional refresh_token=fictional data:application/pdf;base64,TEST private-person';
    for (final error in <Object>[
      Exception(sensitive),
      StateError(sensitive),
      ArgumentError(sensitive),
      const FormatException(sensitive),
      const PostgrestException(
        message: sensitive,
        details: sensitive,
        code: '42501',
      ),
      const AuthException(sensitive),
    ]) {
      final message = documentError(error);
      expect(message, isNot(contains('fictional')));
      expect(message, isNot(contains('private-person')));
      expect(message, isNot(contains('data:')));
    }
  });
}
