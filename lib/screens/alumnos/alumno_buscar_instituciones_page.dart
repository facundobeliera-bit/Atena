import '../../ui/catalogo_publico.dart';
import '../../models/catalogo/ficha_publica.dart';
import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_workspace.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/grupo_curricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/alumno_instituciones_search_service.dart';
import 'alumno_seleccion_grupo_extracurricular_page.dart';
import 'alumno_institucion_perfil_page.dart';
import 'alumno_vacantes_curriculares_page.dart';

class AlumnoBuscarInstitucionesPage extends StatefulWidget {
  final bool esPublica;
  final String textoInicial, tipoFormalInicial;
  final CategoriaPublica? categoriaInicial;
  final CostoOferta? costoInicial;
  final String alumnoDni;
  final String ownerAccountId;
  final String perfilId;

  const AlumnoBuscarInstitucionesPage({
    super.key,
    required this.alumnoDni,
    required this.ownerAccountId,
    required this.perfilId,
  }) : esPublica = false,
       textoInicial = '',
       tipoFormalInicial = '',
       categoriaInicial = null,
       costoInicial = null;

  const AlumnoBuscarInstitucionesPage.publica({
    super.key,
    this.textoInicial = '',
    this.tipoFormalInicial = '',
    this.categoriaInicial,
    this.costoInicial,
  }) : esPublica = true,
       alumnoDni = '',
       ownerAccountId = '',
       perfilId = '';

  @override
  State<AlumnoBuscarInstitucionesPage> createState() =>
      _AlumnoBuscarInstitucionesPageState();
}

