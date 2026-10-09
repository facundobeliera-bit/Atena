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
  String identity = 'auth-a';
  bool permitted = true;
  @override
  String get userId => identity;
  @override
  Future<RemoteIdentityContext> context() async => RemoteIdentityContext({
    'auth_user_id': identity,
    'applicant_profiles': [],
    'institutional_contexts': permitted
        ? [
            {
              'institution_id': 'school',
              'area_id': 'area',
              'operator_id': 'op',
              'institution_name': 'School',
              'area_name': 'Area',
              'public_area_id': 'public-area',
              'capabilities': ['catalog.publish'],
            },
          ]
        : [],
  });
}

void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late _Session session;
  late Map<String, dynamic> workspace;
  final calls = <Map<String, dynamic>>[];
  bool fail = false, wrong = false, change = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'local-protected': 'keep'});
    calls.clear();
    fail = false;
    wrong = false;
    change = false;
    workspace = {
      'institution_id': 'school',
      'area_id': 'area',
      'revision': 0,
      'version': 0,
      'publication_state': 'never_published',
      'document': {
        'schema_version': 3,
        'institution': {
          'id': 'atena_inst',
          'name': 'School',
          'country': 'Argentina',
          'province': 'TEST',
          'city': 'TEST',
        },
        'area': {'id': 'public-area', 'name': 'Area', 'kind': 'curricular'},
        'activities': [],
        'groups': [],
      },
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
    );
    session = _Session(client);
    MultiuserSession.testSession = session;
    server.listen((r) async {
      r.response.persistentConnection = false;
      final raw = await utf8.decoder.bind(r).join();
      final body = raw.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw));
      calls.add(body);
      dynamic result = workspace;
      if (fail) {
        r.response.statusCode = 503;
        result = {'message': 'offline', 'code': '503'};
      } else if (r.uri.path.endsWith('atena_catalog_edit')) {
        final action = body['p_action'];
        workspace = {
          ...workspace,
          'revision': body['p_revision'] + 1,
          'version': body['p_version'] + (action == 'save' ? 0 : 1),
          'document': body['p_document'],
          'publication_state': action == 'publish'
              ? 'published'
              : action == 'withdraw'
              ? 'withdrawn'
              : workspace['publication_state'],
        };
        result = {...workspace, if (wrong) 'area_id': 'foreign'};
        if (change) session.identity = 'auth-b';
      }
      r.response.headers.contentType = ContentType.json;
      r.response.write(jsonEncode(result));
      await r.response.close();
    });
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    await client.dispose();
    await server.close(force: true);
  });
  Future<Map<String, dynamic>> edit(
    String action, [
    Map<String, dynamic>? old,
  ]) => session.editCatalog(
    'school',
    'area',
    old ?? workspace,
    Map<String, dynamic>.from(workspace['document']),
    action,
    'stable-operation',
  );
  test(
    'workspace and draft use remote scope and never local storage',
    () async {
      final old = await session.catalogWorkspace('school', 'area');
      final result = await edit('save', old);
      expect(result['revision'], 1);
      expect(result['version'], 0);
      expect(
        calls.last.keys,
        unorderedEquals([
          'p_institution',
          'p_area',
          'p_operation',
          'p_revision',
          'p_version',
          'p_action',
          'p_document',
        ]),
      );
      expect((await SharedPreferences.getInstance()).getKeys(), {
        'local-protected',
      });
    },
  );
  test('publish and withdraw validate server version/state', () async {
    expect((await edit('publish'))['publication_state'], 'published');
    expect((await edit('withdraw'))['publication_state'], 'withdrawn');
    expect(workspace['version'], 2);
  });
  test('authorization loss blocks even retries before RPC', () async {
    session.permitted = false;
    await expectLater(edit('save'), throwsStateError);
    expect(calls, isEmpty);
  });
  test('foreign reply cannot confirm a catalog mutation', () async {
    wrong = true;
    await expectLater(edit('save'), throwsFormatException);
  });
  test('account switch during mutation fails closed', () async {
    change = true;
    await expectLater(edit('save'), throwsStateError);
  });
  test('offline error propagates without local fallback', () async {
    fail = true;
    await expectLater(edit('save'), throwsA(isA<PostgrestException>()));
    expect((await SharedPreferences.getInstance()).getKeys(), {
      'local-protected',
    });
  });
  testWidgets('existing catalog creates draft then publishes and withdraws', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> settle() async {
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: RemoteCatalogPanel(institutionId: 'school', areaId: 'area'),
      ),
    );
    await settle();
    await tester.tap(find.text('Crear oferta'));
    await tester.pumpAndSettle();
    Future<void> field(String label, String value) async {
      final f = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(f);
      await tester.enterText(f, value);
    }

    await field('Actividad / programa', 'TEST activity');
    await field('Grupo / turno', 'TEST group');
    await field('Días y horario', 'Lunes 10:00-11:00');
    await field('Cupo total', '3');
    await tester.ensureVisible(find.text('Guardar borrador'));
    await tester.tap(find.text('Guardar borrador'));
    await settle();
    expect(find.text('Borrador confirmado por Supabase.'), findsOneWidget);
    expect(workspace['document']['groups'], hasLength(1));
    await tester.tap(find.text('Publicar catálogo compartido'));
    await settle();
    expect(workspace['publication_state'], 'published');
    await tester.tap(find.text('Retirar publicación'));
    await settle();
    expect(workspace['publication_state'], 'withdrawn');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
