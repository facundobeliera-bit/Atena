import 'package:supabase_flutter/supabase_flutter.dart';
import 'multiuser_session.dart';

/// No local account, role or institution is manufactured by this adapter.
class InstitutionOnboarding {
  final MultiuserSession session;
  InstitutionOnboarding(this.session);

  Future<void> register(String email, String password) async {
    if (session.signedIn) {
      throw StateError('Cerrá la sesión antes de registrar otra cuenta.');
    }
    if (password.length < 12) {
      throw StateError('Usá una contraseña de al menos 12 caracteres.');
    }
    await session.client.auth.signUp(email: email.trim(), password: password);
    // Email confirmation and representation approval remain server requirements.
  }

  Future<Map<String, dynamic>> state() => _request('atena_onboarding_state');
  Future<Map<String, dynamic>> command(
    String action,
    Map<String, dynamic> data,
  ) => _request('atena_onboarding_command', {
    'p_action': action,
    'p_data': data,
  });

  Future<Map<String, dynamic>> _request(
    String rpc, [
    Map<String, dynamic>? params,
  ]) async {
    final user = session.userId;
    final token = session.client.auth.currentSession?.accessToken;
    if (user.isEmpty) {
      throw StateError('Ingresá con tu cuenta y verificá el correo.');
    }
    final raw = await session.client.rpc(rpc, params: params);
    if (session.userId != user ||
        session.client.auth.currentSession?.accessToken != token) {
      throw StateError('La sesión cambió. Actualizá antes de continuar.');
    }
    final result = Map<String, dynamic>.from(raw as Map);
    if (result['auth_user_id'] != user) {
      throw StateError('Respuesta de identidad no válida.');
    }
    return result;
  }

  static String error(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is PostgrestException) {
      switch (error.code) {
        case '42501':
          return 'Acceso no autorizado. Verificá tu correo, sesión y permisos.';
        case '23505':
          return 'Ya existe una solicitud. Actualizá para consultar su estado.';
        case 'PT409':
          return 'La operación requiere revisión administrativa o ya cambió. Actualizá antes de reintentar.';
        case '22023':
          return 'Revisá los datos requeridos para esta operación.';
        case 'PGRST202':
          return 'El alta institucional todavía no está habilitada en este servidor.';
      }
    }
    return 'El servidor no confirmó la operación. Actualizá su estado antes de reintentar.';
  }
}
