import 'package:flutter/material.dart';

import '../../models/instituciones/grupo_curricular.dart';
import '../../services/alumno_instituciones_search_service.dart';
import '../../services/instituciones_helpers.dart' as ih;
import 'alumno_solicitar_vacante_page.dart';

class AlumnoVacantesCurricularesPage extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final String alumnoDocumento;
  final String ownerAccountId;
  final String perfilId;

  const AlumnoVacantesCurricularesPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.alumnoDocumento,
    required this.ownerAccountId,
    required this.perfilId,
  });

  @override
  State<AlumnoVacantesCurricularesPage> createState() =>
      _AlumnoVacantesCurricularesPageState();
}

enum _Disponibilidad { todas, disponibles, completas }
enum _Orden { recomendadas, gradoTurno, vacantesPrimero, horario }

class _AlumnoVacantesCurricularesPageState
    extends State<AlumnoVacantesCurricularesPage> {
  bool _cargando = true;
  String? _error;
  List<GrupoCurricular> _grupos = const [];

  final _gradoCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();

  TurnoCurricular? _turno;
  _Disponibilidad _disponibilidad = _Disponibilidad.disponibles;
  _Orden _orden = _Orden.recomendadas;
  bool _soloVacantes = true;

  AlumnoInstitucionSearchFilters? get _contextoBusqueda =>
      AlumnoInstitucionesSearchService.ultimaBusqueda;

  NivelCurricular? get _nivelPrioritario => _contextoBusqueda?.nivel;
  TurnoCurricular? get _turnoPrioritario => _contextoBusqueda?.turno;

  @override
  void initState() {
    super.initState();
    _turno = _turnoPrioritario;
    _soloVacantes = _contextoBusqueda?.soloConVacantes ?? true;
    _cargar();
  }

  @override
  void dispose() {
    _gradoCtrl.dispose();
    _horarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final id = widget.institucionId.trim();
      if (id.isEmpty) {
        throw StateError('La institución no tiene un identificador válido.');
      }

      final grupos = await ih.cargarGruposCurricularesInstitucion(id);

      if (!mounted) return;
      setState(() {
        _grupos = List<GrupoCurricular>.from(grupos);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _grupos = const [];
      });
    }
  }

  String _turnoLabel(TurnoCurricular turno) {
    switch (turno) {
      case TurnoCurricular.manana:
        return 'Mañana';
      case TurnoCurricular.tarde:
        return 'Tarde';
      case TurnoCurricular.noche:
        return 'Noche';
    }
  }

  int _turnoOrder(TurnoCurricular turno) {
    switch (turno) {
      case TurnoCurricular.manana:
        return 0;
      case TurnoCurricular.tarde:
        return 1;
      case TurnoCurricular.noche:
        return 2;
    }
  }

  List<String> _partes(String raw) => raw
      .trim()
      .split('•')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  String _grado(GrupoCurricular grupo) {
    final partes = _partes(grupo.nombreCurso);
    return partes.length > 1 ? partes[1] : grupo.nombreCurso.trim();
  }

  String _nivel(GrupoCurricular grupo) {
    final partes = _partes(grupo.nombreCurso);
    return partes.length > 1 ? partes.first : '';
  }

  String _horario(GrupoCurricular grupo) {
    final inicio = (grupo.horaInicio ?? '').trim();
    final fin = (grupo.horaFin ?? '').trim();
    if (inicio.isEmpty && fin.isEmpty) return 'Horario no informado';
    return '${inicio.isEmpty ? '--:--' : inicio} - ${fin.isEmpty ? '--:--' : fin}';
  }

  bool _esNivelPrioritario(GrupoCurricular grupo) {
    final nivel = _nivelPrioritario;
    if (nivel == null) return false;

    final buscado = nivel.name.toLowerCase();
    final actual = _nivel(grupo).toLowerCase();
    return actual.contains(buscado) || buscado.contains(actual);
  }

  bool _esTurnoPrioritario(GrupoCurricular grupo) =>
      _turnoPrioritario != null && grupo.turno == _turnoPrioritario;

  int _prioridadRecomendacion(GrupoCurricular grupo) {
    final turno = _esTurnoPrioritario(grupo);
    final nivel = _esNivelPrioritario(grupo);
    if (turno && nivel) return 0;
    if (turno) return 1;
    if (nivel) return 2;
    return 3;
  }

  bool _coincide(GrupoCurricular grupo) {
    final grado = _grado(grupo).toLowerCase();
    final nombre = grupo.nombreCurso.toLowerCase();
    final filtroGrado = _gradoCtrl.text.trim().toLowerCase();

    if (filtroGrado.isNotEmpty &&
        !grado.contains(filtroGrado) &&
        !nombre.contains(filtroGrado)) {
      return false;
    }

    if (_turno != null && grupo.turno != _turno) return false;

    if (_soloVacantes && !grupo.tieneCuposDisponibles) return false;

    if (_disponibilidad == _Disponibilidad.disponibles &&
        !grupo.tieneCuposDisponibles) {
      return false;
    }

    if (_disponibilidad == _Disponibilidad.completas &&
        grupo.tieneCuposDisponibles) {
      return false;
    }

    final filtroHorario = _horarioCtrl.text.trim().toLowerCase();
    if (filtroHorario.isNotEmpty &&
        !_horario(grupo).toLowerCase().contains(filtroHorario)) {
      return false;
    }

    return true;
  }

  int _gradoCompare(String a, String b) {
    final matchA = RegExp(r'^(\d+)').firstMatch(a.trim());
    final matchB = RegExp(r'^(\d+)').firstMatch(b.trim());

    if (matchA != null && matchB != null) {
      final numeroA = int.tryParse(matchA.group(1)!) ?? 0;
      final numeroB = int.tryParse(matchB.group(1)!) ?? 0;
      final comparacion = numeroA.compareTo(numeroB);
      if (comparacion != 0) return comparacion;
    }

    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  List<GrupoCurricular> get _filtrados {
    final lista = _grupos.where(_coincide).toList();

    lista.sort((a, b) {
      if (_orden == _Orden.recomendadas) {
        final prioridadA = _prioridadRecomendacion(a);
        final prioridadB = _prioridadRecomendacion(b);
        if (prioridadA != prioridadB) return prioridadA.compareTo(prioridadB);

        final vacanteA = a.tieneCuposDisponibles ? 0 : 1;
        final vacanteB = b.tieneCuposDisponibles ? 0 : 1;
        if (vacanteA != vacanteB) return vacanteA.compareTo(vacanteB);
      }

      if (_orden == _Orden.vacantesPrimero) {
        final comparacion = b.cuposDisponibles.compareTo(a.cuposDisponibles);
        if (comparacion != 0) return comparacion;
      }

      if (_orden == _Orden.horario) {
        final comparacion = (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
        if (comparacion != 0) return comparacion;
      }

      var comparacion = _gradoCompare(_grado(a), _grado(b));
      if (comparacion != 0) return comparacion;

      comparacion = _turnoOrder(a.turno).compareTo(_turnoOrder(b.turno));
      if (comparacion != 0) return comparacion;

      comparacion = b.cuposDisponibles.compareTo(a.cuposDisponibles);
      if (comparacion != 0) return comparacion;

      return (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
    });

    return lista;
  }

  List<GrupoCurricular> get _recomendadas => _filtrados
      .where((grupo) => _prioridadRecomendacion(grupo) < 3)
      .toList();

  List<GrupoCurricular> get _otras => _filtrados
      .where((grupo) => _prioridadRecomendacion(grupo) == 3)
      .toList();

  void _limpiarFiltros() {
    setState(() {
      _gradoCtrl.clear();
      _horarioCtrl.clear();
      _turno = _turnoPrioritario;
      _disponibilidad = _Disponibilidad.disponibles;
      _orden = _Orden.recomendadas;
      _soloVacantes = _contextoBusqueda?.soloConVacantes ?? true;
    });
  }

  Future<void> _abrirFiltros() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajustar búsqueda',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Podés afinar las vacantes sin perder las recomendaciones iniciales.'),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _gradoCtrl,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Grado, sala o año',
                        prefixIcon: const Icon(Icons.school_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TurnoCurricular?>(
                      value: _turno,
                      decoration: InputDecoration(
                        labelText: 'Turno',
                        prefixIcon: const Icon(Icons.wb_sunny_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<TurnoCurricular?>(
                          value: null,
                          child: Text('Todos los turnos'),
                        ),
                        ...TurnoCurricular.values.map(
                          (turno) => DropdownMenuItem<TurnoCurricular?>(
                            value: turno,
                            child: Text(_turnoLabel(turno)),
                          ),
                        ),
                      ],
                      onChanged: (value) => setSheetState(() => _turno = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _horarioCtrl,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Horario',
                        hintText: 'Ej.: 08:00 o 13:30',
                        prefixIcon: const Icon(Icons.schedule_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<_Disponibilidad>(
                      value: _disponibilidad,
                      decoration: InputDecoration(
                        labelText: 'Disponibilidad',
                        prefixIcon: const Icon(Icons.event_seat_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: _Disponibilidad.todas, child: Text('Todas')),
                        DropdownMenuItem(value: _Disponibilidad.disponibles, child: Text('Con vacantes')),
                        DropdownMenuItem(value: _Disponibilidad.completas, child: Text('Sin vacantes')),
                      ],
                      onChanged: (value) => setSheetState(
                        () => _disponibilidad = value ?? _Disponibilidad.disponibles,
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _soloVacantes,
                      title: const Text('Mostrar solo vacantes disponibles'),
                      onChanged: (value) => setSheetState(() => _soloVacantes = value),
                    ),
                    DropdownButtonFormField<_Orden>(
                      value: _orden,
                      decoration: InputDecoration(
                        labelText: 'Ordenar',
                        prefixIcon: const Icon(Icons.sort),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: _Orden.recomendadas, child: Text('Primero las recomendadas')),
                        DropdownMenuItem(value: _Orden.gradoTurno, child: Text('Grado → turno → vacantes')),
                        DropdownMenuItem(value: _Orden.vacantesPrimero, child: Text('Más vacantes primero')),
                        DropdownMenuItem(value: _Orden.horario, child: Text('Por horario')),
                      ],
                      onChanged: (value) => setSheetState(
                        () => _orden = value ?? _Orden.recomendadas,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _limpiarFiltros();
                              setSheetState(() {});
                            },
                            child: const Text('Restablecer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            child: const Text('Aplicar filtros'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result == true && mounted) setState(() {});
  }

  Future<void> _solicitar(GrupoCurricular grupo) async {
    if (!grupo.tieneCuposDisponibles) {
      _mensaje('Esta vacante no tiene cupos disponibles.');
      return;
    }

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AlumnoSolicitarVacantePage(
          alumnoDocumento: widget.alumnoDocumento,
          institucionId: widget.institucionId.trim(),
          institucionNombre: widget.institucionNombre,
          actividadNombre: grupo.nombreCurso,
          esCurricular: true,
          grupoCurricularId: grupo.id,
          aula: grupo.nombreCurso,
          turno:
              '${_turnoLabel(grupo.turno)} • ${(grupo.horaInicio ?? '').trim()}-${(grupo.horaFin ?? '').trim()}',
          ownerAccountId: widget.ownerAccountId,
          perfilId: widget.perfilId,
        ),
      ),
    );

    if (mounted && resultado == true) await _cargar();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _chip(String label, {bool emphasized = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          color: emphasized ? cs.onPrimaryContainer : null,
        ),
      ),
    );
  }

  Widget _contextoCard() {
    final contexto = _contextoBusqueda;
    if (contexto == null) return const SizedBox.shrink();

    final chips = <Widget>[];
    if (contexto.nivel != null) {
      chips.add(_chip('Nivel: ${_nivelLabel(contexto.nivel!)}', emphasized: true));
    }
    if (contexto.turno != null) {
      chips.add(_chip('Turno: ${_turnoLabel(contexto.turno!)}', emphasized: true));
    }
    if (contexto.soloConVacantes) {
      chips.add(_chip('Con vacantes', emphasized: true));
    }
    if (contexto.ciudad != null && contexto.ciudad!.trim().isNotEmpty) {
      chips.add(_chip(contexto.ciudad!));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(.42),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu búsqueda',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 9),
          Wrap(spacing: 7, runSpacing: 7, children: chips),
          const SizedBox(height: 9),
          const Text('Estas condiciones se usan para priorizar las vacantes que más se parecen a lo que buscabas.'),
        ],
      ),
    );
  }

  String _nivelLabel(NivelCurricular nivel) {
    switch (nivel) {
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

  Widget _card(GrupoCurricular grupo, {bool recomendada = false}) {
    final disponible = grupo.tieneCuposDisponibles;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: recomendada ? cs.primary.withOpacity(.28) : cs.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recomendada)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'RECOMENDADA PARA VOS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      if (_nivel(grupo).isNotEmpty)
                        Text(
                          _nivel(grupo),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      Text(
                        _grado(grupo),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                _chip(disponible ? '${grupo.cuposDisponibles} vacantes' : 'Sin vacantes', emphasized: disponible),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(_turnoLabel(grupo.turno)),
                _chip(_horario(grupo)),
                _chip('${grupo.cuposOcupados}/${grupo.cuposTotales} ocupados'),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: disponible ? () => _solicitar(grupo) : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(disponible ? 'Solicitar esta vacante' : 'Curso completo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(
            'No encontramos vacantes con estos filtros',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Probá ampliar la búsqueda para ver otras opciones dentro de la institución.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _limpiarFiltros,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Restablecer filtros'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final recomendadas = _recomendadas;
    final otras = _otras;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacantes disponibles'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      Text(
                        widget.institucionNombre,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      const Text('Explorá las opciones disponibles y elegí el curso que mejor se adapte a tu búsqueda.'),
                      const SizedBox(height: 16),
                      _contextoCard(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${filtrados.length} opciones',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _abrirFiltros,
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Filtrar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filtrados.isEmpty)
                        _emptyState()
                      else if (_orden == _Orden.recomendadas && recomendadas.isNotEmpty) ...[
                        Text(
                          'Recomendadas para tu búsqueda',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        ...recomendadas.map(
                          (grupo) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _card(grupo, recomendada: true),
                          ),
                        ),
                        if (otras.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Otras opciones disponibles',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          ...otras.map(
                            (grupo) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _card(grupo),
                            ),
                          ),
                        ],
                      ] else ...[
                        ...filtrados.map(
                          (grupo) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _card(grupo),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
