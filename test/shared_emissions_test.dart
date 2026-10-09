import 'dart:convert';
import 'dart:io';
import 'package:atena_app/services/remote/emisiones_supabase_repository.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

class _Session extends MultiuserSession {
  _Session(super.client);
  String identity = 'auth-a';
  @override
  String get userId => identity;
}

void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late _Session session;
  late EmisionesSupabaseRepository repository;
  late Map<String, dynamic> identity;
  final calls = <Map<String, dynamic>>[];
  bool fail = false;
  final event = {
    'id': 'event',
    'title': 'Encuentro TEST',
    'note': 'Aviso',
    'date': '2026-10-15',
    'time': '10:30',
    'read': false,
  };
  setUp(() async {
    SharedPreferences.setMockInitialValues({'protected': 'local untouched'});
    calls.clear();
    fail = false;
    identity = {
      'auth_user_id': 'auth-a',
      'applicant_profiles': [
        {'profile_id': 'own-profile'},
      ],
      'institutional_contexts': [
        {
          'institution_id': 'school-a',
          'area_id': 'area-a',
          'operator_id': 'operator-a',
          'institution_name': 'A',
          'area_name': 'Area',
          'public_area_id': 'public-a',
          'capabilities': [
            'calendar.write',
            'communications.write',
            'responses.read',
          ],
        },
      ],
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
    );
    session = _Session(client);
    repository = EmisionesSupabaseRepository(session);
    server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      final body =
          (raw.isEmpty ? null : jsonDecode(raw)) as Map<String, dynamic>? ??
          <String, dynamic>{};
      final name = request.uri.path.split('/').last;
      calls.add({'name': name, 'body': body});
      Object? value;
      if (name == 'atena_authenticated_context') {
        value = identity;
      } else if (fail) {
        request.response.statusCode = 503;
        value = {'code': '503', 'message': 'unavailable'};
      } else if (name == 'atena_emission_save') {
        value = {
          'id': body['p_id'],
          'revision': (body['p_revision'] as int) + 1,
          'delivered': 1,
        };
      } else if (name == 'atena_emissions_student') {
        value = [event];
      } else if (name == 'atena_emission_enrollments') {
        value = [
          {'id': 'request-a', 'profile_id': 'student', 'group_id': 'group'},
        ];
      } else if (name == 'atena_emission_responses') {
        value = [
          {'status': 'yes'},
        ];
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(value));
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  Future<Map<String, dynamic>> save() => repository.save(
    institution: 'school-a',
    area: 'area-a',
    id: 'stable-id',
    operation: 'stable-op',
    kind: 'calendar',
    title: 'TEST',
    body: 'Description',
    requests: ['request-a'],
    start: DateTime(2026, 10, 15, 10, 30),
  );
  test(
    'authorized emissions send enrollment IDs, never client actor or owner',
    () async {
      expect(await repository.enrollments('school-a', 'area-a'), hasLength(1));
      expect((await save())['id'], 'stable-id');
      final body = calls.last['body'] as Map;
      expect(body['p_requests'], ['request-a']);
      expect(
        body.keys.any(
          (k) =>
              k.toString().contains('owner') ||
              k.toString().contains('operator') ||
              k.toString().contains('auth'),
        ),
        false,
      );
      expect(calls.first['body'], isEmpty);
    },
  );
  test('retry preserves operation and request identifiers', () async {
    await save();
    final first = calls.last['body'];
    await save();
    expect(calls.last['body'], first);
  });
  test('foreign institution and area rejected before protected RPC', () async {
    await expectLater(
      repository.enrollments('other-school', 'area-a'),
      throwsStateError,
    );
    await expectLater(
      repository.enrollments('school-a', 'other-area'),
      throwsStateError,
    );
    expect(
      calls.every((c) => c['name'] == 'atena_authenticated_context'),
      true,
    );
  });
  test('revoked capability blocks save', () async {
    (identity['institutional_contexts'] as List).single['capabilities'] =
        <String>[];
    await expectLater(save(), throwsStateError);
    expect(calls.any((c) => c['name'] == 'atena_emission_save'), false);
  });
  test(
    'student calendar and inbox use explicit remote RPC and profile',
    () async {
      expect(
        (await repository.student('own-profile')).single['title'],
        'Encuentro TEST',
      );
      expect(calls.last['body'], {
        'p_profile': 'own-profile',
        'p_kind': 'calendar',
      });
      await repository.student('own-profile', calendar: false);
      expect(calls.last['body'], {
        'p_profile': 'own-profile',
        'p_kind': 'communication',
      });
      expect(
        (await SharedPreferences.getInstance()).getString('protected'),
        'local untouched',
      );
    },
  );
  test('another student profile rejected for reads and replies', () async {
    await expectLater(repository.student('another'), throwsStateError);
    await expectLater(
      repository.respond('another', 'event', 'yes'),
      throwsStateError,
    );
    await expectLater(
      repository.inboxState('another', 'event', read: true),
      throwsStateError,
    );
    expect(
      calls.every((c) => c['name'] == 'atena_authenticated_context'),
      true,
    );
  });
  test(
    'respond persists on server then reloads authoritative calendar',
    () async {
      expect(
        (await repository.respond('own-profile', 'event', 'yes'))?['id'],
        'event',
      );
      expect(calls.map((c) => c['name']), contains('atena_emission_respond'));
      expect(calls.last['name'], 'atena_emissions_student');
    },
  );
  test('response reading requires separate response capability', () async {
    expect(await repository.responses('school-a', 'area-a'), hasLength(1));
    (identity['institutional_contexts'] as List).single['capabilities'] = [
      'calendar.write',
    ];
    await expectLater(
      repository.responses('school-a', 'area-a'),
      throwsStateError,
    );
  });
  test(
    'network errors propagate and never become local success or empty list',
    () async {
      fail = true;
      await expectLater(save(), throwsA(isA<PostgrestException>()));
      await expectLater(
        repository.student('own-profile'),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        repository.inboxState('own-profile', 'event', read: true),
        throwsA(isA<PostgrestException>()),
      );
      expect((await SharedPreferences.getInstance()).getKeys(), {'protected'});
    },
  );
  test('missing or contradictory session fails closed', () async {
    identity['auth_user_id'] = 'other-auth';
    await expectLater(save(), throwsStateError);
    calls.clear();
    session.identity = '';
    await expectLater(repository.student('own-profile'), throwsStateError);
    expect(calls, isEmpty);
  });
}
