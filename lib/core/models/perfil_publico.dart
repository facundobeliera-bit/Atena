// lib/core/models/perfil_publico.dart
//
// Perfil público de la institución: lo que ven las familias al buscarla.
// Las imágenes (logo y fotos) se guardan aparte como blobs; acá solo sus ids.

import 'json_utils.dart';

class PerfilPublico {
  final String descripcion;
  final String horarioAtencion;
  final String horarioClases;
  final String telefono;
  final String whatsapp;
  final String email;
  final String sitioWeb;
  final String instagram;
  final String facebook;
  final String youtube;
  final List<String> servicios;

  /// Ids de blobs de fotos (máximo [maxFotos]).
  final List<String> fotoIds;

  /// Id del blob del logo ('' = sin logo).
  final String logoId;

  static const int maxFotos = 6;

  const PerfilPublico({
    this.descripcion = '',
    this.horarioAtencion = '',
    this.horarioClases = '',
    this.telefono = '',
    this.whatsapp = '',
    this.email = '',
    this.sitioWeb = '',
    this.instagram = '',
    this.facebook = '',
    this.youtube = '',
    this.servicios = const <String>[],
    this.fotoIds = const <String>[],
    this.logoId = '',
  });

  bool get estaVacio =>
      descripcion.isEmpty &&
      horarioAtencion.isEmpty &&
      telefono.isEmpty &&
      sitioWeb.isEmpty &&
      servicios.isEmpty &&
      fotoIds.isEmpty;

  PerfilPublico copyWith({
    String? descripcion,
    String? horarioAtencion,
    String? horarioClases,
    String? telefono,
    String? whatsapp,
    String? email,
    String? sitioWeb,
    String? instagram,
    String? facebook,
    String? youtube,
    List<String>? servicios,
    List<String>? fotoIds,
    String? logoId,
  }) {
    return PerfilPublico(
      descripcion: descripcion ?? this.descripcion,
      horarioAtencion: horarioAtencion ?? this.horarioAtencion,
      horarioClases: horarioClases ?? this.horarioClases,
      telefono: telefono ?? this.telefono,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      sitioWeb: sitioWeb ?? this.sitioWeb,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      youtube: youtube ?? this.youtube,
      servicios: servicios ?? this.servicios,
      fotoIds: fotoIds ?? this.fotoIds,
      logoId: logoId ?? this.logoId,
    );
  }

  JsonDoc toJson() => {
    'descripcion': descripcion,
    'horarioAtencion': horarioAtencion,
    'horarioClases': horarioClases,
    'telefono': telefono,
    'whatsapp': whatsapp,
    'email': email,
    'sitioWeb': sitioWeb,
    'instagram': instagram,
    'facebook': facebook,
    'youtube': youtube,
    'servicios': servicios,
    'fotoIds': fotoIds,
    'logoId': logoId,
  };

  factory PerfilPublico.fromJson(JsonDoc m) => PerfilPublico(
    descripcion: jStr(m['descripcion']),
    horarioAtencion: jStr(m['horarioAtencion'] ?? m['horariosAtencion']),
    horarioClases: jStr(m['horarioClases'] ?? m['horariosAulas']),
    telefono: jStr(m['telefono'] ?? m['telefonoPublico']),
    whatsapp: jStr(m['whatsapp']),
    email: jStr(m['email']),
    sitioWeb: jStr(m['sitioWeb'] ?? m['website']),
    instagram: jStr(m['instagram']),
    facebook: jStr(m['facebook']),
    youtube: jStr(m['youtube']),
    servicios: jStrList(m['servicios']),
    fotoIds: jStrList(m['fotoIds']),
    logoId: jStr(m['logoId']),
  );
}
