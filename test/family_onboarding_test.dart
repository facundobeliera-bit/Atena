import 'dart:convert';
import 'dart:io';
import 'package:atena_app/services/remote/family_onboarding.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/ui/family_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

class _Storage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

class _Session extends MultiuserSession {
  _Session(super.client);
  String identity = 'adult';
  @override
  String get userId => identity;
  @override
  bool get signedIn => identity.isNotEmpty;
}

void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late _Session session;
  late FamilyOnboarding api;
  late Map<String, dynamic> state;
  final calls = <Map<String, dynamic>>[];
  bool fail = false, change = false, wrong = false;
  setUp(() async {
    fail = change = wrong = false;
    calls.clear();
    state = {
      'adult': false,
      'reviewer': false,
      'applications': <Map<String, dynamic>>[],
      'profiles': [],
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _Storage(),
      ),
    );
    session = _Session(client);
    api = FamilyOnboarding(session);
    MultiuserSession.testSession = session;
    server.listen((r) async {
      r.response.persistentConnection = false;
      final raw = await utf8.decoder.bind(r).join();
      final body = raw.isEmpty || raw == 'null'
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw));
      calls.add({'path': r.uri.path, ...body});
      r.response.headers.contentType = ContentType.json;
      if (fail) {
        r.response.statusCode = 503;
        r.response.write(
          jsonEncode({'code': 'unavailable', 'message': 'TEST'}),
        );
      } else if (r.uri.path.endsWith('/signup')) {
        r.response.write(
          jsonEncode({
            'id': '00000000-0000-4000-8000-000000000001',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'fictional@example.invalid',
            'created_at': '2026-10-13T00:00:00Z',
            'app_metadata': {},
            'user_metadata': {},
          }),
        );
      } else if (r.uri.path.endsWith('/atena_requests')) {
        r.response.write(
          jsonEncode([
            {
              'id': 'shared-request',
              'applicant_profile_id': 'child',
              'applicant_auth_user_id': 'other-reviewed-guardian',
              'state': 'confirmed',
            },
          ]),
        );
      } else {
        if (body['p_action'] == 'apply') {
          (state['applications'] as List).add({
            'id': 'application',
            'name': body['p_data']['name'],
            'status': 'pending',
            'applicant': 'adult',
          });
        }
        r.response.write(
          jsonEncode({
            ...state,
            'auth_user_id': wrong ? 'foreign' : session.identity,
          }),
        );
        if (change) session.identity = 'foreign';
      }
      await r.response.close();
    });
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'registration uses Supabase Auth without granting a profile or session',
    () async {
      session.identity = '';
      await api.register(
        'fictional@example.invalid',
        'fictional-long-passphrase',
      );
      expect(calls.single['path'], '/auth/v1/signup');
      expect(calls.single.containsKey('profile_id'), false);
      expect(client.auth.currentSession, isNull);
    },
  );
  test('cannot replace an active identity with signup', () async {
    await expectLater(
      api.register('fictional@example.invalid', 'fictional-long-passphrase'),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });
  test('unauthenticated state does not send requests', () async {
    session.identity = '';
    await expectLater(api.state(), throwsStateError);
    expect(calls, isEmpty);
  });
  test('server identity mismatch rejected', () async {
    wrong = true;
    await expectLater(api.state(), throwsStateError);
  });
  test('pending response discarded after account change', () async {
    change = true;
    await expectLater(
      api.command('apply', {'name': 'TEST', 'kind': 'adult'}),
      throwsStateError,
    );
  });
  test('interrupted connectivity cannot produce local success', () async {
    await server.close(force: true);
    await expectLater(api.state(), throwsA(anything));
  });
  test('family commands never manufacture caller or approval', () async {
    await api.command('apply', {
      'name': 'TEST',
      'kind': 'adult',
      'operation_id': 'test-operation',
    });
    expect(calls.single['path'], '/rest/v1/rpc/atena_family_command');
    expect(calls.single['p_data'], {
      'name': 'TEST',
      'kind': 'adult',
      'operation_id': 'test-operation',
    });
  });
  test(
    'authorized guardian reads enrollment submitted by another guardian',
    () async {
      state['applicant_profiles'] = [
        {'profile_id': 'child'},
      ];
      state['institutional_contexts'] = [];
      final requests = await session.requests(profile: 'child');
      expect(requests.single['id'], 'shared-request');
      expect(requests.single['state'], 'confirmed');
    },
  );
  test('no authorized context means no enrollment query', () async {
    state['applicant_profiles'] = [];
    state['institutional_contexts'] = [];
    await expectLater(session.requests(profile: 'child'), throwsStateError);
    expect(calls.any((c) => c['path'] == '/rest/v1/atena_requests'), false);
  });
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 20; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> show(WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: FamilyOnboardingPage()));
    await settle(t);
  }

  testWidgets('unreviewed adult cannot select minor creation', (t) async {
    await show(t);
    expect(find.text('Nuevo perfil de menor'), findsNothing);
    expect(find.text('Revisar y aprobar'), findsNothing);
  });
  testWidgets('adult application submits birth date and remains pending', (
    t,
  ) async {
    await show(t);
    await t.enterText(
      find.widgetWithText(TextField, 'Nombre del perfil'),
      'TEST Adult',
    );
    await t.enterText(
      find.widgetWithText(TextField, 'Nacimiento (AAAA-MM-DD)'),
      '1990-01-01',
    );
    await t.tap(find.text('Solicitar revisión'));
    await settle(t);
    final request = calls.firstWhere((c) => c['p_action'] == 'apply');
    expect(request['p_data']['birth_date'], '1990-01-01');
    expect(request['p_data'].containsKey('auth_user_id'), false);
    expect(find.text('TEST Adult · pending'), findsOneWidget);
  });
  testWidgets(
    'failed mutation does not show confirmed operation and clears private state',
    (t) async {
      await show(t);
      fail = true;
      await t.tap(find.text('Solicitar revisión'));
      await settle(t);
      expect(find.text('Operación confirmada por el servidor.'), findsNothing);
      expect(find.textContaining('El servidor no confirmó'), findsOneWidget);
      expect(find.text('Solicitar revisión'), findsNothing);
    },
  );
  testWidgets('reviewer cannot approve their own family application', (
    t,
  ) async {
    state['reviewer'] = true;
    state['applications'] = [
      {'id': 'a', 'applicant': 'adult', 'name': 'TEST', 'status': 'pending'},
    ];
    await show(t);
    expect(find.text('Revisar y aprobar'), findsNothing);
  });
  testWidgets(
    'review requires explicit evidence and responsibility confirmation',
    (t) async {
      state['reviewer'] = true;
      state['applications'] = [
        {
          'id': 'a',
          'applicant': 'other',
          'name': 'TEST child',
          'status': 'pending',
          'kind': 'minor',
        },
      ];
      await show(t);
      await t.ensureVisible(find.text('Revisar y aprobar'));
      await t.tap(find.text('Revisar y aprobar'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirmar revisión'),
            )
            .onPressed,
        isNull,
      );
      await t.enterText(
        find.widgetWithText(TextField, 'Referencia de revisión'),
        'TEST evidence reviewed',
      );
      await t.tap(find.byType(CheckboxListTile));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirmar revisión'));
      await settle(t);
      final command = calls.firstWhere((c) => c['p_action'] == 'approve');
      expect(command['p_data']['identity_checked'], true);
      expect(command['p_data']['responsibility_checked'], true);
      expect(command['p_data']['application_id'], 'a');
    },
  );
}