class _AlumnoBuscarInstitucionesPageState
    extends State<AlumnoBuscarInstitucionesPage> {
  final _nombreCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();

  AlumnoBusquedaScope? _scope;
  String? _pais;
  String? _provincia;
  NivelCurricular? _nivel;
  TurnoCurricular? _turno;
  TipoInstitucion? _tipoInstitucion;
  ModalidadCursado? _modalidad;
  final Set<BloqueExtracurricular> _bloques = {};
  bool _soloVacantes = false;
  AlumnoPrecioFiltro _precio = AlumnoPrecioFiltro.todos;

  bool _cargando = false;
  String? _error;
  List<AlumnoInstitucionSearchResult> _resultados = const [];

  static const List<String> _paises = [
    'Argentina',
    'Bolivia',
    'Brasil',
    'Chile',
    'Colombia',
    'España',
    'México',
    'Paraguay',
    'Perú',
    'Uruguay',
  ];

  static const List<String> _provinciasArgentina = [
    'Buenos Aires',
    'Catamarca',
    'Chaco',
    'Chubut',
    'Córdoba',
    'Corrientes',
    'Entre Ríos',
    'Formosa',
    'Jujuy',
    'La Pampa',
    'La Rioja',
    'Mendoza',
    'Misiones',
    'Neuquén',
    'Río Negro',
    'Salta',
    'San Juan',
    'San Luis',
    'Santa Cruz',
    'Santa Fe',
    'Santiago del Estero',
    'Tierra del Fuego, Antártida e Islas del Atlántico Sur',
    'Tucumán',
    'Ciudad Autónoma de Buenos Aires',
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_onFieldChanged);
    _ciudadCtrl.addListener(_onFieldChanged);
    _regionCtrl.addListener(_onFieldChanged);
    _edadCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    _regionCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_scope == null || _cargando) return;
    setState(() {});
  }

  void _seleccionarScope(AlumnoBusquedaScope scope) {
    setState(() {
      _scope = scope;
      _nivel = null;
      _turno = null;
      _tipoInstitucion = null;
      _modalidad = null;
      _bloques.clear();
      _soloVacantes = false;
      _precio = AlumnoPrecioFiltro.todos;
      _error = null;
      _resultados = const [];
    });
  }

  Future<void> _abrirFiltroBloques() async {
    final tmp = Set<BloqueExtracurricular>.from(_bloques);
    final result = await showModalBottomSheet<Set<BloqueExtracurricular>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Categoría de actividad',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setSheetState(tmp.clear),
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final bloque in BloqueExtracurricularX.ordered())
                  CheckboxListTile(
                    value: tmp.contains(bloque),
                    title: Text(bloque.label),
                    subtitle: Text(bloque.descripcionCorta),
                    onChanged: (value) => setSheetState(() {
                      if (value == true)
                        tmp.add(bloque);
                      else
                        tmp.remove(bloque);
                    }),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, tmp),
                    child: const Text('Aplicar módulos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _bloques
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _buscar() async {
    final scope = _scope;
    if (scope == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final edad = int.tryParse(_edadCtrl.text.trim());
      final region = _regionCtrl.text.trim();
      final results = await AlumnoInstitucionesSearchService.search(
        AlumnoInstitucionSearchFilters(
          scope: scope,
          texto: _nombreCtrl.text.trim(),
          pais: _pais,
          provincia: _provincia ?? (region.isEmpty ? null : region),
          ciudad: _ciudadCtrl.text.trim().isEmpty
              ? null
              : _ciudadCtrl.text.trim(),
          nivel: _nivel,
          turno: _turno,
          tipoInstitucion: _tipoInstitucion,
          modalidadCursado: _modalidad,
          bloques: Set<BloqueExtracurricular>.from(_bloques),
          edad: edad,
          soloConVacantes: _soloVacantes,
          precio: _precio,
        ),
      );
      if (!mounted) return;
      setState(() {
        _resultados = results;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _resultados = const [];
      });
    }
  }

  String _scopeDescription(AlumnoBusquedaScope scope) {
    if (scope == AlumnoBusquedaScope.curricular) {
      return AtenaOfferLabels.formalDescription;
    }
    return AtenaOfferLabels.activitiesDescription;
  }

  String _levelLabel(NivelCurricular value) {
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

  String _turnoLabel(TurnoCurricular value) {
    switch (value) {
      case TurnoCurricular.manana:
        return 'Mañana';
      case TurnoCurricular.tarde:
        return 'Tarde';
      case TurnoCurricular.noche:
        return 'Noche';
    }
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

  Widget _scopeCard({
    required AlumnoBusquedaScope scope,
    required IconData icon,
  }) {
    final selected = _scope == scope;
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _seleccionarScope(scope),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scope == AlumnoBusquedaScope.curricular
                          ? AtenaOfferLabels.formal
                          : AtenaOfferLabels.activities,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_scopeDescription(scope)),
                  ],
                ),
              ),
              Radio<AlumnoBusquedaScope>(
                value: scope,
                groupValue: _scope,
                onChanged: (_) => _seleccionarScope(scope),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle)],
        ],
      ),
    ),
  );

  Widget _buildFilters() {
    final scope = _scope;
    if (scope == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    InputDecoration inputDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    return Column(
      children: [
        _sectionTitle('Datos de la institución'),
        TextField(
          controller: _nombreCtrl,
          decoration: inputDecoration(
            'Institución, actividad o programa',
            Icons.search,
          ),
        ),
        const SizedBox(height: 10),
        _sectionTitle(
          'Ubicación',
          subtitle: 'Elegí un país, provincia y localidad.',
        ),
        DropdownButtonFormField<String>(
          value: _pais,
          isExpanded: true,
          decoration: inputDecoration('País', Icons.public),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Todos los países'),
            ),
            ..._paises.map(
              (pais) =>
                  DropdownMenuItem<String>(value: pais, child: Text(pais)),
            ),
          ],
          onChanged: (value) => setState(() {
            _pais = value;
            _provincia = null;
            _regionCtrl.clear();
          }),
        ),
        const SizedBox(height: 10),
        const Text(
          'Buscá por país, provincia y localidad. La búsqueda por distancia estará disponible cuando el catálogo tenga coordenadas verificadas.',
        ),
        const SizedBox(height: 10),
        if (_pais == null || _pais == 'Argentina')
          DropdownButtonFormField<String>(
            value: _provincia,
            isExpanded: true,
            decoration: inputDecoration('Provincia', Icons.map_outlined),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todas las provincias'),
              ),
              ..._provinciasArgentina.map(
                (p) => DropdownMenuItem<String>(value: p, child: Text(p)),
              ),
            ],
            onChanged: (value) => setState(() => _provincia = value),
          )
        else
          TextField(
            controller: _regionCtrl,
            decoration: inputDecoration(
              'Provincia, estado o región',
              Icons.map_outlined,
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _ciudadCtrl,
          decoration: inputDecoration(
            'Localidad o ciudad',
            Icons.location_city,
          ),
        ),
        _sectionTitle('Filtros específicos'),
        if (scope == AlumnoBusquedaScope.curricular) ...[
          DropdownButtonFormField<NivelCurricular>(
            value: _nivel,
            isExpanded: true,
            decoration: inputDecoration(
              'Nivel educativo',
              Icons.school_outlined,
            ),
            items: [
              const DropdownMenuItem<NivelCurricular>(
                value: null,
                child: Text('Todos los niveles'),
              ),
              ...NivelCurricular.values.map(
                (e) => DropdownMenuItem(value: e, child: Text(_levelLabel(e))),
              ),
            ],
            onChanged: (value) => setState(() => _nivel = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<TurnoCurricular>(
            value: _turno,
            isExpanded: true,
            decoration: inputDecoration('Turno', Icons.wb_sunny_outlined),
            items: [
              const DropdownMenuItem<TurnoCurricular>(
                value: null,
                child: Text('Todos los turnos'),
              ),
              ...TurnoCurricular.values.map(
                (e) => DropdownMenuItem(value: e, child: Text(_turnoLabel(e))),
              ),
            ],
            onChanged: (value) => setState(() => _turno = value),
          ),
          const SizedBox(height: 10),
          const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Ciclo educativo',
              border: OutlineInputBorder(),
            ),
            child: Text(
              'El ciclo curricular todavía no está almacenado como dato canónico independiente en el perfil institucional.',
            ),
          ),
        ] else ...[
          InkWell(
            onTap: _abrirFiltroBloques,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: inputDecoration(
                'Categoría de actividad',
                Icons.category_outlined,
              ),
              child: Text(
                _bloques.isEmpty
                    ? 'Todos los módulos'
                    : _bloques.map((e) => e.label).join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _edadCtrl,
            keyboardType: TextInputType.number,
            decoration: inputDecoration(
              'Edad',
              Icons.cake_outlined,
            ).copyWith(hintText: 'Ejemplo: 12'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AlumnoPrecioFiltro>(
            value: _precio,
            isExpanded: true,
            decoration:
                inputDecoration(
                  'Costo de la actividad',
                  Icons.payments_outlined,
                ).copyWith(
                  helperText:
                      'No depende del plan de Atena. Los precios no informados quedan fuera del filtro.',
                  helperMaxLines: 4,
                ),
            items: AlumnoPrecioFiltro.values
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e == AlumnoPrecioFiltro.todos
                          ? 'Todos los valores'
                          : e == AlumnoPrecioFiltro.gratuitos
                          ? 'Gratuitos'
                          : 'Con costo',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _precio = value ?? AlumnoPrecioFiltro.todos),
          ),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField<TipoInstitucion>(
          value: _tipoInstitucion,
          isExpanded: true,
          decoration: inputDecoration(
            'Tipo de institución',
            Icons.account_balance_outlined,
          ),
          items: [
            const DropdownMenuItem<TipoInstitucion>(
              value: null,
              child: Text('Todos los tipos'),
            ),
            ...TipoInstitucion.values.map(
              (e) => DropdownMenuItem(value: e, child: Text(_tipoLabel(e))),
            ),
          ],
          onChanged: (value) => setState(() => _tipoInstitucion = value),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<ModalidadCursado>(
          value: _modalidad,
          isExpanded: true,
          decoration: inputDecoration(
            'Modalidad de cursado',
            Icons.devices_outlined,
          ),
          items: [
            const DropdownMenuItem<ModalidadCursado>(
              value: null,
              child: Text('Todas las modalidades'),
            ),
            ...ModalidadCursado.values.map(
              (e) =>
                  DropdownMenuItem(value: e, child: Text(_modalidadLabel(e))),
            ),
          ],
          onChanged: (value) => setState(() => _modalidad = value),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _soloVacantes,
          title: const Text(
            'Mostrar solamente propuestas con vacantes disponibles',
          ),
          onChanged: (value) => setState(() => _soloVacantes = value ?? false),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _cargando ? null : _buscar,
            icon: const Icon(Icons.search),
            label: Text(_cargando ? 'Buscando...' : 'Buscar instituciones'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Los filtros se aplican sobre los datos actualmente registrados en los perfiles de Atena.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildResultCard(AlumnoInstitucionSearchResult result) {
    final inst = result.institucion;
    final cs = Theme.of(context).colorScheme;
    final extra = inst.actividadesExtracurriculares
        .where((a) => a.activa)
        .toList();
    final bloques = extra.map((a) => a.bloque).toSet().toList();
    final niveles =
        inst.planConfig?.niveles
            .where((e) => e.habilitado)
            .map((e) => _levelLabel(e.nivel))
            .toList() ??
        const <String>[];
    final location = [
      if (inst.ciudad.trim().isNotEmpty) inst.ciudad.trim(),
      if (inst.provincia.trim().isNotEmpty) inst.provincia.trim(),
    ].join(', ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    color: cs.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    inst.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ver perfil',
                  onPressed: () => _mostrarInstitucion(inst),
                  icon: const Icon(Icons.account_balance_outlined),
                ),
              ],
            ),
            if (location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(location),
              ),
            if (result.distanciaKm != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${result.distanciaKm!.toStringAsFixed(1)} km de distancia',
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (inst.curricular)
                  const Chip(label: Text(AtenaOfferLabels.formal)),
                if (inst.extracurricular)
                  const Chip(label: Text(AtenaOfferLabels.activities)),
                Chip(label: Text(_tipoLabel(inst.tipoInstitucion))),
                Chip(label: Text(_modalidadLabel(inst.modalidad))),
              ],
            ),
            if (niveles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Niveles: ${niveles.join(' • ')}'),
            ],
            if (extra.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final activity in extra.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${activity.nombre} · ${activity.precio?.trim().isNotEmpty == true ? activity.precio : 'Costo a consultar'}',
                  ),
                ),
              if (extra.length > 3)
                Text('Y ${extra.length - 3} propuestas más en el perfil'),
            ],
            if (bloques.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Módulos: ${bloques.map((e) => e.label).join(' • ')}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _mostrarInstitucion(inst),
                  icon: const Icon(Icons.account_balance_outlined),
                  label: const Text('Ver perfil'),
                ),
                FilledButton.icon(
                  onPressed: () => _solicitarVacante(inst),
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: const Text('Solicitar vacante'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _solicitarVacante(Institucion inst) async {
    if (!inst.curricular && !inst.extracurricular) return;
    if (inst.curricular && inst.extracurricular) {
      final choice = await showModalBottomSheet<AlumnoBusquedaScope>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Solicitar vacante',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text('Elegí qué tipo de propuesta querés explorar.'),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pop(ctx, AlumnoBusquedaScope.curricular),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text(AtenaOfferLabels.formal),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pop(ctx, AlumnoBusquedaScope.extracurricular),
                  icon: const Icon(Icons.category_outlined),
                  label: const Text(AtenaOfferLabels.activities),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || choice == null) return;
      if (choice == AlumnoBusquedaScope.curricular)
        await _abrirCurricular(inst);
      else
        await _abrirExtracurricular(inst);
      return;
    }
    if (inst.curricular)
      await _abrirCurricular(inst);
    else
      await _abrirExtracurricular(inst);
  }

  Future<void> _abrirCurricular(Institucion inst) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlumnoVacantesCurricularesPage(
          institucionId: inst.id,
          institucionNombre: inst.nombre,
          alumnoDocumento: widget.alumnoDni,
          ownerAccountId: widget.ownerAccountId,
          perfilId: widget.perfilId,
        ),
      ),
    );
  }

  Future<void> _abrirExtracurricular(Institucion inst) async {
    final bloqueInicial = _bloques.length == 1 ? _bloques.first : null;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlumnoSeleccionGrupoExtracurricularPage(
          institucionId: inst.id,
          institucionNombre: inst.nombre,
          alumnoDocumento: widget.alumnoDni,
          ownerAccountId: widget.ownerAccountId,
          perfilId: widget.perfilId,
          bloqueInicial: bloqueInicial,
          filtroInicial: _nombreCtrl.text.trim(),
        ),
      ),
    );
  }

  void _mostrarInstitucion(Institucion inst) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AlumnoInstitucionPerfilPage(
          institucion: inst,
          onSolicitarVacante: () => _solicitarVacante(inst),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.esPublica) {
      return CatalogoPublicoBusqueda(
        textoInicial: widget.textoInicial,
        categoriaInicial: widget.categoriaInicial,
        costoInicial: widget.costoInicial,
        tipoFormalInicial: widget.tipoFormalInicial,
      );
    }
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.alumnoBuscarInstitucionesTitle)),
      body: AtenaWorkspace(
        maxWidth: 1120,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const AtenaSectionHeader(
                eyebrow: 'Explorá tus posibilidades',
                title: '¿Qué estás buscando?',
                subtitle:
                    'Encontrá educación formal, actividades y formación. Una institución puede ofrecer ambas.',
              ),
              const AtenaLocalNotice(),
              AtenaResponsiveGrid(
                minWidth: 420,
                children: [
                  _scopeCard(
                    scope: AlumnoBusquedaScope.curricular,
                    icon: Icons.school_outlined,
                  ),
                  _scopeCard(
                    scope: AlumnoBusquedaScope.extracurricular,
                    icon: Icons.category_outlined,
                  ),
                ],
              ),
              if (_scope != null) ...[
                const Divider(height: 28),
                _buildFilters(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_cargando)
                  const Center(child: CircularProgressIndicator())
                else if (_error == null && _resultados.isEmpty)
                  const AtenaEmptyState(
                    title: 'Todavía no encontramos opciones',
                    message:
                        'Probá otro nombre, una localidad cercana o menos filtros. Solo mostramos información registrada en esta instalación.',
                  )
                else if (_error == null) ...[
                  Text(
                    'Instituciones encontradas: ${_resultados.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AtenaResponsiveGrid(
                    minWidth: 480,
                    children: [
                      for (final result in _resultados)
                        _buildResultCard(result),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
