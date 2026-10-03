// test/pdf_test.dart
//
// Documentos PDF de marca: cada uno se genera con datos completos, vacíos y
// extremos (textos largos, listas de varias páginas, imágenes inválidas).
//
// Para guardar una copia de cada PDF y revisarlo a mano:
//   flutter test --no-pub test/pdf_test.dart --dart-define=ATENA_PDF_OUT=carpeta

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/cuentas/cuenta.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/pdf/atena_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const String _carpetaSalida = String.fromEnvironment('ATENA_PDF_OUT');

/// Comprueba que los bytes sean un PDF completo y devuelve cuántas páginas
/// tiene. Si se pidió una carpeta de salida, guarda una copia.
int _verificar(Uint8List bytes, String nombre) {
  final texto = latin1.decode(bytes);
  expect(texto.startsWith('%PDF'), isTrue, reason: '$nombre: encabezado');
  expect(
    texto.substring(texto.length - 32),
    contains('%%EOF'),
    reason: '$nombre: cierre',
  );
  if (_carpetaSalida.isNotEmpty) {
    File('$_carpetaSalida/$nombre.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  }
  return RegExp(r'/Type\s*/Page(?![s\w])').allMatches(texto).length;
}

PerfilAlumno _perfil({
  String nombre = 'Lucía',
  String apellido = 'Gómez',
  String documento = '45123456',
  DateTime? nacimiento,
  String email = 'familia.gomez@correo.com.ar',
  String telefono = '351 512 3456',
}) => PerfilAlumno(
  id: 'P_1',
  cuentaId: 'C_1',
  ownerAccountId: null,
  documento: documento,
  nombre: nombre,
  apellido: apellido,
  fechaNacimiento: nacimiento ?? DateTime(2019, 5, 10),
  email: email,
  telefono: telefono,
  emancipado: false,
  fechaEmancipacion: null,
  prefs: PreferenciasPerfil.defaults(),
);

Oferta _ofertaFutbol() {
  final creada = DateTime(2026, 3, 1);
  return Oferta(
    id: 'OF_FUTBOL',
    institucionId: 'INST_1',
    tipo: TipoOferta.extracurricular,
    bloque: BloqueExtracurricular.deporteYMovimiento,
    titulo: 'Fútbol infantil',
    grupo: 'Sábados',
    turno: Turno.tarde,
    horario: '15:00 a 16:30',
    dias: 'Sábados',
    cupoTotal: 20,
    edadMinima: 6,
    edadMaxima: 9,
    creadaEl: creada,
    actualizadaEl: creada,
  );
}

Oferta _ofertaPrimero() {
  final creada = DateTime(2026, 3, 1);
  return Oferta(
    id: 'OF_PRIMERO',
    institucionId: 'INST_1',
    tipo: TipoOferta.curricular,
    nivel: NivelCurricular.primaria,
    titulo: '1° grado',
    grupo: 'A',
    turno: Turno.manana,
    horario: '08:00 a 12:15',
    dias: 'Lunes a viernes',
    cupoTotal: 28,
    edadMinima: 6,
    edadMaxima: 7,
    creadaEl: creada,
    actualizadaEl: creada,
  );
}

Solicitud _solicitud({
  String id = 'SOL_mfzk3x9a2b001',
  AlumnoSnapshot? alumno,
  Oferta? oferta,
  String institucion = 'Escuela San Martín',
  EstadoSolicitud estado = EstadoSolicitud.confirmada,
  String mensaje = '',
  String respuesta = '',
  DateTime? creadaEl,
}) {
  final creada = creadaEl ?? DateTime(2026, 9, 28, 10, 15);
  final resuelta = creada.add(const Duration(days: 2, hours: 3));
  return Solicitud(
    id: id,
    alumno: alumno ?? alumnoDemo(),
    institucionId: 'INST_1',
    institucionNombre: institucion,
    oferta: oferta ?? _ofertaPrimero(),
    mensaje: mensaje,
    estado: estado,
    respuesta: respuesta,
    creadaEl: creada,
    actualizadaEl: estado == EstadoSolicitud.pendiente ? creada : resuelta,
    historial: [
      CambioEstado(estado: EstadoSolicitud.pendiente, fecha: creada),
      if (estado != EstadoSolicitud.pendiente)
        CambioEstado(estado: estado, fecha: resuelta, nota: respuesta),
    ],
  );
}

/// Alumnos confirmados de ejemplo, repartidos entre [ofertas].
List<Solicitud> _confirmadas(int cantidad, List<Oferta> ofertas) {
  const nombres = ['Lucía', 'Mateo', 'Sofía', 'Benjamín', 'Martina', 'Joaquín'];
  const apellidos = [
    'Gómez',
    'Álvarez',
    'Núñez',
    'Fernández',
    'Zárate',
    'Ibáñez',
    'Peña',
  ];
  return [
    for (var i = 0; i < cantidad; i++)
      _solicitud(
        id: 'SOL_lista${i.toString().padLeft(4, '0')}',
        oferta: ofertas[i % ofertas.length],
        alumno: AlumnoSnapshot(
          cuentaId: 'C_$i',
          perfilId: 'P_$i',
          nombre: nombres[i % nombres.length],
          apellido: apellidos[i % apellidos.length],
          dni: '${45100200 + i * 137}',
          fechaNacimiento: DateTime(2018 + i % 3, 1 + i % 12, 1 + i % 27),
          email: i % 4 == 0 ? '' : 'familia$i@correo.com.ar',
          telefono: i % 5 == 0 ? '' : '351 55${(1000 + i * 7) % 10000}',
        ),
      ),
  ];
}

/// Foto JPEG de 56 × 56 px (se inserta en el PDF sin recodificar).
final Uint8List _fotoJpeg = base64Decode(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAwICQsJCAwLCgsODQwOEh4UEhEREiUbHBYeLCcuLi'
  'snKyoxN0Y7MTRCNCorPVM+QkhKTk9OLztWXFVMW0ZNTkv/2wBDAQ0ODhIQEiQUFCRLMisyS0tL'
  'S0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0v/wAARCAA4AD'
  'gDASIAAhEBAxEB/8QAGgABAAMBAQEAAAAAAAAAAAAAAAMEBQYCB//EAC0QAAEDAwIEBQMFAAAA'
  'AAAAAAEAAgMEERIFMRMhYXEGIlGBkSNBoTJCsdHx/8QAGgEAAQUBAAAAAAAAAAAAAAAAAgABAw'
  'UGBP/EACURAAIBAwIFBQAAAAAAAAAAAAABAgMEESExBRMygcESIkJx0f/aAAwDAQACEQMRAD8A'
  '+iZJkoskyXJg6SXJMlga7rb6Z7aHT28Wvl5ADmI+p6/6eW+cdI1eRjpJNambM65wY52F+9xYe3'
  'JM2kEo5OwyTJc3pGtTx1Z03WLNqb/SltZsoO3Tt8b77+SdajNYJckUWSJYGIskyUWSZIsBGNo0'
  'Zl1DVKuRwdIagwjyi7Wt69rfC11Xp6d0FTVOGHCmeJAGixDrWdf4B9yrCiejJEY/iiMjT21Ubg'
  '2alkbIx2IJ3tb5IPst/JUK6ndVRxxeThmRrpA8Xu0G9gOpAHP7XVrJHBAyJckUWSIsAkWSrajq'
  'Een0xmkBdzs1o/cfTopMlyPiCqNTqD2h144fI0c9/v8An+Au6zt+fV9L2W5Bc1eVDK3K1VX1NX'
  'PxpZXZA3YASAzt6bBX2+Ja8RYHhOdYjiFnm/r8LHRaSdtRmkpRWFsU0a1SLbT3LArqltU6pE7x'
  'M43Lgd+nbltsuu0jVG6jASW4yssHt+3cdFxKtaZVGjropcrNvZ+/6Tvt8+ygvLSNan7Vqtvwlt'
  '68qc9Xo9zu8kUWSLLYLwiyXDSPdLI6R5u5xJJ9SURXnCV19vJW8Q+PfweURFdlWEREhHbUcrpK'
  'SB7zdzo2kn1NkRFjaixN/ZpYdKP/2Q==',
);

/// Foto PNG vertical (se decodifica y se recorta en círculo).
Future<Uint8List> _fotoPng() async {
  final grabador = ui.PictureRecorder();
  ui.Canvas(grabador)
    ..drawRect(
      const ui.Rect.fromLTWH(0, 0, 120, 160),
      ui.Paint()..color = const ui.Color(0xFFFDE68A),
    )
    ..drawCircle(
      const ui.Offset(60, 150),
      52,
      ui.Paint()..color = const ui.Color(0xFF7C3AED),
    )
    ..drawCircle(
      const ui.Offset(60, 66),
      30,
      ui.Paint()..color = const ui.Color(0xFFF0C4A0),
    );
  final imagen = await grabador.endRecording().toImage(120, 160);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  imagen.dispose();
  return datos!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t = lookupAppLocalizations(const ui.Locale('es'));

  group('Ficha del alumno', () {
    test('con foto y solicitudes en todos los estados', () async {
      final bytes = await AtenaPdf.fichaAlumno(
        t: t,
        perfil: _perfil(),
        foto: _fotoJpeg,
        solicitudes: [
          _solicitud(estado: EstadoSolicitud.confirmada),
          _solicitud(
            estado: EstadoSolicitud.pendiente,
            oferta: _ofertaFutbol(),
            institucion: 'Club Atlético Barrio Norte',
            creadaEl: DateTime(2026, 10, 1, 18, 40),
          ),
          _solicitud(
            estado: EstadoSolicitud.rechazada,
            institucion: 'Colegio Nuestra Señora del Rosario de Fátima',
            creadaEl: DateTime(2026, 8, 12),
          ),
          _solicitud(
            estado: EstadoSolicitud.canceladaPorAlumno,
            institucion: 'Instituto Belgrano',
            creadaEl: DateTime(2026, 7, 3),
          ),
          _solicitud(
            estado: EstadoSolicitud.canceladaPorInstitucion,
            oferta: _ofertaFutbol(),
            institucion: 'Polideportivo Municipal',
            creadaEl: DateTime(2026, 5, 20),
          ),
        ],
      );
      expect(_verificar(bytes, 'ficha_alumno'), 1);
    });

    test('con foto PNG', () async {
      final bytes = await AtenaPdf.fichaAlumno(
        t: t,
        perfil: _perfil(nombre: 'Mateo', apellido: 'Álvarez Peña'),
        foto: await _fotoPng(),
        solicitudes: [_solicitud(estado: EstadoSolicitud.pendiente)],
      );
      expect(_verificar(bytes, 'ficha_alumno_png'), 1);
    });

    test('sin datos opcionales, sin solicitudes y con foto inválida', () async {
      final bytes = await AtenaPdf.fichaAlumno(
        t: t,
        perfil: _perfil(
          apellido: '',
          documento: '',
          nacimiento: DateTime.fromMillisecondsSinceEpoch(0),
          email: '',
          telefono: '',
        ),
        foto: Uint8List.fromList(List<int>.generate(64, (i) => i)),
      );
      expect(_verificar(bytes, 'ficha_alumno_minima'), 1);
    });

    test('con muchas solicitudes continúa en otra página', () async {
      final bytes = await AtenaPdf.fichaAlumno(
        t: t,
        perfil: _perfil(),
        solicitudes: [
          for (var i = 0; i < 70; i++)
            _solicitud(
              id: 'SOL_muchas$i',
              estado: EstadoSolicitud.values[i % EstadoSolicitud.values.length],
              oferta: i.isEven ? _ofertaPrimero() : _ofertaFutbol(),
              institucion: 'Institución educativa número ${i + 1}',
              creadaEl: DateTime(2026, 1, 1).add(Duration(days: i * 3)),
            ),
        ],
      );
      expect(_verificar(bytes, 'ficha_alumno_larga'), greaterThan(1));
    });
  });

  group('Comprobante de solicitud', () {
    test('en cada estado, con mensaje, respuesta e historial', () async {
      for (final estado in EstadoSolicitud.values) {
        final bytes = await AtenaPdf.comprobanteSolicitud(
          t: t,
          solicitud: _solicitud(
            estado: estado,
            mensaje:
                'Hola, nos gustaría que Lucía empiece en marzo. Tiene un '
                'hermano en 3° grado del mismo turno.\n¡Muchas gracias!',
            respuesta: estado == EstadoSolicitud.pendiente
                ? ''
                : 'Recibimos la solicitud. Los esperamos el lunes a las 8:00 '
                      'con la documentación.',
          ),
        );
        expect(_verificar(bytes, 'comprobante_${estado.name}'), 1);
      }
    });

    test('con datos mínimos', () async {
      final ahora = DateTime(2026, 10, 2);
      final bytes = await AtenaPdf.comprobanteSolicitud(
        t: t,
        solicitud: Solicitud(
          id: '',
          alumno: const AlumnoSnapshot(
            cuentaId: '',
            perfilId: '',
            nombre: '',
            apellido: '',
            dni: '',
          ),
          institucionId: '',
          institucionNombre: '',
          oferta: Oferta(
            id: '',
            institucionId: '',
            tipo: TipoOferta.extracurricular,
            titulo: '',
            cupoTotal: 0,
            creadaEl: ahora,
            actualizadaEl: ahora,
          ),
          estado: EstadoSolicitud.pendiente,
          creadaEl: DateTime.fromMillisecondsSinceEpoch(0),
          actualizadaEl: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      expect(_verificar(bytes, 'comprobante_minimo'), 1);
    });
  });

  group('Listado de alumnos', () {
    test('varias ofertas, ordenado y en varias páginas', () async {
      final bytes = await AtenaPdf.listadoAlumnos(
        t: t,
        institucionNombre: 'Escuela San Martín',
        confirmadas: _confirmadas(64, [_ofertaPrimero(), _ofertaFutbol()]),
      );
      expect(_verificar(bytes, 'listado_alumnos'), greaterThan(1));
    });

    test('una sola oferta con título propio', () async {
      final bytes = await AtenaPdf.listadoAlumnos(
        t: t,
        institucionNombre: 'Escuela San Martín',
        titulo: 'Alumnos de 1° grado A',
        confirmadas: _confirmadas(18, [_ofertaPrimero()]),
      );
      expect(_verificar(bytes, 'listado_alumnos_oferta'), 1);
    });

    test('sin alumnos; ignora solicitudes que no están confirmadas', () async {
      final bytes = await AtenaPdf.listadoAlumnos(
        t: t,
        institucionNombre: 'Escuela San Martín',
        confirmadas: [_solicitud(estado: EstadoSolicitud.pendiente)],
      );
      expect(_verificar(bytes, 'listado_alumnos_vacio'), 1);
    });
  });

  group('Croquis', () {
    test('aula de 5 × 6 con lugares libres', () async {
      var croquis = Croquis.vacio(
        id: 'CR_1',
        institucionId: 'INST_1',
        nombre: '1° grado A · Aula 4',
      );
      const alumnos = [
        'Lucía Gómez',
        'Mateo Álvarez',
        'Sofía Núñez',
        'Benjamín Fernández',
        'Martina Zárate',
        'Joaquín Ibáñez',
        'Valentina Peña',
        'Thiago Rodríguez',
        'Emma Sánchez',
        'Santino Muñoz',
        'Isabella Agüero',
        'Bautista Giménez',
        'Catalina Domínguez',
        'Felipe Benítez',
        'Olivia Méndez',
        'Lautaro Córdoba',
        'Mía Ramírez',
      ];
      for (final (i, nombre) in alumnos.indexed) {
        // Se dejan lugares libres salteados.
        final lugar = i + i ~/ 4;
        croquis = croquis.conAsiento(lugar ~/ 6, lugar % 6, nombre);
      }
      final bytes = await AtenaPdf.croquis(
        t: t,
        institucionNombre: 'Escuela San Martín',
        croquis: croquis,
      );
      expect(_verificar(bytes, 'croquis'), 1);
    });

    test('aula completa de 10 × 10 con nombres largos', () async {
      var croquis = Croquis.vacio(
        id: 'CR_2',
        institucionId: 'INST_1',
        nombre: 'Salón de actos',
        filas: 10,
        columnas: 10,
      );
      for (var f = 0; f < 10; f++) {
        for (var c = 0; c < 10; c++) {
          croquis = croquis.conAsiento(
            f,
            c,
            (f + c).isEven
                ? 'María de los Ángeles Fernández Villanueva'
                : 'Juan Pérez',
          );
        }
      }
      final bytes = await AtenaPdf.croquis(
        t: t,
        institucionNombre: 'Escuela San Martín',
        croquis: croquis,
      );
      expect(_verificar(bytes, 'croquis_completo'), 1);
    });

    test('aula vacía de un solo lugar y sin nombre', () async {
      final bytes = await AtenaPdf.croquis(
        t: t,
        institucionNombre: '',
        croquis: Croquis.vacio(
          id: 'CR_3',
          institucionId: 'INST_1',
          nombre: '',
          filas: 1,
          columnas: 1,
        ),
      );
      expect(_verificar(bytes, 'croquis_minimo'), 1);
    });
  });

  test('textos muy largos, emojis y otros alfabetos no rompen', () async {
    final largo = 'Institución con un nombre larguísimo ' * 12;
    final alumno = AlumnoSnapshot(
      cuentaId: 'C_9',
      perfilId: 'P_9',
      nombre: 'Władysław Ángel 🙂 ${'Maximiliano ' * 10}',
      apellido: 'Çelik-Ødegård Иванов 山田 ${'Fernández ' * 10}',
      dni: '1234567890123456789012345',
      fechaNacimiento: DateTime(2015, 2, 28),
      email: '${'correo.muy.largo.' * 8}@dominio-extenso.com.ar',
      telefono: '+54 9 351 000 0000 interno 12345',
    );
    final solicitud = _solicitud(
      alumno: alumno,
      institucion: largo,
      mensaje: 'Línea 1\r\n\r\n\r\n\r\nLínea 2 ✅\t${'palabra ' * 600}',
      respuesta: 'x' * 5000,
    );

    expect(
      _verificar(
        await AtenaPdf.fichaAlumno(
          t: t,
          perfil: _perfil(
            nombre: alumno.nombre,
            apellido: alumno.apellido,
            documento: alumno.dni,
            email: alumno.email,
            telefono: alumno.telefono,
          ),
          solicitudes: [solicitud, solicitud],
        ),
        'extremo_ficha',
      ),
      greaterThan(0),
    );
    expect(
      _verificar(
        await AtenaPdf.comprobanteSolicitud(t: t, solicitud: solicitud),
        'extremo_comprobante',
      ),
      greaterThan(0),
    );
    expect(
      _verificar(
        await AtenaPdf.listadoAlumnos(
          t: t,
          institucionNombre: largo,
          titulo: largo,
          confirmadas: [solicitud, _solicitud()],
        ),
        'extremo_listado',
      ),
      greaterThan(0),
    );
    expect(
      _verificar(
        await AtenaPdf.croquis(
          t: t,
          institucionNombre: largo,
          croquis: Croquis.vacio(
            id: 'CR_4',
            institucionId: 'INST_1',
            nombre: largo,
            filas: 2,
            columnas: 3,
          ).conAsiento(0, 0, alumno.nombreCompleto),
        ),
        'extremo_croquis',
      ),
      1,
    );
  });

  test('los documentos se generan en inglés y portugués', () async {
    for (final idioma in ['en', 'pt']) {
      final tr = lookupAppLocalizations(ui.Locale(idioma));
      final solicitud = _solicitud(
        mensaje: 'Olá! Gostaríamos de uma vaga para a Lucía.',
        respuesta: 'Welcome! See you on Monday.',
      );
      expect(
        _verificar(
          await AtenaPdf.fichaAlumno(
            t: tr,
            perfil: _perfil(),
            foto: _fotoJpeg,
            solicitudes: [solicitud],
          ),
          'ficha_alumno_$idioma',
        ),
        1,
      );
      expect(
        _verificar(
          await AtenaPdf.comprobanteSolicitud(t: tr, solicitud: solicitud),
          'comprobante_$idioma',
        ),
        1,
      );
      expect(
        _verificar(
          await AtenaPdf.listadoAlumnos(
            t: tr,
            institucionNombre: 'Escuela San Martín',
            confirmadas: _confirmadas(12, [_ofertaPrimero(), _ofertaFutbol()]),
          ),
          'listado_alumnos_$idioma',
        ),
        1,
      );
      expect(
        _verificar(
          await AtenaPdf.croquis(
            t: tr,
            institucionNombre: 'Escuela San Martín',
            croquis: Croquis.vacio(
              id: 'CR_5',
              institucionId: 'INST_1',
              nombre: 'Sala 2',
              filas: 3,
              columnas: 4,
            ).conAsiento(1, 2, 'Lucía Gómez'),
          ),
          'croquis_$idioma',
        ),
        1,
      );
    }
  });
}
