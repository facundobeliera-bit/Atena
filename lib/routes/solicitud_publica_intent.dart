import '../services/plan_habilitacion_service.dart';
import 'package:flutter/material.dart';
import '../models/catalogo/ficha_publica.dart';
import '../models/extracurriculares/bloque_extracurricular.dart';
import '../services/catalogo_publicable_service.dart';
import '../services/cuenta_service.dart';
import '../services/session_service.dart';
import '../services/remote/multiuser_session.dart';
import '../services/solicitudes_service.dart';
import '../services/instituciones_helpers.dart' as helpers;
import '../screens/auth/alumno_login_page.dart';
import '../screens/cuentas/cuenta_home_page.dart';
import '../screens/alumnos/alumno_solicitar_vacante_page.dart';

/// Navigation intent only, never proof of identity or authorization.
class SolicitudPublicaIntent {
  final String institucionId, grupoId;
  final CategoriaPublica categoria;
  const SolicitudPublicaIntent({
    required this.institucionId,
    required this.grupoId,
    required this.categoria,
  });

  Future<void> continuar(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (MultiuserSession.enabled) {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => MultiuserSession.current.signedIn
              ? CuentaHomePage(
                  cuentaId: MultiuserSession.current.userId,
                  solicitudPublica: this,
                )
              : AlumnoLoginPage(solicitudPublica: this),
        ),
      );
      return;
    }
    try {
      if (!await PlanHabilitacionService.puedeRecibirPorId(institucionId)) {
        throw StateError(PlanHabilitacionService.inscripcionNoHabilitada);
      }
      final session = await SessionService.getSession();
      final owner = session?.role == SessionRole.cuenta
          ? session!.userId
          : await SessionService.getInstitucionOwnerAccountIdLogueado();
      final perfil = owner == null
          ? null
          : await CuentaService.getPerfilAlumnoActivoValidado(owner);
      if (!context.mounted) return;
      if (perfil == null) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => owner == null
                ? AlumnoLoginPage(solicitudPublica: this)
                : CuentaHomePage(cuentaId: owner, solicitudPublica: this),
          ),
        );
        return;
      }
      final institutions = await CatalogoPublicableService().buscarPublico();
      final insts = institutions.where((i) => i.id == institucionId).toList();
      if (insts.length != 1) {
        throw StateError('La institución ya no tiene ofertas publicadas.');
      }
      final offers = insts.single.ofertas
          .where((o) => o.id == grupoId && o.categoria == categoria)
          .toList();
      if (offers.length != 1 || !offers.single.habilitada) {
        throw StateError('La oferta ya no admite solicitudes. Volvé a buscar.');
      }
      final offer = offers.single;
      String activity, group, schedule;
      String? module;
      if (categoria == CategoriaPublica.formal) {
        final g = (await helpers.cargarGruposInstitucion(
          institucionId,
        )).singleWhere((g) => g.id == grupoId && g.areaId == offer.areaId);
        activity = g.actividadNombre;
        group = g.nombreGrupo;
        schedule = g.turno ?? '';
      } else {
        final g =
            (await SolicitudesService.gruposExtracurricularesParaAlumno(
              institucionId,
            )).singleWhere(
              (g) => g.id == grupoId && g.areaId == offer.areaId && g.activo,
            );
        activity = g.actividadNombre;
        group = g.nombreGrupo;
        schedule = g.turno;
        module = g.bloque.key;
      }
      // Recheck after asynchronous catalog reads, including changed/revoked sessions.
      final current = await CuentaService.getPerfilAlumnoActivoValidado(owner!);
      if (current?.id != perfil.id) {
        throw StateError('Tu sesión cambió. Volvé a ingresar con tu perfil.');
      }
      if (!context.mounted) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: perfil.documento,
            ownerAccountId: owner,
            perfilId: perfil.id,
            institucionId: institucionId,
            institucionNombre: insts.single.nombre,
            actividadNombre: activity,
            esCurricular: categoria == CategoriaPublica.formal,
            grupoCurricularId: categoria == CategoriaPublica.formal
                ? grupoId
                : null,
            aula: group,
            turno: schedule,
            moduleKey: module,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is StateError
                ? e.message.toString()
                : 'No se pudo comprobar la oferta. Volvé a intentarlo.',
          ),
        ),
      );
    }
  }
}
