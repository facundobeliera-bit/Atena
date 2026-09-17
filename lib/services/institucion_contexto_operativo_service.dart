import 'institucion_areas_service.dart';
import 'institucion_operadores_service.dart';
import 'session_service.dart';

class InstitucionContextoOperativoService {
  InstitucionContextoOperativoService._();
  static final instance = InstitucionContextoOperativoService._();

  static String _id(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');

  Future<InstitutionOperationalContext?> activarContextoOperativo({
    required String institucionId,
    required String ownerAccountId,
    required String areaId,
    required String operadorId,
  }) async {
    final candidate = InstitutionOperationalContext(
      institutionId: _id(institucionId),
      ownerAccountId: _id(ownerAccountId),
      areaId: _id(areaId),
      operatorId: _id(operadorId),
    );
    if (!await _esValido(candidate)) return null;
    await SessionService.setInstitutionOperationalContext(candidate);
    final stored = await SessionService.getInstitutionOperationalContext();
    return _same(candidate, stored) ? stored : null;
  }

  Future<InstitutionOperationalContext?> reconstruirContextoOperativo() async {
    final stored = await SessionService.getInstitutionOperationalContext();
    if (stored == null) return null;
    if (!await _esValido(stored)) {
      await SessionService.clearInstitutionOperationalContext();
      return null;
    }
    return stored;
  }

  Future<bool> _esValido(InstitutionOperationalContext value) async {
    if (value.institutionId.isEmpty ||
        value.ownerAccountId.isEmpty ||
        value.areaId.isEmpty ||
        value.operatorId.isEmpty) {
      return false;
    }
    final session = await SessionService.getSession();
    final owner = await SessionService.getInstitucionOwnerAccountIdLogueado();
    if (session?.role != SessionRole.institucion ||
        _id(session!.userId) != value.institutionId ||
        _id(owner ?? '') != value.ownerAccountId) {
      return false;
    }
    final area = await InstitucionAreasService.instance.buscarPorId(
      value.institutionId,
      value.areaId,
    );
    final operator = await InstitucionOperadoresService.instance.buscar(
      value.institutionId,
      value.operatorId,
    );
    if (area == null ||
        !area.activa ||
        operator == null ||
        !operator.puedeActivarse) {
      return false;
    }
    final assignment = await InstitucionOperadoresService.instance
        .obtenerAsignacion(
          institucionId: value.institutionId,
          areaId: value.areaId,
          operadorId: value.operatorId,
        );
    return assignment?.estaActiva == true;
  }

  bool _same(
    InstitutionOperationalContext expected,
    InstitutionOperationalContext? actual,
  ) =>
      actual != null &&
      expected.institutionId == actual.institutionId &&
      expected.ownerAccountId == actual.ownerAccountId &&
      expected.areaId == actual.areaId &&
      expected.operatorId == actual.operatorId;
}
