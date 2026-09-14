import 'package:atena_app/services/documentos_temporales_service.dart';
import 'package:atena_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ownerA = 'owner-documentos-A';
const ownerB = 'owner-documentos-B';
const perfilA = 'perfil-documentos-A';
const perfilB = 'perfil-documentos-B';
const institucionA = 'institucion-documentos-A';
const institucionB = 'institucion-documentos-B';

void simulateRestart() {
  StorageService.instance.resetCache();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    simulateRestart();
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
    simulateRestart();
  });

  test(
    'solicitud documental conserva creación y actualización tras reinicio',
    () async {
      await DocumentosTemporalesService.solicitar(
        institucionId: institucionA,
        ownerAccountId: ownerA,
        perfilId: perfilA,
        tipo: TipoDocumento.dni,
        mensaje: 'Presentar frente y dorso',
      );

      final creada = await DocumentosTemporalesService.listarSolicitudesPerfil(
        perfilId: perfilA,
      );
      expect(creada, hasLength(1));
      expect(creada.single.estado, EstadoSolicitudDocumento.pendiente);

      simulateRestart();
      final reconstruida =
          await DocumentosTemporalesService.listarSolicitudesPerfil(
            perfilId: perfilA,
          );
      expect(reconstruida, hasLength(1));
      expect(reconstruida.single.id, creada.single.id);
      expect(reconstruida.single.mensaje, 'Presentar frente y dorso');

      await DocumentosTemporalesService.marcarSolicitudCumplida(
        perfilId: perfilA,
        solicitudId: creada.single.id,
        notificar: false,
      );
      simulateRestart();

      final actualizada =
          await DocumentosTemporalesService.listarSolicitudesPerfil(
            perfilId: perfilA,
          );
      expect(actualizada.single.estado, EstadoSolicitudDocumento.cumplida);
    },
  );

  test(
    'documento permanece, queda aislado por perfil y su borrado persiste',
    () async {
      await DocumentosTemporalesService.subirDocumentoTemporal(
        institucionSolicitanteId: institucionA,
        ownerAccountId: ownerA,
        perfilId: perfilA,
        tipo: TipoDocumento.boletin,
        ref: 'archivo-local/boletin-2026.pdf',
        ttlDays: 10,
        notificar: false,
      );

      final guardados =
          await DocumentosTemporalesService.listarDocumentosPerfil(
            perfilId: perfilA,
          );
      expect(guardados, hasLength(1));
      expect(guardados.single.ref, 'archivo-local/boletin-2026.pdf');

      simulateRestart();
      final reconstruidos =
          await DocumentosTemporalesService.listarDocumentosPerfil(
            perfilId: perfilA,
          );
      final ajenos = await DocumentosTemporalesService.listarDocumentosPerfil(
        perfilId: perfilB,
      );
      expect(reconstruidos.single.id, guardados.single.id);
      expect(reconstruidos.single.tipo, TipoDocumento.boletin);
      expect(ajenos, isEmpty);

      await DocumentosTemporalesService.eliminarDocumento(
        perfilId: perfilA,
        documentoId: guardados.single.id,
      );
      simulateRestart();

      expect(
        await DocumentosTemporalesService.listarDocumentosPerfil(
          perfilId: perfilA,
        ),
        isEmpty,
      );
    },
  );

  test(
    'listado institucional se reconstruye sin mezclar instituciones',
    () async {
      await DocumentosTemporalesService.solicitar(
        institucionId: institucionA,
        ownerAccountId: ownerA,
        perfilId: perfilA,
        tipo: TipoDocumento.partidaNacimiento,
      );
      await DocumentosTemporalesService.solicitar(
        institucionId: institucionB,
        ownerAccountId: ownerB,
        perfilId: perfilB,
        tipo: TipoDocumento.constanciaCuil,
      );
      await DocumentosTemporalesService.subirDocumentoTemporal(
        institucionSolicitanteId: institucionA,
        ownerAccountId: ownerA,
        perfilId: perfilA,
        tipo: TipoDocumento.partidaNacimiento,
        ref: 'archivo-local/partida-A.pdf',
        notificar: false,
      );
      await DocumentosTemporalesService.subirDocumentoTemporal(
        institucionSolicitanteId: institucionB,
        ownerAccountId: ownerB,
        perfilId: perfilB,
        tipo: TipoDocumento.constanciaCuil,
        ref: 'archivo-local/cuil-B.pdf',
        notificar: false,
      );

      simulateRestart();
      final solicitudesA =
          await DocumentosTemporalesService.listarSolicitudesInstitucion(
            institucionId: institucionA,
          );
      final documentosA =
          await DocumentosTemporalesService.listarDocumentosInstitucion(
            institucionId: institucionA,
          );

      expect(solicitudesA, hasLength(1));
      expect(solicitudesA.single.perfilId, perfilA);
      expect(documentosA, hasLength(1));
      expect(documentosA.single.perfilId, perfilA);
    },
  );

  test('propietario institucional registrado sobrevive al reinicio', () async {
    await DocumentosTemporalesService.registrarOwnerDeInstitucion(
      institucionPerfilId: institucionA,
      ownerAccountId: ownerA,
    );
    simulateRestart();

    await DocumentosTemporalesService.solicitar(
      institucionId: institucionA,
      ownerAccountId: ownerB,
      perfilId: perfilB,
      tipo: TipoDocumento.libretaSanitaria,
    );

    final keys = await StorageService.instance.getKeys();
    expect(
      keys,
      contains('docs_temporales_v1_owner_institucion_$institucionA'),
    );
    expect(keys.any((key) => key.contains(ownerA)), isTrue);
  });
}
