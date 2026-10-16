import 'dart:convert';
import 'dart:io';
import 'package:atena_app/services/remote/identity_rectification.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/ui/identity_rectification_page.dart';
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
  bool enabled = true;
  @override
  bool get essentialOperationsReady => enabled;
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
  late IdentityRectification api;
  late Map<String, dynamic> state;
  final calls = <Map<String, dynamic>>[];
  bool fail = false, change = false, wrong = false;
  setUp(() async {
    fail = change = wrong = false;
    calls.clear();
    state = {
      'family_reviewer': false,
      'institution_reviewer': false,
      'targets': [
        {
          'scope': 'family',
          'id': 'profile',
          'name': 'TEST Adult',
          'birth_date': '1990-01-01',
        },
      ],
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
    api = IdentityRectification(session);
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
            'previous_name': 'TEST Adult',
            'proposed_name': body['p_data']['name'],
            'previous_birth_date': '1990-01-01',
            'proposed_birth_date': body['p_data']['birth_date'],
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
  test('disabled and unauthenticated operations never reach network', () async {
    session.enabled = false;
    expect(() => api.state(), throwsStateError);
    session.enabled = true;
    session.identity = '';
    await expectLater(api.state(), throwsStateError);
    expect(calls, isEmpty);
  });
  test('foreign server identity rejected', () async {
    wrong = true;
    await expectLater(api.state(), throwsStateError);
  });
  test('response discarded after account switch', () async {
    change = true;
    await expectLater(api.command('apply', {'name': 'TEST'}), throwsStateError);
  });
  test('network failure never becomes a local correction', () async {
    fail = true;
    await expectLater(api.state(), throwsA(anything));
  });
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 25; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> show(WidgetTester t) async {
    t.view.physicalSize = const Size(1000, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(const MaterialApp(home: IdentityRectificationPage()));
    await settle(t);
  }

  testWidgets('critical edit submits proposal only with no identity grants', (
    t,
  ) async {
    await show(t);
    await t.tap(find.text('Solicitar rectificación'));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byType(TextFormField).at(0), 'TEST Corrected');
    await t.enterText(find.byType(TextFormField).at(1), '1990-02-01');
    await t.enterText(
      find.byType(TextFormField).at(2),
      'TEST documented correction',
    );
    await t.tap(find.text('Enviar a revisión'));
    await settle(t);
    final body =
        calls.firstWhere((c) => c['p_action'] == 'apply')['p_data'] as Map;
    expect(body.keys.toSet(), {
      'scope',
      'target_id',
      'name',
      'birth_date',
      'reason',
      'operation_id',
    });
    expect(body['target_id'], 'profile');
    expect(find.textContaining('TEST Corrected · pending'), findsOneWidget);
    expect(find.text('Revisar y aprobar'), findsNothing);
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('identity changes during dialog prevent correction', (t) async {
    await show(t);
    await t.tap(find.text('Solicitar rectificación'));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(
      find.byType(TextFormField).at(2),
      'TEST documented correction',
    );
    session.identity = 'other';
    await t.tap(find.text('Enviar a revisión'));
    await settle(t);
    expect(calls.any((c) => c['p_action'] == 'apply'), false);
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('review needs independent reviewer and explicit verification', (
    t,
  ) async {
    state['targets'] = [];
    state['family_reviewer'] = true;
    state['applications'] = [
      {
        'id': 'correction',
        'scope': 'family',
        'applicant': 'other',
        'status': 'pending',
        'previous_name': 'TEST Before',
        'proposed_name': 'TEST After',
        'reason': 'TEST documented correction',
      },
    ];
    await show(t);
    await t.tap(find.text('Revisar y aprobar'));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byType(TextField), 'TEST reviewed evidence');
    await t.pump();
    expect(
      t
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirmar revisión'),
          )
          .onPressed,
      isNull,
    );
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    await t.tap(find.text('Confirmar revisión'));
    await settle(t);
    final body =
        calls.firstWhere((c) => c['p_action'] == 'approve')['p_data'] as Map;
    expect(body, {
      'application_id': 'correction',
      'review_reference': 'TEST reviewed evidence',
      'identity_checked': true,
    });
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('same applicant is never offered self review', (t) async {
    state['targets'] = [];
    state['family_reviewer'] = true;
    state['applications'] = [
      {
        'id': 'correction',
        'scope': 'family',
        'applicant': 'adult',
        'status': 'pending',
        'previous_name': 'TEST Before',
        'proposed_name': 'TEST After',
      },
    ];
    await show(t);
    expect(find.text('Revisar y aprobar'), findsNothing);
    await t.pumpWidget(const SizedBox.shrink());
  });
}
