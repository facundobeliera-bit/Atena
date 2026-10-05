/// Explicit public read model. Never holds an owner, operator, credential,
/// request, student record or the canonical institutional object.
enum CategoriaPublica { formal, actividades }

enum CostoOferta { gratuito, arancelado, consultar }

CostoOferta clasificarCosto(String? value) {
  final text = (value ?? '').trim().toLowerCase();
  if ([
    'gratis',
    'gratuito',
    'gratuita',
    'sin costo',
    'sin cargo',
  ].contains(text)) {
    return CostoOferta.gratuito;
  }
  final number = text.replaceAll(RegExp(r'[$€\s]'), '').replaceAll(',', '.');
  if (RegExp(r'^\d+(\.\d+)*$').hasMatch(number)) {
    return number.replaceAll('.', '').split('').every((e) => e == '0')
        ? CostoOferta.gratuito
        : CostoOferta.arancelado;
  }
  if (text == 'arancelado' || text == 'arancelada' || text == 'con costo') {
    return CostoOferta.arancelado;
  }
  return CostoOferta.consultar;
}

String normalizarBusquedaPublica(String value) {
  var text = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  for (final e in {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  }.entries) {
    text = text.replaceAll(e.key, e.value);
  }
  return text;
}

class OfertaPublica {
  final String id,
      institucionId,
      areaId,
      nombre,
      grupo,
      horario,
      precio,
      edades,
      descripcion,
      tipoFormal;
  final CategoriaPublica categoria;
  final int? disponibles;
  final bool habilitada;
  const OfertaPublica({
    required this.id,
    required this.institucionId,
    required this.areaId,
    required this.nombre,
    required this.grupo,
    required this.horario,
    required this.precio,
    required this.edades,
    required this.descripcion,
    required this.categoria,
    required this.disponibles,
    required this.habilitada,
    this.tipoFormal = 'escolar',
  });
  CostoOferta get costo => clasificarCosto(precio);
  String get costoLabel => switch (costo) {
    CostoOferta.gratuito => 'Gratuito',
    CostoOferta.arancelado =>
      precio.isEmpty ? 'Arancelado' : 'Arancelado · $precio',
    CostoOferta.consultar => 'Costo a consultar',
  };
  String get categoriaLabel => categoria == CategoriaPublica.formal
      ? 'Educación formal'
      : 'Actividades y formación';
  String get nivelLabel => categoria == CategoriaPublica.actividades
      ? 'Actividad'
      : tipoFormal == 'universidad'
      ? 'Universidad · Carrera / programa'
      : tipoFormal == 'superior'
      ? 'Educación superior · Programa'
      : 'Educación formal';
  OfertaPublica disponibilidad(int? n, bool enabled) => OfertaPublica(
    id: id,
    institucionId: institucionId,
    areaId: areaId,
    nombre: nombre,
    grupo: grupo,
    horario: horario,
    precio: precio,
    edades: edades,
    descripcion: descripcion,
    categoria: categoria,
    disponibles: n,
    habilitada: enabled,
    tipoFormal: tipoFormal,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'institution': institucionId,
    'area': areaId,
    'name': nombre,
    'group': grupo,
    'schedule': horario,
    'price': precio,
    'ages': edades,
    'description': descripcion,
    'kind': categoria.name,
    'available': disponibles,
    'enabled': habilitada,
    'formal_type': tipoFormal,
  };
  factory OfertaPublica.fromMap(Map<String, dynamic> m) => OfertaPublica(
    id: m['id'] as String,
    institucionId: m['institution'] as String,
    areaId: m['area'] as String,
    nombre: m['name'] as String,
    grupo: m['group'] as String,
    horario: m['schedule'] as String,
    precio: m['price'] as String,
    edades: m['ages'] as String,
    descripcion: m['description'] as String,
    categoria: CategoriaPublica.values.byName(m['kind'] as String),
    disponibles: m['available'] as int?,
    habilitada: m['enabled'] == true,
    tipoFormal: m['formal_type'] as String? ?? 'escolar',
  );
}

class FichaPublicaInstitucion {
  final String id,
      nombre,
      pais,
      provincia,
      localidad,
      direccion,
      telefono,
      descripcion,
      modalidad;
  final List<String> fotos;
  final List<OfertaPublica> ofertas;
  const FichaPublicaInstitucion({
    required this.id,
    required this.nombre,
    required this.pais,
    required this.provincia,
    required this.localidad,
    required this.direccion,
    required this.telefono,
    required this.descripcion,
    required this.modalidad,
    required this.ofertas,
    this.fotos = const [],
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': nombre,
    'country': pais,
    'province': provincia,
    'city': localidad,
    'address': direccion,
    'phone': telefono,
    'description': descripcion,
    'modality': modalidad,
    'photos': fotos,
    'offers': ofertas.map((e) => e.toMap()).toList(),
  };
  factory FichaPublicaInstitucion.fromMap(Map<String, dynamic> m) =>
      FichaPublicaInstitucion(
        id: m['id'] as String,
        nombre: m['name'] as String,
        pais: m['country'] as String,
        provincia: m['province'] as String,
        localidad: m['city'] as String,
        direccion: m['address'] as String,
        telefono: m['phone'] as String,
        descripcion: m['description'] as String,
        modalidad: m['modality'] as String,
        fotos: List<String>.unmodifiable(
          (m['photos'] as List? ?? []).whereType<String>(),
        ),
        ofertas: List<OfertaPublica>.unmodifiable(
          (m['offers'] as List).map(
            (e) => OfertaPublica.fromMap(Map<String, dynamic>.from(e)),
          ),
        ),
      );
  FichaPublicaInstitucion conOfertas(List<OfertaPublica> values) =>
      FichaPublicaInstitucion(
        id: id,
        nombre: nombre,
        pais: pais,
        provincia: provincia,
        localidad: localidad,
        direccion: direccion,
        telefono: telefono,
        descripcion: descripcion,
        modalidad: modalidad,
        fotos: fotos,
        ofertas: List.unmodifiable(values),
      );
}
