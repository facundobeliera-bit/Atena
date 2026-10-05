import 'dart:convert';
import 'dart:io';

import 'package:atena_app/models/catalogo/ficha_publica.dart';
import 'package:atena_app/services/catalogo_publicable_service.dart';
import 'package:atena_app/services/remote/catalogo_supabase_repository.dart';
import 'package:atena_app/services/remote/solicitudes_supabase_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalogo_publicable_flow_test.dart' as fixture;

class _LoopbackBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

// Real Supabase HTTP client against an isolated loopback contract server.
// Server SQL security/concurrency is tested separately in PostgreSQL.
void main() {
  _LoopbackBinding();
  late HttpServer server;
  late SupabaseClient client;
  late CatalogoSupabaseRepository catalog;
  late SolicitudesSupabaseRepository requests;
  late Future<void> Function(HttpRequest) reply;
  final calls = <Map<String, dynamic>>[];

  Future<void> respond(
    HttpRequest request,
    Object value, {
    int status = 200,
  }) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(value));
    await request.response.close();
  }

  setUp(() async {
    await fixture.seed();
    calls.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public-key',
    );
    catalog = CatalogoSupabaseRepository(client);
    requests = SolicitudesSupabaseRepository(client);
    reply = (r) async => respond(r, []);
    server.listen((r) async {
      final body = await utf8.decoder.bind(r).join();
      calls.add({
        'path': r.uri.path,
        'query': r.uri.queryParameters,
        'body': body.isEmpty ? null : jsonDecode(body),
      });
      await reply(r);
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  Future<void> sync() async {
    final service = CatalogoPublicableService(transporte: catalog);
    await service.preparar(fixture.instId, fixture.areaId);
    await service.sincronizar(fixture.instId, fixture.areaId);
  }

  Map<String, dynamic> receipt() {
    final b = calls.last['body'] as Map;
    return {
      'institution_id': b['p_institution_id'],
      'area_id': b['p_area_id'],
      'operation_id': b['p_operation_id'],
      'fingerprint': b['p_fingerprint'],
      'version': (b['p_expected_version'] as int) + 1,
    };
  }

  test(
    'actual adapter connects existing outbox and verifies receipt',
    () async {
      reply = (r) => respond(r, receipt());
      await sync();
      expect(calls.single['path'], '/rest/v1/rpc/atena_publish_catalog');
      final body = calls.single['body'] as Map;
      expect(
        body.keys,
        unorderedEquals([
          'p_institution_id',
          'p_area_id',
          'p_operation_id',
          'p_expected_version',
          'p_fingerprint',
          'p_payload',
          'p_state',
        ]),
      );
      expect(body['p_payload'], isNot(contains('private-')));
      expect(
        (await CatalogoPublicableService().consultar(
          fixture.instId,
          fixture.areaId,
        )).estado,
        EstadoCatalogo.confirmado,
      );
    },
  );

  test(
    'explicit public university price and requirements enter schema3',
    () async {
      final service = CatalogoPublicableService();
      final before = await service.consultar(fixture.instId, fixture.areaId);
      final id = before.catalogo.grupos.single['id'] as String;
      await service.publicarLocal(
        fixture.instId,
        fixture.areaId,
        tipoFormal: 'universidad',
        precios: {id: 'Gratuito'},
        requisitos: {id: 'Título secundario'},
      );
      final after = await service.consultar(fixture.instId, fixture.areaId);
      expect(after.catalogo.grupos.single['formal_type'], 'universidad');
      expect(after.catalogo.grupos.single['price'], 'Gratuito');
      expect(after.catalogo.grupos.single['requirements'], 'Título secundario');
      expect(after.catalogo.json, isNot(contains('private-address')));
    },
  );

  test('conflict is retained and never reported confirmed', () async {
    reply = (r) =>
        respond(r, {'code': 'PT409', 'message': 'Conflict'}, status: 409);
    await expectLater(sync(), throwsA(isA<ConflictoCatalogo>()));
    expect(
      (await CatalogoPublicableService().consultar(
        fixture.instId,
        fixture.areaId,
      )).estado,
      EstadoCatalogo.conflicto,
    );
  });

  test(
    'revoked authorization stays explicit and does not erase outbox',
    () async {
      reply = (r) => respond(r, {
        'code': '42501',
        'message': 'Not authorized',
      }, status: 403);
      await expectLater(sync(), throwsA(isA<PostgrestException>()));
      expect(
        (await CatalogoPublicableService().consultar(
          fixture.instId,
          fixture.areaId,
        )).estado,
        EstadoCatalogo.pendiente,
      );
    },
  );

  test(
    'uncertain response preserves operation key for an exact retry',
    () async {
      reply = (r) => respond(r, {...receipt(), 'area_id': 'foreign'});
      await expectLater(sync(), throwsA(isA<ConexionCatalogo>()));
      final first = calls.single['body'];
      expect(
        (await CatalogoPublicableService().consultar(
          fixture.instId,
          fixture.areaId,
        )).estado,
        EstadoCatalogo.errorConexion,
      );
      reply = (r) => respond(r, receipt());
      await CatalogoPublicableService(
        transporte: catalog,
      ).sincronizar(fixture.instId, fixture.areaId);
      expect(calls.last['body'], first);
    },
  );

  test(
    'withdrawal uses same authorized/versioned RPC, never a direct delete',
    () async {
      reply = (r) => respond(r, receipt());
      final projection = await CatalogoPublicableService().consultar(
        fixture.instId,
        fixture.areaId,
      );
      await catalog.retirar(
        institutionId: fixture.instId,
        areaId: fixture.areaId,
        operationId: 'withdrawal-key',
        expectedVersion: 4,
        catalogo: projection.catalogo,
      );
      expect(calls.single['body']['p_state'], 'withdrawn');
      expect(calls.single['body']['p_expected_version'], 4);
    },
  );

  test(
    'public reader uses safe existing DTO and preserves V1 taxonomy',
    () async {
      final service = CatalogoPublicableService();
      final initial = await service.consultar(fixture.instId, fixture.areaId);
      await service.publicarLocal(
        fixture.instId,
        fixture.areaId,
        tipoFormal: 'universidad',
        precios: {initial.catalogo.grupos.single['id']: '0'},
      );
      final d = (await service.consultar(
        fixture.instId,
        fixture.areaId,
      )).catalogo.datos;
      reply = (r) => respond(r, [
        {
          'institution_id': d['institution']['id'],
          'area_id': d['area']['id'],
          'version': 1,
          'document': d,
        },
      ]);
      final rows = await catalog.leerPublico();
      expect(rows.single.ofertas.single.tipoFormal, 'universidad');
      expect(rows.single.ofertas.single.costo, CostoOferta.gratuito);
      expect(rows.single.ofertas.single.disponibles, 18);
      expect(rows.single.telefono, isEmpty);
      expect(calls.single['path'], '/rest/v1/rpc/atena_catalog_read');
      expect(calls.single['body'], {'p_offset': 0, 'p_limit': 200});
    },
  );

  test(
    'public reader distinguishes confirmed empty from server error',
    () async {
      expect(await catalog.leerPublico(), isEmpty);
      reply = (r) =>
          respond(r, {'code': '42501', 'message': 'Denied'}, status: 403);
      await expectLater(
        catalog.leerPublico(),
        throwsA(isA<PostgrestException>()),
      );
    },
  );

  test('public reader rejects contradictory public institution ID', () async {
    final d = (await CatalogoPublicableService().consultar(
      fixture.instId,
      fixture.areaId,
    )).catalogo.datos;
    reply = (r) => respond(r, [
      {
        'institution_id': 'foreign',
        'area_id': d['area']['id'],
        'version': 1,
        'document': d,
      },
    ]);
    await expectLater(catalog.leerPublico(), throwsFormatException);
  });

  test('status does not reset outbox or imply confirmation', () async {
    reply = (r) => respond(r, {'version': 7, 'publication_state': 'withdrawn'});
    expect(await catalog.version(fixture.instId, fixture.areaId), 7);
    expect(
      (await CatalogoPublicableService().consultar(
        fixture.instId,
        fixture.areaId,
      )).estado,
      EstadoCatalogo.local,
    );
  });

  test('server unavailable preserves an uncertain send for retry', () async {
    reply = (r) =>
        respond(r, {'code': '503', 'message': 'Unavailable'}, status: 503);
    await expectLater(sync(), throwsA(isA<ConexionCatalogo>()));
    expect(
      (await CatalogoPublicableService().consultar(
        fixture.instId,
        fixture.areaId,
      )).estado,
      EstadoCatalogo.errorConexion,
    );
  });

  test(
    'public pagination does not silently truncate after first page',
    () async {
      final template = (await CatalogoPublicableService().consultar(
        fixture.instId,
        fixture.areaId,
      )).catalogo.datos;
      reply = (r) {
        final offset = calls.last['body']['p_offset'] as int;
        final rows = List.generate(offset == 0 ? 200 : 1, (i) {
          final id = 'atena_${(offset + i).toRadixString(16).padLeft(64, '0')}';
          return {
            'institution_id': id,
            'area_id': id,
            'version': 1,
            'document': {
              ...template,
              'institution': {...template['institution'], 'id': id},
              'area': {...template['area'], 'id': id},
              'groups': [],
            },
          };
        });
        return respond(r, rows);
      };
      expect(await catalog.leerPublico(), hasLength(201));
      expect(calls.last['body']['p_offset'], 200);
    },
  );

  Map<String, dynamic> requestRow() => {
    'id': 'request-A',
    'state': 'pending',
    'applicant_profile_id': 'verified-profile',
    'group_id': 'public-group',
    'operation_id': 'operation-A',
  };

  test('create sends no capacity, plan, owner or actor claims', () async {
    reply = (r) => respond(r, requestRow());
    await requests.crear(
      perfilVerificado: 'verified-profile',
      grupoPublico: 'public-group',
      operationId: 'operation-A',
    );
    expect(calls.single['body'], {
      'p_profile_id': 'verified-profile',
      'p_group_id': 'public-group',
      'p_operation_id': 'operation-A',
    });
  });
  test('same request retry uses same client operation key', () async {
    reply = (r) => respond(r, requestRow());
    for (var i = 0; i < 2; i++) {
      await requests.crear(
        perfilVerificado: 'verified-profile',
        grupoPublico: 'public-group',
        operationId: 'operation-A',
      );
    }
    expect(calls.first['body'], calls.last['body']);
  });
  test(
    'capacity conflict is propagated, never converted into success',
    () async {
      reply = (r) =>
          respond(r, {'code': 'PT409', 'message': 'No capacity'}, status: 409);
      await expectLater(
        requests.decidir('request-A', 'confirmed'),
        throwsA(isA<PostgrestException>()),
      );
      expect(calls.single['body'], {
        'p_request_id': 'request-A',
        'p_state': 'confirmed',
      });
    },
  );
  test('request identity contradiction rejects apparent success', () async {
    reply = (r) =>
        respond(r, {...requestRow(), 'applicant_profile_id': 'foreign'});
    await expectLater(
      requests.crear(
        perfilVerificado: 'verified-profile',
        grupoPublico: 'public-group',
        operationId: 'operation-A',
      ),
      throwsFormatException,
    );
  });
  test('confirmation requires matching ID and state', () async {
    reply = (r) => respond(r, {...requestRow(), 'state': 'confirmed'});
    expect(
      (await requests.decidir('request-A', 'confirmed'))['state'],
      'confirmed',
    );
    await expectLater(
      requests.decidir('request-B', 'confirmed'),
      throwsFormatException,
    );
  });
  test('history remains RLS filtered and explicitly paginated', () async {
    reply = (r) => respond(r, [requestRow()]);
    expect(
      (await requests.listar(offset: 10, limit: 20)).single['id'],
      'request-A',
    );
    expect(calls.single['query']['offset'], '10');
    expect(
      calls.single['query'].containsKey('applicant_auth_user_id'),
      isFalse,
    );
    await expectLater(requests.listar(limit: 1000), throwsArgumentError);
  });
}
