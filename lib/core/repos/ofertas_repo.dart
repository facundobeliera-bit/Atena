// lib/core/repos/ofertas_repo.dart
//
// Ofertas (cursos, salas y grupos con cupo) de cada institución.

import '../errors.dart';
import '../models/oferta.dart';
import '../models/solicitud.dart';
import '../store/atena_store.dart';
import 'solicitudes_repo.dart';

class OfertasRepo {
  OfertasRepo._();
  static final OfertasRepo instance = OfertasRepo._();

  final AtenaStore _store = AtenaStore.instance;

  String _col(String institucionId) => 'ofertas.$institucionId';

  Future<List<Oferta>> listar(
    String institucionId, {
    bool soloActivas = false,
  }) async {
    if (institucionId.isEmpty) return const <Oferta>[];
    final docs = await _store.read(_col(institucionId));
    final list = docs
        .map(Oferta.fromJson)
        .where((o) => !soloActivas || o.activa)
        .toList();
    list.sort(_orden);
    return list;
  }

  static int _orden(Oferta a, Oferta b) {
    if (a.tipo != b.tipo) return a.tipo.index.compareTo(b.tipo.index);
    final na = a.nivel?.index ?? a.bloque?.index ?? 0;
    final nb = b.nivel?.index ?? b.bloque?.index ?? 0;
    if (na != nb) return na.compareTo(nb);
    return a.nombreCompleto.toLowerCase().compareTo(
      b.nombreCompleto.toLowerCase(),
    );
  }

  Future<Oferta?> obtener(String institucionId, String ofertaId) async {
    final doc = await _store.get(_col(institucionId), ofertaId);
    return doc == null ? null : Oferta.fromJson(doc);
  }

  /// Crea una oferta nueva (id generado) o actualiza una existente.
  Future<Oferta> guardar(Oferta oferta) async {
    if (oferta.institucionId.isEmpty || oferta.titulo.trim().isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    if (oferta.cupoTotal < 1) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    if (oferta.esCurricular && oferta.nivel == null) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    if (!oferta.esCurricular && oferta.bloque == null) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    final min = oferta.edadMinima;
    final max = oferta.edadMaxima;
    if (min != null && max != null && min > max) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }

    final ahora = DateTime.now();
    final nueva = oferta.id.isEmpty
        ? Oferta(
            id: AtenaIds.next('OF'),
            institucionId: oferta.institucionId,
            tipo: oferta.tipo,
            nivel: oferta.esCurricular ? oferta.nivel : null,
            bloque: oferta.esCurricular ? null : oferta.bloque,
            titulo: oferta.titulo.trim(),
            grupo: oferta.grupo.trim(),
            turno: oferta.turno,
            horario: oferta.horario.trim(),
            dias: oferta.dias.trim(),
            cupoTotal: oferta.cupoTotal,
            edadMinima: oferta.edadMinima,
            edadMaxima: oferta.edadMaxima,
            descripcion: oferta.descripcion.trim(),
            arancel: oferta.arancel.trim(),
            activa: oferta.activa,
            creadaEl: ahora,
            actualizadaEl: ahora,
          )
        : oferta.copyWith(actualizadaEl: ahora);

    await _store.put(_col(nueva.institucionId), nueva.toJson());
    return nueva;
  }

  Future<void> cambiarActiva(
    String institucionId,
    String ofertaId,
    bool activa,
  ) async {
    final o = await obtener(institucionId, ofertaId);
    if (o == null) throw const AtenaException(AtenaError.noEncontrado);
    await _store.put(_col(institucionId), o.copyWith(activa: activa).toJson());
  }

  /// Elimina una oferta sin solicitudes activas. Si tiene, conviene pausarla.
  Future<void> eliminar(String institucionId, String ofertaId) async {
    final solicitudes = await SolicitudesRepo.instance.porInstitucion(
      institucionId,
    );
    final activas = solicitudes.any(
      (s) => s.ofertaId == ofertaId && s.estado.esActiva,
    );
    if (activas) {
      throw const AtenaException(AtenaError.ofertaConSolicitudes);
    }
    await _store.delete(_col(institucionId), ofertaId);
  }

  /// Ofertas con su ocupación (confirmados y pendientes).
  Future<List<OfertaConCupo>> conCupo(
    String institucionId, {
    bool soloActivas = false,
  }) async {
    final ofertas = await listar(institucionId, soloActivas: soloActivas);
    final solicitudes = await SolicitudesRepo.instance.porInstitucion(
      institucionId,
    );
    return ofertas.map((o) {
      var conf = 0;
      var pend = 0;
      for (final s in solicitudes) {
        if (s.ofertaId != o.id) continue;
        if (s.estado == EstadoSolicitud.confirmada) conf++;
        if (s.estado == EstadoSolicitud.pendiente) pend++;
      }
      return OfertaConCupo(oferta: o, confirmados: conf, pendientes: pend);
    }).toList();
  }
}
