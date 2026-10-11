import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:atena_app/ui/institution_onboarding_page.dart';
import 'package:atena_app/services/remote/institution_onboarding.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
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
  String identity = '';
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
  late InstitutionOnboarding api;
  final calls = <Map<String, dynamic>>[];
  final applications = <Map<String, dynamic>>[];
  bool fail = false, wrong = false, change = false;
  setUp(() async {
    calls.clear();
    applications.clear();
    fail = false;
    wrong = false;
    change = false;
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
    api = InstitutionOnboarding(session);
    MultiuserSession.testSession = session;
    server.listen((r) async {
      r.response.persistentConnection = false;
      final raw = await utf8.decoder.bind(r).join();
      final body = (raw.isEmpty || raw == 'null')
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw));
      calls.add({'path': r.uri.path, ...body});
      r.response.headers.contentType = ContentType.json;
      if (fail) {
        r.response.statusCode = 403;
        r.response.write(jsonEncode({'code': '42501', 'message': 'denied'}));
      } else if (r.uri.path.endsWith('/signup')) {
        r.response.write(
          jsonEncode({
            'id': '00000000-0000-4000-8000-000000000001',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'fictional@example.invalid',
            'created_at': '2026-10-10T00:00:00Z',
            'app_metadata': {},
            'user_metadata': {},
          }),
        );
      } else {
        if (body['p_action'] == 'apply') {
          applications.add({
            'id': 'application-test',
            'name': body['p_data']['name'],
            'status': 'pending',
            'applicant': session.identity,
          });
        }
        r.response.write(
          jsonEncode({
            'auth_user_id': wrong ? 'foreign' : session.identity,
            'applications': applications,
            'institutions': [],
            'invitations': [],
            'status': 'pending',
            'reviewer': false,
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
    'signup uses Auth and creates neither local account nor institutional role',
    () async {
      await api.register(
        'fictional@example.invalid',
        'fictional-test-passphrase',
      );
      expect(calls.single['path'], '/auth/v1/signup');
      expect(calls.single.containsKey('institution_id'), false);
      expect(client.auth.currentSession, isNull);
    },
  );
  test('signup cannot replace authenticated identity', () async {
    session.identity = 'owner';
    await expectLater(
      api.register('fictional@example.invalid', 'fictional-test-passphrase'),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });
  test('request only reports server confirmed pending state', () async {
    session.identity = 'owner';
    final result = await api.command('apply', {
      'name': 'TEST',
      'reference': 'TEST-001',
      'operation_id': MultiuserSession.operationId(),
    });
    expect(result['status'], 'pending');
    expect(calls.single['path'], '/rest/v1/rpc/atena_onboarding_command');
    expect(calls.single.containsKey('auth_user_id'), false);
  });
  test('unverified or unauthorized request never reports success', () async {
    session.identity = 'owner';
    fail = true;
    await expectLater(
      api.command('apply', {}),
      throwsA(isA<PostgrestException>()),
    );
  });
  test('late response after identity switch is discarded', () async {
    session.identity = 'owner';
    change = true;
    await expectLater(api.state(), throwsStateError);
  });
  test('foreign server identity fails closed', () async {
    session.identity = 'owner';
    wrong = true;
    await expectLater(api.state(), throwsStateError);
  });
  test('signed out cannot send administrative request', () async {
    await expectLater(api.command('approve', {}), throwsStateError);
    expect(calls, isEmpty);
  });
  test('network loss does not fabricate local approval', () async {
    session.identity = 'owner';
    await server.close(force: true);
    await expectLater(api.command('approve', {}), throwsA(anything));
  });
  testWidgets(
    'institutional application form submits to server and shows pending approval',
    (tester) async {
      session.identity = 'owner';
      Future<void> settle() async {
        for (var i = 0; i < 15; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await tester.pumpWidget(
        const MaterialApp(home: InstitutionOnboardingPage()),
      );
      await settle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre de la institución'),
        'TEST institución',
      );
      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Referencia institucional para revisión',
        ),
        'TEST-reference',
      );
      await tester.ensureVisible(find.text('Solicitar incorporación'));
      await tester.tap(find.text('Solicitar incorporación'));
      await settle();
      expect(find.text('TEST institución · pending'), findsOneWidget);
      expect(
        find.text('Operación confirmada por el servidor.'),
        findsOneWidget,
      );
      expect(calls.where((c) => c['p_action'] == 'apply'), hasLength(1));
      expect(find.text('Revisar y aprobar'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
