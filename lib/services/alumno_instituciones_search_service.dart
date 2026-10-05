import 'dart:math' as math;
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/extracurriculares/bloque_extracurricular.dart';
import '../models/extracurriculares/actividad_extracurricular.dart';
import '../models/instituciones/grupo_curricular.dart';
import '../models/instituciones/instituciones_integrado.dart';
import 'instituciones_helpers.dart' as ih;
import 'solicitudes_service.dart';

/// Scope principal del buscador del alumno.
enum AlumnoBusquedaScope { curricular, extracurricular }

enum AlumnoPrecioFiltro { todos, gratuitos, conCosto }

class AlumnoInstitucionSearchFilters {
  final AlumnoBusquedaScope scope;
  final String texto;
  final String? pais;
  final String? provincia;
  final String? ciudad;
  final NivelCurricular? nivel;
  final TurnoCurricular? turno;
  final TipoInstitucion? tipoInstitucion;
  final ModalidadCursado? modalidadCursado;
  final Set<BloqueExtracurricular> bloques;
  final int? edad;
  final bool soloConVacantes;
  final AlumnoPrecioFiltro precio;
  final double? userLat;
  final double? userLng;
  final double? maxDistanceKm;
  final bool ordenarPorDistancia;

  const AlumnoInstitucionSearchFilters({
    required this.scope,
    this.texto = '',
    this.pais,
    this.provincia,
    this.ciudad,
    this.nivel,
    this.turno,
    this.tipoInstitucion,
    this.modalidadCursado,
    this.bloques = const <BloqueExtracurricular>{},
    this.edad,
    this.soloConVacantes = false,
    this.precio = AlumnoPrecioFiltro.todos,
    this.userLat,
    this.userLng,
    this.maxDistanceKm,
    this.ordenarPorDistancia = false,
  });
}

class AlumnoInstitucionSearchResult {
  final Institucion institucion;
  final double? distanciaKm;

  const AlumnoInstitucionSearchResult({
    required this.institucion,
    this.distanciaKm,
  });
}

class AlumnoInstitucionesSearchService {
  /// Última intención de búsqueda confirmada por el alumno.
  /// Se utiliza para conservar el contexto al pasar de instituciones a vacantes.
  static AlumnoInstitucionSearchFilters? ultimaBusqueda;

  static String _norm(String value) => value.trim().toLowerCase();

