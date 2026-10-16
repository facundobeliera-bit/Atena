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
      'state': 'pending',
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
      if (request.uri.path.endsWith('atena_request_decide')) {
        writes.add(body);
        if (fail ||
            (row['state'] != 'pending' && row['state'] != body['p_state'])) {
          request.response.statusCode = 409;
          result = {'code': 'PT409', 'message': 'Terminal request'};
        } else {
          row = {...row, 'state': body['p_state']};
          result = row;
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
    await t.tap(find.text('Cancelar solicitud'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Confirmar cancelación'));
    await settle(t);
  }

  for (final institution in [false, true]) {
    testWidgets(
      'pending cancellation from ${institution ? "institution" : "family"} uses existing RPC',
      (t) async {
        await open(t, institution: institution);
        await confirm(t);
        expect(writes.single, {
          'p_request_id': 'request-a',
          'p_state': institution
              ? 'cancelled_by_institution'
              : 'cancelled_by_student',
        });
        expect(find.text('Cancelada'), findsOneWidget);
        expect(find.text('Cancelar solicitud'), findsNothing);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('dismissed confirmation sends no write', (t) async {
    await open(t);
    await t.tap(find.text('Cancelar solicitud'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Volver'));
    await settle(t);
    expect(writes, isEmpty);
    expect(row['state'], 'pending');
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'account switch while dialog open cannot cancel as another identity',
    (t) async {
      await open(t);
      await t.tap(find.text('Cancelar solicitud'));
      await t.pump(const Duration(milliseconds: 300));
      session.actor = 'auth-b';
      await t.tap(find.text('Confirmar cancelación'));
      await settle(t);
      expect(writes, isEmpty);
      expect(find.textContaining('La sesión cambió'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('revoked family link rejects pending dialog', (t) async {
    await open(t);
    allowed = false;
    await confirm(t);
    expect(writes, isEmpty);
    expect(row['state'], 'pending');
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('server rejection is not shown as cancelled', (t) async {
    await open(t);
    fail = true;
    await confirm(t);
    expect(row['state'], 'pending');
    expect(find.text('Cancelada'), findsNothing);
    expect(find.textContaining('No se pudo confirmar'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('read-only operator cannot cancel', (t) async {
    canDecide = false;
    await open(t, institution: true);
    expect(find.text('Cancelar solicitud'), findsNothing);
    expect(writes, isEmpty);
    await t.pumpWidget(const SizedBox.shrink());
  });
  for (final state in ['confirmed', 'rejected', 'cancelled_by_student']) {
    testWidgets('$state offers no cancellation', (t) async {
      row['state'] = state;
      await open(t);
      expect(find.text('Cancelar solicitud'), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
  test('foreign profile/request and revoked link cannot reach write', () async {
    await expectLater(
      session.cancelRequest('foreign-profile', 'request-a'),
      throwsStateError,
    );
    await expectLater(
      session.cancelRequest('profile-a', 'foreign-request'),
      throwsStateError,
    );
    allowed = false;
    await expectLater(
      session.cancelRequest('profile-a', 'request-a'),
      throwsStateError,
    );
    expect(writes, isEmpty);
  });
  test('same cancellation retry delegates idempotence to server', () async {
    await session.cancelRequest('profile-a', 'request-a');
    await session.cancelRequest('profile-a', 'request-a');
    expect(writes, hasLength(2));
    expect(writes[0], writes[1]);
    expect(row['state'], 'cancelled_by_student');
  });
  test(
    'confirmation winning the race cannot become a local cancellation',
    () async {
      row['state'] = 'confirmed';
      await expectLater(
        session.cancelRequest('profile-a', 'request-a'),
        throwsA(isA<PostgrestException>()),
      );
      expect(row['state'], 'confirmed');
    },
  );
  for (final institution in [false, true]) {
    test(
      'late cancellation response after identity switch fails closed institution=$institution',
      () async {
        switchOnWrite = true;
        await expectLater(
          institution
              ? session.decide(
                  'institution-a',
                  'area-a',
                  'request-a',
                  'cancelled_by_institution',
                )
              : session.cancelRequest('profile-a', 'request-a'),
          throwsStateError,
        );
      },
    );
  }
}
