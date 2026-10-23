import 'dart:async';
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
  bool commitThenDisconnect = false;
  bool offline = false, requestExists = true;
  String? refusalCode;
  Completer<void>? catalogGate, catalogStarted;
  final decisions = <Map<String, dynamic>>[];
  final writes = <Map<String, dynamic>>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({'local-preserved': 'keep'});
    allowed = canDecide = true;
    fail = switchOnWrite = false;
    commitThenDisconnect = false;
    offline = false;
    requestExists = true;
    refusalCode = null;
    catalogGate = catalogStarted = null;
    decisions.clear();
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
      if (request.uri.path == '/auth/v1/token') {
        session.actor = body['email'] == 'institution@example.invalid'
            ? 'auth-a'
            : 'auth-b';
        result = {
          'access_token': 'local-http-fixture-not-a-real-jwt',
          'refresh_token': 'local-http-fixture-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': session.actor,
            'aud': 'authenticated',
            'email': body['email'],
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'created_at': '2026-10-23T00:00:00Z',
          },
        };
      }
      if (request.uri.path.endsWith('atena_catalog_read')) {
        if (catalogStarted != null && !catalogStarted!.isCompleted) {
          catalogStarted!.complete();
        }
        await catalogGate?.future;
        final occupied = row['state'] == 'confirmed' ? 1 : 0;
        result = [
          {
            'institution_id': 'public-institution-a',
            'area_id': 'public-area-a',
            'document': {
              'schema_version': 3,
              'institution': {
                'id': 'public-institution-a',
                'name': 'Institution TEST',
                'country': 'Argentina',
                'province': 'TEST',
                'city': 'TEST',
              },
              'area': {
                'id': 'public-area-a',
                'kind': 'curricular',
                'name': 'Area TEST',
              },
              'activities': [],
              'groups': [
                {
                  'id': 'group-a',
                  'name': 'Group TEST',
                  'kind': 'curricular',
                  'activity_label': 'Activity TEST',
                  'schedule': 'Lunes 10:00',
                  'capacity': 2,
                  'occupied': occupied,
                  'available': 2 - occupied,
                  'availability': 'available',
                  'price': '',
                  'ages': 'Adultos',
                  'formal_type': 'escolar',
                },
              ],
            },
          },
        ];
      }
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
      if (request.uri.path.endsWith('/atena_requests')) {
        result = requestExists ? [row] : [];
      }
      if (request.uri.path.endsWith('atena_request_create')) {
        requestExists = true;
        row = {
          ...row,
          'state': 'pending',
          'operation_id': body['p_operation_id'],
          'applicant_auth_user_id': session.actor,
        };
        result = row;
      }
      if (request.uri.path.endsWith('atena_request_decide')) {
        decisions.add(body);
        row = {...row, 'state': body['p_state']};
        result = row;
      }
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
          if (fail || refusalCode != null) {
            request.response.statusCode = 409;
            result = {
              'code': refusalCode ?? 'PT409',
              'message': 'TEST refusal',
            };
          } else {
            row = {...row, 'state': 'withdrawn_by_institution'};
          }
        }
        if (switchOnWrite) session.actor = 'auth-b';
      }
      if (commitThenDisconnect &&
          (request.uri.path.endsWith('atena_enrollment_withdraw') ||
              request.uri.path.endsWith('atena_request_decide'))) {
        commitThenDisconnect = false;
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.destroy();
        return;
      }
      request.response.headers.contentType = ContentType.json;
      request.response.persistentConnection = false;
      if (offline) {
        request.response.statusCode = 503;
        result = {'code': '503', 'message': 'Local simulated outage'};
      }
      request.response.write(jsonEncode(result));
      await request.response.close();
    });
  });
  tearDown(() async {
    if (catalogGate != null && !catalogGate!.isCompleted) {
      catalogGate!.complete();
    }
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

  for (final nextActor in ['', 'auth-b']) {
    testWidgets(
      'late catalog must not reveal previous profile actor=$nextActor',
      (t) async {
        catalogGate = Completer<void>();
        catalogStarted = Completer<void>();
        await t.pumpWidget(
          const MaterialApp(home: RemoteRequestsPanel(profile: 'profile-a')),
        );
        for (var i = 0; i < 100 && !catalogStarted!.isCompleted; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 20));
        }
        expect(catalogStarted!.isCompleted, isTrue);
        session.actor = nextActor;
        catalogGate!.complete();
        await settle(t);
        expect(find.text('Perfil: profile-a'), findsNothing);
        expect(find.text('Confirmada'), findsNothing);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'lost withdrawal response reconciles server state before another action',
    (t) async {
      await open(t, institution: true);
      commitThenDisconnect = true;
      await confirm(t);
      expect(writes, hasLength(1));
      expect(find.text('Baja institucional'), findsOneWidget);
      expect(find.text('Dar de baja inscripción'), findsNothing);
      expect(find.text('Vacantes disponibles: 2'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('lost confirmation response reconciles state and capacity', (
    t,
  ) async {
    row['state'] = 'pending';
    await open(t, institution: true);
    commitThenDisconnect = true;
    await t.tap(find.text('Confirmar'));
    await settle(t);
    expect(decisions, hasLength(1));
    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('Vacantes disponibles: 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('PT426 asks for an update instead of a blind retry', (t) async {
    await open(t, institution: true);
    refusalCode = 'PT426';
    await confirm(t);
    expect(find.textContaining('versión'), findsOneWidget);
    expect(row['state'], 'confirmed');
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'HTTP simulated client journey from login and request to confirmation withdrawal and both histories',
    (t) async {
      requestExists = false;
      row['state'] = 'pending';
      await t.runAsync(
        () =>
            session.signIn('institution@example.invalid', 'local-fixture-only'),
      );
      expect(client.auth.currentUser!.id, 'auth-a');
      final catalog = await t.runAsync(() => session.catalog());
      expect(catalog!.single.ofertas.single.disponibles, 2);
      await t.runAsync(
        () => session.signIn('student@example.invalid', 'local-fixture-only'),
      );
      expect(client.auth.currentUser!.id, 'auth-b');
      await t.pumpWidget(
        MaterialApp(
          home: RemoteRequestPanel(
            profile: 'profile-a',
            offer: catalog.single.ofertas.single,
          ),
        ),
      );
      await t.tap(find.text('Enviar solicitud'));
      for (
        var i = 0;
        i < 150 && find.text('Pendiente').evaluate().isEmpty;
        i++
      ) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Pendiente'), findsOneWidget);
      expect(row['applicant_auth_user_id'], 'auth-b');
      await t.pumpWidget(const SizedBox.shrink());
      await t.runAsync(
        () =>
            session.signIn('institution@example.invalid', 'local-fixture-only'),
      );
      await t.pumpWidget(const MaterialApp(home: RemoteAccountPanel()));
      await settle(t);
      await t.ensureVisible(find.text('Gestionar solicitudes'));
      await t.tap(find.text('Gestionar solicitudes'));
      await settle(t);
      await t.pumpAndSettle();
      final confirmAction = t
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar'))
          .onPressed!;
      confirmAction();
      confirmAction();
      await settle(t);
      expect(decisions, hasLength(1));
      expect(find.text('Confirmada'), findsOneWidget);
      expect(find.text('Vacantes disponibles: 1'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      await t.runAsync(
        () => session.signIn('student@example.invalid', 'local-fixture-only'),
      );
      await open(t);
      expect(find.text('Confirmada'), findsOneWidget);
      expect(find.text('Vacantes disponibles: 1'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      await t.runAsync(
        () =>
            session.signIn('institution@example.invalid', 'local-fixture-only'),
      );
      await open(t, institution: true);
      await t.tap(find.text('Dar de baja inscripción'));
      await t.pump(const Duration(milliseconds: 300));
      await t.enterText(find.byType(TextField), 'TEST reason');
      await t.pump();
      final withdrawAction = t
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirmar baja'),
          )
          .onPressed!;
      withdrawAction();
      withdrawAction();
      await settle(t);
      expect(writes, hasLength(1));
      expect(find.text('Baja institucional'), findsOneWidget);
      expect(find.text('Vacantes disponibles: 2'), findsOneWidget);
      for (final institution in [true, false]) {
        await t.pumpWidget(const SizedBox.shrink());
        if (!institution) {
          await t.runAsync(
            () =>
                session.signIn('student@example.invalid', 'local-fixture-only'),
          );
        }
        await open(t, institution: institution);
        await t.tap(find.text('Ver historial de baja'));
        for (var i = 0; i < 25; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('Historial de inscripción'), findsOneWidget);
        expect(find.textContaining('TEST reason'), findsOneWidget);
        await t.tap(find.text('Cerrar'));
        await t.pumpAndSettle();
        expect(find.text('Vacantes disponibles: 2'), findsOneWidget);
      }
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'connection recovery reloads without stale actions or new writes',
    (t) async {
      await open(t, institution: true);
      offline = true;
      await t.tap(find.byTooltip('Actualizar'));
      await settle(t);
      expect(find.text('Dar de baja inscripción'), findsNothing);
      expect(find.text('Confirmada'), findsNothing);
      offline = false;
      await t.tap(find.byTooltip('Actualizar'));
      await settle(t);
      expect(find.text('Confirmada'), findsOneWidget);
      expect(writes, isEmpty);
      expect(decisions, isEmpty);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('permission refusal is explicit and does not change enrollment', (
    t,
  ) async {
    await open(t, institution: true);
    refusalCode = '42501';
    await confirm(t);
    expect(find.textContaining('permiso vigente'), findsOneWidget);
    expect(row['state'], 'confirmed');
    await t.pumpWidget(const SizedBox.shrink());
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
