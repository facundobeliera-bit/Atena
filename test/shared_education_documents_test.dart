import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:atena_app/models/alumnos/modulo_educativo.dart';
import 'package:atena_app/services/documentacion_operativa_service.dart';
import 'package:atena_app/services/documentos_temporales_service.dart';
import 'package:atena_app/services/remote/documentos_supabase_repository.dart';
import 'package:atena_app/services/remote/educacion_supabase_repository.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/services/trayectoria_educativa_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

class _Session extends MultiuserSession {
  _Session(super.client);
  @override
  String get userId => 'auth-test';
}

void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late _Session session;
  late EducacionSupabaseRepository education;
  late DocumentosSupabaseRepository documents;
  late Map<String, dynamic> context;
  final calls = <Map<String, dynamic>>[];
  bool fail = false, contradictory = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'protected': 'historical'});
    calls.clear();
    fail = false;
    contradictory = false;
    context = {
      'auth_user_id': 'auth-test',
      'applicant_profiles': [
        {'profile_id': 'profile-test'},
      ],
      'institutional_contexts': [
        {
          'institution_id': 'institution-test',
          'area_id': 'area-test',
          'operator_id': 'operator-test',
          'institution_name': 'TEST',
          'area_name': 'TEST area',
          'public_area_id': 'public-test',
          'capabilities': [
            'education.read',
            'education.write',
            'documents.read',
            'documents.write',
          ],
        },
      ],
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'fictional');
    session = _Session(client);
    MultiuserSession.testSession = session;
    education = EducacionSupabaseRepository(session);
    documents = DocumentosSupabaseRepository(session);
    server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      final body =
          (raw.isEmpty ? null : jsonDecode(raw)) as Map<String, dynamic>? ?? {};
      final name = request.uri.path.split('/').last;
      calls.add({'name': name, 'body': body});
      Object? result;
      if (name == 'atena_authenticated_context') {
        result = context;
      } else if (fail) {
        request.response.statusCode = 503;
        result = {'code': '503', 'message': 'Unavailable'};
      } else if (name == 'atena_education_save') {
        result = {
          'id': contradictory ? 'wrong' : body['p_id'],
          'revision': (body['p_revision'] as int) + 1,
        };
      } else if (name.endsWith('_enrollments')) {
        result = [
          {
            'id': 'enrollment-test',
            'profile_id': 'profile-test',
            'group_id': 'group-test',
            'kind': 'curricular',
            'created_at': '2026-10-08T00:00:00Z',
            'updated_at': '2026-10-08T00:00:00Z',
          },
        ];
      } else if (name == 'atena_education_read') {
        result = [
          {'id': 'educational-test', 'revision': 1, 'porcentaje': 55},
        ];
      } else if (name == 'atena_documents_read') {
        result = {'requests': [], 'documents': []};
      } else if (name == 'atena_document_request' ||
          name == 'atena_document_upload') {
        result = contradictory ? 'wrong' : body['p_id'];
      } else if (name == 'atena_documents_remove') {
        result = 1;
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(result));
      await request.response.close();
    });
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    await client.dispose();
    await server.close(force: true);
  });
  Future<void> saveEducation() => education.save(
    institution: 'institution-test',
    area: 'area-test',
    request: 'enrollment-test',
    id: 'educational-test',
    module: ModuloEducativo.progreso,
    data: {'porcentaje': 40},
    visible: true,
    revision: 1,
  );
  test(
    'educational enrollment maps only server context without local identity',
    () async {
      final rows = await TrayectoriaEducativaService.instance.inscripciones(
        'institution-test',
        'area-test',
      );
      expect(rows.single.perfilId, 'profile-test');
      expect(rows.single.ownerAccountId, isNull);
    },
  );
  test('educational retry preserves operation and expected revision', () async {
    await saveEducation();
    final first = Map.of(calls.last['body'] as Map);
    await saveEducation();
    expect(calls.last['body'], first);
    expect(first['p_revision'], 1);
    expect(first.keys, isNot(contains('operatorId')));
  });
  test(
    'existing trajectory service reads remote with verified profile',
    () async {
      final rows = await TrayectoriaEducativaService.instance.leerAlumno(
        ownerAccountId: 'auth-test',
        perfilId: 'profile-test',
        modulo: ModuloEducativo.progreso,
      );
      expect(rows.single['porcentaje'], 55);
      expect(calls.last['name'], 'atena_education_read');
    },
  );
  test('foreign student rejected before educational request', () async {
    await expectLater(
      education.readStudent(
        'auth-other',
        'profile-test',
        ModuloEducativo.progreso,
      ),
      throwsStateError,
    );
    expect(calls.where((c) => c['name'] == 'atena_education_read'), isEmpty);
  });
  test('educational capability revoked before write', () async {
    ((context['institutional_contexts'] as List).single
        as Map)['capabilities'] = [
      'education.read',
    ];
    await expectLater(saveEducation(), throwsStateError);
    expect(calls.where((c) => c['name'] == 'atena_education_save'), isEmpty);
  });
  test('invalid educational field rejected before remote save', () async {
    await expectLater(
      education.save(
        institution: 'institution-test',
        area: 'area-test',
        request: 'enrollment-test',
        id: 'e',
        module: ModuloEducativo.progreso,
        data: {'porcentaje': 101},
        visible: true,
        revision: 0,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(calls.where((c) => c['name'] == 'atena_education_save'), isEmpty);
  });
  test('contradictory education confirmation rejected', () async {
    contradictory = true;
    await expectLater(saveEducation(), throwsFormatException);
  });
  test('remote failure does not persist locally or report success', () async {
    fail = true;
    await expectLater(saveEducation(), throwsA(isA<PostgrestException>()));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'protected'});
    expect(prefs.getString('protected'), 'historical');
  });
  test('documents use verified enrollment and stable operation', () async {
    await DocumentacionOperativaService.solicitar(
      'institution-test',
      'enrollment-test',
      TipoDocumento.otro,
      'TEST',
      remoteAreaId: 'area-test',
      operationId: 'stable-operation',
    );
    expect(calls.last['name'], 'atena_document_request');
    final body = calls.last['body'] as Map;
    expect(body['p_id'], 'stable-operation');
    expect(body.containsKey('ownerAccountId'), false);
  });
  test(
    'document upload uses existing validation without local storage',
    () async {
      await DocumentacionOperativaService.adjuntar(
        'auth-test',
        'profile-test',
        'request-test',
        Uint8List.fromList(utf8.encode('%PDF-TEST')),
      );
      expect(calls.last['name'], 'atena_document_upload');
      expect((await SharedPreferences.getInstance()).getKeys(), {'protected'});
    },
  );
  test('invalid file never sent', () async {
    await expectLater(
      DocumentacionOperativaService.adjuntar(
        'auth-test',
        'profile-test',
        'request-test',
        Uint8List.fromList([1, 2, 3]),
      ),
      throwsArgumentError,
    );
    expect(calls, isEmpty);
  });
  test('forged document owner denied', () async {
    await expectLater(
      documents.upload('wrong', 'profile-test', 'id', Uint8List(1)),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });
  test(
    'remote document metadata replaces local list without merging',
    () async {
      expect(
        await DocumentacionOperativaService.solicitudesAlumno(
          'auth-test',
          'profile-test',
        ),
        isEmpty,
      );
      expect(calls.last['name'], 'atena_documents_read');
    },
  );
  test('document cleanup remains scoped to own profile', () async {
    expect(
      await DocumentacionOperativaService.limpiar('auth-test', 'profile-test'),
      1,
    );
    expect(calls.last['body'], {
      'p_profile': 'profile-test',
      'p_id': null,
      'p_expired_only': true,
    });
  });
  test('contradictory document upload confirmation is failure', () async {
    contradictory = true;
    await expectLater(
      documents.upload('auth-test', 'profile-test', 'id', Uint8List(1)),
      throwsFormatException,
    );
  });
  test('server rejection never completes local document request', () async {
    fail = true;
    await expectLater(
      DocumentacionOperativaService.adjuntar(
        'auth-test',
        'profile-test',
        'id',
        Uint8List.fromList(utf8.encode('%PDF-test')),
      ),
      throwsA(isA<PostgrestException>()),
    );
    expect((await SharedPreferences.getInstance()).getKeys(), {'protected'});
  });
}
