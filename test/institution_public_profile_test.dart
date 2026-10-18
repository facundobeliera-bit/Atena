import 'dart:convert';
import 'dart:io';
import 'package:atena_app/models/catalogo/ficha_publica.dart';
import 'package:atena_app/services/remote/catalogo_supabase_repository.dart';
import 'package:atena_app/services/remote/institution_onboarding.dart';
import 'package:atena_app/services/remote/institution_public_profile.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/ui/institution_public_profile_page.dart';
import 'package:atena_app/ui/catalogo_publico.dart';
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
  String identity = 'owner-a';
  @override
  String get userId => identity;
}

void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late _Session session;
  late InstitutionPublicProfile api;
  late Map<String, String> document;
  final writes = <Map<String, dynamic>>[];
  bool fail = false, change = false, wrong = false, legacy = false;
  int revision = 0;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'protected-local': 'keep'});
    writes.clear();
    fail = false;
    change = false;
    wrong = false;
    legacy = false;
    revision = 0;
    document = {
      for (final k in InstitutionPublicProfile.fields.keys) k: '',
      'public_name': 'TEST institución',
      'phone': 'TEST teléfono',
      'email': 'test@example.invalid',
      'opening_hours': 'Lunes 9 a 12',
      'description': 'TEST descripción',
      'address': 'TEST dirección',
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
    );
    session = _Session(client);
    MultiuserSession.testSession = session;
    api = InstitutionPublicProfile(InstitutionOnboarding(session));
    server.listen((r) async {
      r.response.persistentConnection = false;
      final raw = await utf8.decoder.bind(r).join();
      final body = raw.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw));
      final user = session.userId;
      dynamic response;
      if (r.uri.path.endsWith('atena_catalog_read')) {
        response = [
          for (final area in ['area1', 'area2'])
            {
              'institution_id': 'public-school',
              'area_id': area,
              'document': {
                'schema_version': 3,
                'institution': {
                  'id': 'public-school',
                  'name': 'TEST institución',
                  'country': 'TEST',
                  'province': 'TEST',
                  'city': 'TEST',
                  if (!legacy) ...{
                    'description': document['description'],
                    'address': document['address'],
                    'phone': document['phone'],
                    'email': document['email'],
                    'opening_hours': document['opening_hours'],
                  },
                },
                'area': {'id': area},
                'groups': [
                  {
                    'id': 'group-$area',
                    'kind': 'curricular',
                    'name': 'TEST grupo',
                    'activity_label': 'TEST oferta',
                    'schedule': 'Lunes 10:00-11:00',
                    'available': 2,
                    'availability': 'available',
                  },
                ],
              },
            },
        ];
      } else {
        if (r.uri.path.endsWith('atena_institution_profile_save')) {
          writes.add(body);
          if (!fail) {
            revision = body['p_revision'] + 1;
            document = Map<String, String>.from(body['p_document']);
          }
        }
        response = {
          'auth_user_id': user,
          'institution_id': wrong ? 'foreign' : 'school',
          'revision': revision,
          'document': document,
          if (body.containsKey('p_operation'))
            'operation_id': body['p_operation'],
        };
        if (fail && body.containsKey('p_operation')) {
          r.response.statusCode = 503;
          response = {'code': '503', 'message': 'offline'};
        }
        if (change) session.identity = 'owner-b';
      }
      r.response.headers.contentType = ContentType.json;
      r.response.write(jsonEncode(response));
      await r.response.close();
    });
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'save validates server acknowledgement and keeps local storage intact',
    () async {
      await api.read('school');
      final result = await api.save('school', 'operation', 0, document);
      expect(result['revision'], 1);
      expect(writes.single['p_document'], document);
      expect(writes.single.containsKey('owner'), false);
      expect(
        (await SharedPreferences.getInstance()).getString('protected-local'),
        'keep',
      );
    },
  );
  test('foreign institution response rejected', () async {
    wrong = true;
    await expectLater(api.read('school'), throwsStateError);
  });
  test('identity change during reply rejected', () async {
    change = true;
    await expectLater(api.read('school'), throwsStateError);
  });
  test(
    'save reply from a previous session never confirms in the new session',
    () async {
      change = true;
      await expectLater(
        api.save('school', 'operation', 0, document),
        throwsStateError,
      );
    },
  );
  test('failed write cannot become local success', () async {
    fail = true;
    await expectLater(
      api.save('school', 'operation', 0, document),
      throwsA(isA<PostgrestException>()),
    );
    expect(revision, 0);
  });
  test('public contact survives area merging and serialization', () async {
    final values = await CatalogoSupabaseRepository(client).leerPublico();
    expect(values, hasLength(1));
    final value = FichaPublicaInstitucion.fromMap(values.single.toMap());
    expect(value.email, 'test@example.invalid');
    expect(value.telefono, 'TEST teléfono');
    expect(value.direccion, 'TEST dirección');
    expect(value.descripcion, 'TEST descripción');
    expect(value.horariosAtencion, 'Lunes 9 a 12');
  });
  test('previous backend without contact remains compatible', () async {
    legacy = true;
    final value = (await CatalogoSupabaseRepository(
      client,
    ).leerPublico()).single;
    expect(value.email, isEmpty);
    expect(value.horariosAtencion, isEmpty);
    expect(value.nombre, 'TEST institución');
    final map = value.toMap()
      ..remove('email')
      ..remove('opening_hours');
    expect(FichaPublicaInstitucion.fromMap(map).email, isEmpty);
  });
  testWidgets(
    'failed save freezes payload, retries same operation and permits reload',
    (tester) async {
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
          home: InstitutionPublicProfilePage(institutionId: 'school'),
        ),
      );
      await settle();
      expect(find.text('TEST institución'), findsOneWidget);
      final save = find.text('Guardar datos públicos');
      await tester.scrollUntilVisible(
        save,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      fail = true;
      await tester.tap(save);
      await settle();
      expect(
        find.text('Perfil público confirmado por el servidor.'),
        findsNothing,
      );
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .every((f) => f.enabled == false),
        true,
      );
      final retry = find.text('Reintentar envío');
      await tester.ensureVisible(retry);
      fail = false;
      await tester.tap(retry);
      await settle();
      expect(writes, hasLength(2));
      expect(writes[0], writes[1]);
      await tester.scrollUntilVisible(
        find.text('Perfil público confirmado por el servidor.'),
        -350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Perfil público confirmado por el servidor.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Consultar estado guardado'));
      await settle();
      expect(find.text('TEST institución'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'public screen shows contact without exposing administrative identity',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: CatalogoPublicoPerfil(institucionId: 'public-school'),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('TEST dirección'), findsOneWidget);
      expect(find.text('TEST descripción'), findsOneWidget);
      expect(find.text('Contacto público: TEST teléfono'), findsOneWidget);
      expect(find.text('Correo público: test@example.invalid'), findsOneWidget);
      expect(find.text('Atención: Lunes 9 a 12'), findsOneWidget);
      expect(find.textContaining('owner-a'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
