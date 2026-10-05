enum ModuloEducativo {
  progreso('Progreso'),
  boletines('Boletines'),
  titulos('Títulos y certificaciones'),
  becas('Becas'),
  sanciones('Sanciones'),
  equivalencias('Equivalencias');

  const ModuloEducativo(this.label);
  final String label;
  static ModuloEducativo? desdeRuta(String path) => switch (path) {
    '/progreso' => progreso,
    '/boletines' => boletines,
    '/titulos' => titulos,
    '/becas' => becas,
    '/sanciones' || '/convivencia' => sanciones,
    '/equivalencias' => equivalencias,
    _ => null,
  };

  Map<String, String> get campos => switch (this) {
    progreso => {'porcentaje': 'Avance (%)'},
    boletines => {
      'anio': 'Año',
      'periodo': 'Período',
      'calificaciones': 'Calificaciones (una por línea: Materia = nota)',
      'observaciones': 'Observaciones del boletín',
    },
    titulos => {
      'titulo': 'Título o certificación',
      'entidadEmisora': 'Entidad emisora',
      'fechaEmision': 'Fecha de emisión',
    },
    becas => {
      'nombre': 'Nombre de la beca',
      'descripcion': 'Descripción',
      'fechaInicio': 'Inicio de vigencia',
      'fechaFin': 'Fin de vigencia (opcional)',
    },
    sanciones => {
      'motivo': 'Motivo',
      'tipo': 'Tipo de medida (opcional)',
      'detalle': 'Detalle',
      'fecha': 'Fecha de registro',
      'hasta': 'Vigente hasta (opcional)',
    },
    equivalencias => {
      'institucionOrigenId': 'Institución de origen (identificador)',
      'materiaOrigen': 'Materia o actividad de origen',
      'materiaDestino': 'Materia o actividad de destino',
      'observacion': 'Observaciones de la decisión',
      'fecha': 'Fecha de decisión',
    },
  };

  String? get booleano => switch (this) {
    becas || sanciones => 'activa',
    equivalencias => 'aprobada',
    _ => null,
  };

  bool esFecha(String key) => key.startsWith('fecha') || key == 'hasta';

  String get aviso => switch (this) {
    progreso => 'Registrá únicamente el avance observado en esta inscripción.',
    boletines =>
      'Sin calificaciones, el boletín permanece incompleto. Las notas se cargan manualmente; Atena no las calcula ni inventa.',
    titulos =>
      'Documento local de Atena. No acredita validación oficial por una autoridad externa.',
    becas =>
      'Registro de una beca otorgada por la institución. No evalúa elegibilidad.',
    sanciones =>
      'Registro institucional con historial de correcciones. No se elimina el historial ni se clasifica al alumno.',
    equivalencias =>
      'Registrá una decisión institucional existente. Atena no determina equivalencias automáticamente.',
  };

  Map<String, dynamic> validar(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    const optional = {
      'descripcion',
      'fechaFin',
      'tipo',
      'detalle',
      'hasta',
      'observacion',
      'observaciones',
      'calificaciones',
    };
    for (final field in campos.keys) {
      final value = input[field];
      final text = (value ?? '').toString().trim();
      if (field == 'calificaciones') {
        if (value is! Map) {
          throw ArgumentError(
            'Las calificaciones deben indicar materia y nota.',
          );
        }
        final grades = <String, double>{};
        for (final entry in value.entries) {
          final grade = double.tryParse(entry.value.toString());
          final subject = entry.key.toString().trim();
          if (subject.isEmpty || grade == null || !grade.isFinite) {
            throw ArgumentError('Revisá la materia y la calificación.');
          }
          if (grades.containsKey(subject)) {
            throw ArgumentError('Materia repetida.');
          }
          grades[subject] = grade;
        }
        result[field] = grades;
        result['completo'] = grades.isNotEmpty;
      } else if (field == 'porcentaje') {
        final number = double.tryParse(text);
        if (number == null || !number.isFinite || number < 0 || number > 100) {
          throw ArgumentError('El avance debe estar entre 0 y 100.');
        }
        result[field] = number;
      } else if (field == 'anio') {
        final year = int.tryParse(text);
        if (year == null || year < 1900 || year > 2200) {
          throw ArgumentError('Ingresá un año válido.');
        }
        result[field] = year;
      } else if (esFecha(field)) {
        if (text.isEmpty && optional.contains(field)) {
          result[field] = null;
          continue;
        }
        final date = DateTime.tryParse(text);
        if (date == null ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
            date.toIso8601String().substring(0, 10) != text) {
          throw ArgumentError('Ingresá una fecha válida (AAAA-MM-DD).');
        }
        result[field] = date.toIso8601String();
      } else {
        if (text.isEmpty && !optional.contains(field)) {
          throw ArgumentError('Completá: ${campos[field]}.');
        }
        if (text.length > 4000) {
          throw ArgumentError('El texto es demasiado extenso.');
        }
        result[field] = text;
      }
    }
    if (booleano != null) {
      if (input[booleano] is! bool) {
        throw ArgumentError('Seleccioná el estado.');
      }
      result[booleano!] = input[booleano];
    }
    final start = result['fechaInicio'] ?? result['fecha'];
    final end = result['fechaFin'] ?? result['hasta'];
    if (start != null &&
        end != null &&
        DateTime.parse(end).isBefore(DateTime.parse(start))) {
      throw ArgumentError('La fecha final no puede ser anterior al inicio.');
    }
    return result;
  }
}
