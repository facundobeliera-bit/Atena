// lib/core/demo/demo_seeder.dart
//
// Datos de ejemplo para demostraciones y revisión en tiendas:
// tres instituciones con vacantes y una familia con dos alumnos.
// Es idempotente: si ya están cargados, no duplica nada.

import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/auth_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/institucion_service.dart';
import '../atena_core.dart';

class DemoCredenciales {
  static const String password = 'demo1234';
  static const String familia = 'familia@demo.com';
  static const String colegio = 'colegio@demo.com';
  static const String jardin = 'jardin@demo.com';
  static const String club = 'club@demo.com';
}

class _InstDemo {
  final String email;
  final String nombre;
  final String cuit;
  final String direccion;
  final String ciudad;
  final String provincia;
  final TipoInstitucion tipo;
  final List<NivelCurricular> niveles;
  final List<BloqueExtracurricular> bloques;
  final PerfilPublico perfil;

  const _InstDemo({
    required this.email,
    required this.nombre,
    required this.cuit,
    required this.direccion,
    required this.ciudad,
    required this.provincia,
    required this.tipo,
    required this.niveles,
    required this.bloques,
    required this.perfil,
  });
}

class DemoSeeder {
  const DemoSeeder._();

  static Future<bool> yaCargado() async {
    final id = await InstitucionService.getInstitucionIdByEmail(
      DemoCredenciales.colegio,
    );
    return id != null && id.isNotEmpty;
  }

