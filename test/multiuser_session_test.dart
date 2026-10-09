import 'dart:convert';
import 'dart:io';

import 'package:atena_app/services/catalogo_publicable_service.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

// Only the local HTTP contract suite substitutes identity. Real GoTrue/JWT and
// ordinary widgets are covered separately by multiuser_remote_live_test.dart.
class _Session extends MultiuserSession {
  _Session(super.client);
  String identity = 'own-auth';
  @override
  String get userId => identity;
}

void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late _Session session;
  late Map<String, dynamic> identity;
  final calls = <Map<String, dynamic>>[];
  bool failCatalog = false;
  bool hideCatalog = false;
  bool changeDuringCreate = false;
  bool wrongOwner = false;
  final document = {
    'schema_version': 3,
    'institution': {
      'id': 'public-inst',
      'name': 'Escuela ficticia',
      'country': 'Argentina',
      'province': 'Demo',
      'city': 'Demo',
    },
    'area': {'id': 'public-area', 'kind': 'curricular', 'name': 'Formal'},
    'activities': [],
    'groups': [
      {
        'id': 'public-group',
        'activity_label': 'Taller',
        'name': 'Grupo A',
        'schedule': 'Lunes 10:00',
        'kind': 'curricular',
        'available': 1,
        'availability': 'available',
        'price': 'Gratuito',
        'ages': 'Adultos',
        'formal_type': 'escolar',
      },
    ],
  };
  Map<String, dynamic> row(String id, String institutionId, String profile) => {
    'id': id,
    'institution_id': institutionId,
    'area_id': 'assigned-area',
    'applicant_profile_id': profile,
    'applicant_auth_user_id': 'own-auth',
    'group_id': 'public-group',
    'state': 'pending',
    'operation_id': 'retry-id',
  };
  setUp(() async {
    SharedPreferences.setMockInitialValues({'local_marker': 'keep'});
    calls.clear();
    failCatalog = false;
    hideCatalog = false;
    changeDuringCreate = false;
    wrongOwner = false;
    (document['groups'] as List).single['availability'] = 'available';
    (document['groups'] as List).single['available'] = 1;
    identity = {
      'auth_user_id': 'own-auth',
      'applicant_profiles': [
        {'profile_id': 'own-profile'},
      ],
      'institutional_contexts': [
        {
          'institution_id': 'assigned-inst',
          'area_id': 'assigned-area',
          'operator_id': 'own-operator',
          'institution_name': 'Institución',
          'area_name': 'Área',
          'public_area_id': 'public-area',
          'capabilities': [
            'requests.read',
            'requests.decide',
            'catalog.publish',
          ],
        },
      ],
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public-key',
    );
    session = _Session(client);
    MultiuserSession.testSession = session;
    server.listen((request) async {
      final text = await utf8.decoder.bind(request).join();
      final body = text.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(text) as Map<String, dynamic>?) ?? <String, dynamic>{};
      final path = request.uri.path;
      calls.add({'path': path, 'body': body});
      Object response = [];
      if (path.endsWith('atena_authenticated_context')) response = identity;
      if (path.endsWith('atena_catalog_read')) {
        response = [
          {
            'institution_id': 'public-inst',
            'area_id': 'public-area',
            'document': document,
            'version': 1,
          },
        ];
        if (hideCatalog) response = [];
        if (failCatalog) {
          request.response.statusCode = 503;
          response = {'code': '503', 'message': 'offline'};
        }
      }
      if (path.endsWith('atena_request_create')) {
        response = {
          ...row('created', 'assigned-inst', body['p_profile_id']),
          'operation_id': body['p_operation_id'],
          if (wrongOwner) 'applicant_auth_user_id': 'another-auth',
        };
      }
      if (path.endsWith('atena_request_create') && changeDuringCreate) {
        session.identity = 'another-auth';
      }
      if (path.endsWith('/atena_requests')) {
        response = [
          row('institution-row', 'assigned-inst', 'someone-else'),
          row('own-row', 'another-inst', 'own-profile'),
        ];
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    await client.dispose();
    await server.close(force: true);
  });
  test('context discovery sends no identity arguments', () async {
    expect((await session.context()).profiles, ['own-profile']);
    expect(calls.single['body'], isEmpty);
  });
  test('contradictory remote identity fails closed', () async {
    identity['auth_user_id'] = 'another-auth';
    await expectLater(session.context(), throwsStateError);
  });
  test('missing identity fails before requesting protected context', () async {
    session.identity = '';
    await expectLater(session.context(), throwsStateError);
    expect(calls, isEmpty);
  });
  test(
    'anonymous public search uses remote source and preserves local data',
    () async {
      session.identity = '';
      expect(
        await CatalogoPublicableService().buscarPublico(
          texto: 'Taller',
          soloDisponibles: true,
        ),
        hasLength(1),
      );
      expect(
        await CatalogoPublicableService().buscarPublico(texto: 'no match'),
        isEmpty,
      );
      expect(
        calls.every((c) => c['path'].endsWith('atena_catalog_read')),
        isTrue,
      );
      expect((await SharedPreferences.getInstance()).getKeys(), {
        'local_marker',
      });
    },
  );
  test(
    'network failure never becomes local success or empty catalog',
    () async {
      failCatalog = true;
      await expectLater(
        CatalogoPublicableService().buscarPublico(),
        throwsA(isA<PostgrestException>()),
      );
      expect((await SharedPreferences.getInstance()).getKeys(), {
        'local_marker',
      });
    },
  );
  test('foreign profile rejected before request RPC', () async {
    final offer = (await session.catalog()).single.ofertas.single;
    await expectLater(
      session.create('foreign-profile', offer, 'retry-id'),
      throwsStateError,
    );
    expect(
      calls.any((c) => c['path'].endsWith('atena_request_create')),
      isFalse,
    );
  });
  test(
    'a request retry still reaches the authoritative RPC when capacity changes',
    () async {
      final offer = (await session.catalog()).single.ofertas.single;
      await session.create('own-profile', offer, 'retry-id');
      (document['groups'] as List).single['availability'] = 'full';
      (document['groups'] as List).single['available'] = 0;
      await session.create('own-profile', offer, 'retry-id');
      expect(
        calls.where((c) => c['path'].endsWith('atena_request_create')),
        hasLength(2),
      );
    },
  );
  test(
    'request retry retains key and sends no local identity/capacity/plan claims',
    () async {
      final offer = (await session.catalog()).single.ofertas.single;
      for (var i = 0; i < 2; i++) {
        await session.create('own-profile', offer, 'retry-id');
      }
      final sends = calls
          .where((c) => c['path'].endsWith('atena_request_create'))
          .toList();
      expect(sends, hasLength(2));
      expect(sends.first['body'], {
        'p_profile_id': 'own-profile',
        'p_group_id': 'public-group',
        'p_operation_id': 'retry-id',
      });
      expect(sends.last['body'], sends.first['body']);
    },
  );
  test(
    'institution view does not mix own applicant requests from another institution',
    () async {
      expect(
        (await session.requests(
          institutionId: 'assigned-inst',
          areaId: 'assigned-area',
        )).map((r) => r['id']),
        ['institution-row'],
      );
      expect(
        (await session.requests(profile: 'own-profile')).map((r) => r['id']),
        ['own-row'],
      );
    },
  );
  test(
    'unassigned context and manipulated decision never reach write RPC',
    () async {
      await expectLater(
        session.institution('foreign-inst', 'assigned-area', 'requests.decide'),
        throwsStateError,
      );
      await expectLater(
        session.decide(
          'assigned-inst',
          'assigned-area',
          'own-row',
          'confirmed',
        ),
        throwsStateError,
      );
      expect(
        calls.any((c) => c['path'].endsWith('atena_request_decide')),
        isFalse,
      );
    },
  );
  test('revoked applicant is not read from local identity', () async {
    identity['applicant_profiles'] = [];
    await expectLater(
      session.requests(profile: 'own-profile'),
      throwsStateError,
    );
    expect(calls.any((c) => c['path'].endsWith('/atena_requests')), isFalse);
  });
  for (final unavailable in ['withdrawn', 'offline']) {
    test('accepted request retry survives $unavailable catalog', () async {
      final offer = (await session.catalog()).single.ofertas.single;
      final first = await session.create('own-profile', offer, 'retry-id');
      hideCatalog = unavailable == 'withdrawn';
      failCatalog = unavailable == 'offline';
      final retry = await session.create('own-profile', offer, 'retry-id');
      expect(retry['id'], first['id']);
      expect(
        calls.where((c) => c['path'].endsWith('atena_request_create')),
        hasLength(2),
      );
    });
  }
  test(
    'in-flight creation cannot confirm success in a different session',
    () async {
      final offer = (await session.catalog()).single.ofertas.single;
      changeDuringCreate = true;
      await expectLater(
        session.create('own-profile', offer, 'retry-id'),
        throwsStateError,
      );
    },
  );
  test('creation rejects response assigned to another auth identity', () async {
    final offer = (await session.catalog()).single.ofertas.single;
    wrongOwner = true;
    await expectLater(
      session.create('own-profile', offer, 'retry-id'),
      throwsA(isA<FormatException>()),
    );
  });
}
