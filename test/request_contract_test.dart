import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:atena_app/services/remote/solicitudes_supabase_repository.dart';

// Actual SDK transport against a local fixture. Server authorization is tested
// independently in PostgreSQL; the header is not a credential or permission.
void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SolicitudesSupabaseRepository api;
  final received = <String>[];
  setUp(() async {
    received.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
    );
    api = SolicitudesSupabaseRepository(client);
    server.listen((r) async {
      final raw = await utf8.decoder.bind(r).join();
      final body = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      final version = r.headers.value('x-atena-request-contract');
      received.add(version ?? 'absent');
      r.response.headers.contentType = ContentType.json;
      r.response.persistentConnection = false;
      if (version != '2') {
        r.response.statusCode = 426;
        r.response.write(
          jsonEncode({
            'code': 'PT426',
            'message':
                'Actualiza Atena para consultar o gestionar inscripciones.',
          }),
        );
      } else {
        final row = {
          'id': 'test-request',
          'state': body['p_state'] ?? 'pending',
          'group_id': body['p_group_id'],
          'applicant_profile_id': body['p_profile_id'],
          'operation_id': body['p_operation_id'],
        };
        r.response.write(
          jsonEncode(r.uri.path.endsWith('/atena_requests') ? [row] : row),
        );
      }
      await r.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test('current reader advertises supported state contract', () async {
    expect(await api.listar(), hasLength(1));
    expect(received, ['2']);
  });
  test('creation sends version without client actor authority', () async {
    expect(
      (await api.crear(
        perfilVerificado: 'profile',
        grupoPublico: 'group',
        operationId: 'operation',
      ))['id'],
      'test-request',
    );
    expect(received, ['2']);
  });
  test('decision sends supported contract', () async {
    expect(
      (await api.decidir('test-request', 'confirmed'))['state'],
      'confirmed',
    );
    expect(received, ['2']);
  });
  test(
    'legacy transport receives explicit upgrade error, never empty success',
    () async {
      await expectLater(
        client.from('atena_requests').select(),
        throwsA(
          isA<PostgrestException>().having((e) => e.code, 'code', 'PT426'),
        ),
      );
      expect(received, ['absent']);
    },
  );
}
