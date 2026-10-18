import 'institution_onboarding.dart';

/// Public presentation only. Ownership and legal identity are never editable.
class InstitutionPublicProfile {
  final InstitutionOnboarding api;
  InstitutionPublicProfile(this.api);

  static const fields = <String, String>{
    'public_name': 'Nombre público',
    'description': 'Descripción pública',
    'country': 'País',
    'province': 'Provincia',
    'city': 'Localidad',
    'address': 'Dirección pública',
    'phone': 'Teléfono de contacto',
    'email': 'Correo de contacto público',
    'opening_hours': 'Horarios de atención',
  };

  Future<Map<String, dynamic>> read(String institution) async => _check(
    await api.request('atena_institution_profile', {
      'p_institution': institution,
    }),
    institution,
  );

  Future<Map<String, dynamic>> save(
    String institution,
    String operation,
    int revision,
    Map<String, String> document,
  ) async {
    final result = _check(
      await api.request('atena_institution_profile_save', {
        'p_institution': institution,
        'p_operation': operation,
        'p_revision': revision,
        'p_document': document,
      }),
      institution,
    );
    if (result['operation_id'] != operation ||
        result['revision'] != revision + 1) {
      throw StateError(
        'El servidor no confirmó esta revisión. Actualizá antes de continuar.',
      );
    }
    return result;
  }

  Map<String, dynamic> _check(Map<String, dynamic> result, String institution) {
    final document = result['document'];
    if (result['institution_id'] != institution ||
        result['revision'] is! int ||
        result['revision'] < 0 ||
        document is! Map ||
        document.length != fields.length ||
        fields.keys.any((k) => document[k] is! String)) {
      throw StateError('Respuesta de perfil institucional no válida.');
    }
    return result;
  }
}
