// lib/services/password_hasher.dart
//
// Hash de contraseñas con PBKDF2-HMAC-SHA256 y sal aleatoria.
//
// Formato guardado: pbkdf2$sha256$<iteraciones>$<sal base64>$<hash base64>
//
// Compatibilidad: verifica también los formatos viejos (base64 del texto o
// texto plano) para que los usuarios existentes puedan ingresar; en ese caso
// `needsRehash` devuelve true y el servicio guarda el hash nuevo.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

enum LegacyPasswordFormat { base64, plain }

class PasswordHasher {
  const PasswordHasher._();

  static const String _prefix = 'pbkdf2';
  static const int _iterations = 12000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  /// Largo mínimo para contraseñas nuevas.
  static const int minLength = 8;

  static String hash(String password) {
    final rnd = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => rnd.nextInt(256)),
    );
    final key = _pbkdf2(utf8.encode(password), salt, _iterations, _keyLength);
    return '$_prefix\$sha256\$$_iterations\$${base64Encode(salt)}\$${base64Encode(key)}';
  }

  static bool isModernHash(String stored) => stored.startsWith('$_prefix\$');

  static bool needsRehash(String stored) => !isModernHash(stored);

  static bool verify(
    String password,
    String stored, {
    LegacyPasswordFormat legacy = LegacyPasswordFormat.base64,
  }) {
    if (stored.isEmpty) return false;

    if (isModernHash(stored)) {
      final parts = stored.split('\$');
      if (parts.length != 5) return false;
      final iterations = int.tryParse(parts[2]);
      if (iterations == null || iterations <= 0) return false;
      try {
        final salt = base64Decode(parts[3]);
        final expected = base64Decode(parts[4]);
        final actual = _pbkdf2(
          utf8.encode(password),
          salt,
          iterations,
          expected.length,
        );
        return _constantTimeEquals(actual, expected);
      } catch (_) {
        return false;
      }
    }

    final trimmed = password.trim();
    switch (legacy) {
      case LegacyPasswordFormat.base64:
        return _constantTimeEquals(
          utf8.encode(base64Encode(utf8.encode(trimmed))),
          utf8.encode(stored),
        );
      case LegacyPasswordFormat.plain:
        return _constantTimeEquals(utf8.encode(trimmed), utf8.encode(stored));
    }
  }

  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final out = <int>[];
    var block = 1;
    while (out.length < keyLength) {
      final input = Uint8List(salt.length + 4)
        ..setAll(0, salt)
        ..[salt.length] = (block >> 24) & 0xff
        ..[salt.length + 1] = (block >> 16) & 0xff
        ..[salt.length + 2] = (block >> 8) & 0xff
        ..[salt.length + 3] = block & 0xff;
      var u = hmac.convert(input).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.addAll(t);
      block++;
    }
    return out.sublist(0, keyLength);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