  /// Carga los datos de ejemplo. Devuelve false si ya estaban cargados.
  static Future<bool> cargar() async {
    if (await yaCargado()) return false;

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // -------------------------------------------------------------------------
    // Instituciones
    // -------------------------------------------------------------------------
    const colegio = _InstDemo(
      email: DemoCredenciales.colegio,
      nombre: 'Colegio San Martín',
      cuit: '30712345678',
      direccion: 'Av. Colón 1250',
      ciudad: 'Córdoba',
      provincia: 'Córdoba',
      tipo: TipoInstitucion.primaria,
      niveles: [NivelCurricular.primaria, NivelCurricular.secundaria],
      bloques: [
        BloqueExtracurricular.deporteYMovimiento,
        BloqueExtracurricular.cienciaTecnologiaYRobotica,
        BloqueExtracurricular.idiomasYComunicacion,
      ],
      perfil: PerfilPublico(
        descripcion:
            'Colegio bilingüe con más de 40 años de trayectoria. Acompañamos a '
            'cada alumno con grupos reducidos, talleres de robótica y deporte.',
        horarioAtencion: 'Lunes a viernes de 7:30 a 17:00',
        horarioClases: 'Mañana 8:00 a 12:30 · Tarde 13:30 a 17:30',
        telefono: '3514123456',
        whatsapp: '3514123456',
        email: 'secretaria@colegiosanmartin.edu.ar',
        sitioWeb: 'https://www.colegiosanmartin.edu.ar',
        instagram: '@colegiosanmartin',
        servicios: [
          'Bilingüe',
          'Comedor',
          'Jornada extendida',
          'Gabinete psicopedagógico',
          'Laboratorio',
        ],
      ),
    );
    const jardin = _InstDemo(
      email: DemoCredenciales.jardin,
      nombre: 'Jardín Arcoíris',
      cuit: '30798765432',
      direccion: 'Bv. Oroño 845',
      ciudad: 'Rosario',
      provincia: 'Santa Fe',
      tipo: TipoInstitucion.jardin,
      niveles: [NivelCurricular.jardin],
      bloques: [BloqueExtracurricular.arteYExpresion],
      perfil: PerfilPublico(
        descripcion:
            'Jardín de infantes con salas de 3, 4 y 5 años. Aprendemos jugando, '
            'con música, arte y mucho cariño.',
        horarioAtencion: 'Lunes a viernes de 8:00 a 16:00',
        telefono: '3415551234',
        email: 'hola@jardinarcoiris.com.ar',
        servicios: ['Patio de juegos', 'Música', 'Jornada extendida'],
      ),
    );
    const club = _InstDemo(
      email: DemoCredenciales.club,
      nombre: 'Club Atlético Los Andes',
      cuit: '30711223344',
      direccion: 'San Martín 2100',
      ciudad: 'Mendoza',
      provincia: 'Mendoza',
      tipo: TipoInstitucion.club,
      niveles: [],
      bloques: [
        BloqueExtracurricular.deporteYMovimiento,
        BloqueExtracurricular.arteYExpresion,
      ],
      perfil: PerfilPublico(
        descripcion:
            'Club de barrio con escuelas de natación, básquet y danza para '
            'chicos y chicas desde los 5 años.',
        horarioAtencion: 'Lunes a sábados de 9:00 a 21:00',
        telefono: '2614789012',
        instagram: '@clublosandes',
        servicios: ['Pileta climatizada', 'Gimnasio', 'Becas deportivas'],
      ),
    );

    final colegioId = await _crearInstitucion(colegio, hoy);
    final jardinId = await _crearInstitucion(jardin, hoy);
    final clubId = await _crearInstitucion(club, hoy);

    // -------------------------------------------------------------------------
    // Ofertas
    // -------------------------------------------------------------------------
    final ofertas = OfertasRepo.instance;
    Future<Oferta> curricular(
      String inst,
      NivelCurricular nivel,
      String titulo,
      String grupo,
      Turno turno,
      String horario,
      int cupo, {
      int? edadMin,
      int? edadMax,
    }) {
      return ofertas.guardar(
        Oferta(
          id: '',
          institucionId: inst,
          tipo: TipoOferta.curricular,
          nivel: nivel,
          titulo: titulo,
          grupo: grupo,
          turno: turno,
          horario: horario,
          dias: 'Lun a Vie',
          cupoTotal: cupo,
          edadMinima: edadMin,
          edadMaxima: edadMax,
          creadaEl: ahora,
          actualizadaEl: ahora,
        ),
      );
    }

    Future<Oferta> extra(
      String inst,
      BloqueExtracurricular bloque,
      String titulo,
      String grupo,
      Turno turno,
      String horario,
      String dias,
      int cupo, {
      int? edadMin,
      int? edadMax,
      String arancel = '',
      String descripcion = '',
    }) {
      return ofertas.guardar(
        Oferta(
          id: '',
          institucionId: inst,
          tipo: TipoOferta.extracurricular,
          bloque: bloque,
          titulo: titulo,
          grupo: grupo,
          turno: turno,
          horario: horario,
          dias: dias,
          cupoTotal: cupo,
          edadMinima: edadMin,
          edadMaxima: edadMax,
          arancel: arancel,
          descripcion: descripcion,
          creadaEl: ahora,
          actualizadaEl: ahora,
        ),
      );
    }

    await curricular(
      colegioId,
      NivelCurricular.primaria,
      '1° grado',
      'A',
      Turno.manana,
      '08:00 a 12:30',
      25,
      edadMin: 6,
      edadMax: 7,
    );
    final tercero = await curricular(
      colegioId,
      NivelCurricular.primaria,
      '3° grado',
      'A',
      Turno.manana,
      '08:00 a 12:30',
      25,
      edadMin: 8,
      edadMax: 9,
    );
    await curricular(
      colegioId,
      NivelCurricular.primaria,
      '5° grado',
      'B',
      Turno.tarde,
      '13:30 a 17:30',
      28,
      edadMin: 10,
      edadMax: 11,
    );
    final primerAnio = await curricular(
      colegioId,
      NivelCurricular.secundaria,
      '1° año',
      'A',
      Turno.manana,
      '07:45 a 13:00',
      30,
      edadMin: 12,
      edadMax: 13,
    );
    final robotica = await extra(
      colegioId,
      BloqueExtracurricular.cienciaTecnologiaYRobotica,
      'Robótica',
      'Inicial',
      Turno.tarde,
      '14:00 a 15:30',
      'Mar y Jue',
      15,
      edadMin: 7,
      edadMax: 12,
      arancel: r'$ 18.000 por mes',
      descripcion: 'Armado y programación de robots con kits educativos.',
    );
    await extra(
      colegioId,
      BloqueExtracurricular.idiomasYComunicacion,
      'Inglés conversacional',
      'Kids',
      Turno.tarde,
      '17:30 a 18:30',
      'Lun y Mié',
      12,
      edadMin: 8,
      edadMax: 12,
    );
    await extra(
      colegioId,
      BloqueExtracurricular.deporteYMovimiento,
      'Fútbol infantil',
      '',
      Turno.tarde,
      '18:00 a 19:00',
      'Vie',
      20,
      edadMin: 6,
      edadMax: 10,
    );
    for (final (titulo, edad) in [
      ('Sala de 3', 3),
      ('Sala de 4', 4),
      ('Sala de 5', 5),
    ]) {
      await curricular(
        jardinId,
        NivelCurricular.jardin,
        titulo,
        'Turno mañana',
        Turno.manana,
        '08:30 a 12:00',
        18,
        edadMin: edad,
        edadMax: edad,
      );
    }
    await extra(
      jardinId,
      BloqueExtracurricular.arteYExpresion,
      'Taller de arte',
      '',
      Turno.tarde,
      '14:00 a 15:00',
      'Mié',
      12,
      edadMin: 3,
      edadMax: 5,
    );
    await extra(
      clubId,
      BloqueExtracurricular.deporteYMovimiento,
      'Natación',
      'Escuelita',
      Turno.tarde,
      '17:00 a 18:00',
      'Lun, Mié y Vie',
      16,
      edadMin: 5,
      edadMax: 12,
      arancel: r'$ 22.000 por mes',
    );
    await extra(
      clubId,
      BloqueExtracurricular.deporteYMovimiento,
      'Básquet',
      'Mini',
      Turno.tarde,
      '18:00 a 19:30',
      'Mar y Jue',
      20,
      edadMin: 9,
      edadMax: 13,
    );
    await extra(
      clubId,
      BloqueExtracurricular.arteYExpresion,
      'Danza urbana',
      '',
      Turno.tarde,
      '19:00 a 20:00',
      'Sáb',
      15,
      edadMin: 8,
      edadMax: 16,
    );

    // -------------------------------------------------------------------------
    // Familia con dos alumnos
    // -------------------------------------------------------------------------
    final familia = await AuthService.registrarFamilia(
      email: DemoCredenciales.familia,
      password: DemoCredenciales.password,
      remember: true,
      nombre: 'Lucía',
      apellido: 'Gómez',
      dni: '50123456',
      fechaNacimiento: DateTime(hoy.year - 8, 5, 10),
      telefono: '3511234567',
    );
    final cuentaId = familia.cuenta.id;
    final lucia = familia.perfil;
    final tomas = await AlumnosRepo.instance.crear(
      cuentaId: cuentaId,
      nombre: 'Tomás',
      apellido: 'Gómez',
      dni: '47123456',
      fechaNacimiento: DateTime(hoy.year - 12, 2, 20),
    );

    final solicitudes = SolicitudesRepo.instance;
    final alumnos = AlumnosRepo.instance;
    final s1 = await solicitudes.crear(
      alumno: alumnos.snapshot(cuentaId, lucia),
      institucionNombre: colegio.nombre,
      oferta: tercero,
      mensaje: 'Nos mudamos a Córdoba en marzo. ¡Gracias!',
    );
    await solicitudes.responder(
      s1.id,
      institucionId: colegioId,
      aceptar: true,
      nota: 'Bienvenida Lucía. Te esperamos el primer día de clases.',
    );
    final s2 = await solicitudes.crear(
      alumno: alumnos.snapshot(cuentaId, lucia),
      institucionNombre: colegio.nombre,
      oferta: robotica,
    );
    await solicitudes.responder(s2.id, institucionId: colegioId, aceptar: true);
    await solicitudes.crear(
      alumno: alumnos.snapshot(cuentaId, tomas),
      institucionNombre: colegio.nombre,
      oferta: primerAnio,
      mensaje: 'Viene de una escuela pública de Rosario.',
    );

    // -------------------------------------------------------------------------
    // Calendario, avisos y documentación
    // -------------------------------------------------------------------------
    final cal = CalendarioRepo.instance;
    await cal.guardarEvento(
      Evento(
        id: '',
        institucionId: colegioId,
        institucionNombre: colegio.nombre,
        tipo: TipoEvento.reunion,
        titulo: 'Reunión de familias de 3° grado',
        descripcion: 'Presentación del equipo docente y del proyecto anual.',
        lugar: 'Salón de actos',
        inicio: hoy.add(const Duration(days: 6, hours: 18)),
        todoElDia: false,
        ofertaIds: [tercero.id],
        pideConfirmacion: true,
        creadoEl: ahora,
      ),
    );
    await cal.guardarEvento(
      Evento(
        id: '',
        institucionId: colegioId,
        institucionNombre: colegio.nombre,
        tipo: TipoEvento.acto,
        titulo: 'Acto por el Día de la Independencia',
        lugar: 'Patio central',
        inicio: hoy.add(const Duration(days: 12, hours: 10)),
        todoElDia: false,
        creadoEl: ahora,
      ),
    );
    await cal.guardarEvento(
      Evento(
        id: '',
        institucionId: colegioId,
        institucionNombre: colegio.nombre,
        tipo: TipoEvento.vacaciones,
        titulo: 'Receso de invierno',
        inicio: hoy.add(const Duration(days: 20)),
        fin: hoy.add(const Duration(days: 33)),
        creadoEl: ahora,
      ),
    );
    await cal.enviarAviso(
      institucionId: colegioId,
      institucionNombre: colegio.nombre,
      titulo: 'Útiles escolares',
      mensaje:
          'Ya está disponible la lista de útiles de cada grado en secretaría. '
          'Recordá etiquetar todos los materiales con nombre y grado.',
    );
    await DocumentosRepo.instance.solicitar(
      institucionId: colegioId,
      institucionNombre: colegio.nombre,
      cuentaId: cuentaId,
      perfilId: lucia.id,
      alumnoNombre: lucia.displayName,
      tipo: TipoDocumento.certificadoMedico,
      detalle: 'Apto físico para Educación Física.',
      fechaLimite: hoy.add(const Duration(days: 10)),
    );

    // Los datos quedan cargados sin sesión iniciada.
    await AuthService.logout();
    return true;
  }

