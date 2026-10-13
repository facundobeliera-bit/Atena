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
  bool fail = false, wrong = false, change = false, reviewer = false;
  setUp(() async {
    calls.clear();
    applications.clear();
    fail = false;
    wrong = false;
    change = false;
    reviewer = false;
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
        if (body['p_action'] == 'approve' || body['p_action'] == 'reject') {
          final application = applications.singleWhere(
            (a) => a['id'] == body['p_data']['application_id'],
          );
          application['status'] = body['p_action'] == 'approve'
              ? 'approved'
              : 'rejected';
        }
        r.response.write(
          jsonEncode({
            'auth_user_id': wrong ? 'foreign' : session.identity,
            'applications': applications,
            'institutions': [],
            'invitations': [],
            'status': 'pending',
            'reviewer': reviewer,
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

  Future<void> settleReview(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openReview(WidgetTester tester, {bool own = false}) async {
    session.identity = 'reviewer-test';
    reviewer = true;
    applications.add({
      'id': 'review-application-test',
      'name': 'TEST revisión',
      'reference': 'TEST expediente',
      'applicant': own ? session.identity : 'applicant-test',
      'status': 'pending',
    });
    await tester.pumpWidget(
      const MaterialApp(home: InstitutionOnboardingPage()),
    );
    await settleReview(tester);
  }

  for (final approve in [true, false]) {
    testWidgets(
      'reviewer ${approve ? 'approval' : 'rejection'} uses audited server command',
      (tester) async {
        await openReview(tester);
        final button = find.text(approve ? 'Revisar y aprobar' : 'Rechazar');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Referencia de revisión (sin datos sensibles)',
          ),
          'TEST evidencia revisada',
        );
        await tester.tap(find.text('Continuar'));
        await settleReview(tester);
        if (approve) {
          expect(calls.where((c) => c['p_action'] == 'approve'), isEmpty);
          expect(find.text('Verificación administrativa'), findsOneWidget);
          await tester.tap(find.text('Confirmar revisión'));
        }
        await settleReview(tester);
        final sent = calls.singleWhere(
          (c) => c['p_action'] == (approve ? 'approve' : 'reject'),
        );
        expect(sent['p_data'], {
          'application_id': 'review-application-test',
          'review_reference': 'TEST evidencia revisada',
          'representation_checked': approve,
        });
        expect(
          find.text('TEST revisión · ${approve ? 'approved' : 'rejected'}'),
          findsOneWidget,
        );
        expect(
          find.text('Operación confirmada por el servidor.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'reviewer cannot approve their own application in the interface',
    (tester) async {
      await openReview(tester, own: true);
      expect(find.text('TEST revisión · pending'), findsOneWidget);
      expect(find.text('Revisar y aprobar'), findsNothing);
      expect(find.text('Rechazar'), findsNothing);
      expect(calls.where((c) => c['p_action'] != null), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reviewer revoked while decision dialog is open cannot show success',
    (tester) async {
      await openReview(tester);
      await tester.ensureVisible(find.text('Rechazar'));
      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Referencia de revisión (sin datos sensibles)',
        ),
        'TEST revisión revocada',
      );
      fail = true; // Server rejects the decision after permission revocation.
      await tester.tap(find.text('Continuar'));
      await settleReview(tester);
      expect(find.text('Operación confirmada por el servidor.'), findsNothing);
      expect(
        find.text(
          'Acceso no autorizado. Verificá tu correo, sesión y permisos.',
        ),
        findsOneWidget,
      );
      expect(applications.single['status'], 'pending');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
