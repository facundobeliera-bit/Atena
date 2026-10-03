// lib/core/repos/alumnos_repo.dart
//
// Perfiles de alumno de una cuenta familiar (datos personales y foto).
// Los datos viven en CuentaService; la foto se guarda aparte como blob.

import 'dart:convert';
import 'dart:typed_data';

import '../../models/cuentas/cuenta.dart';
import '../../services/auth_errors.dart';
import '../../services/cuenta_service.dart';
import '../../services/storage_service.dart';
import '../errors.dart';
import '../models/solicitud.dart';
import '../store/atena_store.dart';

class AlumnosRepo {
  AlumnosRepo._();
  static final AlumnosRepo instance = AlumnosRepo._();

  static const int maxBytesFoto = 900 * 1024;

  final AtenaStore _store = AtenaStore.instance;

  static String _blobFoto(String perfilId) => 'foto.$perfilId';

  Future<List<PerfilAlumno>> perfiles(String cuentaId) =>
      CuentaService.listarPerfilesAlumno(cuentaId);

  Future<PerfilAlumno?> perfil(String perfilId) =>
      CuentaService.getPerfilAlumnoById(perfilId);

  /// Verifica que el perfil pertenezca a la cuenta.
  Future<PerfilAlumno?> perfilDeCuenta(String cuentaId, String perfilId) async {
    final lista = await perfiles(cuentaId);
    for (final p in lista) {
      if (p.id == perfilId) return p;
    }
    return null;
  }

  Future<PerfilAlumno> crear({
    required String cuentaId,
    required String nombre,
    required String apellido,
    required String dni,
    required DateTime fechaNacimiento,
    String email = '',
    String telefono = '',
  }) {
    return CuentaService.crearPerfilAlumno(
      cuentaId: cuentaId,
      documento: dni,
      nombre: nombre,
      apellido: apellido,
      fechaNacimiento: fechaNacimiento,
      email: email,
      telefono: telefono,
    );
  }

  /// Actualiza los datos personales. El DNI no puede repetirse en la cuenta.
  Future<void> actualizar({
    required String cuentaId,
    required PerfilAlumno perfil,
    required String nombre,
    required String apellido,
    required String dni,
    required DateTime fechaNacimiento,
    String email = '',
    String telefono = '',
  }) async {
    final dniDigits = dni.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^\d{7,9}$').hasMatch(dniDigits)) {
      throw const AuthException(AuthErrorCode.invalidDni);
    }
    if (nombre.trim().isEmpty || apellido.trim().isEmpty) {
      throw const AuthException(AuthErrorCode.invalidName);
    }
    final otros = await perfiles(cuentaId);
    final repetido = otros.any(
      (p) => p.id != perfil.id && p.documento == dniDigits,
    );
    if (repetido) throw const AuthException(AuthErrorCode.duplicateDni);

    final actualizado = PerfilAlumno(
      id: perfil.id,
      cuentaId: perfil.cuentaId,
      ownerAccountId: perfil.ownerAccountId,
      documento: dniDigits,
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      fechaNacimiento: fechaNacimiento,
      email: email.trim(),
      telefono: telefono.trim(),
      emancipado: perfil.emancipado,
      fechaEmancipacion: perfil.fechaEmancipacion,
      prefs: perfil.prefs,
    );
    await CuentaService.actualizarPerfilAlumno(actualizado);
    _store.revision.value++;
  }

  AlumnoSnapshot snapshot(String cuentaId, PerfilAlumno p) => AlumnoSnapshot(
    cuentaId: cuentaId,
    perfilId: p.id,
    nombre: p.nombre,
    apellido: p.apellido,
    dni: p.documento,
    fechaNacimiento: p.fechaNacimiento.millisecondsSinceEpoch == 0
        ? null
        : p.fechaNacimiento,
    email: p.email,
    telefono: p.telefono,
  );

  // ---------------------------------------------------------------------------
  // Foto
  // ---------------------------------------------------------------------------

  Future<Uint8List?> foto(String perfilId) async {
    final raw = await _store.readBlob(_blobFoto(perfilId));
    if (raw != null && raw.isNotEmpty) {
      try {
        return base64Decode(raw);
      } catch (_) {
        return null;
      }
    }

    // Migración: fotos guardadas por versiones anteriores dentro de la ficha.
    try {
      final ficha = await StorageService.instance.getJson(
        'v3_perfil_alumno_$perfilId',
      );
      final ref = (ficha?['fotoPerfilLocalPath'] ?? '').toString().trim();
      if (ref.startsWith('b64:')) {
        final b64 = ref.substring(4);
        final bytes = base64Decode(b64);
        await _store.writeBlob(_blobFoto(perfilId), b64);
        return bytes;
      }
    } catch (_) {}
    return null;
  }

  Future<void> guardarFoto(String perfilId, Uint8List bytes) async {
    if (bytes.isEmpty) throw const AtenaException(AtenaError.datosInvalidos);
    if (bytes.length > maxBytesFoto) {
      throw const AtenaException(AtenaError.archivoMuyGrande);
    }
    final ok = await _store.writeBlob(_blobFoto(perfilId), base64Encode(bytes));
    if (!ok) throw const AtenaException(AtenaError.sinEspacio);
  }

  Future<void> eliminarFoto(String perfilId) async {
    await _store.deleteBlob(_blobFoto(perfilId));
    try {
      final ficha = await StorageService.instance.getJson(
        'v3_perfil_alumno_$perfilId',
      );
      if (ficha != null && ficha['fotoPerfilLocalPath'] != null) {
        ficha.remove('fotoPerfilLocalPath');
        await StorageService.instance.setJson(
          'v3_perfil_alumno_$perfilId',
          ficha,
        );
      }
    } catch (_) {}
  }
}
