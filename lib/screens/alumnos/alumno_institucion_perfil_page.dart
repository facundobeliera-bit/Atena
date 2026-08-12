import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/instituciones/instituciones_integrado.dart';

/// Perfil institucional de consulta para alumnos/interesados.
///
/// Esta pantalla es estrictamente de solo lectura: no recibe sesión
/// institucional, no expone controles de edición y no escribe datos.
/// Lee la misma información pública que la institución administra en
/// InstitucionPerfilPage mediante la clave canónica:
/// inst_public_profile_v1_<institucionPerfilId>.
class AlumnoInstitucionPerfilPage extends StatefulWidget {
  final Institucion institucion;
  final VoidCallback? onSolicitarVacante;

  const AlumnoInstitucionPerfilPage({
    super.key,
    required this.institucion,
    this.onSolicitarVacante,
  });

  @override
  State<AlumnoInstitucionPerfilPage> createState() =>
      _AlumnoInstitucionPerfilPageState();
}

class _AlumnoInstitucionPerfilPageState
    extends State<AlumnoInstitucionPerfilPage> {
  bool _cargando = true;
  _PublicExtra _publico = const _PublicExtra();

  @override
  void initState() {
    super.initState();
    _loadPublicExtra();
  }

  Future<void> _loadPublicExtra() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      final id = widget.institucion.id.trim();
      final raw = (prefs.getString('inst_public_profile_v1_$id') ?? '').trim();
      if (raw.isNotEmpty) {
        _publico = _PublicExtra.fromJson(raw);
      }
    } catch (_) {
      _publico = const _PublicExtra();
    }

    if (!mounted) return;
    setState(() => _cargando = false);
  }

  String _tipoLabel(TipoInstitucion value) {
    switch (value) {
      case TipoInstitucion.jardin:
        return 'Jardín';
      case TipoInstitucion.primaria:
        return 'Primaria';
      case TipoInstitucion.secundaria:
        return 'Secundaria';
      case TipoInstitucion.tecnica:
        return 'Técnica';
      case TipoInstitucion.terciario:
        return 'Terciario';
      case TipoInstitucion.taller:
        return 'Taller';
      case TipoInstitucion.club:
        return 'Club';
      case TipoInstitucion.otra:
        return 'Otra';
    }
  }

  String _modalidadLabel(ModalidadCursado value) {
    switch (value) {
      case ModalidadCursado.presencial:
        return 'Presencial';
      case ModalidadCursado.remoto:
        return 'Remoto';
      case ModalidadCursado.hibrido:
        return 'Híbrido';
    }
  }

  String _nivelLabel(NivelCurricular value) {
    switch (value) {
      case NivelCurricular.jardin:
        return 'Jardín';
      case NivelCurricular.primaria:
        return 'Primaria';
      case NivelCurricular.secundaria:
        return 'Secundaria';
      case NivelCurricular.tecnica:
        return 'Técnica';
      case NivelCurricular.terciario:
        return 'Terciario';
    }
  }

  Uint8List? _bytes(String value) {
    try {
      final s = value.trim();
      if (s.isEmpty) return null;
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  Widget _section(String title, Widget child) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _dataRow(IconData icon, String label, String value) {
    final v = value.trim();
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: v),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(List<String> values) {
    final clean = values.map((e) => e.trim()).where((e) => e.isNotEmpty);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [for (final value in clean) Chip(label: Text(value))],
    );
  }

  Widget _buildHeader(Institucion inst) {
    final location = [
      if (inst.ciudad.trim().isNotEmpty) inst.ciudad.trim(),
      if (inst.provincia.trim().isNotEmpty) inst.provincia.trim(),
      if (inst.pais.trim().isNotEmpty) inst.pais.trim(),
    ].join(', ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    inst.nombre.trim().isEmpty
                        ? 'Institución'
                        : inst.nombre.trim(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const Chip(label: Text('Perfil institucional')),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              _dataRow(Icons.location_on_outlined, 'Ubicación', location),
            ],
            _chips([
              _tipoLabel(inst.tipoInstitucion),
              _modalidadLabel(inst.modalidad),
              if (inst.curricular) 'Curricular',
              if (inst.extracurricular) 'Extracurricular',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(Institucion inst) {
    return _section(
      'Información institucional',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dataRow(Icons.place_outlined, 'Dirección', inst.direccion),
          _dataRow(Icons.public, 'País', inst.pais),
          _dataRow(Icons.map_outlined, 'Provincia', inst.provincia),
          _dataRow(Icons.location_city, 'Localidad', inst.ciudad),
          _dataRow(Icons.phone_outlined, 'Teléfono', inst.telefono),
          _dataRow(Icons.email_outlined, 'Email', inst.email),
          _dataRow(Icons.account_balance_outlined, 'Tipo de institución',
              _tipoLabel(inst.tipoInstitucion)),
          _dataRow(Icons.devices_outlined, 'Modalidad',
              _modalidadLabel(inst.modalidad)),
        ],
      ),
    );
  }

  Widget _buildOffer(Institucion inst) {
    final levels = inst.planConfig?.niveles
            .where((e) => e.habilitado)
            .map((e) => e.nombrePropio?.trim().isNotEmpty == true
                ? e.nombrePropio!.trim()
                : _nivelLabel(e.nivel))
            .toList() ??
        <String>[];

    final extras = inst.actividadesExtracurriculares
        .where((e) => e.activa)
        .toList();

    if (!inst.curricular && !inst.extracurricular &&
        levels.isEmpty && extras.isEmpty) {
      return const SizedBox.shrink();
    }

    return _section(
      'Propuestas disponibles',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inst.curricular) ...[
            const Text('Curricular', style: TextStyle(fontWeight: FontWeight.w800)),
            if (levels.isNotEmpty) ...[
              const SizedBox(height: 7),
              _chips(levels),
            ],
          ],
          if (inst.extracurricular) ...[
            if (inst.curricular) const SizedBox(height: 14),
            const Text('Extracurricular', style: TextStyle(fontWeight: FontWeight.w800)),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 7),
              for (final activity in extras)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(activity.nombre),
                  subtitle: Text([
                    activity.bloque.label,
                    if ((activity.edades ?? '').trim().isNotEmpty)
                      'Edades: ${activity.edades}',
                    if ((activity.precio ?? '').trim().isNotEmpty)
                      'Valor: ${activity.precio}',
                  ].join(' • ')),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPublicExtra() {
    final p = _publico;
    final social = <String, String>{
      'Instagram': p.instagram,
      'Facebook': p.facebook,
      'TikTok': p.tiktok,
      'YouTube': p.youtube,
      'X': p.x,
      'LinkedIn': p.linkedin,
    }..removeWhere((_, value) => value.trim().isEmpty);

    final hasPublic = p.descripcion.trim().isNotEmpty ||
        p.horariosAtencion.trim().isNotEmpty ||
        p.horariosAulas.trim().isNotEmpty ||
        p.telefonoPublico.trim().isNotEmpty ||
        p.website.trim().isNotEmpty ||
        social.isNotEmpty ||
        p.servicios.isNotEmpty ||
        (p.ofreceCursosCortos && p.cursosCortos.isNotEmpty) ||
        p.fotos.isNotEmpty;

    if (!hasPublic) return const SizedBox.shrink();

    return Column(
      children: [
        if (p.fotos.isNotEmpty)
          _section(
            'Fotos',
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final bytes = _bytes(p.fotos[index]);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 118,
                      height: 118,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: bytes == null
                          ? const Icon(Icons.broken_image_outlined)
                          : Image.memory(bytes, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ),
        if (p.descripcion.trim().isNotEmpty)
          _section(
            'Descripción',
            Text(p.descripcion.trim()),
          ),
        if (p.horariosAtencion.trim().isNotEmpty ||
            p.horariosAulas.trim().isNotEmpty)
          _section(
            'Horarios',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dataRow(Icons.access_time, 'Horarios de atención', p.horariosAtencion),
                _dataRow(Icons.schedule, 'Horarios de aulas', p.horariosAulas),
              ],
            ),
          ),
        if (p.telefonoPublico.trim().isNotEmpty || p.website.trim().isNotEmpty)
          _section(
            'Contacto',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dataRow(Icons.phone_in_talk, 'Teléfono público', p.telefonoPublico),
                _dataRow(Icons.language, 'Sitio web', p.website),
              ],
            ),
          ),
        if (social.isNotEmpty)
          _section(
            'Redes sociales',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in social.entries)
                  _dataRow(Icons.link, entry.key, entry.value),
              ],
            ),
          ),
        if (p.servicios.isNotEmpty)
          _section('Servicios', _chips(p.servicios)),
        if (p.ofreceCursosCortos && p.cursosCortos.isNotEmpty)
          _section(
            'Cursos cortos',
            Column(
              children: [
                for (final curso in p.cursosCortos)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(curso.nombre),
                    subtitle: Text([
                      if (curso.duracion.trim().isNotEmpty)
                        'Duración: ${curso.duracion}',
                      if (curso.precio.trim().isNotEmpty)
                        'Precio: ${curso.precio}',
                      if (curso.modalidad.trim().isNotEmpty)
                        'Modalidad: ${curso.modalidad}',
                    ].join(' • ')),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inst = widget.institucion;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de la institución')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildHeader(inst),
            _buildBasicInfo(inst),
            _buildOffer(inst),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildPublicExtra(),
            if (widget.onSolicitarVacante != null &&
                (inst.curricular || inst.extracurricular))
              FilledButton.icon(
                onPressed: widget.onSolicitarVacante,
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text('Solicitar vacante'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PublicExtra {
  final String descripcion;
  final String horariosAtencion;
  final String horariosAulas;
  final String telefonoPublico;
  final String website;
  final String instagram;
  final String facebook;
  final String tiktok;
  final String youtube;
  final String x;
  final String linkedin;
  final List<String> servicios;
  final bool ofreceCursosCortos;
  final List<_ShortCourse> cursosCortos;
  final List<String> fotos;

  const _PublicExtra({
    this.descripcion = '',
    this.horariosAtencion = '',
    this.horariosAulas = '',
    this.telefonoPublico = '',
    this.website = '',
    this.instagram = '',
    this.facebook = '',
    this.tiktok = '',
    this.youtube = '',
    this.x = '',
    this.linkedin = '',
    this.servicios = const [],
    this.ofreceCursosCortos = false,
    this.cursosCortos = const [],
    this.fotos = const [],
  });

  factory _PublicExtra.fromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const _PublicExtra();
      final m = decoded.cast<String, dynamic>();
      final servicios = (m['servicios'] is List)
          ? (m['servicios'] as List)
              .map((e) => (e ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const <String>[];
      final cursos = (m['cursosCortos'] is List)
          ? (m['cursosCortos'] as List)
              .whereType<Map>()
              .map((e) => _ShortCourse.fromMap(e.cast<String, dynamic>()))
              .toList()
          : const <_ShortCourse>[];
      final fotos = (m['fotos'] is List)
          ? (m['fotos'] as List)
              .map((e) => (e ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .take(5)
              .toList()
          : const <String>[];

      bool asBool(dynamic value) {
        if (value is bool) return value;
        if (value is num) return value != 0;
        final s = (value ?? '').toString().trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'si' || s == 'sí' || s == 'yes';
      }

      return _PublicExtra(
        descripcion: (m['descripcion'] ?? '').toString(),
        horariosAtencion: (m['horariosAtencion'] ?? '').toString(),
        horariosAulas: (m['horariosAulas'] ?? '').toString(),
        telefonoPublico: (m['telefonoPublico'] ?? '').toString(),
        website: (m['website'] ?? '').toString(),
        instagram: (m['instagram'] ?? '').toString(),
        facebook: (m['facebook'] ?? '').toString(),
        tiktok: (m['tiktok'] ?? '').toString(),
        youtube: (m['youtube'] ?? '').toString(),
        x: (m['x'] ?? '').toString(),
        linkedin: (m['linkedin'] ?? '').toString(),
        servicios: servicios,
        ofreceCursosCortos: asBool(m['ofreceCursosCortos']),
        cursosCortos: cursos,
        fotos: fotos,
      );
    } catch (_) {
      return const _PublicExtra();
    }
  }
}

class _ShortCourse {
  final String nombre;
  final String duracion;
  final String precio;
  final String modalidad;

  const _ShortCourse({
    required this.nombre,
    this.duracion = '',
    this.precio = '',
    this.modalidad = '',
  });

  factory _ShortCourse.fromMap(Map<String, dynamic> m) {
    return _ShortCourse(
      nombre: (m['nombre'] ?? '').toString(),
      duracion: (m['duracion'] ?? '').toString(),
      precio: (m['precio'] ?? '').toString(),
      modalidad: (m['modalidad'] ?? '').toString(),
    );
  }
}