  static Future<String> _crearInstitucion(_InstDemo d, DateTime hoy) async {
    final auth = await InstitucionService.registrarInstitucion(
      email: d.email,
      passwordHash: DemoCredenciales.password,
      nombre: d.nombre,
    );
    final owner = auth.institucionId;
    final perfil = await CuentaService.crearPerfilInstitucion(
      cuentaId: owner,
      nombre: d.nombre,
      emailContacto: d.email,
      telefonoContacto: d.perfil.telefono,
    );

    final inst = Institucion(
      id: perfil.id,
      nombre: d.nombre,
      cuit: d.cuit,
      direccion: d.direccion,
      pais: 'Argentina',
      provincia: d.provincia,
      ciudad: d.ciudad,
      modalidad: ModalidadCursado.presencial,
      email: d.email,
      telefono: d.perfil.telefono,
      curricular: d.niveles.isNotEmpty,
      extracurricular: d.bloques.isNotEmpty,
      tipoInstitucion: d.tipo,
      tipoPlan: 'Prueba',
      estadoPlan: EstadoPlanInstitucion.enPrueba,
      planInicio: hoy,
      planFin: hoy.add(const Duration(days: 30)),
      planConfig: PlanInstitucionConfig(
        niveles: [
          for (final n in d.niveles)
            PlanNivelCurricular(nivel: n, habilitado: true),
        ],
        modulos: [
          for (final b in d.bloques)
            PlanModuloExtracurricular(bloque: b, habilitado: true),
        ],
      ),
    );

    final repo = InstitucionesRepo.instance;
    await repo.guardarPerfilPublico(perfil.id, d.perfil);
    await repo.guardar(inst);
    return perfil.id;
  }
}
