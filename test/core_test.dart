// test/core_test.dart
//
// Reglas de negocio de la capa de datos: ofertas, solicitudes, notificaciones,
// calendario, avisos, documentos y directorio de instituciones.

import 'dart:typed_data';

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> expectAtenaError(Future<Object?> f, AtenaError error) async {
  try {
    await f;
    fail('Se esperaba AtenaException(${error.name})');
  } on AtenaException catch (e) {
    expect(e.error, error);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetStorage);

  group('Ofertas', () {
    test('valida datos obligatorios', () async {
      final repo = OfertasRepo.instance;
      await expectAtenaError(
        repo.guardar(ofertaDemo(cupo: 0)),
        AtenaError.datosInvalidos,
      );
      await expectAtenaError(
        repo.guardar(ofertaDemo(titulo: '  ')),
        AtenaError.datosInvalidos,
      );
    });

    test('crea con id y lista ordenado', () async {
      final repo = OfertasRepo.instance;
      final a = await repo.guardar(ofertaDemo(titulo: '2° grado'));
      final b = await repo.guardar(ofertaDemo(titulo: '1° grado'));
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(b.id));
      final lista = await repo.listar('INST_1');
      expect(lista.map((o) => o.titulo), ['1° grado', '2° grado']);
    });

    test('no se elimina con solicitudes activas', () async {
      final oferta = await OfertasRepo.instance.guardar(ofertaDemo());
      await SolicitudesRepo.instance.crear(
        alumno: alumnoDemo(),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );
      await expectAtenaError(
        OfertasRepo.instance.eliminar('INST_1', oferta.id),
        AtenaError.ofertaConSolicitudes,
      );
    });
  });

  group('Solicitudes', () {
    late Oferta oferta;

    setUp(() async {
      oferta = await OfertasRepo.instance.guardar(ofertaDemo(cupo: 1));
    });

    test('crea pendiente y avisa a alumno e institución', () async {
      final s = await SolicitudesRepo.instance.crear(
        alumno: alumnoDemo(),
        institucionNombre: 'Escuela San Martín',
        oferta: oferta,
        mensaje: 'Hola',
      );
      expect(s.estado, EstadoSolicitud.pendiente);
      expect(s.historial, hasLength(1));

      final alumno = await NotificacionesRepo.instance.listar('C_1');
      expect(alumno.single.tipo, TipoNotificacion.solicitudEnviada);
      expect(alumno.single.destinoId, s.id);

      // Sin cuenta registrada, la cuenta de la institución es su propio id.
      final inst = await NotificacionesRepo.instance.listar('INST_1');
      expect(inst.single.tipo, TipoNotificacion.solicitudRecibida);
      expect(inst.single.dato('alumno'), 'Lucía Gómez');
    });

    test('no permite duplicadas activas', () async {
      await SolicitudesRepo.instance.crear(
        alumno: alumnoDemo(),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );
      await expectAtenaError(
        SolicitudesRepo.instance.crear(
          alumno: alumnoDemo(),
          institucionNombre: 'Escuela',
          oferta: oferta,
        ),
        AtenaError.solicitudDuplicada,
      );
    });

    test('oferta pausada no recibe solicitudes', () async {
      await OfertasRepo.instance.cambiarActiva('INST_1', oferta.id, false);
      await expectAtenaError(
        SolicitudesRepo.instance.crear(
          alumno: alumnoDemo(),
          institucionNombre: 'Escuela',
          oferta: oferta,
        ),
        AtenaError.ofertaInactiva,
      );
    });

    test('respeta el cupo al confirmar y al crear', () async {
      final repo = SolicitudesRepo.instance;
      final s1 = await repo.crear(
        alumno: alumnoDemo(perfilId: 'P_1'),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );
      final s2 = await repo.crear(
        alumno: alumnoDemo(perfilId: 'P_2', cuentaId: 'C_2', nombre: 'Juan'),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );

      final ok = await repo.responder(
        s1.id,
        institucionId: 'INST_1',
        aceptar: true,
      );
      expect(ok.estado, EstadoSolicitud.confirmada);

      await expectAtenaError(
        repo.responder(s2.id, institucionId: 'INST_1', aceptar: true),
        AtenaError.sinCupo,
      );

      await expectAtenaError(
        repo.crear(
          alumno: alumnoDemo(perfilId: 'P_3', cuentaId: 'C_3'),
          institucionNombre: 'Escuela',
          oferta: oferta,
        ),
        AtenaError.sinCupo,
      );

      final conCupo = await OfertasRepo.instance.conCupo('INST_1');
      expect(conCupo.single.confirmados, 1);
      expect(conCupo.single.pendientes, 1);
      expect(conCupo.single.completa, isTrue);
    });

    test('solo la institución dueña responde y solo pendientes', () async {
      final repo = SolicitudesRepo.instance;
      final s = await repo.crear(
        alumno: alumnoDemo(),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );
      await expectAtenaError(
        repo.responder(s.id, institucionId: 'OTRA', aceptar: true),
        AtenaError.noAutorizado,
      );
      await repo.responder(
        s.id,
        institucionId: 'INST_1',
        aceptar: false,
        nota: 'Sin vacantes para la edad',
      );
      await expectAtenaError(
        repo.responder(s.id, institucionId: 'INST_1', aceptar: true),
        AtenaError.estadoInvalido,
      );

      final n = await NotificacionesRepo.instance.listar('C_1');
      expect(n.first.tipo, TipoNotificacion.solicitudRechazada);
      expect(n.first.dato('nota'), 'Sin vacantes para la edad');
    });

    test('el alumno cancela solo las propias', () async {
      final repo = SolicitudesRepo.instance;
      final s = await repo.crear(
        alumno: alumnoDemo(),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );
      await expectAtenaError(
        repo.cancelar(s.id, perfilId: 'OTRO'),
        AtenaError.noAutorizado,
      );
      final c = await repo.cancelar(s.id, perfilId: 'P_1');
      expect(c.estado, EstadoSolicitud.canceladaPorAlumno);
      await expectAtenaError(
        repo.cancelar(s.id, perfilId: 'P_1'),
        AtenaError.estadoInvalido,
      );

      final inst = await NotificacionesRepo.instance.listar('INST_1');
      expect(inst.first.tipo, TipoNotificacion.solicitudCancelada);
    });

    test('la baja libera el cupo', () async {
      final repo = SolicitudesRepo.instance;
      final s = await repo.crear(
        alumno: alumnoDemo(),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );
      await repo.responder(s.id, institucionId: 'INST_1', aceptar: true);
      final baja = await repo.darDeBaja(s.id, institucionId: 'INST_1');
      expect(baja.estado, EstadoSolicitud.canceladaPorInstitucion);
      expect(baja.historial.map((h) => h.estado), [
        EstadoSolicitud.pendiente,
        EstadoSolicitud.confirmada,
        EstadoSolicitud.canceladaPorInstitucion,
      ]);
      final otra = await repo.crear(
        alumno: alumnoDemo(perfilId: 'P_9', cuentaId: 'C_9'),
        institucionNombre: 'Escuela',
        oferta: oferta,
      );
      expect(otra.estado, EstadoSolicitud.pendiente);
    });
  });

  group('Notificaciones', () {
    test('filtra por perfil y marca leídas', () async {
      final repo = NotificacionesRepo.instance;
      for (final p in ['P_1', 'P_2', '']) {
        await repo.enviar(
          Notificacion(
            id: '',
            cuentaId: 'C_1',
            perfilId: p,
            tipo: TipoNotificacion.aviso,
            fecha: DateTime.now(),
          ),
        );
      }
      expect(await repo.listar('C_1'), hasLength(3));
      expect(await repo.listar('C_1', perfilId: 'P_1'), hasLength(2));
      expect(await repo.noLeidas('C_1', perfilId: 'P_1'), 2);
      await repo.marcarTodasLeidas('C_1', perfilId: 'P_1');
      expect(await repo.noLeidas('C_1'), 1);
    });
  });

  group('Calendario y avisos', () {
    test('el alumno ve solo eventos de sus ofertas confirmadas', () async {
      final a = await OfertasRepo.instance.guardar(ofertaDemo(titulo: 'A'));
      final b = await OfertasRepo.instance.guardar(ofertaDemo(titulo: 'B'));
      final s = await SolicitudesRepo.instance.crear(
        alumno: alumnoDemo(),
        institucionNombre: 'Escuela',
        oferta: a,
      );

      final cal = CalendarioRepo.instance;
      Evento ev(String titulo, List<String> ofertas) => Evento(
        id: '',
        institucionId: 'INST_1',
        institucionNombre: 'Escuela',
        tipo: TipoEvento.reunion,
        titulo: titulo,
        inicio: DateTime(2026, 4, 1),
        ofertaIds: ofertas,
        creadoEl: DateTime.now(),
      );

      await cal.guardarEvento(ev('Para todos', const []));
      expect(await cal.eventosAlumno('P_1'), isEmpty);

      await SolicitudesRepo.instance.responder(
        s.id,
        institucionId: 'INST_1',
        aceptar: true,
      );
      await cal.guardarEvento(ev('Solo A', [a.id]));
      await cal.guardarEvento(ev('Solo B', [b.id]));

      final visibles = await cal.eventosAlumno('P_1');
      expect(visibles.map((e) => e.titulo).toSet(), {'Para todos', 'Solo A'});

      final n = await NotificacionesRepo.instance.listar('C_1');
      expect(
        n.where((x) => x.tipo == TipoNotificacion.eventoPublicado),
        hasLength(1),
      );
    });

    test('aviso llega a cada alumno confirmado una vez', () async {
      final a = await OfertasRepo.instance.guardar(ofertaDemo(cupo: 5));
      for (final p in ['P_1', 'P_2']) {
        final s = await SolicitudesRepo.instance.crear(
          alumno: alumnoDemo(perfilId: p, cuentaId: 'C_$p'),
          institucionNombre: 'Escuela',
          oferta: a,
        );
        await SolicitudesRepo.instance.responder(
          s.id,
          institucionId: 'INST_1',
          aceptar: true,
        );
      }
      final aviso = await CalendarioRepo.instance.enviarAviso(
        institucionId: 'INST_1',
        institucionNombre: 'Escuela',
        titulo: 'Acto patrio',
        mensaje: 'Traer escarapela',
      );
      expect(aviso.destinatarios, 2);
      final n = await NotificacionesRepo.instance.listar('C_P_1');
      expect(n.first.tipo, TipoNotificacion.aviso);
      expect(n.first.titulo, 'Acto patrio');
    });
  });

  group('Documentos', () {
    test('pedido, entrega y revisión', () async {
      final repo = DocumentosRepo.instance;
      final pedido = await repo.solicitar(
        institucionId: 'INST_1',
        institucionNombre: 'Escuela',
        cuentaId: 'C_1',
        perfilId: 'P_1',
        alumnoNombre: 'Lucía Gómez',
        tipo: TipoDocumento.certificadoMedico,
      );
      expect(pedido.estado, EstadoPedidoDocumento.pendiente);

      await expectAtenaError(
        repo.entregar(
          pedidoId: pedido.id,
          perfilId: 'P_1',
          nombreArchivo: 'virus.exe',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        AtenaError.formatoNoSoportado,
      );
      await expectAtenaError(
        repo.entregar(
          pedidoId: pedido.id,
          perfilId: 'P_1',
          nombreArchivo: 'grande.pdf',
          bytes: Uint8List(DocumentosRepo.maxBytes + 1),
        ),
        AtenaError.archivoMuyGrande,
      );

      final entregado = await repo.entregar(
        pedidoId: pedido.id,
        perfilId: 'P_1',
        nombreArchivo: 'certificado.pdf',
        bytes: Uint8List.fromList(List<int>.filled(100, 7)),
      );
      expect(entregado.estado, EstadoPedidoDocumento.entregado);
      expect(entregado.archivo?.mime, 'application/pdf');
      expect((await repo.archivo(pedido.id))?.length, 100);

      final revisado = await repo.revisar(
        pedidoId: pedido.id,
        institucionId: 'INST_1',
        aprobado: false,
        observacion: 'Falta la firma',
      );
      expect(revisado.estado, EstadoPedidoDocumento.rechazado);
      expect(revisado.requiereAccionAlumno, isTrue);

      final n = await NotificacionesRepo.instance.listar('C_1');
      expect(n.first.tipo, TipoNotificacion.documentoRechazado);
      final inst = await NotificacionesRepo.instance.listar('INST_1');
      expect(inst.first.tipo, TipoNotificacion.documentoEntregado);
    });
  });

  group('Directorio', () {
    test('indexa y busca sin importar tildes', () async {
      final repo = InstitucionesRepo.instance;
      await repo.guardar(institucionDemo());
      await repo.guardar(
        institucionDemo(
          id: 'INST_2',
          nombre: 'Club Atlético Norte',
          ciudad: 'Rosario',
          provincia: 'Santa Fe',
          niveles: const [],
          bloques: const [BloqueExtracurricular.deporteYMovimiento],
        ),
      );

      expect(await repo.listar(), hasLength(2));
      final porTexto = await repo.buscar(
        const FiltroInstituciones(texto: 'cordoba'),
      );
      expect(porTexto.single.id, 'INST_1');

      final porNivel = await repo.buscar(
        const FiltroInstituciones(nivel: NivelCurricular.primaria),
      );
      expect(porNivel.single.nombre, 'Escuela San Martín');

      final porBloque = await repo.buscar(
        const FiltroInstituciones(
          bloque: BloqueExtracurricular.deporteYMovimiento,
        ),
      );
      expect(porBloque, hasLength(2));
    });

    test('perfil público e imágenes', () async {
      final repo = InstitucionesRepo.instance;
      await repo.guardar(institucionDemo());
      final img = await repo.guardarImagen(Uint8List.fromList([9, 9, 9]));
      await repo.guardarPerfilPublico(
        'INST_1',
        PerfilPublico(descripcion: 'Bilingüe', fotoIds: [img]),
      );
      final p = await repo.perfilPublico('INST_1');
      expect(p.descripcion, 'Bilingüe');
      expect(await repo.imagen(p.fotoIds.single), [9, 9, 9]);
      final idx = await repo.listar();
      expect(idx.single.descripcion, 'Bilingüe');
    });
  });
}
