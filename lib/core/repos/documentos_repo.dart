// lib/core/repos/documentos_repo.dart
//
// Pedidos de documentación entre institución y alumnos, con archivos adjuntos.
// Los archivos se guardan aparte (blobs) para no inflar los listados.

import 'dart:convert';
import 'dart:typed_data';

import '../errors.dart';
import '../models/documento.dart';
import '../models/notificacion.dart';
import '../store/atena_store.dart';
import 'notificaciones_repo.dart';

class DocumentosRepo {
  DocumentosRepo._();
  static final DocumentosRepo instance = DocumentosRepo._();

  static const String _col = 'documentos';

  /// Tamaño máximo por archivo.
  static const int maxBytes = 3 * 1024 * 1024;

  static const Set<String> mimesPermitidos = {
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
  };

  final AtenaStore _store = AtenaStore.instance;
  final NotificacionesRepo _noti = NotificacionesRepo.instance;

  static String _blob(String pedidoId) => 'doc.$pedidoId';

  static String mimeDesdeNombre(String nombre) {
    final n = nombre.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<List<PedidoDocumento>> _where(bool Function(JsonDoc d) test) async {
    final docs = await _store.read(_col);
    final list = docs.where(test).map(PedidoDocumento.fromJson).toList();
    list.sort((a, b) => b.actualizadoEl.compareTo(a.actualizadoEl));
    return list;
  }

  Future<List<PedidoDocumento>> porInstitucion(String institucionId) =>
      _where((d) => d['institucionId'] == institucionId);

  Future<List<PedidoDocumento>> porPerfil(String perfilId) =>
      _where((d) => d['perfilId'] == perfilId);

  Future<PedidoDocumento?> obtener(String id) async {
    final d = await _store.get(_col, id);
    return d == null ? null : PedidoDocumento.fromJson(d);
  }

  /// La institución pide un documento a un alumno.
  Future<PedidoDocumento> solicitar({
    required String institucionId,
    required String institucionNombre,
    required String cuentaId,
    required String perfilId,
    required String alumnoNombre,
    required TipoDocumento tipo,
    String detalle = '',
    DateTime? fechaLimite,
  }) async {
    if (institucionId.isEmpty || cuentaId.isEmpty || perfilId.isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    if (tipo == TipoDocumento.otro && detalle.trim().isEmpty) {
      throw const AtenaException(AtenaError.datosInvalidos);
    }
    final ahora = DateTime.now();
    final pedido = PedidoDocumento(
      id: AtenaIds.next('DOC'),
      institucionId: institucionId,
      institucionNombre: institucionNombre,
      cuentaId: cuentaId,
      perfilId: perfilId,
      alumnoNombre: alumnoNombre,
      tipo: tipo,
      detalle: detalle.trim(),
      fechaLimite: fechaLimite,
      estado: EstadoPedidoDocumento.pendiente,
      creadoEl: ahora,
      actualizadoEl: ahora,
    );
    await _store.put(_col, pedido.toJson());

    await _noti.enviar(
      Notificacion(
        id: '',
        cuentaId: cuentaId,
        perfilId: perfilId,
        tipo: TipoNotificacion.documentoSolicitado,
        datos: {
          'institucion': institucionNombre,
          'documento': tipo.name,
          'detalle': pedido.detalle,
          if (fechaLimite != null) 'fechaLimite': fechaLimite.toIso8601String(),
        },
        destino: DestinoNotificacion.documento,
        destinoId: pedido.id,
        fecha: ahora,
      ),
    );
    return pedido;
  }

  /// El alumno (o su familia) sube el archivo pedido.
  Future<PedidoDocumento> entregar({
    required String pedidoId,
    required String perfilId,
    required String nombreArchivo,
    required Uint8List bytes,
  }) async {
    final pedido = await obtener(pedidoId);
    if (pedido == null) throw const AtenaException(AtenaError.noEncontrado);
    if (pedido.perfilId != perfilId) {
      throw const AtenaException(AtenaError.noAutorizado);
    }
    if (!pedido.requiereAccionAlumno &&
        pedido.estado != EstadoPedidoDocumento.entregado) {
      throw const AtenaException(AtenaError.estadoInvalido);
    }
    if (bytes.isEmpty) throw const AtenaException(AtenaError.datosInvalidos);
    if (bytes.length > maxBytes) {
      throw const AtenaException(AtenaError.archivoMuyGrande);
    }
    final mime = mimeDesdeNombre(nombreArchivo);
    if (!mimesPermitidos.contains(mime)) {
      throw const AtenaException(AtenaError.formatoNoSoportado);
    }

    final ok = await _store.writeBlob(_blob(pedidoId), base64Encode(bytes));
    if (!ok) throw const AtenaException(AtenaError.sinEspacio);

    final actualizado = pedido.copyWith(
      estado: EstadoPedidoDocumento.entregado,
      archivo: ArchivoAdjunto(
        id: AtenaIds.next('ARC'),
        nombre: nombreArchivo,
        mime: mime,
        bytes: bytes.length,
        subidoEl: DateTime.now(),
      ),
      observacion: '',
    );
    await _store.put(_col, actualizado.toJson());

    await _noti.enviarAInstitucion(
      pedido.institucionId,
      (cuenta) => Notificacion(
        id: '',
        cuentaId: cuenta,
        perfilId: pedido.institucionId,
        tipo: TipoNotificacion.documentoEntregado,
        datos: {
          'alumno': pedido.alumnoNombre,
          'documento': pedido.tipo.name,
          'detalle': pedido.detalle,
        },
        destino: DestinoNotificacion.documento,
        destinoId: pedido.id,
        fecha: DateTime.now(),
      ),
    );
    return actualizado;
  }

  /// La institución aprueba o rechaza un documento entregado.
  Future<PedidoDocumento> revisar({
    required String pedidoId,
    required String institucionId,
    required bool aprobado,
    String observacion = '',
  }) async {
    final pedido = await obtener(pedidoId);
    if (pedido == null) throw const AtenaException(AtenaError.noEncontrado);
    if (pedido.institucionId != institucionId) {
      throw const AtenaException(AtenaError.noAutorizado);
    }
    if (pedido.estado != EstadoPedidoDocumento.entregado) {
      throw const AtenaException(AtenaError.estadoInvalido);
    }

    final actualizado = pedido.copyWith(
      estado: aprobado
          ? EstadoPedidoDocumento.aprobado
          : EstadoPedidoDocumento.rechazado,
      observacion: observacion.trim(),
    );
    await _store.put(_col, actualizado.toJson());

    await _noti.enviar(
      Notificacion(
        id: '',
        cuentaId: pedido.cuentaId,
        perfilId: pedido.perfilId,
        tipo: aprobado
            ? TipoNotificacion.documentoAprobado
            : TipoNotificacion.documentoRechazado,
        datos: {
          'institucion': pedido.institucionNombre,
          'documento': pedido.tipo.name,
          'detalle': pedido.detalle,
          if (observacion.trim().isNotEmpty) 'nota': observacion.trim(),
        },
        destino: DestinoNotificacion.documento,
        destinoId: pedido.id,
        fecha: DateTime.now(),
      ),
    );
    return actualizado;
  }

  /// La institución cancela un pedido que ya no necesita.
  Future<void> cancelar({
    required String pedidoId,
    required String institucionId,
  }) async {
    final pedido = await obtener(pedidoId);
    if (pedido == null) throw const AtenaException(AtenaError.noEncontrado);
    if (pedido.institucionId != institucionId) {
      throw const AtenaException(AtenaError.noAutorizado);
    }
    await _store.put(
      _col,
      pedido.copyWith(estado: EstadoPedidoDocumento.cancelado).toJson(),
    );
  }

  Future<Uint8List?> archivo(String pedidoId) async {
    final raw = await _store.readBlob(_blob(pedidoId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }
}
