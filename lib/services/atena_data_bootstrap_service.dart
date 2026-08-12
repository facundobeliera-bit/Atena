// lib/services/atena_data_bootstrap_service.dart
//
// ATENA – DATA BOOTSTRAP
//
// Inicialización liviana de la persistencia local.
// No crea datos nuevos de dominio: reconstruye índices derivados a partir
// de registros que ya existen en StorageService.
//
// FIX PERSISTENCIA DE CUENTAS (agosto 2026):
// - Reconstruye el índice cuenta_email_<email> desde las cuentas persistidas.
// - Si el índice de email falta o apunta a una cuenta inexistente, lo repara.
// - Esto evita que una cuenta correctamente guardada quede invisible para
//   Login después de cerrar/reabrir la aplicación.
// - No altera contraseñas, perfiles ni sesión.

import '../models/cuentas/cuenta.dart';
import 'institucion_storage_repository.dart';
import 'storage_service.dart';

class AtenaDataBootstrapService {
  AtenaDataBootstrapService._();

  static final AtenaDataBootstrapService instance =
      AtenaDataBootstrapService._();

  final StorageService _storage = StorageService.instance;
  final InstitucionStorageRepository _instituciones =
      InstitucionStorageRepository.instance;

  bool _initialized = false;
  Future<void>? _inflight;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();

    final current = _inflight;
    if (current != null) return current;

    final future = _initializeInternal();
    _inflight = future;

    return future.whenComplete(() {
      _inflight = null;
    });
  }

  Future<void> _initializeInternal() async {
    try {
      // Inicializa el acceso común a StorageService sin crear datos.
      final keys = await _storage.getKeys();

      // Reconstruye índices derivados de cuentas antes de que Login los use.
      await _rebuildCuentaEmailIndex(keys);

      // Reconstruye el índice institucional desde las keys existentes.
      // Esto recupera también datos creados por versiones anteriores.
      await _instituciones.rebuildIndex();

      _initialized = true;
    } catch (_) {
      // El bootstrap es best-effort: una falla de persistencia no debe
      // impedir que la aplicación continúe hacia su flujo normal.
    }
  }

  /// Repara el índice secundario email -> cuenta a partir de la fuente
  /// persistida primaria: cuenta_<cuentaId>.
  ///
  /// Es deliberadamente idempotente: ejecutar el bootstrap varias veces no
  /// duplica cuentas ni modifica sus datos; solo corrige índices derivados.
  Future<void> _rebuildCuentaEmailIndex(Set<String> keys) async {
    const accountPrefix = 'cuenta_';
    const emailIndexPrefix = 'cuenta_email_';
    const ultimoPerfilPrefix = 'cuenta_ultimo_perfil_';

    for (final key in keys) {
      if (!key.startsWith(accountPrefix)) continue;
      if (key.startsWith(emailIndexPrefix)) continue;
      if (key.startsWith(ultimoPerfilPrefix)) continue;

      final raw = await _storage.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;

      Cuenta cuenta;
      try {
        cuenta = Cuenta.fromJson(raw);
      } catch (_) {
        continue;
      }

      final email = cuenta.email.trim().toLowerCase();
      final cuentaId = cuenta.id.trim();
      if (email.isEmpty || cuentaId.isEmpty) continue;

      final indexKey = '$emailIndexPrefix$email';
      final indexedId = (await _storage.getString(indexKey) ?? '').trim();

      if (indexedId == cuentaId) continue;

      // El índice es derivado: siempre debe apuntar al registro primario
      // que acabamos de leer y validar.
      await _storage.setString(indexKey, cuentaId);
    }
  }
}
