import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/catalogo/ficha_publica.dart';
import '../catalogo_publicable_service.dart';
import 'atena_supabase_client.dart';
import 'catalogo_supabase_repository.dart';
import 'solicitudes_supabase_repository.dart';

class RemoteInstitutionContext {
  final String institutionId, areaId, operatorId, name, areaName, publicAreaId;
  final Set<String> capabilities;
  RemoteInstitutionContext(Map<String, dynamic> row)
    : institutionId = row['institution_id'] as String,
      areaId = row['area_id'] as String,
      operatorId = row['operator_id'] as String,
      name = row['institution_name'] as String,
      areaName = row['area_name'] as String,
      publicAreaId = row['public_area_id'] as String,
      capabilities = Set.unmodifiable(List<String>.from(row['capabilities']));
}

class RemoteIdentityContext {
  final String userId;
  final List<String> profiles;
  final List<RemoteInstitutionContext> institutions;
  RemoteIdentityContext(Map<String, dynamic> row)
    : userId = row['auth_user_id'] as String,
      profiles = List.unmodifiable(
        (row['applicant_profiles'] as List).map(
          (p) => p['profile_id'] as String,
        ),
      ),
      institutions = List.unmodifiable(
        (row['institutional_contexts'] as List).map(
          (r) => RemoteInstitutionContext(Map<String, dynamic>.from(r)),
        ),
      );
}

/// Explicit mode, never an automatic fallback after a network failure.
/// Supabase persists only its own Auth session; no local Atena session is created.
class MultiuserSession {
  static const configured = bool.fromEnvironment('ATENA_MULTIUSER');
  @visibleForTesting
  static MultiuserSession? testSession;
  static MultiuserSession? _instance;
  static bool get enabled => configured || testSession != null;
  static MultiuserSession get current =>
      testSession ?? (_instance ??= _create());
  static MultiuserSession _create() {
    final client = AtenaSupabaseClient.optionalClient;
    if (client == null) {
      throw StateError('Falta configurar el backend compartido.');
    }
    return MultiuserSession(client);
  }

