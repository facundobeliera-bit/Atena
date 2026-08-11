import 'dart:math' as math;

import '../models/extracurriculares/bloque_extracurricular.dart';
import '../models/extracurriculares/actividad_extracurricular.dart';
import '../models/instituciones/instituciones_integrado.dart';
import 'instituciones_helpers.dart' as ih;

/// Scope principal del buscador del alumno.
enum AlumnoBusquedaScope { curricular, extracurricular }

enum AlumnoPrecioFiltro { todos, gratuitos, conCosto }

class AlumnoInstitucionSearchFilters {
  final AlumnoBusquedaScope scope;
  final String texto;
  final String? provincia;
  final String? ciudad;
  final NivelCurricular? nivel;
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
    this.provincia,
    this.ciudad,
    this.nivel,
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
  static String _norm(String value) => value.trim().toLowerCase();

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
      map['lng'] ?? map['lon'] ?? map['longitude'] ?? map['ubicacionLng'] ?? map['geoLng'],
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
    if (raw.isEmpty) return true;

    final normalized = raw.replaceAll('años', '').replaceAll('año', '');
    final numbers = RegExp(r'\d+').allMatches(normalized)
        .map((m) => int.tryParse(m.group(0)!))
        .whereType<int>()
        .toList();

    if (numbers.isEmpty) return true;
    if (numbers.length == 1) return edad == numbers.first;

    final min = math.min(numbers[0], numbers[1]);
    final max = math.max(numbers[0], numbers[1]);
    return edad >= min && edad <= max;
  }

  static bool _esGratuito(String? precio) {
    final p = (precio ?? '').trim().toLowerCase();
    if (p.isEmpty) return true;
    if (p == '0' || p == r'$0' || p.contains('gratis') || p.contains('gratuito')) {
      return true;
    }
    return false;
  }

  static bool _cumplePrecio(ActividadExtracurricular a, AlumnoPrecioFiltro filtro) {
    switch (filtro) {
      case AlumnoPrecioFiltro.todos:
        return true;
      case AlumnoPrecioFiltro.gratuitos:
        return _esGratuito(a.precio);
      case AlumnoPrecioFiltro.conCosto:
        return !_esGratuito(a.precio);
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

  static List<ActividadExtracurricular> _actividadesActivas(Institucion inst) {
    return inst.actividadesExtracurriculares.where((a) => a.activa).toList();
  }

  static bool _tieneVacantesExtracurriculares(Institucion inst) {
    return _actividadesActivas(inst).any((a) => a.tieneCuposDisponibles);
  }

  static Future<List<AlumnoInstitucionSearchResult>> search(
    AlumnoInstitucionSearchFilters filters,
  ) async {
    final raw = await ih.cargarInstitucionesRegistradas();
    final results = <AlumnoInstitucionSearchResult>[];

    for (final original in raw) {
      if (original.id.trim().isEmpty) continue;

      var inst = original;
      try {
        final conGrupos = await ih.hidratarInstitucionConGruposCurriculares(inst);
        inst = await ih.hidratarInstitucionConExtracurriculares(
          conGrupos,
          migrateIfLegacy: false,
        );
      } catch (_) {
        // Si la hidratación falla, se conserva la institución base.
      }

      if (filters.scope == AlumnoBusquedaScope.curricular && !inst.curricular) {
        continue;
      }
      if (filters.scope == AlumnoBusquedaScope.extracurricular && !inst.extracurricular) {
        continue;
      }

      final texto = _norm(filters.texto);
      if (texto.isNotEmpty && !_norm(inst.nombre).contains(texto)) continue;

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
        if (filters.soloConVacantes && !_tieneVacantesCurriculares(inst)) continue;
      } else {
        var actividades = _actividadesActivas(inst);

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
          actividades = actividades.where((a) => a.tieneCuposDisponibles).toList();
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
        if (filters.maxDistanceKm != null && distancia > filters.maxDistanceKm!) {
          continue;
        }
      } else if (filters.maxDistanceKm != null &&
          filters.userLat != null &&
          filters.userLng != null) {
        // Se pidió radio, pero esta institución todavía no tiene coordenadas.
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
          return _norm(a.institucion.nombre).compareTo(_norm(b.institucion.nombre));
        }
        if (da == null) return 1;
        if (db == null) return -1;
        final c = da.compareTo(db);
        if (c != 0) return c;
        return _norm(a.institucion.nombre).compareTo(_norm(b.institucion.nombre));
      });
    } else {
      results.sort(
        (a, b) => _norm(a.institucion.nombre).compareTo(_norm(b.institucion.nombre)),
      );
    }

    return results;
  }
}
