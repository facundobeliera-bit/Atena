import '../services/plan_habilitacion_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/catalogo/ficha_publica.dart';
import '../services/catalogo_publicable_service.dart';
import '../routes/solicitud_publica_intent.dart';
import '../screens/alumnos/alumno_buscar_instituciones_page.dart';
import '../screens/alumnos/alumno_institucion_perfil_page.dart';
import 'atena_workspace.dart';

const _local =
    'Publicaciones de este dispositivo. Todavía no se comparten entre dispositivos.';

class AccesoBuscadorPublico extends StatelessWidget {
  const AccesoBuscadorPublico({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Explorar instituciones',
    icon: const Icon(Icons.travel_explore),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AlumnoBuscarInstitucionesPage.publica(),
      ),
    ),
  );
}

class PortadaBuscadorPublico extends StatefulWidget {
  const PortadaBuscadorPublico({super.key});
  @override
  State<PortadaBuscadorPublico> createState() => _PortadaBuscadorPublicoState();
}

class _PortadaBuscadorPublicoState extends State<PortadaBuscadorPublico> {
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _open({
    CategoriaPublica? category,
    CostoOferta? cost,
    String formal = '',
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AlumnoBuscarInstitucionesPage.publica(
        textoInicial: _text.text,
        categoriaInicial: category,
        costoInicial: cost,
        tipoFormalInicial: formal,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Encontrá dónde estudiar, aprender y desarrollarte.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Explorá instituciones y propuestas sin crear una cuenta.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            onSubmitted: (_) => _open(),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Institución, carrera o actividad',
              hintText: 'Por ejemplo: inglés, primaria, música',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _open(),
            icon: const Icon(Icons.search),
            label: const Text('Buscar propuestas'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Educación formal'),
                onPressed: () => _open(category: CategoriaPublica.formal),
              ),
              ActionChip(
                label: const Text('Actividades y formación'),
                onPressed: () => _open(category: CategoriaPublica.actividades),
              ),
              ActionChip(
                label: const Text('Universidades'),
                onPressed: () => _open(
                  category: CategoriaPublica.formal,
                  formal: 'universidad',
                ),
              ),
              ActionChip(
                label: const Text('Opciones gratuitas'),
                onPressed: () => _open(cost: CostoOferta.gratuito),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(_local),
        ],
      ),
    ),
  );
}

class CatalogoPublicoBusqueda extends StatefulWidget {
  final String textoInicial, tipoFormalInicial;
  final CategoriaPublica? categoriaInicial;
  final CostoOferta? costoInicial;
  const CatalogoPublicoBusqueda({
    super.key,
    this.textoInicial = '',
    this.tipoFormalInicial = '',
    this.categoriaInicial,
    this.costoInicial,
  });
  @override
  State<CatalogoPublicoBusqueda> createState() =>
      _CatalogoPublicoBusquedaState();
}

