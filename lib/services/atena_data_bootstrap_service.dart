// lib/services/atena_data_bootstrap_service.dart
//
// ATENA – DATA BOOTSTRAP
//
// Inicialización liviana de la persistencia local.
// No crea datos, no altera sesión y no cambia el routing.
// Su función es validar/reconstruir índices persistidos antes de que la UI
// comience a consumir el dominio local.

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
      await _storage.getKeys();

      // Reconstruye el índice institucional desde las keys existentes.
      // Esto recupera también datos creados por versiones anteriores.
      await _instituciones.rebuildIndex();

      _initialized = true;
    } catch (_) {
      // El bootstrap es best-effort: una falla de persistencia no debe
      // impedir que la aplicación continúe hacia su flujo normal.
    }
  }
}
