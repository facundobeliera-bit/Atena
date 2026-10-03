// lib/core/repos/croquis_repo.dart
//
// Croquis de aula de cada institución.

import '../errors.dart';
import '../models/croquis.dart';
import '../store/atena_store.dart';

class CroquisRepo {
  CroquisRepo._();
  static final CroquisRepo instance = CroquisRepo._();

  final AtenaStore _store = AtenaStore.instance;

  String _col(String institucionId) => 'croquis.$institucionId';

  Future<List<Croquis>> listar(String institucionId) async {
    final docs = await _store.read(_col(institucionId));
    final list = docs.map(Croquis.fromJson).toList();
    list.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    return list;
  }

  Future<Croquis?> obtener(String institucionId, String id) async {
    final d = await _store.get(_col(institucionId), id);
    return d == null ? null : Croquis.fromJson(d);
  }

  Future<Croquis> crear({
    required String institucionId,
    required String nombre,
    String ofertaId = '',
    int filas = 5,
    int columnas = 6,
  }) async {
    if (nombre.trim().isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    final c = Croquis.vacio(
      id: AtenaIds.next('CRQ'),
      institucionId: institucionId,
      nombre: nombre.trim(),
      ofertaId: ofertaId,
      filas: filas,
      columnas: columnas,
    );
    await _store.put(_col(institucionId), c.toJson());
    return c;
  }

  Future<void> guardar(Croquis c) =>
      _store.put(_col(c.institucionId), c.toJson());

  Future<void> eliminar(String institucionId, String id) =>
      _store.delete(_col(institucionId), id);
}
