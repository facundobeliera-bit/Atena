// lib/core/repos/instituciones_repo.dart
//
// Directorio de instituciones:
// - Datos de la institución (InstitucionService es la fuente de verdad).
// - Índice de búsqueda para familias (se actualiza al guardar).
// - Perfil público (descripción, contacto, fotos, logo).

import 'dart:convert';
import 'dart:typed_data';

import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/institucion_service.dart';
import '../../services/storage_service.dart';
import '../errors.dart';
import '../models/json_utils.dart';
import '../models/perfil_publico.dart';
import '../store/atena_store.dart';

/// Datos mínimos de una institución para listados y búsqueda.
class InstitucionResumen {
  final String id;
  final String nombre;
  final String ciudad;
  final String provincia;
  final String pais;
  final String direccion;
  final TipoInstitucion tipo;
  final ModalidadCursado modalidad;
  final List<NivelCurricular> niveles;
  final List<BloqueExtracurricular> bloques;
  final String logoId;
  final String descripcion;

  const InstitucionResumen({
    required this.id,
    required this.nombre,
    required this.ciudad,
    required this.provincia,
    required this.pais,
    required this.direccion,
    required this.tipo,
    required this.modalidad,
    required this.niveles,
    required this.bloques,
    required this.logoId,
    required this.descripcion,
  });

  String get ubicacion =>
      [ciudad, provincia].where((s) => s.trim().isNotEmpty).join(', ');

  JsonDoc toJson() => {
    'id': id,
    'nombre': nombre,
    'ciudad': ciudad,
    'provincia': provincia,
    'pais': pais,
    'direccion': direccion,
    'tipo': tipo.name,
    'modalidad': modalidad.name,
    'niveles': niveles.map((n) => n.name).toList(),
    'bloques': bloques.map((b) => b.key).toList(),
    'logoId': logoId,
    'descripcion': descripcion,
  };

  factory InstitucionResumen.fromJson(JsonDoc m) => InstitucionResumen(
    id: jStr(m['id']),
    nombre: jStr(m['nombre']),
    ciudad: jStr(m['ciudad']),
    provincia: jStr(m['provincia']),
    pais: jStr(m['pais']),
    direccion: jStr(m['direccion']),
    tipo: enumByName(TipoInstitucion.values, m['tipo'], TipoInstitucion.otra),
    modalidad: enumByName(
      ModalidadCursado.values,
      m['modalidad'],
      ModalidadCursado.presencial,
    ),
    niveles: jStrList(m['niveles'])
        .map(
          (s) =>
              enumByName(NivelCurricular.values, s, NivelCurricular.primaria),
        )
        .toSet()
        .toList(),
    bloques: jStrList(m['bloques'])
        .map(BloqueExtracurricularX.tryParse)
        .whereType<BloqueExtracurricular>()
        .toSet()
        .toList(),
    logoId: jStr(m['logoId']),
    descripcion: jStr(m['descripcion']),
  );
}

/// Criterios de búsqueda de instituciones.
class FiltroInstituciones {
  final String texto;
  final NivelCurricular? nivel;
  final BloqueExtracurricular? bloque;
  final ModalidadCursado? modalidad;

  const FiltroInstituciones({
    this.texto = '',
    this.nivel,
    this.bloque,
    this.modalidad,
  });

  bool get vacio =>
      texto.trim().isEmpty &&
      nivel == null &&
      bloque == null &&
      modalidad == null;
}

/// Normaliza texto para búsquedas (minúsculas y sin tildes).
String normalizarBusqueda(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = s.toLowerCase().trim();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString();
}

class InstitucionesRepo {
  InstitucionesRepo._();
  static final InstitucionesRepo instance = InstitucionesRepo._();

  static const String _colIndice = 'instituciones.indice';
  static const int maxBytesImagen = 1500 * 1024;

  final AtenaStore _store = AtenaStore.instance;
  bool _indiceVerificado = false;