class _CatalogoPublicoBusquedaState extends State<CatalogoPublicoBusqueda> {
  late final _query = TextEditingController(text: widget.textoInicial);
  final _city = TextEditingController(),
      _province = TextEditingController(),
      _country = TextEditingController(),
      _schedule = TextEditingController(),
      _ages = TextEditingController();
  late CategoriaPublica? _category = widget.categoriaInicial;
  late CostoOferta? _cost = widget.costoInicial;
  late String _formal = widget.tipoFormalInicial;
  String _modality = '';
  bool _available = false, _busy = false;
  String? _error;
  List<FichaPublicaInstitucion> _results = [];
  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    for (final c in [_query, _city, _province, _country, _schedule, _ages]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _search() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final values = await CatalogoPublicableService().buscarPublico(
        texto: _query.text,
        categoria: _category,
        costo: _cost,
        localidad: _city.text,
        provincia: _province.text,
        pais: _country.text,
        horario: _schedule.text,
        edades: _ages.text,
        modalidad: _modality,
        tipoFormal: _formal,
        soloDisponibles: _available,
      );
      if (mounted) setState(() => _results = values);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo consultar el catálogo. Volvé a intentarlo.';
          _results = [];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      onSubmitted: (_) => _search(),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Explorar Atena'),
      leading: Navigator.of(context).canPop()
          ? null
          : IconButton(
              tooltip: 'Volver al inicio',
              icon: const Icon(Icons.home_outlined),
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (_) => false),
            ),
    ),
    body: AtenaWorkspace(
      maxWidth: 1000,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const AtenaSectionHeader(
              eyebrow: 'Buscador público',
              title: 'Tu próxima oportunidad',
              subtitle:
                  'Instituciones, carreras y actividades. Explorá sin iniciar sesión.',
            ),
            _field(_query, 'Institución, carrera o actividad'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas las propuestas'),
                  selected: _category == null,
                  onSelected: (_) => setState(() {
                    _category = null;
                    _formal = '';
                  }),
                ),
                for (final c in CategoriaPublica.values)
                  ChoiceChip(
                    label: Text(
                      c == CategoriaPublica.formal
                          ? 'Educación formal'
                          : 'Actividades y formación',
                    ),
                    selected: _category == c,
                    onSelected: (_) => setState(() {
                      _category = c;
                      if (c == CategoriaPublica.actividades) _formal = '';
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CostoOferta?>(
              initialValue: _cost,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Costo de la oferta',
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos los costos')),
                DropdownMenuItem(
                  value: CostoOferta.gratuito,
                  child: Text('Sólo opciones gratuitas'),
                ),
                DropdownMenuItem(
                  value: CostoOferta.arancelado,
                  child: Text('Aranceladas'),
                ),
                DropdownMenuItem(
                  value: CostoOferta.consultar,
                  child: Text('Consultar / no informado'),
                ),
              ],
              onChanged: (v) => setState(() => _cost = v),
            ),
            ExpansionTile(
              title: const Text('Ubicación y más filtros'),
              children: [
                _field(_city, 'Localidad'),
                _field(_province, 'Provincia'),
                _field(_country, 'País'),
                _field(_schedule, 'Turno u horario publicado'),
                _field(_ages, 'Edades publicadas'),
                DropdownButtonFormField<String>(
                  initialValue: _modality,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Modalidad'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todas')),
                    DropdownMenuItem(
                      value: 'presencial',
                      child: Text('Presencial'),
                    ),
                    DropdownMenuItem(value: 'remoto', child: Text('Remoto')),
                    DropdownMenuItem(value: 'hibrido', child: Text('Híbrido')),
                  ],
                  onChanged: (v) => setState(() => _modality = v ?? ''),
                ),
                if (_category != CategoriaPublica.actividades)
                  DropdownButtonFormField<String>(
                    key: ValueKey(_formal),
                    initialValue: _formal,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Educación formal',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '',
                        child: Text('Todos los niveles'),
                      ),
                      DropdownMenuItem(
                        value: 'escolar',
                        child: Text('Escolar'),
                      ),
                      DropdownMenuItem(
                        value: 'superior',
                        child: Text('Superior / institutos'),
                      ),
                      DropdownMenuItem(
                        value: 'universidad',
                        child: Text('Universidad'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _formal = v ?? ''),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Con vacantes informadas'),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
                const Text(
                  'Filtramos por ubicación publicada. No calculamos distancias.',
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 16),
            const Text(_local),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (!_busy && _error == null && _results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No hay propuestas publicadas que coincidan. Probá otros filtros. Las instituciones deben publicar su catálogo en este dispositivo.',
                ),
              ),
            for (final i in _results)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.nombre,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        [
                          i.localidad,
                          i.provincia,
                          i.pais,
                        ].where((e) => e.isNotEmpty).join(' · '),
                      ),
                      for (final o in i.ofertas.take(3))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${o.nombre} · ${o.categoriaLabel}\n${o.costoLabel}${o.disponibles == null ? '' : ' · ${o.disponibles} vacantes informadas'}',
                          ),
                        ),
                      if (i.ofertas.length > 3)
                        Text('Y ${i.ofertas.length - 3} propuestas más'),
                      OutlinedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlumnoInstitucionPerfilPage.publica(
                                    institucionId: i.id,
                                  ),
                            ),
                          );
                          if (mounted) _search();
                        },
                        child: const Text('Ver institución y ofertas'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class CatalogoPublicoPerfil extends StatefulWidget {
  final String institucionId;
  const CatalogoPublicoPerfil({super.key, required this.institucionId});
  @override
  State<CatalogoPublicoPerfil> createState() => _CatalogoPublicoPerfilState();
}

class _CatalogoPublicoPerfilState extends State<CatalogoPublicoPerfil> {
  FichaPublicaInstitucion? _data;
  bool _recibeSolicitudes = false;
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await CatalogoPublicableService().buscarPublico();
      final matches = all.where((i) => i.id == widget.institucionId).toList();
      if (mounted) {
        final recibe = await PlanHabilitacionService.puedeRecibirPorId(
          widget.institucionId,
        );
        if (!mounted) return;
        setState(() {
          _data = matches.isEmpty ? null : matches.single;
          _recibeSolicitudes = recibe;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo consultar la publicación.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _photo(String value) {
    try {
      if (value.startsWith('https://')) {
        return Image.network(
          value,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      }
      return Image.memory(
        base64Decode(value.contains(',') ? value.split(',').last : value),
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Institución y ofertas')),
      body: AtenaWorkspace(
        maxWidth: 900,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (!_busy && i == null)
                Text(_error ?? 'Esta institución no tiene ofertas publicadas.'),
              if (i != null) ...[
                Text(
                  i.nombre,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Información publicada localmente por un operador autorizado. Sin verificación externa.',
                ),
                const SizedBox(height: 12),
                Text(
                  [
                    i.localidad,
                    i.provincia,
                    i.pais,
                  ].where((e) => e.isNotEmpty).join(' · '),
                ),
                if (i.direccion.isNotEmpty) Text(i.direccion),
                if (i.modalidad.isNotEmpty) Text('Modalidad: ${i.modalidad}'),
                if (i.descripcion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(i.descripcion),
                  ),
                if (i.telefono.isNotEmpty)
                  SelectableText('Contacto público: ${i.telefono}'),
                if (!_recibeSolicitudes)
                  const Text(PlanHabilitacionService.inscripcionNoHabilitada),
                for (final p in i.fotos.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _photo(p),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Ofertas de la institución',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final o in i.ofertas)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.nivelLabel,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            o.nombre,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${o.tipoFormal == 'universidad' ? 'Comisión / grupo' : 'Grupo'}: ${o.grupo}',
                          ),
                          if (o.horario.isNotEmpty)
                            Text('Horario: ${o.horario}'),
                          if (o.edades.isNotEmpty) Text('Edades: ${o.edades}'),
                          if (o.descripcion.isNotEmpty) Text(o.descripcion),
                          const SizedBox(height: 8),
                          Text(o.costoLabel),
                          Text(
                            !o.habilitada
                                ? 'Sin vacantes disponibles'
                                : o.disponibles == null
                                ? 'Disponibilidad a consultar'
                                : '${o.disponibles} vacantes informadas',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: !o.habilitada || !_recibeSolicitudes
                                ? null
                                : () async {
                                    await SolicitudPublicaIntent(
                                      institucionId: i.id,
                                      grupoId: o.id,
                                      categoria: o.categoria,
                                    ).continuar(context);
                                    if (mounted) await _load();
                                  },
                            icon: const Icon(Icons.how_to_reg_outlined),
                            label: const Text('Solicitar inscripción'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(_local),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
