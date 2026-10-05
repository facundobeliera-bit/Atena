import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/catalogo/ficha_publica.dart';
import '../catalogo_publicable_service.dart';

/// Reuses the catalog outbox contract. No implicit publication, identity
/// provisioning, local-to-remote ID inference or administrative credential.
class CatalogoSupabaseRepository implements TransporteCatalogo {
  final SupabaseClient client;
  const CatalogoSupabaseRepository(this.client);

  @override
  Future<ConfirmacionCatalogo> publicar({
    required String institutionId,
    required String areaId,
    required String operationId,
    required int expectedVersion,
    required CatalogoPublicable catalogo,
  }) => _enviar(
    institutionId,
    areaId,
    operationId,
    expectedVersion,
    catalogo,
    'published',
  );

  /// Withdrawal is an explicit, versioned operation with its own retry key.
  Future<ConfirmacionCatalogo> retirar({
    required String institutionId,
    required String areaId,
    required String operationId,
    required int expectedVersion,
    required CatalogoPublicable catalogo,
  }) => _enviar(
    institutionId,
    areaId,
    operationId,
    expectedVersion,
    catalogo,
    'withdrawn',
  );

  Future<ConfirmacionCatalogo> _enviar(
    String inst,
    String area,
    String operation,
    int version,
    CatalogoPublicable catalog,
    String state,
  ) async {
    try {
      final value = await client
          .rpc(
            'atena_publish_catalog',
            params: {
              'p_institution_id': inst,
              'p_area_id': area,
              'p_operation_id': operation,
              'p_expected_version': version,
              'p_fingerprint': catalog.huella,
              'p_payload': catalog.json,
              'p_state': state,
            },
          )
          .timeout(const Duration(seconds: 25));
      if (value is! Map ||
          value['institution_id'] != inst ||
          value['area_id'] != area ||
          value['operation_id'] != operation ||
          value['fingerprint'] != catalog.huella ||
          value['version'] != version + 1) {
        // The result is uncertain: preserve the payload/key and retry safely.
        throw ConexionCatalogo();
      }
      return ConfirmacionCatalogo(
        institutionId: inst,
        areaId: area,
        operationId: operation,
        fingerprint: catalog.huella,
        version: version + 1,
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PT409') throw ConflictoCatalogo();
      if (['500', '502', '503', '504'].contains(e.code)) {
        throw ConexionCatalogo();
      }
      // Auth/schema/validation failures must not become empty or offline data.
      rethrow;
    } on TimeoutException {
      throw ConexionCatalogo();
    } on ConexionCatalogo {
      rethrow;
    } catch (e) {
      if (e is FormatException || e is TypeError) rethrow;
      throw ConexionCatalogo();
    }
  }

  Future<int> version(String institutionId, String areaId) async {
    final data = await client.rpc(
      'atena_catalog_status',
      params: {'p_institution_id': institutionId, 'p_area_id': areaId},
    );
    if (data is! Map || data['version'] is! int || data['version'] < 0) {
      throw const FormatException('Versión de catálogo remoto inválida.');
    }
    return data['version'] as int;
  }

  /// Anonymous public read, paginated to avoid silently losing rows at the
  /// server's default limit. RLS filters withdrawn/inactive publications.
  /// Never falls back to local snapshots or treats a failed request as [].
  Future<List<FichaPublicaInstitucion>> leerPublico() async {
    final institutions = <String, FichaPublicaInstitucion>{};
    const pageSize = 200;
    for (var offset = 0; ; offset += pageSize) {
      final rows = await client.rpc(
        'atena_catalog_read',
        params: {'p_offset': offset, 'p_limit': pageSize},
      );
      if (rows is! List) {
        throw const FormatException('Catálogo remoto inválido.');
      }
      for (final row in rows) {
        final ficha = _ficha(Map<String, dynamic>.from(row as Map));
        final previous = institutions[ficha.id];
        institutions[ficha.id] = previous == null
            ? ficha
            : previous.conOfertas([...previous.ofertas, ...ficha.ofertas]);
      }
      if (rows.length < pageSize) break;
    }
    return List.unmodifiable(institutions.values);
  }

  static FichaPublicaInstitucion _ficha(Map<String, dynamic> row) {
    final d = Map<String, dynamic>.from(row['document'] as Map);
    if (![2, 3].contains(d['schema_version'])) {
      throw const FormatException('Catálogo remoto incompatible.');
    }
    final institution = Map<String, dynamic>.from(d['institution'] as Map);
    final area = Map<String, dynamic>.from(d['area'] as Map);
    if (institution['id'] != row['institution_id'] ||
        area['id'] != row['area_id']) {
      throw const FormatException('Identidad pública contradictoria.');
    }
    final offers = <OfertaPublica>[];
    for (final raw in d['groups'] as List) {
      final g = Map<String, dynamic>.from(raw as Map);
      if (g['availability'] == 'suspended') continue;
      offers.add(
        OfertaPublica(
          id: g['id'] as String,
          institucionId: institution['id'] as String,
          areaId: area['id'] as String,
          nombre: g['activity_label'] as String,
          grupo: g['name'] as String,
          horario: g['schedule'] as String,
          precio: g['price'] as String? ?? '',
          edades: g['ages'] as String? ?? '',
          descripcion: g['description'] as String? ?? '',
          requisitos: g['requirements'] as String? ?? '',
          tipoFormal: g['formal_type'] as String? ?? 'escolar',
          categoria: g['kind'] == 'curricular'
              ? CategoriaPublica.formal
              : CategoriaPublica.actividades,
          disponibles: g['available'] as int?,
          habilitada: g['availability'] == 'available',
        ),
      );
    }
    return FichaPublicaInstitucion(
      id: institution['id'] as String,
      nombre: institution['name'] as String,
      pais: institution['country'] as String,
      provincia: institution['province'] as String,
      localidad: institution['city'] as String,
      direccion: '',
      telefono: '',
      descripcion: '',
      modalidad: '',
      ofertas: offers,
    );
  }
}
