// lib/core/repos/bajas_repo.dart
//
// Baja de cuentas: borra los datos de una familia o de una institución.
//
// - Familia: se borran la cuenta, sus alumnos, solicitudes, documentos, notas,
//   fotos y notificaciones. Cada institución recibe un aviso por los lugares
//   que se liberan.
// - Institución: se borran la institución, sus vacantes, eventos, avisos,
//   croquis, pedidos de documentos y perfil público. Las solicitudes activas
//   se cierran y quedan en el historial de cada familia, con un aviso.
// - En ambos casos se barren también las claves de versiones anteriores.

import '../../services/cuenta_service.dart';
import '../models/croquis.dart';
import '../models/json_utils.dart';
import '../models/notificacion.dart';
import '../models/solicitud.dart';
import '../store/atena_store.dart';
import 'instituciones_repo.dart';
import 'notificaciones_repo.dart';

class BajasRepo {
  BajasRepo._();
  static final BajasRepo instance = BajasRepo._();

  final AtenaStore _store = AtenaStore.instance;
  final NotificacionesRepo _noti = NotificacionesRepo.instance;

  // ---------------------------------------------------------------------------
  // Familia
  // ---------------------------------------------------------------------------

  Future<void> eliminarFamilia(String cuentaId) async {
    final id = cuentaId.trim();
    if (id.isEmpty) return;

    final perfiles = await CuentaService.listarPerfilesAlumno(id);
    final perfilIds = {for (final p in perfiles) p.id};
    bool propio(JsonDoc d) =>
        d['cuentaId'] == id || perfilIds.contains(d['perfilId']);

    // 1) Solicitudes: se quitan y cada institución sabe qué lugar se libera.
    final quitadas = await _store.update<List<Solicitud>>('solicitudes', (
      docs,
    ) {
      final out = docs.where(propio).map(Solicitud.fromJson).toList();
      docs.removeWhere(propio);
      return out;
    });

    final ahora = DateTime.now();
    for (final s in quitadas.where((s) => s.estado.esActiva)) {
      await _noti.enviarAInstitucion(
        s.institucionId,
        (cuenta) => Notificacion(
          id: '',
          cuentaId: cuenta,
          perfilId: s.institucionId,
          tipo: TipoNotificacion.cuentaEliminada,
          datos: {'alumno': s.alumno.nombreCompleto, 'oferta': s.ofertaNombre},
          fecha: ahora,
        ),
      );
    }

    // 2) Croquis: se liberan los bancos de los alumnos confirmados.
    final confirmadas = quitadas.where(
      (s) => s.estado == EstadoSolicitud.confirmada,
    );
    for (final s in confirmadas) {
      await _liberarBancos(s);
    }

    // 3) Documentos entregados y sus archivos.
    final pedidos = await _store.update<List<String>>('documentos', (docs) {
      final ids = docs.where(propio).map((d) => jStr(d['id'])).toList();
      docs.removeWhere(propio);
      return ids;
    });
    for (final pedido in pedidos) {
      await _store.deleteBlob('doc.$pedido');
    }

    // 4) Confirmaciones de asistencia a eventos.
    for (final col in await _store.collections('respuestas.')) {
      await _store.update<void>(col, (docs) {
        docs.removeWhere((d) => perfilIds.contains(d['perfilId']));
      });
    }

    // 5) Notas, fotos y notificaciones.
    for (final p in perfilIds) {
      await _store.drop('notas.$p');
      await _store.deleteBlob('foto.$p');
    }
    await _store.drop('notificaciones.$id');

    // 6) Cuenta, alumnos e índices.
    await _barrer({id, ...perfilIds});
  }

