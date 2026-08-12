// lib/services/atena_data_bootstrap_service.dart
//
// ATENA - DATA BOOTSTRAP
//
// Inicializacion liviana de la persistencia local.
//
// Responsabilidades:
// - No crea datos nuevos de dominio.
// - Reconstruye indices derivados a partir de registros persistidos.
// - Repara el indice cuenta_email_<email> cuando falta o es incorrecto.
// - Reconstruye el indice institucional.
// - Repara relaciones Cuenta -> Perfil cuando un perfil persistido quedo
//   fuera de la lista de perfiles de su cuenta.
//
// FIX PERSISTENCIA DE CUENTAS:
// - Reconstruye el indice cuenta_email_<email> desde las cuentas persistidas.
// - Si el indice de email falta o apunta a una cuenta inexistente, lo repara.
// - Esto evita que una cuenta correctamente guardada quede invisible para
//   Login despues de cerrar/reabrir la aplicacion.
// - No altera contrasenas, perfiles ni sesion.
//
// FIX RELACIONES CUENTA -> PERFIL:
// - Detecta perfiles de alumno e institucion realmente persistidos.
// - Obtiene su ownerAccountId/cuentaId.
// - Verifica que la cuenta exista.
// - Si el perfil no figura en la lista de perfiles de la cuenta,
//   lo reincorpora.
// - La reparacion es idempotente y best-effort.

import '../models/cuentas/cuenta.dart';
import 'cuenta_service.dart';
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

  /// Inicializa la persistencia derivada de ATENA.
  ///
  /// La inicializacion es:
  /// - idempotente;
  /// - segura ante llamadas concurrentes;
  /// - best-effort ante fallos de almacenamiento.
  Future<void> initialize() {
    if (_initialized) {
      return Future<void>.value();
    }

    final current = _inflight;

    if (current != null) {
      return current;
    }

    final future = _initializeInternal();

    _inflight = future;

    return future.whenComplete(() {
      _inflight = null;
    });
  }

  Future<void> _initializeInternal() async {
    try {
      // Inicializa el acceso comun a StorageService sin crear datos.
      final keys = await _storage.getKeys();

      // Reconstruye indices derivados de cuentas antes de que Login los use.
      await _rebuildCuentaEmailIndex(keys);

      // Reconstruye el indice institucional desde las keys existentes.
      await _instituciones.rebuildIndex();

      // Repara relaciones Cuenta -> Perfil a partir de los perfiles que
      // realmente existen en StorageService.
      await _repairAccountProfileLinks();

      _initialized = true;
    } catch (_) {
      // Best-effort:
      // una falla de almacenamiento no debe impedir el arranque.
    }
  }

  /// Repara las relaciones Cuenta -> Perfil a partir de los perfiles
  /// realmente persistidos.
  ///
  /// Esto evita depender exclusivamente de una lista o indice de perfiles
  /// que pudiera haber quedado incompleto en una version anterior.
  Future<void> _repairAccountProfileLinks() async {
    final keys = await _storage.getKeys();

    const perfilAlumnoPrefix = 'perfil_alumno_';
    const perfilInstitucionPrefix = 'perfil_institucion_';

    final alumnos = <String>{};
    final instituciones = <String>{};

    for (final key in keys) {
      if (key.startsWith(perfilAlumnoPrefix)) {
        final id = key.substring(perfilAlumnoPrefix.length).trim();

        if (id.isNotEmpty) {
          alumnos.add(id);
        }
      } else if (key.startsWith(perfilInstitucionPrefix)) {
        final id = key.substring(perfilInstitucionPrefix.length).trim();

        if (id.isNotEmpty) {
          instituciones.add(id);
        }
      }
    }

    // ------------------------------------------------------------
    // PERFIS DE ALUMNO
    // ------------------------------------------------------------

    for (final perfilId in alumnos) {
      try {
        final perfil = await CuentaService.getPerfilAlumnoById(perfilId);

        if (perfil == null) {
          continue;
        }

        final owner = (perfil.ownerAccountId ?? perfil.cuentaId).trim();

        if (owner.isEmpty) {
          continue;
        }

        final cuenta = await CuentaService.getCuentaById(owner);

        if (cuenta == null) {
          continue;
        }

        final normalized = cuenta.perfilesAlumnoIds
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final perfilPersistidoId = perfil.id.trim();

        if (perfilPersistidoId.isEmpty) {
          continue;
        }

        if (!normalized.contains(perfilPersistidoId)) {
          cuenta.perfilesAlumnoIds = List<String>.from(normalized)
            ..add(perfilPersistidoId);

          await CuentaService.actualizarCuenta(cuenta);
        }
      } catch (_) {
        // Reparacion individual best-effort.
      }
    }

    // ------------------------------------------------------------
    // PERFILES DE INSTITUCION
    // ------------------------------------------------------------

    for (final perfilId in instituciones) {
      try {
        final perfil = await CuentaService.getPerfilInstitucionById(perfilId);

        if (perfil == null) {
          continue;
        }

        final owner = (perfil.ownerAccountId ?? perfil.cuentaId).trim();

        if (owner.isEmpty) {
          continue;
        }

        final cuenta = await CuentaService.getCuentaById(owner);

        if (cuenta == null) {
          continue;
        }

        final normalized = cuenta.perfilesInstitucionIds
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final perfilPersistidoId = perfil.id.trim();

        if (perfilPersistidoId.isEmpty) {
          continue;
        }

        if (!normalized.contains(perfilPersistidoId)) {
          cuenta.perfilesInstitucionIds = List<String>.from(normalized)
            ..add(perfilPersistidoId);

          await CuentaService.actualizarCuenta(cuenta);
        }
      } catch (_) {
        // Reparacion individual best-effort.
      }
    }
  }

  /// Repara el indice secundario:
  ///
  ///     email -> cuentaId
  ///
  /// utilizando como fuente primaria los registros:
  ///
  ///     cuenta_<cuentaId>
  ///
  /// Es deliberadamente idempotente:
  /// ejecutar el bootstrap varias veces no duplica cuentas ni modifica
  /// contrasenas, perfiles u otros datos de dominio.
  Future<void> _rebuildCuentaEmailIndex(Set<String> keys) async {
    const accountPrefix = 'cuenta_';
    const emailIndexPrefix = 'cuenta_email_';
    const ultimoPerfilPrefix = 'cuenta_ultimo_perfil_';

    for (final key in keys) {
      if (!key.startsWith(accountPrefix)) {
        continue;
      }

      // Los indices derivados no son cuentas primarias.
      if (key.startsWith(emailIndexPrefix)) {
        continue;
      }

      // El ultimo perfil seleccionado tampoco es una cuenta.
      if (key.startsWith(ultimoPerfilPrefix)) {
        continue;
      }

      final raw = await _storage.getString(key);

      if (raw == null || raw.trim().isEmpty) {
        continue;
      }

      Cuenta cuenta;

      try {
        cuenta = Cuenta.fromJson(raw);
      } catch (_) {
        // Registro invalido: no puede reconstruirse su indice.
        continue;
      }

      final email = cuenta.email.trim().toLowerCase();
      final cuentaId = cuenta.id.trim();

      if (email.isEmpty || cuentaId.isEmpty) {
        continue;
      }

      final indexKey = '$emailIndexPrefix$email';

      final indexedId = (await _storage.getString(indexKey) ?? '').trim();

      if (indexedId == cuentaId) {
        continue;
      }

      // El indice es derivado:
      // siempre debe apuntar al registro primario que acabamos de
      // leer y validar.
      await _storage.setString(indexKey, cuentaId);
    }
  }
}
