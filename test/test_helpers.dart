// test/test_helpers.dart
//
// Utilidades comunes de las pruebas: almacenamiento limpio por prueba y
// datos de ejemplo.

import 'package:atena_app/core/atena_core.dart';
import 'package:atena_app/models/extracurriculares/bloque_extracurricular.dart';
import 'package:atena_app/models/instituciones/instituciones_integrado.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> resetStorage() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  StorageService.instance.resetCache();
  AtenaStore.instance.resetCache();
}

Institucion institucionDemo({
  String id = 'INST_1',
  String nombre = 'Escuela San Martín',
  String ciudad = 'Córdoba',
  String provincia = 'Córdoba',
  List<NivelCurricular> niveles = const [NivelCurricular.primaria],
  List<BloqueExtracurricular> bloques = const [
    BloqueExtracurricular.deporteYMovimiento,
  ],
}) {
  final now = DateTime(2026, 3, 1);
  return Institucion(
    id: id,
    nombre: nombre,
    cuit: '30712345678',
    direccion: 'Av. Siempre Viva 123',
    pais: 'Argentina',
    provincia: provincia,
    ciudad: ciudad,
    modalidad: ModalidadCursado.presencial,
    email: 'info@escuela.edu.ar',
    telefono: '3511234567',
    curricular: niveles.isNotEmpty,
    extracurricular: bloques.isNotEmpty,
    tipoInstitucion: TipoInstitucion.primaria,
    tipoPlan: 'Prueba',
    estadoPlan: EstadoPlanInstitucion.enPrueba,
    planInicio: now,
    planFin: now.add(const Duration(days: 30)),
    planConfig: PlanInstitucionConfig(
      niveles: [
        for (final n in niveles)
          PlanNivelCurricular(nivel: n, habilitado: true),
      ],
      modulos: [
        for (final b in bloques)
          PlanModuloExtracurricular(bloque: b, habilitado: true),
      ],
    ),
  );
}

Oferta ofertaDemo({
  String institucionId = 'INST_1',
  int cupo = 2,
  bool activa = true,
  String titulo = '1° grado',
}) {
  final now = DateTime(2026, 3, 1);
  return Oferta(
    id: '',
    institucionId: institucionId,
    tipo: TipoOferta.curricular,
    nivel: NivelCurricular.primaria,
    titulo: titulo,
    grupo: 'A',
    turno: Turno.manana,
    horario: '08:00 a 12:00',
    cupoTotal: cupo,
    activa: activa,
    creadaEl: now,
    actualizadaEl: now,
  );
}

AlumnoSnapshot alumnoDemo({
  String cuentaId = 'C_1',
  String perfilId = 'P_1',
  String nombre = 'Lucía',
  String apellido = 'Gómez',
}) {
  return AlumnoSnapshot(
    cuentaId: cuentaId,
    perfilId: perfilId,
    nombre: nombre,
    apellido: apellido,
    dni: '45123456',
    fechaNacimiento: DateTime(2019, 5, 10),
  );
}
