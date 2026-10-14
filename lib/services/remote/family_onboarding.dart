import 'institution_onboarding.dart';

/// Auth registration is shared; profile authority is granted only by the server.
class FamilyOnboarding extends InstitutionOnboarding {
  FamilyOnboarding(super.session);
  @override
  Future<Map<String, dynamic>> state() => request('atena_family_state');
  @override
  Future<Map<String, dynamic>> command(
    String action,
    Map<String, dynamic> data,
  ) => request('atena_family_command', {'p_action': action, 'p_data': data});
}