  final SupabaseClient client;
  MultiuserSession(this.client);
  bool get signedIn => client.auth.currentUser != null;
  String get userId => client.auth.currentUser?.id ?? '';

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await context();
  }

  Future<void> signOut() async {
    await client.auth.signOut(scope: SignOutScope.local);
  }

  Future<RemoteIdentityContext> context() async {
    final expected = userId;
    if (expected.isEmpty) throw StateError('Ingresá con tu cuenta remota.');
    final row = await client.rpc('atena_authenticated_context');
    final result = RemoteIdentityContext(Map<String, dynamic>.from(row));
    if (result.userId != expected || userId != expected) {
      throw StateError('La identidad de la sesión cambió. Volvé a ingresar.');
    }
    return result;
  }

  Future<RemoteInstitutionContext> institution(
    String institutionId,
    String areaId,
    String capability,
  ) async {
    final allowed = (await context()).institutions.where(
      (c) =>
          c.institutionId == institutionId &&
          c.areaId == areaId &&
          c.capabilities.contains(capability),
    );
    if (allowed.length != 1) {
      throw StateError('No tenés permiso para esta área.');
    }
    return allowed.single;
  }

  Future<List<FichaPublicaInstitucion>> catalog() =>
      CatalogoSupabaseRepository(client).leerPublico();

  Future<OfertaPublica> offer(String institutionId, String groupId) async {
    final offers = (await catalog())
        .where((i) => i.id == institutionId)
        .expand((i) => i.ofertas)
        .where((o) => o.id == groupId)
        .toList();
    if (offers.length != 1) throw StateError('La oferta ya no está publicada.');
    return offers.single;
  }

  Future<Map<String, dynamic>> create(
    String profile,
    OfertaPublica selected,
    String operation,
  ) async {
    final identity = await context();
    if (!identity.profiles.contains(profile)) {
      throw StateError('El perfil no pertenece a tu sesión remota.');
    }
    // The RPC resolves an accepted operation before checking current publication
    // and capacity. A withdrawn/offline catalog must not block that recovery.
    // New requests still require server-validated publication and availability.
    final result = await SolicitudesSupabaseRepository(client).crear(
      perfilVerificado: profile,
      grupoPublico: selected.id,
      operationId: operation,
    );
    if (userId != identity.userId) throw StateError('La sesión cambió.');
    if (result['applicant_auth_user_id'] != identity.userId) {
      throw const FormatException(
        'Propietario remoto de solicitud contradictorio.',
      );
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> requests({
    String? profile,
    String? institutionId,
    String? areaId,
  }) async {
    final identity = await context();
    if (profile != null) {
      if (!identity.profiles.contains(profile)) {
        throw StateError('Perfil no autorizado.');
      }
    } else {
      await institution(institutionId ?? '', areaId ?? '', 'requests.read');
    }
    final all = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += 100) {
      final page = await SolicitudesSupabaseRepository(
        client,
      ).listar(offset: offset);
      all.addAll(
        page.where(
          (r) => profile != null
              ? r['applicant_profile_id'] == profile &&
                    r['applicant_auth_user_id'] == identity.userId
              : r['institution_id'] == institutionId && r['area_id'] == areaId,
        ),
      );
      if (page.length < 100) break;
    }
    if (identity.userId != userId) throw StateError('La sesión cambió.');
    return all;
  }

  Future<void> decide(
    String institutionId,
    String areaId,
    String id,
    String state,
  ) async {
    await institution(institutionId, areaId, 'requests.decide');
    final rows = await requests(institutionId: institutionId, areaId: areaId);
    if (!rows.any((r) => r['id'] == id)) {
      throw StateError('Solicitud fuera del área seleccionada.');
    }
    await SolicitudesSupabaseRepository(client).decidir(id, state);
  }

  /// Only provisioned, already published pilot offers can be revised here.
  /// This does not provision groups/capacity or infer local-to-remote mappings.
  Future<Map<String, dynamic>> publication(
    String institutionId,
    String areaId,
  ) async {
    final scope = await institution(institutionId, areaId, 'catalog.publish');
    final rows = await client
        .from('atena_catalog_publications')
        .select()
        .eq('area_id', scope.publicAreaId);
    if (rows.length != 1) {
      throw StateError(
        'Esta área necesita una oferta remota previamente habilitada.',
      );
    }
    return Map<String, dynamic>.from(rows.single);
  }

  Future<void> publish(
    String institutionId,
    String areaId,
    Map<String, dynamic> document,
    int version,
    String operation,
  ) async {
    await institution(institutionId, areaId, 'catalog.publish');
    await CatalogoSupabaseRepository(client).publicar(
      institutionId: institutionId,
      areaId: areaId,
      operationId: operation,
      expectedVersion: version,
      catalogo: await CatalogoPublicable.fromRemoteDocument(document),
    );
  }

  Future<Map<String, dynamic>> catalogWorkspace(
    String institutionId,
    String areaId,
  ) async {
    final auth = userId;
    await institution(institutionId, areaId, 'catalog.publish');
    final value = await client.rpc(
      'atena_catalog_workspace',
      params: {'p_institution': institutionId, 'p_area': areaId},
    );
    if (userId != auth) throw StateError('La sesión cambió.');
    return _workspace(value, institutionId, areaId);
  }

  Future<Map<String, dynamic>> editCatalog(
    String institutionId,
    String areaId,
    Map<String, dynamic> workspace,
    Map<String, dynamic> document,
    String action,
    String operation,
  ) async {
    final auth = userId;
    await institution(institutionId, areaId, 'catalog.publish');
    if (!['save', 'publish', 'withdraw'].contains(action)) {
      throw ArgumentError('Acción de catálogo inválida.');
    }
    final value = await client.rpc(
      'atena_catalog_edit',
      params: {
        'p_institution': institutionId,
        'p_area': areaId,
        'p_operation': operation,
        'p_revision': workspace['revision'],
        'p_version': workspace['version'],
        'p_action': action,
        'p_document': document,
      },
    );
    if (userId != auth) throw StateError('La sesión cambió.');
    final result = _workspace(value, institutionId, areaId);
    if (result['revision'] != workspace['revision'] + 1 ||
        result['version'] !=
            workspace['version'] + (action == 'save' ? 0 : 1) ||
        (action == 'publish' && result['publication_state'] != 'published') ||
        (action == 'withdraw' && result['publication_state'] != 'withdrawn')) {
      throw const FormatException('Confirmación de catálogo contradictoria.');
    }
    return result;
  }

  static Map<String, dynamic> _workspace(
    dynamic value,
    String institution,
    String area,
  ) {
    if (value is! Map ||
        value['institution_id'] != institution ||
        value['area_id'] != area ||
        value['revision'] is! int ||
        value['version'] is! int ||
        value['document'] is! Map ||
        ![
          'never_published',
          'published',
          'withdrawn',
        ].contains(value['publication_state'])) {
      throw const FormatException('Catálogo institucional inválido.');
    }
    return Map<String, dynamic>.from(value);
  }

  static String operationId({bool catalog = false}) {
    final random = Random.secure();
    final bytes = List.generate(catalog ? 32 : 16, (_) => random.nextInt(256));
    if (!catalog) {
      bytes[6] = (bytes[6] & 15) | 64;
      bytes[8] = (bytes[8] & 63) | 128;
    }
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return catalog
        ? hex
        : '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
