import 'dart:convert';
import 'dart:io';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/ui/multiuser_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

class _Session extends MultiuserSession {
  _Session(super.client);
  String actor = 'auth-a';
  bool enabled = true;
  @override
  bool get enrollmentWithdrawalReady => enabled;
  @override
  String get userId => actor;
}

// Real adapter/SDK against controlled local HTTP. This does not claim JWT or
// remote writes; the deployed RPC's authorization remains the final authority.
void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late _Session session;
  late Map<String, dynamic> row;
  bool allowed = true, canDecide = true, fail = false, switchOnWrite = false;
  final writes = <Map<String, dynamic>>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({'local-preserved': 'keep'});
    allowed = canDecide = true;
    fail = switchOnWrite = false;
    writes.clear();
    row = {
      'id': 'request-a',
      'institution_id': 'institution-a',
      'area_id': 'area-a',
      'applicant_profile_id': 'profile-a',
      'applicant_auth_user_id': 'auth-a',
      'group_id': 'group-a',
      'state': 'confirmed',
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    session = _Session(client);
    MultiuserSession.testSession = session;
    server.listen((request) async {
      if (request.uri.path.endsWith('/atena_requests') ||
          request.uri.path.endsWith('atena_enrollment_withdraw') ||
          request.uri.path.endsWith('/atena_enrollment_withdrawals')) {
        expect(request.headers.value('x-atena-request-contract'), '2');
      }
      final text = await utf8.decoder.bind(request).join();
      final body = text.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(text) as Map<String, dynamic>?) ?? <String, dynamic>{};
      Object result = [];
      if (request.uri.path.endsWith('atena_authenticated_context')) {
        result = {
          'auth_user_id': session.userId,
          'applicant_profiles': allowed
              ? [
                  {'profile_id': 'profile-a'},
                ]
              : [],
          'institutional_contexts': [
            {
              'institution_id': 'institution-a',
              'area_id': 'area-a',
              'operator_id': 'operator-a',
              'institution_name': 'Institution TEST',
              'area_name': 'Area TEST',
              'public_area_id': 'public-area-a',
              'capabilities': [
                'requests.read',
                if (canDecide) 'requests.decide',
              ],
            },
          ],
        };
      }
      if (request.uri.path.endsWith('/atena_requests')) result = [row];
      if (request.uri.path.endsWith('atena_enrollment_withdraw') ||
          request.uri.path.endsWith('/atena_enrollment_withdrawals')) {
        final event = {
          'request_id': 'request-a',
          'institution_id': 'institution-a',
          'area_id': 'area-a',
          'reason': body['p_reason'] ?? 'TEST reason',
          'confirmed_at': '2026-10-01T10:00:00Z',
          'confirmed_by_auth_user_id': 'auth-a',
          'confirmed_by_operator_id': 'operator-a',
          'withdrawn_at': '2026-10-16T10:00:00Z',
          'withdrawn_by_auth_user_id': 'auth-a',
          'withdrawn_by_operator_id': 'operator-a',
        };
        result = event;
        if (request.uri.path.endsWith('atena_enrollment_withdraw')) {
          writes.add(body);
          if (fail) {
            request.response.statusCode = 409;
            result = {'code': 'PT409', 'message': 'TEST conflict'};
          } else {
            row = {...row, 'state': 'withdrawn_by_institution'};
          }
        }
        if (switchOnWrite) session.actor = 'auth-b';
      }
      request.response.headers.contentType = ContentType.json;
      request.response.persistentConnection = false;
      request.response.write(jsonEncode(result));
      await request.response.close();
    });
  });
  tearDown(() async {
    expect((await SharedPreferences.getInstance()).getKeys(), {
      'local-preserved',
    });
    MultiuserSession.testSession = null;
    await client.dispose();
    await server.close(force: true);
  });
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 150; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pump(const Duration(milliseconds: 50));
      if (i > 5 && find.byType(LinearProgressIndicator).evaluate().isEmpty) {
        return;
      }
    }
    expect(find.byType(LinearProgressIndicator), findsNothing);
  }

  Future<void> open(WidgetTester t, {bool institution = false}) async {
    t.view.physicalSize = const Size(1000, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: institution
            ? const RemoteRequestsPanel(
                institutionId: 'institution-a',
                areaId: 'area-a',
              )
            : const RemoteRequestsPanel(profile: 'profile-a'),
      ),
    );
    await settle(t);
  }

  Future<void> confirm(WidgetTester t) async {
    await t.tap(find.text('Dar de baja inscripción'));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byType(TextField), 'TEST reason');
    await t.pump();
    await t.tap(find.text('Confirmar baja'));
    await settle(t);
  }

  test('withdrawal build flag does not enable identity rectification', () {
    final configured = MultiuserSession(client);
    expect(configured.essentialOperationsReady, isFalse);
    expect(
      configured.enrollmentWithdrawalReady,
      const bool.fromEnvironment('ATENA_ENROLLMENT_WITHDRAWAL_READY'),
    );
  });

  testWidgets(
    'institution withdrawal is remote and family sees audited terminal state',
    (t) async {
      await open(t, institution: true);
      await confirm(t);
      expect(writes.single, {
        'p_request_id': 'request-a',
        'p_reason': 'TEST reason',
      });
      expect(find.text('Baja institucional'), findsOneWidget);
      expect(find.text('Dar de baja inscripción'), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
      await open(t);
      expect(find.text('Baja institucional'), findsOneWidget);
      await t.tap(find.text('Ver historial de baja'));
      for (var i = 0; i < 25; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.textContaining('TEST reason'), findsOneWidget);
      expect(find.textContaining('operator-a'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final institution in [false, true]) {
    testWidgets('gate disabled offers no withdrawal institution=$institution', (
      t,
    ) async {
      session.enabled = false;
      await open(t, institution: institution);
      expect(find.text('Dar de baja inscripción'), findsNothing);
      await expectLater(
        session.withdrawEnrollment(
          'institution-a',
          'area-a',
          'request-a',
          'TEST reason',
        ),
        throwsStateError,
      );
      expect(writes, isEmpty);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('family cannot withdraw and read-only operator cannot withdraw', (
    t,
  ) async {
    await open(t);
    expect(find.text('Dar de baja inscripción'), findsNothing);
    await t.pumpWidget(const SizedBox.shrink());
    canDecide = false;
    await open(t, institution: true);
    expect(find.text('Dar de baja inscripción'), findsNothing);
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('reason required and dismissed dialog sends no request', (
    t,
  ) async {
    await open(t, institution: true);
    await t.tap(find.text('Dar de baja inscripción'));
    await t.pump(const Duration(milliseconds: 300));
    expect(
      t
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirmar baja'),
          )
          .onPressed,
      isNull,
    );
    await t.tap(find.text('Volver'));
    await settle(t);
    expect(writes, isEmpty);
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('server refusal never shown as successful withdrawal', (t) async {
    await open(t, institution: true);
    fail = true;
    await confirm(t);
    expect(row['state'], 'confirmed');
    expect(find.text('Baja institucional'), findsNothing);
    expect(find.textContaining('No se pudo confirmar'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('identity switch while dialog open prevents writing', (t) async {
    await open(t, institution: true);
    await t.tap(find.text('Dar de baja inscripción'));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byType(TextField), 'TEST reason');
    await t.pump();
    session.actor = 'auth-b';
    await t.tap(find.text('Confirmar baja'));
    await settle(t);
    expect(writes, isEmpty);
    await t.pumpWidget(const SizedBox.shrink());
  });
  test('foreign area and request IDs never reach write', () async {
    await expectLater(
      session.withdrawEnrollment(
        'foreign',
        'area-a',
        'request-a',
        'TEST reason',
      ),
      throwsStateError,
    );
    await expectLater(
      session.withdrawEnrollment(
        'institution-a',
        'area-a',
        'foreign',
        'TEST reason',
      ),
      throwsStateError,
    );
    canDecide = false;
    await expectLater(
      session.withdrawEnrollment(
        'institution-a',
        'area-a',
        'request-a',
        'TEST reason',
      ),
      throwsStateError,
    );
    expect(writes, isEmpty);
  });
  test('late withdrawal and history discarded after session switch', () async {
    switchOnWrite = true;
    await expectLater(
      session.withdrawEnrollment(
        'institution-a',
        'area-a',
        'request-a',
        'TEST reason',
      ),
      throwsStateError,
    );
    session.actor = 'auth-a';
    await expectLater(session.withdrawalHistory('request-a'), throwsStateError);
  });
  testWidgets(
    'compatible reader retains withdrawal history with new actions off',
    (t) async {
      session.enabled = false;
      row['state'] = 'withdrawn_by_institution';
      await open(t, institution: false);
      expect(find.text('Baja institucional'), findsOneWidget);
      expect(find.text('Dar de baja inscripción'), findsNothing);
      await t.tap(find.text('Ver historial de baja'));
      for (var i = 0; i < 25; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Historial de inscripción'), findsOneWidget);
      expect(find.textContaining('TEST reason'), findsOneWidget);
      expect(writes, isEmpty);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('withdrawal dialog fits a narrow viewport with keyboard', (
    t,
  ) async {
    await open(t, institution: true);
    t.view.physicalSize = const Size(360, 640);
    await t.pump();
    await t.tap(find.text('Dar de baja inscripción'));
    await t.pump(const Duration(milliseconds: 300));
    t.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(t.view.resetViewInsets);
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });
}
