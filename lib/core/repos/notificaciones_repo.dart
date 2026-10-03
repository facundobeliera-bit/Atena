// lib/core/repos/notificaciones_repo.dart
//
// Bandeja de notificaciones por cuenta (familia o institución).

import '../../services/cuenta_service.dart';
import '../models/notificacion.dart';
import '../store/atena_store.dart';

class NotificacionesRepo {
  NotificacionesRepo._();
  static final NotificacionesRepo instance = NotificacionesRepo._();

  static const int _maxPorCuenta = 300;

  final AtenaStore _store = AtenaStore.instance;

  String _col(String cuentaId) => 'notificaciones.$cuentaId';

  /// Cuenta dueña de un perfil institucional (para avisarle a la institución).
  Future<String> cuentaDeInstitucion(String institucionId) async {
    try {
      final owner = await CuentaService.getOwnerAccountIdForPerfilInstitucion(
        institucionId,
      );
      if ((owner ?? '').trim().isNotEmpty) return owner!.trim();
    } catch (_) {}
    // Registro estándar: el primer perfil institucional comparte id con la cuenta.
    return institucionId;
  }

  Future<void> enviar(Notificacion n) async {
    if (n.cuentaId.isEmpty) return;
    final doc = n.id.isEmpty
        ? Notificacion(
            id: AtenaIds.next('N'),
            cuentaId: n.cuentaId,
            perfilId: n.perfilId,
            tipo: n.tipo,
            datos: n.datos,
            titulo: n.titulo,
            mensaje: n.mensaje,
            destino: n.destino,
            destinoId: n.destinoId,
            fecha: n.fecha,
            leida: n.leida,
          ).toJson()
        : n.toJson();

    await _store.update<void>(_col(n.cuentaId), (docs) {
      docs.insert(0, doc);
      if (docs.length > _maxPorCuenta) {
        docs.removeRange(_maxPorCuenta, docs.length);
      }
    });
  }

  Future<void> enviarAInstitucion(
    String institucionId,
    Notificacion Function(String cuentaId) build,
  ) async {
    final cuenta = await cuentaDeInstitucion(institucionId);
    await enviar(build(cuenta));
  }

  bool _match(Notificacion n, String? perfilId) {
    final p = (perfilId ?? '').trim();
    if (p.isEmpty) return true;
    return n.perfilId.isEmpty || n.perfilId == p;
  }

  Future<List<Notificacion>> listar(String cuentaId, {String? perfilId}) async {
    if (cuentaId.isEmpty) return const <Notificacion>[];
    final docs = await _store.read(_col(cuentaId));
    final list = docs
        .map(Notificacion.fromJson)
        .where((n) => _match(n, perfilId))
        .toList();
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  Future<int> noLeidas(String cuentaId, {String? perfilId}) async {
    final list = await listar(cuentaId, perfilId: perfilId);
    return list.where((n) => !n.leida).length;
  }

  Future<void> marcarLeida(String cuentaId, String id, {bool leida = true}) {
    return _store.update<void>(_col(cuentaId), (docs) {
      for (final d in docs) {
        if (d['id'] == id) d['leida'] = leida;
      }
    });
  }

  Future<void> marcarTodasLeidas(String cuentaId, {String? perfilId}) {
    return _store.update<void>(_col(cuentaId), (docs) {
      for (final d in docs) {
        if (_match(Notificacion.fromJson(d), perfilId)) d['leida'] = true;
      }
    });
  }

  Future<void> eliminar(String cuentaId, String id) {
    return _store.update<void>(_col(cuentaId), (docs) {
      docs.removeWhere((d) => d['id'] == id);
    });
  }

  Future<void> eliminarTodas(String cuentaId, {String? perfilId}) {
    return _store.update<void>(_col(cuentaId), (docs) {
      docs.removeWhere((d) => _match(Notificacion.fromJson(d), perfilId));
    });
  }
}