  static String _norm(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  // ---------------------------------------------------------------------------
  // Institución
  // ---------------------------------------------------------------------------

  Future<Institucion?> obtener(String id) async {
    final key = _norm(id);
    if (key.isEmpty) return null;
    return InstitucionService.getInstitucionById(key);
  }

  Future<void> guardar(Institucion inst) async {
    await InstitucionService.upsertInstitucion(inst);
    await _indexar(inst);
  }

  /// Garantiza que la institución aparezca en las búsquedas de las familias.
  Future<void> asegurarIndexada(Institucion inst) async {
    final existente = await _store.get(_colIndice, _norm(inst.id));
    if (existente == null) await _indexar(inst);
  }

  Future<void> _indexar(Institucion inst) async {
    final perfil = await perfilPublico(inst.id);
    final plan = inst.planSafe;
    final resumen = InstitucionResumen(
      id: _norm(inst.id),
      nombre: inst.nombre.trim(),
      ciudad: inst.ciudad.trim(),
      provincia: inst.provincia.trim(),
      pais: inst.pais.trim(),
      direccion: inst.direccion.trim(),
      tipo: inst.tipoInstitucion,
      modalidad: inst.modalidad,
      niveles: inst.curricular
          ? plan.niveles.where((n) => n.habilitado).map((n) => n.nivel).toList()
          : const <NivelCurricular>[],
      bloques: inst.extracurricular
          ? plan.modulos
                .where((m) => m.habilitado)
                .map((m) => m.bloque)
                .toList()
          : const <BloqueExtracurricular>[],
      logoId: perfil.logoId,
      descripcion: perfil.descripcion,
    );
    await _store.put(_colIndice, resumen.toJson());
  }

  /// Reconstruye el índice a partir de las instituciones guardadas
  /// (instalaciones previas a esta versión).
  Future<void> _asegurarIndice() async {
    if (_indiceVerificado) return;
    _indiceVerificado = true;

    final actuales = await _store.read(_colIndice);
    if (actuales.isNotEmpty) return;

    const prefix = 'atena_institucion_by_id_';
    final keys = await _store.rawKeys();
    for (final k in keys) {
      if (!k.startsWith(prefix)) continue;
      final id = k.substring(prefix.length);
      final inst = await InstitucionService.getInstitucionById(id);
      if (inst == null || _norm(inst.id) != id) continue;
      if (inst.nombre.trim().isEmpty) continue;
      await _indexar(inst);
    }
  }

  Future<List<InstitucionResumen>> listar() async {
    await _asegurarIndice();
    final docs = await _store.read(_colIndice);
    final list = docs.map(InstitucionResumen.fromJson).toList();
    list.sort(
      (a, b) =>
          normalizarBusqueda(a.nombre).compareTo(normalizarBusqueda(b.nombre)),
    );
    return list;
  }

  Future<List<InstitucionResumen>> buscar(FiltroInstituciones f) async {
    final todas = await listar();
    final q = normalizarBusqueda(f.texto);
    final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return todas.where((i) {
      if (f.nivel != null && !i.niveles.contains(f.nivel)) return false;
      if (f.bloque != null && !i.bloques.contains(f.bloque)) return false;
      if (f.modalidad != null && i.modalidad != f.modalidad) return false;
      if (terms.isEmpty) return true;
      final hay = normalizarBusqueda(
        '${i.nombre} ${i.ciudad} ${i.provincia} ${i.direccion}',
      );
      return terms.every(hay.contains);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Perfil público
  // ---------------------------------------------------------------------------

  String _kPerfil(String id) => 'perfilpublico.${_norm(id)}';

  Future<PerfilPublico> perfilPublico(String institucionId) async {
    final id = _norm(institucionId);
    if (id.isEmpty) return const PerfilPublico();

    final doc = await _store.readSingle(_kPerfil(id));
    if (doc != null) return PerfilPublico.fromJson(doc);

    // Migración del formato anterior (fotos embebidas en base64).
    final old = await StorageService.instance.getString(
      'inst_public_profile_v1_$id',
    );
    if (old != null && old.trim().isNotEmpty) {
      try {
        final m = jsonDecode(old);
        if (m is Map) {
          final map = Map<String, dynamic>.from(m);
          var perfil = PerfilPublico.fromJson(map);
          final fotos = map['fotos'];
          if (fotos is List && perfil.fotoIds.isEmpty) {
            final ids = <String>[];
            for (final f in fotos.take(PerfilPublico.maxFotos)) {
              final b64 = jStr(f).replaceFirst('b64:', '');
              if (b64.isEmpty) continue;
              final blobId = AtenaIds.next('IMG');
              if (await _store.writeBlob('img.$blobId', b64)) ids.add(blobId);
            }
            perfil = perfil.copyWith(fotoIds: ids);
          }
          await _store.writeSingle(_kPerfil(id), perfil.toJson());
          return perfil;
        }
      } catch (_) {}
    }
    return const PerfilPublico();
  }

  Future<void> guardarPerfilPublico(
    String institucionId,
    PerfilPublico perfil,
  ) async {
    final id = _norm(institucionId);
    if (id.isEmpty) throw const AtenaException(AtenaError.datosInvalidos);
    await _store.writeSingle(_kPerfil(id), perfil.toJson());
    final inst = await obtener(id);
    if (inst != null) await _indexar(inst);
  }

  // ---------------------------------------------------------------------------
  // Imágenes (logo y fotos)
  // ---------------------------------------------------------------------------

  Future<String> guardarImagen(Uint8List bytes) async {
    if (bytes.isEmpty) throw const AtenaException(AtenaError.datosInvalidos);
    if (bytes.length > maxBytesImagen) {
      throw const AtenaException(AtenaError.archivoMuyGrande);
    }
    final blobId = AtenaIds.next('IMG');
    final ok = await _store.writeBlob('img.$blobId', base64Encode(bytes));
    if (!ok) throw const AtenaException(AtenaError.sinEspacio);
    return blobId;
  }

  Future<Uint8List?> imagen(String blobId) async {
    if (blobId.trim().isEmpty) return null;
    final raw = await _store.readBlob('img.$blobId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> eliminarImagen(String blobId) async {
    if (blobId.trim().isEmpty) return;
    await _store.deleteBlob('img.$blobId');
  }
}
