import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

typedef _OpenNative =
    Int32 Function(
      Pointer<Pointer<Void>>,
      Pointer<Utf16>,
      Pointer<Utf16>,
      Uint32,
    );
typedef _OpenDart =
    int Function(Pointer<Pointer<Void>>, Pointer<Utf16>, Pointer<Utf16>, int);
typedef _DeriveNative =
    Int32 Function(
      Pointer<Void>,
      Pointer<Uint8>,
      Uint32,
      Pointer<Uint8>,
      Uint32,
      Uint64,
      Pointer<Uint8>,
      Uint32,
      Uint32,
    );
typedef _DeriveDart =
    int Function(
      Pointer<Void>,
      Pointer<Uint8>,
      int,
      Pointer<Uint8>,
      int,
      int,
      Pointer<Uint8>,
      int,
      int,
    );
typedef _CloseNative = Int32 Function(Pointer<Void>, Uint32);
typedef _CloseDart = int Function(Pointer<Void>, int);

Future<List<int>?> deriveWindows(String password, List<int> salt, int rounds) {
  if (!Platform.isWindows) return Future<List<int>?>.value(null);
  return Isolate.run(() => _derive(password, salt, rounds));
}

List<int> _derive(String password, List<int> salt, int rounds) {
  final bcrypt = DynamicLibrary.open('bcrypt.dll');
  final open = bcrypt.lookupFunction<_OpenNative, _OpenDart>(
    'BCryptOpenAlgorithmProvider',
  );
  final derive = bcrypt.lookupFunction<_DeriveNative, _DeriveDart>(
    'BCryptDeriveKeyPBKDF2',
  );
  final close = bcrypt.lookupFunction<_CloseNative, _CloseDart>(
    'BCryptCloseAlgorithmProvider',
  );
  final handle = calloc<Pointer<Void>>();
  final algorithm = 'SHA256'.toNativeUtf16();
  final passwordBytes = utf8.encode(password);
  final passwordPtr = calloc<Uint8>(passwordBytes.length);
  final saltPtr = calloc<Uint8>(salt.length);
  final resultPtr = calloc<Uint8>(32);
  var opened = false;
  try {
    passwordPtr.asTypedList(passwordBytes.length).setAll(0, passwordBytes);
    saltPtr.asTypedList(salt.length).setAll(0, salt);
    // BCRYPT_ALG_HANDLE_HMAC_FLAG makes SHA256 usable as PBKDF2's HMAC PRF.
    final openStatus = open(handle, algorithm, nullptr, 0x00000008);
    if (openStatus != 0) {
      throw StateError('Windows PBKDF2 provider failed: $openStatus');
    }
    opened = true;
    final status = derive(
      handle.value,
      passwordPtr,
      passwordBytes.length,
      saltPtr,
      salt.length,
      rounds,
      resultPtr,
      32,
      0,
    );
    if (status != 0) throw StateError('Windows PBKDF2 failed: $status');
    return List<int>.from(resultPtr.asTypedList(32));
  } finally {
    passwordPtr
        .asTypedList(passwordBytes.length)
        .fillRange(0, passwordBytes.length, 0);
    calloc.free(passwordPtr);
    calloc.free(saltPtr);
    calloc.free(resultPtr);
    calloc.free(algorithm);
    if (opened) close(handle.value, 0);
    calloc.free(handle);
  }
}
