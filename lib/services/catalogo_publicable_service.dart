import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/instituciones/area_operativa.dart';
import '../models/catalogo/ficha_publica.dart';
import '../models/instituciones/operador_institucional.dart';
import '../models/extracurriculares/bloque_extracurricular.dart';
import 'extracurriculares_service.dart';
import 'institucion_areas_service.dart';
import 'institucion_operadores_service.dart';
import 'instituciones_helpers.dart' as helpers;
import 'solicitudes_service.dart';

enum EstadoCatalogo {
  local,
  pendiente,
  confirmado,
  cambiosLocales,
  errorConexion,
  conflicto,
}

/// A public projection, never a replacement for Atena's canonical models.
/// JSON is immutable; every consumer receives a fresh decoded copy.
class CatalogoPublicable {
  final String json;
  final String huella;
  CatalogoPublicable._(this.json, this.huella);
  Map<String, dynamic> get datos => jsonDecode(json) as Map<String, dynamic>;
  List<dynamic> get grupos => datos['groups'] as List<dynamic>;
  List<dynamic> get actividades => datos['activities'] as List<dynamic>;
  bool get vacio => grupos.isEmpty && actividades.isEmpty;
}

class EstadoCatalogoPublicable {
  final CatalogoPublicable catalogo;
  final EstadoCatalogo estado;
  final int versionConfirmada;
  final DateTime? preparadoEn;
  final DateTime? confirmadoEn;
  const EstadoCatalogoPublicable(
    this.catalogo,
    this.estado,
    this.versionConfirmada, {
    this.preparadoEn,
    this.confirmadoEn,
  });
}

class ConfirmacionCatalogo {
  final String institutionId, areaId, operationId, fingerprint;
  final int version;
  const ConfirmacionCatalogo({
    required this.institutionId,
    required this.areaId,
    required this.operationId,
    required this.fingerprint,
    required this.version,
  });
}

class ConflictoCatalogo implements Exception {}

class ConexionCatalogo implements Exception {}

/// Optional server adapter boundary. Normal builds keep local mode.
/// The server MUST authenticate from its token, authorize the live link/area,
/// and atomically check expectedVersion + deduplicate operationId + replace
/// only this area's projection. A client-supplied ID is never authorization.
abstract interface class TransporteCatalogo {
  Future<ConfirmacionCatalogo> publicar({
    required String institutionId,
    required String areaId,
    required String operationId,
    required int expectedVersion,
    required CatalogoPublicable catalogo,
  });
}

class CatalogoPublicableService {
  static const _publicPrefix = 'atena_catalog_public_local_v1_';

  Future<FichaPublicaInstitucion?> publicacionLocal(
    String institution,
    String area,
  ) async {
    await _autorizar(institution, area);
    final raw = (await SharedPreferences.getInstance()).getString(
      '$_publicPrefix${await _hash([institution, area])}',
    );
    if (raw == null) return null;
    return FichaPublicaInstitucion.fromMap(
      Map<String, dynamic>.from(jsonDecode(raw)['institution']),
    );
  }