  /// Quita el nombre del alumno de los croquis de su curso, salvo que otro
  /// alumno confirmado de la institución tenga el mismo nombre.
  Future<void> _liberarBancos(Solicitud s) async {
    final nombre = s.alumno.nombreCompleto;
    if (nombre.isEmpty) return;

    final siguen = await _store.read('solicitudes');
    final homonimo = siguen.any((d) {
      final otra = Solicitud.fromJson(d);
      return otra.institucionId == s.institucionId &&
          otra.estado == EstadoSolicitud.confirmada &&
          otra.alumno.nombreCompleto == nombre;
    });
    if (homonimo) return;

    await _store.update<void>('croquis.${s.institucionId}', (docs) {
      for (var i = 0; i < docs.length; i++) {
        final c = Croquis.fromJson(docs[i]);
        if (c.ofertaId.isNotEmpty && c.ofertaId != s.ofertaId) continue;
        if (!c.asientos.contains(nombre)) continue;
        docs[i] = Croquis(
          id: c.id,
          institucionId: c.institucionId,
          nombre: c.nombre,
          ofertaId: c.ofertaId,
          filas: c.filas,
          columnas: c.columnas,
          asientos: [for (final a in c.asientos) a == nombre ? '' : a],
          actualizadoEl: DateTime.now(),
        ).toJson();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Institución
  // ---------------------------------------------------------------------------

  Future<void> eliminarInstitucion({
    required String institucionId,
    required String ownerAccountId,
  }) async {
    final id = institucionId.trim();
    final owner = ownerAccountId.trim();
    if (id.isEmpty) return;

    final inst = await InstitucionesRepo.instance.obtener(id);
    final nombre = inst?.nombre.trim() ?? '';

    // 1) Solicitudes activas: se cierran y se avisa a cada familia.
    final cerradas = await _store.update<List<Solicitud>>('solicitudes', (
      docs,
    ) {
      final out = <Solicitud>[];
      for (var i = 0; i < docs.length; i++) {
        final s = Solicitud.fromJson(docs[i]);
        if (s.institucionId != id || !s.estado.esActiva) continue;
        final cerrada = s.conEstado(EstadoSolicitud.canceladaPorInstitucion);
        docs[i] = cerrada.toJson();
        out.add(cerrada);
      }
      return out;
    });

    final ahora = DateTime.now();
    for (final s in cerradas) {
      await _noti.enviar(
        Notificacion(
          id: '',
          cuentaId: s.alumno.cuentaId,
          perfilId: s.alumno.perfilId,
          tipo: TipoNotificacion.institucionEliminada,
          datos: {
            'institucion': s.institucionNombre.isEmpty
                ? nombre
                : s.institucionNombre,
            'alumno': s.alumno.nombreCompleto,
            'oferta': s.ofertaNombre,
          },
          destino: DestinoNotificacion.solicitud,
          destinoId: s.id,
          fecha: ahora,
        ),
      );
    }

    // 2) Pedidos de documentos y archivos recibidos.
    final pedidos = await _store.update<List<String>>('documentos', (docs) {
      bool deEsta(JsonDoc d) => d['institucionId'] == id;
      final ids = docs.where(deEsta).map((d) => jStr(d['id'])).toList();
      docs.removeWhere(deEsta);
      return ids;
    });
    for (final pedido in pedidos) {
      await _store.deleteBlob('doc.$pedido');
    }

    // 3) Perfil público con su logo y fotos.
    final repo = InstitucionesRepo.instance;
    final perfil = await repo.perfilPublico(id);
    for (final img in [perfil.logoId, ...perfil.fotoIds]) {
      await repo.eliminarImagen(img);
    }
    await _store.deleteSingle('perfilpublico.$id');
    await _store.delete('instituciones.indice', id);

    // 4) Vacantes, calendario, avisos, croquis y bandeja.
    for (final col in [
      'ofertas',
      'eventos',
      'respuestas',
      'avisos',
      'croquis',
    ]) {
      await _store.drop('$col.$id');
    }
    await _store.drop('notificaciones.$id');
    if (owner.isNotEmpty) await _store.drop('notificaciones.$owner');

    // 5) Credenciales, cuenta contenedora e índices.
    await _barrer({id, if (owner.isNotEmpty) owner});
  }

  // ---------------------------------------------------------------------------

  /// Borra las claves que nombran a estos ids o que los guardan como valor
  /// (índices por email o DNI, alias, sesión), incluidas las de versiones
  /// anteriores de la app.
  Future<void> _barrer(Set<String> ids) async {
    final validos = ids
        .map((s) => s.trim())
        .where((s) => s.length >= 3)
        .toSet();
    if (validos.isEmpty) return;

    final patrones = [
      for (final id in validos)
        RegExp('(^|[^A-Za-z0-9])${RegExp.escape(id)}(\$|[^A-Za-z0-9])'),
    ];

    final borrar = <String>[];
    for (final k in await _store.rawKeys()) {
      if (patrones.any((p) => p.hasMatch(k))) {
        borrar.add(k);
        continue;
      }
      final v = await _store.rawValue(k);
      if (v is String && v.length < 80 && validos.contains(v.trim())) {
        borrar.add(k);
      }
    }
    await _store.removeRaw(borrar);
  }
}
