import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'local_password_native_stub.dart'
    if (dart.library.io) 'local_password_native_io.dart'
    as native;

/// Versioned, salted password verifier for local prototype credentials.
class LocalPasswordHasher {
  LocalPasswordHasher._();

  static const int iterations = 600000;
  static const String _prefix = 'pbkdf2-sha256:';

  static bool isModern(String value) => value.startsWith(_prefix);

  static Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final key = await _derive(password.trim(), salt, iterations);
    return '$_prefix$iterations:${base64UrlEncode(salt)}:${base64UrlEncode(key)}';
  }

  static Future<bool> verify(String password, String encoded) async {
    if (!isModern(encoded)) return false;
    final parts = encoded.split(':');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < iterations || rounds > 10000000) {
      return false;
    }
    try {
      final salt = base64Url.decode(parts[2]);
      final expected = base64Url.decode(parts[3]);
      if (salt.length != 16 || expected.length != 32) return false;
      final actual = await _derive(password.trim(), salt, rounds);
      var difference = 0;
      for (var i = 0; i < expected.length; i++) {
        difference |= actual[i] ^ expected[i];
      }
      return difference == 0;
    } on FormatException {
      return false;
    }
  }

  static Future<List<int>> _derive(
    String password,
    List<int> salt,
    int rounds,
  ) async {
    final nativeKey = await native.deriveWindows(password, salt, rounds);
    if (nativeKey != null) return nativeKey;
    final key = await Pbkdf2.hmacSha256(
      iterations: rounds,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }
}