  /// Explicit local publication, separate from the remote outbox. Source
  /// records remain canonical; this allowlisted snapshot is only a read model.
  Future<void> publicarLocal(
    String institution,
    String area, {
    String tipoFormal = 'escolar',
    Map<String, String> precios = const {},
    Map<String, String> requisitos = const {},
  }) async {
    if (!['escolar', 'superior', 'universidad'].contains(tipoFormal)) {
      throw const FormatException('Tipo de educación formal inválido.');
    }
    final key = '$_publicPrefix${await _hash([institution, area])}';
    await _serial(key, () async {
      await _autorizar(institution, area, escritura: true);
      final projection = await _proyectar(institution, area);
      final inst = (await helpers.cargarInstitucionPorId(institution))!;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('inst_public_profile_v1_$institution');
      final extra = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw));
      final formal =
          projection.datos['area']['kind'] == TipoAreaOperativa.curricular.name;
      final ids = <String, String>{};
      if (formal) {
        for (final g in await helpers.cargarGruposInstitucion(institution)) {
          if (g.areaId == area) {
            ids[await identificador('curricular-group', institution, g.id)] =
                g.id;
          }
        }
      } else {
        for (final g in await ExtracurricularesService.instance.cargarGrupos(
          institution,
        )) {
          if (g.areaId == area) {
            ids[await identificador('extra-group', institution, g.id)] = g.id;
          }
        }
      }
      final offers = <OfertaPublica>[];
      for (final g in projection.grupos) {
        if (g['availability'] == 'suspended') continue;
        final id = ids[g['id']];
        if (id == null) {
          throw StateError('El grupo cambió. Volvé a revisar el catálogo.');
        }
        final matches = projection.actividades
            .where((a) => a['name'] == g['activity_label'])
            .toList();
        final a = matches.length == 1 ? matches.single : null;
        if (a != null && a['active'] != true) continue;
        offers.add(
          OfertaPublica(
            id: id,
            institucionId: institution,
            areaId: area,
            nombre: g['activity_label'],
            grupo: g['name'],
            horario: g['schedule'],
            precio: formal ? (precios[g['id']] ?? '') : (a?['price'] ?? ''),
            edades: a?['ages'] ?? '',
            descripcion: a?['description'] ?? '',
            categoria: formal
                ? CategoriaPublica.formal
                : CategoriaPublica.actividades,
            disponibles: g['available'],
            habilitada: g['availability'] != 'full',
            tipoFormal: tipoFormal,
            requisitos: requisitos[g['id']] ?? '',
          ),
        );
      }
      final data = FichaPublicaInstitucion(
        id: institution,
        nombre: inst.nombre,
        pais: inst.pais,
        provincia: inst.provincia,
        localidad: inst.ciudad,
        direccion: inst.direccion,
        telefono: extra['telefonoPublico'] as String? ?? '',
        descripcion: extra['descripcion'] as String? ?? '',
        modalidad: inst.modalidad.name,
        fotos: (extra['fotos'] as List? ?? []).whereType<String>().toList(),
        ofertas: offers,
      );
      await _autorizar(institution, area, escritura: true);
      await _guardar(key, {
        'schema': 1,
        'area': area,
        'published_at': DateTime.now().toUtc().toIso8601String(),
        'institution': data.toMap(),
      });
    });
  }

  Future<void> retirarLocal(String institution, String area) async {
    final key = '$_publicPrefix${await _hash([institution, area])}';
    await _serial(key, () async {
      await _autorizar(institution, area, escritura: true);
      if (!await (await SharedPreferences.getInstance()).remove(key)) {
        throw StateError('No se pudo retirar la publicación.');
      }
    });
  }

  /// Anonymous read: no account/profile or private model leaves this boundary.
  /// Missing, corrupt, deleted or suspended sources fail closed, without repair.
  Future<List<FichaPublicaInstitucion>> buscarPublico({
    String texto = '',
    CategoriaPublica? categoria,
    CostoOferta? costo,
    String localidad = '',
    String provincia = '',
    String pais = '',
    String modalidad = '',
    String horario = '',
    String edades = '',
    String tipoFormal = '',
    bool soloDisponibles = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, FichaPublicaInstitucion>{};
    bool matches(String value, String query) => normalizarBusquedaPublica(
      value,
    ).contains(normalizarBusquedaPublica(query));
    for (final key
        in prefs.getKeys().where((k) => k.startsWith(_publicPrefix)).toList()
          ..sort()) {
      try {
        final record = jsonDecode(prefs.getString(key)!);
        if (record['schema'] != 1) continue;
        final data = FichaPublicaInstitucion.fromMap(
          Map<String, dynamic>.from(record['institution']),
        );
        final area = await InstitucionAreasService.instance.buscarPorId(
          data.id,
          record['area'],
        );
        if (area == null ||
            !area.activa ||
            await helpers.cargarInstitucionPorId(data.id) == null) {
          continue;
        }
        if (!matches(data.localidad, localidad) ||
            !matches(data.provincia, provincia) ||
            !matches(data.pais, pais) ||
            !matches(data.modalidad, modalidad)) {
          continue;
        }
        final formal = await SolicitudesService.gruposCurricularesParaAlumno(
          data.id,
        );
        final extra =
            await SolicitudesService.gruposExtracurricularesParaAlumno(data.id);
        final canonical = await helpers.cargarGruposInstitucion(data.id);
        final offers = <OfertaPublica>[];
        for (final o in data.ofertas) {
          if (o.institucionId != data.id || o.areaId != area.id) continue;
          OfertaPublica? live;
          if (o.categoria == CategoriaPublica.formal) {
            final source = canonical
                .where((g) => g.id == o.id && g.areaId == area.id)
                .toList();
            final gs = formal.where((g) => g.id == o.id).toList();
            if (source.length == 1 &&
                gs.length == 1 &&
                source.single.actividadNombre == o.nombre &&
                source.single.nombreGrupo == o.grupo &&
                (source.single.turno ?? '') == o.horario) {
              final g = gs.single;
              live = o.disponibilidad(
                g.cuposTotales - g.cuposOcupados,
                g.tieneCuposDisponibles,
              );
            }
          } else {
            final gs = extra
                .where(
                  (g) =>
                      g.id == o.id &&
                      g.areaId == area.id &&
                      g.activo &&
                      g.actividadNombre == o.nombre &&
                      g.nombreGrupo == o.grupo &&
                      g.turno == o.horario,
                )
                .toList();
            if (gs.length == 1) {
              final g = gs.single;
              live = o.disponibilidad(
                g.cupoMaximo == 0 ? null : g.cupoMaximo - g.cupoOcupado,
                g.cupoMaximo == 0 || g.cupoMaximo > g.cupoOcupado,
              );
            }
          }
          if (live == null ||
              (live.disponibles != null && live.disponibles! < 0)) {
            continue;
          }
          if (categoria != null && live.categoria != categoria ||
              costo != null && live.costo != costo) {
            continue;
          }
          if (soloDisponibles &&
              (!live.habilitada ||
                  live.disponibles == null ||
                  live.disponibles! <= 0)) {
            continue;
          }
          if (!matches(live.horario, horario) ||
              !matches(live.edades, edades)) {
            continue;
          }
          if (tipoFormal.isNotEmpty &&
              (live.categoria != CategoriaPublica.formal ||
                  live.tipoFormal != tipoFormal)) {
            continue;
          }
          if (!matches(
            '${data.nombre} ${live.nombre} ${live.grupo} ${live.nivelLabel} ${live.descripcion}',
            texto,
          )) {
            continue;
          }
          offers.add(live);
        }
        if (offers.isNotEmpty) {
          result[data.id] = data.conOfertas([
            ...?result[data.id]?.ofertas,
            ...offers,
          ]);
        }
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      } on ArgumentError {
        continue;
      }
    }
    return result.values.toList()..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  final TransporteCatalogo? transporte;
  CatalogoPublicableService({this.transporte});
  static final _colas = <String, Future<void>>{};

  static Future<String> _hash(Object value) async => (await Sha256().hash(
    utf8.encode(jsonEncode(value)),
  )).bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Names are excluded: editing a label never creates a second remote ID.
  static Future<String> identificador(
    String tipo,
    String institucion,
    String id,
  ) async {
    if (institucion.trim().isEmpty || id.trim().isEmpty) {
      throw const FormatException(
        'El registro no tiene un identificador estable.',
      );
    }
    return 'atena_${await _hash(['catalog-v1', tipo, institucion, id])}';
  }

  Future<void> _autorizar(
    String institution,
    String area, {
    bool escritura = false,
  }) async {
    final operator = await InstitucionOperadoresService.instance
        .autorizarActivo(
          institucionId: institution,
          areaId: area,
          capacidad: escritura
              ? CapacidadInstitucional.groupsWrite
              : CapacidadInstitucional.groupsRead,
        );
    if (operator == null) {
      throw StateError(
        'No tenés permiso para consultar o preparar el catálogo de esta área.',
      );
    }
  }

  void _capacidad(int total, int ocupados, {bool noGestionada = false}) {
    if (total < 0 || ocupados < 0 || (!noGestionada && ocupados > total)) {
      throw const FormatException(
        'Revisá la ocupación del grupo antes de preparar el catálogo.',
      );
    }
  }

  Future<CatalogoPublicable> _proyectar(
    String institution,
    String areaId,
  ) async {
    await _autorizar(institution, areaId);
    final area = await InstitucionAreasService.instance.buscarPorId(
      institution,
      areaId,
    );
    final inst = await helpers.cargarInstitucionPorId(institution);
    if (area == null ||
        !area.activa ||
        inst == null ||
        inst.id != institution) {
      throw StateError('No se pudo comprobar la institución y el área.');
    }
    final groups = <Map<String, dynamic>>[];
    final activities = <Map<String, dynamic>>[];
    final ids = <String>{};
    final requests = await SolicitudesService.obtenerSolicitudesParaInstitucion(
      institucionId: institution,
    );
    void unique(String id) {
      if (id.trim().isEmpty || !ids.add(id)) {
        throw const FormatException(
          'Identificadores de catálogo vacíos o duplicados.',
        );
      }
    }

    if (area.tipo == TipoAreaOperativa.curricular) {
      // Same resolver used by Gestión and the student flow, including explicit [].
      final canonical = await helpers.cargarGruposInstitucion(institution);
      for (final g in canonical) {
        if (g.institucionId != institution || (g.areaId ?? '').isEmpty) {
          throw const FormatException(
            'Hay grupos sin un área comprobable. Revisalos en Gestión de vacantes.',
          );
        }
        if (g.areaId != areaId) continue;
        unique(g.id);
        _capacidad(g.cupoMaximo, g.cupoOcupado);
        final occupied = math.max(
          g.cupoOcupado,
          SolicitudesService.contarConfirmadasDeGrupo(
            solicitudes: requests,
            institucionId: institution,
            curricular: true,
            grupoId: g.id,
          ),
        );
        _capacidad(g.cupoMaximo, occupied);
        groups.add({
          'id': await identificador('curricular-group', institution, g.id),
          'kind': 'curricular',
          'name': g.nombreGrupo,
          'activity_label': g.actividadNombre,
          'schedule': g.turno ?? '',
          'capacity': g.cupoMaximo,
          'occupied': occupied,
          'available': g.cupoMaximo - occupied,
          'availability': g.estado.name == 'suspendido'
              ? 'suspended'
              : g.estado.name != 'disponible' || g.cupoMaximo <= occupied
              ? 'full'
              : 'available',
          'status': g.estado.name,
        });
      }
    } else {
      // The existing extracurricular reader is tolerant. Publication must not
      // interpret corrupt or partially dropped source data as an empty catalog.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(
        ExtracurricularesService.kGruposExtracurriculares(institution),
      );
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw);
      if (decoded is! List || decoded.any((v) => v is! Map)) {
        throw const FormatException('Catálogo extracurricular inválido.');
      }
      for (final item in decoded) {
        if (item['id'] is! String ||
            item['institucionId'] != institution ||
            item['cupoMaximo'] is! int ||
            item['cupoOcupado'] is! int ||
            item['activo'] is! bool ||
            BloqueExtracurricularX.tryParseAny(item['bloque']) == null) {
          throw const FormatException(
            'Un grupo extracurricular requiere revisión antes de publicarse.',
          );
        }
        _capacidad(
          item['cupoMaximo'] as int,
          item['cupoOcupado'] as int,
          noGestionada: item['cupoMaximo'] == 0,
        );
      }
      final canonical = await ExtracurricularesService.instance.cargarGrupos(
        institution,
      );
      if (canonical.length != decoded.length) {
        throw const FormatException('Hay grupos duplicados o ilegibles.');
      }
      for (final g in canonical) {
        if (g.institucionId != institution || (g.areaId ?? '').isEmpty) {
          throw const FormatException('Hay grupos sin un área comprobable.');
        }
        if (g.areaId != areaId) continue;
        if (g.bloque.key != area.claveOrigen) {
          throw const FormatException(
            'El módulo del grupo contradice su área.',
          );
        }
        unique(g.id);
        _capacidad(
          g.cupoMaximo,
          g.cupoOcupado,
          noGestionada: g.cupoMaximo == 0,
        );
        final occupied = math.max(
          g.cupoOcupado,
          SolicitudesService.contarConfirmadasDeGrupo(
            solicitudes: requests,
            institucionId: institution,
            curricular: false,
            actividadNombre: g.actividadNombre,
            nombreGrupo: g.nombreGrupo,
            turno: g.turno,
            moduleKey: g.bloque.key,
          ),
        );
        _capacidad(g.cupoMaximo, occupied, noGestionada: g.cupoMaximo == 0);
        groups.add({
          'id': await identificador('extra-group', institution, g.id),
          'kind': 'extracurricular',
          'name': g.nombreGrupo,
          'activity_label': g.actividadNombre,
          'schedule': g.turno,
          'capacity': g.cupoMaximo == 0 ? null : g.cupoMaximo,
          'occupied': occupied,
          'available': g.cupoMaximo == 0 ? null : g.cupoMaximo - occupied,
          'availability': !g.activo
              ? 'suspended'
              : g.cupoMaximo == 0
              ? 'unmanaged'
              : g.cupoMaximo <= occupied
              ? 'full'
              : 'available',
          'status': g.activo ? 'activo' : 'suspendido',
        });
      }
      ids.clear();
      for (final a in inst.actividadesExtracurriculares) {
        if (a.institucionId != institution) {
          throw const FormatException('Actividad de otra institución.');
        }
        if (a.bloque.key != area.claveOrigen) continue;
        unique(a.id);
        activities.add({
          'id': await identificador('activity', institution, a.id),
          'name': a.nombre,
          'active': a.activa,
          'schedule': a.horario ?? '',
          'description': a.descripcion ?? '',
          'ages': a.edades ?? '',
          'price': a.precio ?? '',
        });
      }
    }
    groups.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    activities.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    // Only explicitly published presentation fields may enrich the remote
    // projection. Canonical identity/contact records are never serialized.
    final published = await publicacionLocal(institution, areaId);
    final presentation = <String, OfertaPublica>{};
    for (final offer in published?.ofertas ?? <OfertaPublica>[]) {
      presentation[await identificador(
            offer.categoria == CategoriaPublica.formal
                ? 'curricular-group'
                : 'extra-group',
            institution,
            offer.id,
          )] =
          offer;
    }
    for (final group in groups) {
      final offer = presentation[group['id']];
      final matches = activities.where(
        (a) => a['name'] == group['activity_label'],
      );
      final activity = matches.length == 1 ? matches.single : null;
      group.addAll({
        'formal_type': offer?.tipoFormal ?? 'escolar',
        'price': offer?.precio ?? activity?['price'] ?? '',
        'requirements': offer?.requisitos ?? '',
        'description': offer?.descripcion ?? activity?['description'] ?? '',
        'ages': offer?.edades ?? activity?['ages'] ?? '',
      });
    }
    final data = <String, dynamic>{
      'schema_version': 3,
      'institution': {
        'id': await identificador('institution', institution, institution),
        'name': inst.nombre,
        'city': inst.ciudad,
        'province': inst.provincia,
        'country': inst.pais,
      },
      'area': {
        'id': await identificador('area', institution, areaId),
        'name': area.nombre,
        'kind': area.tipo.name,
      },
      'activities': activities,
      'groups': groups,
    };
    await _autorizar(institution, areaId);
    return CatalogoPublicable._(jsonEncode(data), await _hash(data));
  }

  Future<String> _key(String institution, String area) async =>
      'atena_catalog_outbox_v1_${await _hash([institution, area])}';

  Future<Map<String, dynamic>> _leer(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    final map = jsonDecode(raw);
    if (map is! Map<String, dynamic> ||
        map['version'] is! int ||
        map['version'] < 0 ||
        ![
          EstadoCatalogo.pendiente.name,
          EstadoCatalogo.confirmado.name,
          EstadoCatalogo.errorConexion.name,
          EstadoCatalogo.conflicto.name,
        ].contains(map['state']) ||
        map['payload'] is! String ||
        map['operation'] is! String ||
        (map['operation'] as String).isEmpty ||
        map['fingerprint'] is! String) {
      throw const FormatException(
        'Estado de sincronización inválido. No se sobrescribió.',
      );
    }
    final payload = jsonDecode(map['payload'] as String);
    if (payload is! Map<String, dynamic> ||
        await _hash(payload) != map['fingerprint']) {
      throw const FormatException('La preparación local está dañada.');
    }
    return map;
  }

  Future<void> _guardar(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, jsonEncode(value))) {
      throw StateError('No se pudo guardar la preparación local.');
    }
  }

  Future<T> _serial<T>(String key, Future<T> Function() action) {
    final result = (_colas[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _colas[key] = tail;
    tail.then((_) {
      if (identical(_colas[key], tail)) _colas.remove(key);
    });
    return result;
  }

  Future<EstadoCatalogoPublicable> consultar(
    String institution,
    String area,
  ) async {
    final catalog = await _proyectar(institution, area);
    final record = await _leer(await _key(institution, area));
    var state = record.isEmpty
        ? EstadoCatalogo.local
        : EstadoCatalogo.values.byName(record['state'] as String);
    if (record.isNotEmpty &&
        record['fingerprint'] != catalog.huella &&
        state != EstadoCatalogo.errorConexion &&
        state != EstadoCatalogo.conflicto) {
      state = EstadoCatalogo.cambiosLocales;
    }
    await _autorizar(institution, area);
    return EstadoCatalogoPublicable(
      catalog,
      state,
      record['version'] as int? ?? 0,
      preparadoEn: DateTime.tryParse(record['prepared_at'] as String? ?? ''),
      confirmadoEn: DateTime.tryParse(record['confirmed_at'] as String? ?? ''),
    );
  }

  /// Saves an outbox snapshot only. No network call, source rewrite or capacity consumption.
  Future<void> preparar(String institution, String area) async {
    final key = await _key(institution, area);
    await _serial(key, () async {
      await _autorizar(institution, area, escritura: true);
      final catalog = await _proyectar(institution, area);
      final record = await _leer(key);
      if (record['state'] == EstadoCatalogo.conflicto.name) {
        throw ConflictoCatalogo();
      }
      if (record['fingerprint'] == catalog.huella) return;
      // An uncertain send must be retried with the SAME payload/key first.
      if (record['state'] == EstadoCatalogo.errorConexion.name) {
        throw StateError('Primero debe resolverse el envío pendiente.');
      }
      final version = record['version'] as int? ?? 0;
      await _autorizar(institution, area, escritura: true);
      await _guardar(key, {
        'version': version,
        'state': EstadoCatalogo.pendiente.name,
        'fingerprint': catalog.huella,
        'payload': catalog.json,
        'prepared_at': DateTime.now().toUtc().toIso8601String(),
        'operation': await _hash([institution, area, version, catalog.huella]),
      });
    });
  }

  /// Not exposed by the UI until a separately approved remote adapter exists.
  Future<void> sincronizar(String institution, String area) async {
    final remote = transporte;
    if (remote == null) {
      throw StateError('Publicación remota todavía no habilitada.');
    }
    final key = await _key(institution, area);
    await _serial(key, () async {
      await _autorizar(institution, area, escritura: true);
      final record = await _leer(key);
      if (record['state'] == EstadoCatalogo.confirmado.name) return;
      if (record['state'] == EstadoCatalogo.conflicto.name) {
        throw ConflictoCatalogo();
      }
      if (record['payload'] is! String ||
          record['operation'] is! String ||
          record['fingerprint'] is! String) {
        throw StateError('Prepará primero el catálogo.');
      }
      final snapshot = CatalogoPublicable._(
        record['payload'] as String,
        record['fingerprint'] as String,
      );
      if (await _hash(snapshot.datos) != snapshot.huella) {
        throw const FormatException('La preparación local está dañada.');
      }
      final fresh = await _proyectar(institution, area);
      if (fresh.huella != snapshot.huella &&
          record['state'] != EstadoCatalogo.errorConexion.name) {
        throw StateError('El catálogo cambió. Prepará una nueva versión.');
      }
      await _autorizar(institution, area, escritura: true);
      try {
        final receipt = await remote.publicar(
          institutionId: institution,
          areaId: area,
          operationId: record['operation'] as String,
          expectedVersion: record['version'] as int,
          catalogo: snapshot,
        );
        if (receipt.institutionId != institution ||
            receipt.areaId != area ||
            receipt.operationId != record['operation'] ||
            receipt.fingerprint != snapshot.huella ||
            receipt.version != (record['version'] as int) + 1) {
          throw ConexionCatalogo();
        }
        await _guardar(key, {
          ...record,
          'state': EstadoCatalogo.confirmado.name,
          'version': receipt.version,
          'confirmed_at': DateTime.now().toUtc().toIso8601String(),
        });
      } on ConflictoCatalogo {
        await _guardar(key, {
          ...record,
          'state': EstadoCatalogo.conflicto.name,
        });
        rethrow;
      } on ConexionCatalogo {
        await _guardar(key, {
          ...record,
          'state': EstadoCatalogo.errorConexion.name,
        });
        rethrow;
      }
    });
  }
}