  // Accent folding is only for discovery, never for IDs or group association.
  static String _searchText(String value) {
    var normalized = value.trim().toLowerCase();
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    for (final entry in accents.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  static double? _lat(Institucion inst) {
    final map = inst.toMap();
    return _toDouble(
      map['lat'] ?? map['latitude'] ?? map['ubicacionLat'] ?? map['geoLat'],
    );
  }

  static double? _lng(Institucion inst) {
    final map = inst.toMap();
    return _toDouble(
      map['lng'] ??
          map['lon'] ??
          map['longitude'] ??
          map['ubicacionLng'] ??
          map['geoLng'],
    );
  }

  static double _haversineKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static bool _actividadAdmiteEdad(ActividadExtracurricular a, int edad) {
    final raw = (a.edades ?? '').trim().toLowerCase();
    if (raw.isEmpty) return false;

    final normalized = raw.replaceAll('años', '').replaceAll('año', '');
    final numbers = RegExp(r'\d+')
        .allMatches(normalized)
        .map((m) => int.tryParse(m.group(0)!))
        .whereType<int>()
        .toList();

    if (normalized.contains('todas las edades')) return true;
    if (numbers.isEmpty) return false;
    if (numbers.length == 1) {
      if (normalized.contains('desde') ||
          normalized.contains('a partir') ||
          normalized.contains('+') ||
          normalized.contains('en adelante')) {
        return edad >= numbers.first;
      }
      if (normalized.contains('hasta')) return edad <= numbers.first;
      return edad == numbers.first;
    }

    final min = math.min(numbers[0], numbers[1]);
    final max = math.max(numbers[0], numbers[1]);
    return edad >= min && edad <= max;
  }

  static bool? _esGratuito(String? precio) {
    final p = (precio ?? '').trim().toLowerCase();
    if (p.isEmpty) return null;
    if (p == '0' ||
        p == r'$0' ||
        p == 'gratis' ||
        p == 'gratuito' ||
        p == 'sin costo') {
      return true;
    }
    final amount = p.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (amount.isEmpty) return null;
    if (RegExp(r'^0+([,.]0+)*$').hasMatch(amount)) return true;
    return RegExp(r'[1-9]').hasMatch(amount) ? false : null;
  }

  static bool _cumplePrecio(
    ActividadExtracurricular a,
    AlumnoPrecioFiltro filtro,
  ) {
    switch (filtro) {
      case AlumnoPrecioFiltro.todos:
        return true;
      case AlumnoPrecioFiltro.gratuitos:
        return _esGratuito(a.precio) == true;
      case AlumnoPrecioFiltro.conCosto:
        return _esGratuito(a.precio) == false;
    }
  }

  static List<NivelCurricular> _nivelesHabilitados(Institucion inst) {
    final config = inst.planConfig;
    if (config == null) return <NivelCurricular>[];
    return config.niveles
        .where((e) => e.habilitado)
        .map((e) => e.nivel)
        .toList();
  }

  static bool _tieneVacantesCurriculares(Institucion inst) {
    return inst.gruposCurriculares.any((g) => g.tieneCuposDisponibles);
  }

  static bool _tieneVacantesCurricularesConFiltro(
    Institucion inst,
    AlumnoInstitucionSearchFilters filters,
  ) {
    return inst.gruposCurriculares.any((g) {
      if (filters.soloConVacantes && !g.tieneCuposDisponibles) return false;
      if (filters.nivel != null) {
        final nombre = _norm(g.nombreCurso);
        final nivel = _norm(filters.nivel!.name);
        if (!nombre.contains(nivel)) return false;
      }
      if (filters.turno != null && g.turno != filters.turno) return false;
      return true;
    });
  }

  static List<ActividadExtracurricular> _actividadesActivas(Institucion inst) {
    return inst.actividadesExtracurriculares.where((a) => a.activa).toList();
  }

  static bool _tieneVacantesExtracurriculares(Institucion inst) {
    return _actividadesActivas(inst).any((a) => a.tieneCuposDisponibles);
  }

  static Future<List<Institucion>> _cargarCatalogoInstituciones() async {
    final result = <Institucion>[];
    final seen = <String>{};

    void add(Institucion inst) {
      final id = inst.id.trim();
      if (id.isEmpty) return;
      final key = _norm(id);
      if (seen.add(key)) result.add(inst);
    }

    try {
      final indexed = await ih.cargarInstitucionesRegistradas();
      for (final inst in indexed) {
        add(inst);
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      const prefix = 'atena_institucion_by_id_';

      for (final key in prefs.getKeys()) {
        if (!key.startsWith(prefix)) continue;
        final raw = prefs.getString(key);
        if (raw == null || raw.trim().isEmpty) continue;

        try {
          add(Institucion.fromJson(raw));
        } catch (_) {}
      }
    } catch (_) {}

    return result;
  }

  static Future<List<AlumnoInstitucionSearchResult>> search(
    AlumnoInstitucionSearchFilters filters,
  ) async {
    ultimaBusqueda = filters;

    final raw = await _cargarCatalogoInstituciones();
    final results = <AlumnoInstitucionSearchResult>[];

    for (final original in raw) {
      if (original.id.trim().isEmpty) continue;

      var inst = original;
      try {
        inst = await ih.hidratarInstitucionConGruposCurriculares(original);
        inst = inst.copyWith(
          gruposCurriculares:
              await SolicitudesService.gruposCurricularesParaAlumno(inst.id),
        );
      } catch (e) {
        // Estado curricular desconocido: no atribuir disponibilidad histórica.
        // Conservar la institución para filtros generales y extracurriculares.
        debugPrint('[ATENA][SEARCH][CURRICULAR_ERROR] ${original.id}: $e');
        inst = original.copyWith(gruposCurriculares: <GrupoCurricular>[]);
      }
      try {
        inst = await ih.hidratarInstitucionConExtracurriculares(
          inst,
          migrateIfLegacy: false,
        );
      } catch (e) {
        debugPrint('[ATENA][SEARCH][EXTRA_ERROR] ${original.id}: $e');
      }

      if (filters.scope == AlumnoBusquedaScope.curricular && !inst.curricular) {
        continue;
      }
      if (filters.scope == AlumnoBusquedaScope.extracurricular &&
          !inst.extracurricular) {
        continue;
      }

      final texto = _searchText(filters.texto);
      final matchesInstitution = _searchText(inst.nombre).contains(texto);
      if (texto.isNotEmpty &&
          !matchesInstitution &&
          !_actividadesActivas(
            inst,
          ).any((a) => _searchText(a.nombre).contains(texto)) &&
          !inst.gruposCurriculares.any(
            (g) => _searchText(g.nombreCurso).contains(texto),
          )) {
        continue;
      }

      if (filters.pais != null &&
          filters.pais!.trim().isNotEmpty &&
          _norm(inst.pais) != _norm(filters.pais!)) {
        continue;
      }

      if (filters.provincia != null &&
          filters.provincia!.trim().isNotEmpty &&
          _norm(inst.provincia) != _norm(filters.provincia!)) {
        continue;
      }

      if (filters.ciudad != null &&
          filters.ciudad!.trim().isNotEmpty &&
          !_norm(inst.ciudad).contains(_norm(filters.ciudad!))) {
        continue;
      }

      if (filters.tipoInstitucion != null &&
          inst.tipoInstitucion != filters.tipoInstitucion) {
        continue;
      }

      if (filters.modalidadCursado != null &&
          inst.modalidad != filters.modalidadCursado) {
        continue;
      }

      if (filters.scope == AlumnoBusquedaScope.curricular) {
        final niveles = _nivelesHabilitados(inst);
        if (filters.nivel != null && !niveles.contains(filters.nivel)) continue;
        if ((filters.soloConVacantes || filters.turno != null) &&
            !_tieneVacantesCurricularesConFiltro(inst, filters)) {
          continue;
        }
      } else {
        var actividades = _actividadesActivas(inst);
        if (texto.isNotEmpty && !matchesInstitution) {
          actividades = actividades
              .where((a) => _searchText(a.nombre).contains(texto))
              .toList();
        }

        if (filters.bloques.isNotEmpty) {
          actividades = actividades
              .where((a) => filters.bloques.contains(a.bloque))
              .toList();
        }

        if (filters.edad != null) {
          actividades = actividades
              .where((a) => _actividadAdmiteEdad(a, filters.edad!))
              .toList();
        }

        if (filters.precio != AlumnoPrecioFiltro.todos) {
          actividades = actividades
              .where((a) => _cumplePrecio(a, filters.precio))
              .toList();
        }

        if (filters.soloConVacantes) {
          final grupos =
              await SolicitudesService.gruposExtracurricularesParaAlumno(
                inst.id,
              );
          actividades = actividades
              .where(
                (a) => grupos.any(
                  (g) =>
                      g.tieneCupos &&
                      g.bloque == a.bloque &&
                      _norm(g.actividadNombre) == _norm(a.nombre),
                ),
              )
              .toList();
        }

        if (filters.bloques.isNotEmpty ||
            filters.edad != null ||
            filters.precio != AlumnoPrecioFiltro.todos ||
            filters.soloConVacantes) {
          if (actividades.isEmpty) continue;
        }
      }

      double? distancia;
      final lat = _lat(inst);
      final lng = _lng(inst);
      if (filters.userLat != null &&
          filters.userLng != null &&
          lat != null &&
          lng != null) {
        distancia = _haversineKm(
          lat1: filters.userLat!,
          lng1: filters.userLng!,
          lat2: lat,
          lng2: lng,
        );
        if (filters.maxDistanceKm != null &&
            distancia > filters.maxDistanceKm!) {
          continue;
        }
      } else if (filters.maxDistanceKm != null &&
          filters.userLat != null &&
          filters.userLng != null) {
        continue;
      }

      results.add(
        AlumnoInstitucionSearchResult(
          institucion: inst,
          distanciaKm: distancia,
        ),
      );
    }

    if (filters.ordenarPorDistancia &&
        filters.userLat != null &&
        filters.userLng != null) {
      results.sort((a, b) {
        final da = a.distanciaKm;
        final db = b.distanciaKm;
        if (da == null && db == null) {
          return _norm(
            a.institucion.nombre,
          ).compareTo(_norm(b.institucion.nombre));
        }
        if (da == null) return 1;
        if (db == null) return -1;
        final c = da.compareTo(db);
        if (c != 0) return c;
        return _norm(
          a.institucion.nombre,
        ).compareTo(_norm(b.institucion.nombre));
      });
    } else {
      results.sort(
        (a, b) =>
            _norm(a.institucion.nombre).compareTo(_norm(b.institucion.nombre)),
      );
    }

    return results;
  }
}
