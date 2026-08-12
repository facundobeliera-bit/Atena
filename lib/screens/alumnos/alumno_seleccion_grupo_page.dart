// lib/screens/alumnos/alumno_seleccion_grupo_page.dart

import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/alumno_service.dart';
import '../../services/instituciones_helpers.dart' as ih;
import '../../models/instituciones/instituciones_integrado.dart';
import '../../models/instituciones/grupo_curricular.dart';
import '../../models/alumnos/alumnos_integrados.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/extracurriculares/actividad_extracurricular.dart';
import 'alumno_solicitar_vacante_page.dart';

enum ModoSolicitudUI { curricular, extracurricular }

class AlumnoSeleccionGrupoPage extends StatefulWidget {
  final String institucionId;
  final String? institucionNombre;
  final String alumnoDocumento;
  final String ownerAccountId;
  final String perfilId;

  const AlumnoSeleccionGrupoPage({
    super.key,
    required this.institucionId,
    required this.alumnoDocumento,
    this.institucionNombre,
    required this.ownerAccountId,
    required this.perfilId,
  });

  @override
  State<AlumnoSeleccionGrupoPage> createState() =>
      _AlumnoSeleccionGrupoPageState();
}

class _AlumnoSeleccionGrupoPageState extends State<AlumnoSeleccionGrupoPage> {
  bool _cargando = true;
  Institucion? _perfilInst;
  Alumno? _alumno;

  ModoSolicitudUI _modo = ModoSolicitudUI.curricular;

  final Map<TurnoCurricular, List<GrupoCurricular>> _gruposPorTurno = {
    TurnoCurricular.manana: <GrupoCurricular>[],
    TurnoCurricular.tarde: <GrupoCurricular>[],
    TurnoCurricular.noche: <GrupoCurricular>[],
  };

  GrupoCurricular? _grupoSeleccionado;
  String? _curricularRadioValue;

  // Filtros de vacante: TODOS son opcionales.
  TurnoCurricular? _filtroTurno;
  String _filtroCurso = '';
  final TextEditingController _cursoController = TextEditingController();

  bool _cargandoExtra = false;
  bool _extraCargadoUnaVez = false;
  bool _extraCargandoAhora = false;
  BloqueExtracurricular? _bloqueSeleccionado;
  List<ActividadExtracurricular> _actividadesExtra =
      <ActividadExtracurricular>[];
  ActividadExtracurricular? _actividadSeleccionada;
  String? _extraRadioValue;

  String get _owner => widget.ownerAccountId.trim();
  String get _perfilId => widget.perfilId.trim();
  String get _instId => widget.institucionId.trim();

  @override
  void initState() {
    super.initState();
    _cursoController.addListener(() {
      final value = _cursoController.text.trim();
      if (value == _filtroCurso) return;
      if (!mounted) return;
      setState(() => _filtroCurso = value);
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _cursoController.dispose();
    super.dispose();
  }

  String _nombreGrupo(GrupoCurricular g) {
    final n = g.nombreCurso.trim();
    return n.isEmpty ? g.toString() : n;
  }

  bool _tieneCupo(GrupoCurricular g) => g.tieneCuposDisponibles;

  String _labelTurnoCurricular(AppLocalizations l, TurnoCurricular t) {
    switch (t) {
      case TurnoCurricular.manana:
        return l.commonShiftMorning;
      case TurnoCurricular.tarde:
        return l.commonShiftAfternoon;
      case TurnoCurricular.noche:
        return l.commonShiftNight;
    }
  }

  String _turnoUiForGrupo(AppLocalizations l, GrupoCurricular g) {
    final base = _labelTurnoCurricular(l, g.turno).trim();
    final hi = (g.horaInicio ?? '').trim();
    final hf = (g.horaFin ?? '').trim();
    if (hi.isEmpty && hf.isEmpty) return base;
    return '$base • ${hi.isNotEmpty ? hi : '--:--'}-${hf.isNotEmpty ? hf : '--:--'}';
  }

  String _subtitleCurricular(AppLocalizations l, GrupoCurricular g) {
    final turnoTxt = _turnoUiForGrupo(l, g);
    final slotsTxt = l.alumnoSeleccionGrupoSlotsAvailable(g.cuposDisponibles);
    if (_tieneCupo(g)) return '$turnoTxt\n$slotsTxt';
    return '$turnoTxt\n$slotsTxt\n${l.alumnoSeleccionGrupoNoSlotsShort}';
  }

  void _snack(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  List<BloqueExtracurricular> _orderedBloques() =>
      BloqueExtracurricularX.ordered();

  ActividadExtracurricular? _findActividadById(String id) {
    final x = id.trim();
    if (x.isEmpty) return null;
    for (final a in _actividadesExtra) {
      if (a.id == x) return a;
    }
    return null;
  }

  GrupoCurricular? _findGrupoById(String id) {
    for (final entry in _gruposPorTurno.entries) {
      for (final g in entry.value) {
        if (g.id == id) return g;
      }
    }
    return null;
  }

  List<GrupoCurricular> get _gruposFiltrados {
    final texto = _filtroCurso.toLowerCase();
    final todos = <GrupoCurricular>[];
    for (final lista in _gruposPorTurno.values) {
      todos.addAll(lista);
    }

    final filtrados = todos.where((g) {
      if (_filtroTurno != null && g.turno != _filtroTurno) return false;
      if (texto.isNotEmpty &&
          !_nombreGrupo(g).toLowerCase().contains(texto)) {
        return false;
      }
      return true;
    }).toList();

    filtrados.sort((a, b) {
      final c = _nombreGrupo(a).toLowerCase().compareTo(
            _nombreGrupo(b).toLowerCase(),
          );
      if (c != 0) return c;
      final t = a.turno.index.compareTo(b.turno.index);
      if (t != 0) return t;
      return a.id.compareTo(b.id);
    });
    return filtrados;
  }

  void _limpiarFiltrosVacante() {
    if (!mounted) return;
    setState(() {
      _filtroTurno = null;
      _filtroCurso = '';
      _cursoController.clear();
      _curricularRadioValue = null;
      _grupoSeleccionado = null;
    });
  }

  void _seleccionarCurricularRadio(String grupoId) {
    final l = AppLocalizations.of(context);
    final g = _findGrupoById(grupoId);
    if (g == null) return;
    if (!_tieneCupo(g)) {
      _snack(l.alumnoSeleccionGrupoNoSlotsShort);
      return;
    }
    setState(() {
      _grupoSeleccionado = g;
      _curricularRadioValue = grupoId;
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    final l = AppLocalizations.of(context);

    try {
      if (_owner.isEmpty || _perfilId.isEmpty) {
        setState(() => _cargando = false);
        _snack(l.commonInvalidSession);
        return;
      }
      if (_instId.isEmpty) {
        setState(() => _cargando = false);
        _snack(l.alumnoSeleccionGrupoInstitutionLoadFailed);
        return;
      }

      dev.log('[ATENA][ALUMNO][SEL_GRUPO] cargarDatos instId=$_instId');
      final institucion = await ih.cargarInstitucionPorId(_instId);
      final alumno = await AlumnoService.instance.getPerfilAlumnoByPerfilId(
        ownerAccountId: _owner,
        perfilId: _perfilId,
      );
      final gruposAll = await ih.cargarGruposCurricularesInstitucion(_instId);

      final grupos = List<GrupoCurricular>.from(gruposAll)
        ..sort((a, b) {
          final c = _nombreGrupo(a).toLowerCase().compareTo(
                _nombreGrupo(b).toLowerCase(),
              );
          if (c != 0) return c;
          final h = (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
          if (h != 0) return h;
          return a.id.compareTo(b.id);
        });

      final porTurno = <TurnoCurricular, List<GrupoCurricular>>{
        TurnoCurricular.manana: <GrupoCurricular>[],
        TurnoCurricular.tarde: <GrupoCurricular>[],
        TurnoCurricular.noche: <GrupoCurricular>[],
      };
      for (final g in grupos) {
        porTurno[g.turno]!.add(g);
      }

      if (!mounted) return;
      setState(() {
        _perfilInst = institucion;
        _alumno = alumno;
        _gruposPorTurno[TurnoCurricular.manana] = porTurno[TurnoCurricular.manana]!;
        _gruposPorTurno[TurnoCurricular.tarde] = porTurno[TurnoCurricular.tarde]!;
        _gruposPorTurno[TurnoCurricular.noche] = porTurno[TurnoCurricular.noche]!;
        _filtroTurno = null;
        _filtroCurso = '';
        _cursoController.clear();
        _curricularRadioValue = null;
        _grupoSeleccionado = null;
        _cargando = false;
      });

      if (grupos.isEmpty) {
        dev.log('[ATENA][ALUMNO][SEL_GRUPO] WARNING: institución sin grupos: $_instId');
      }
    } catch (e) {
      dev.log('[ATENA][ALUMNO][SEL_GRUPO] ERROR cargarDatos: $e', error: e);
      if (!mounted) return;
      setState(() {
        _perfilInst = null;
        _alumno = null;
        _gruposPorTurno.updateAll((_, __) => <GrupoCurricular>[]);
        _curricularRadioValue = null;
        _grupoSeleccionado = null;
        _cargando = false;
      });
      _snack(l.alumnoSeleccionGrupoLoadError('$e'));
    }
  }

  Future<void> _cargarExtracurricularesSiHaceFalta() async {
    if (_extraCargadoUnaVez) return;
    await _refrescarExtracurriculares();
  }

  Future<void> _refrescarExtracurriculares() async {
    if (!mounted || _extraCargandoAhora) return;
    _extraCargandoAhora = true;
    setState(() {
      _cargandoExtra = true;
      _actividadSeleccionada = null;
      _extraRadioValue = null;
      _actividadesExtra = <ActividadExtracurricular>[];
    });
    final l = AppLocalizations.of(context);
    try {
      final acts = await ih.cargarActividadesExtracurricularesPorInstitucion(_instId);
      if (!mounted) return;
      setState(() {
        _actividadesExtra = acts;
        _extraCargadoUnaVez = true;
        _cargandoExtra = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extraCargadoUnaVez = true;
        _cargandoExtra = false;
        _actividadesExtra = <ActividadExtracurricular>[];
      });
      _snack(l.alumnoSeleccionGrupoExtraLoadError('$e'));
    } finally {
      _extraCargandoAhora = false;
    }
  }

  List<ActividadExtracurricular> get _extraFiltradas {
    if (_bloqueSeleccionado == null) {
      return List<ActividadExtracurricular>.from(_actividadesExtra);
    }
    return _actividadesExtra
        .where((a) => a.bloque == _bloqueSeleccionado)
        .toList();
  }

  Future<void> _irASolicitarVacanteCurricular() async {
    final l = AppLocalizations.of(context);
    final inst = _perfilInst;
    final g = _grupoSeleccionado;
    if (inst == null) {
      _snack(l.commonInstitutionUnavailable);
      return;
    }
    if (g == null) {
      _snack(l.alumnoSeleccionGrupoPickCourseAndShift);
      return;
    }
    if (!_tieneCupo(g)) {
      _snack(l.alumnoSeleccionGrupoNoSlotsShort);
      return;
    }

    final nombre = (widget.institucionNombre ?? '').trim().isNotEmpty
        ? widget.institucionNombre!.trim()
        : inst.nombre;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ok = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: widget.alumnoDocumento,
            institucionId: _instId,
            institucionNombre: nombre,
            actividadNombre: _nombreGrupo(g),
            esCurricular: true,
            aula: _nombreGrupo(g),
            turno: _turnoUiForGrupo(l, g),
            grupoCurricularId: g.id,
            ownerAccountId: _owner,
            perfilId: _perfilId,
          ),
        ),
      );
      if (!mounted) return;
      if (ok == true) {
        _snack(l.commonRequestCreated);
        navigator.pop();
      }
    } catch (e) {
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.alumnoSeleccionGrupoOpenSolicitudError('$e'))),
        );
      }
    }
  }

  Future<void> _irASolicitarVacanteExtracurricular() async {
    final l = AppLocalizations.of(context);
    final inst = _perfilInst;
    final act = _actividadSeleccionada;
    if (inst == null) {
      _snack(l.commonInstitutionUnavailable);
      return;
    }
    if (act == null) {
      _snack(l.alumnoSeleccionGrupoPickExtraActivity);
      return;
    }
    if (!act.tieneCuposDisponibles) {
      _snack(l.alumnoSeleccionGrupoExtraNoSlots);
      return;
    }

    final nombre = (widget.institucionNombre ?? '').trim().isNotEmpty
        ? widget.institucionNombre!.trim()
        : inst.nombre;
    final horario = (act.horario ?? '').trim();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ok = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: widget.alumnoDocumento,
            institucionId: _instId,
            institucionNombre: nombre,
            actividadNombre: act.nombre,
            esCurricular: false,
            aula: null,
            turno: horario.isEmpty ? null : horario,
            ownerAccountId: _owner,
            perfilId: _perfilId,
            moduleKey: act.bloque.key,
          ),
        ),
      );
      if (!mounted) return;
      if (ok == true) {
        _snack(l.commonRequestCreated);
        navigator.pop();
      }
    } catch (e) {
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.alumnoSeleccionGrupoOpenSolicitudError('$e'))),
        );
      }
    }
  }

  Future<void> _accionSolicitar() async {
    if (_modo == ModoSolicitudUI.curricular) {
      return _irASolicitarVacanteCurricular();
    }
    return _irASolicitarVacanteExtracurricular();
  }

  bool get _puedeSolicitar {
    if (_modo == ModoSolicitudUI.curricular) {
      final g = _grupoSeleccionado;
      return g != null && _tieneCupo(g);
    }
    final a = _actividadSeleccionada;
    return a != null && a.tieneCuposDisponibles;
  }

  Widget _filtrosCurriculares() {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final turnos = <TurnoCurricular>[...
      TurnoCurricular.values,
    ];

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros de vacante (opcionales)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Podés dejar todo en Todos para explorar todas las opciones de la institución.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TurnoCurricular?>(
              value: _filtroTurno,
              decoration: const InputDecoration(
                labelText: 'Turno',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<TurnoCurricular?>(
                  value: null,
                  child: Text('Todos los turnos'),
                ),
                for (final t in turnos)
                  DropdownMenuItem<TurnoCurricular?>(
                    value: t,
                    child: Text(_labelTurnoCurricular(l, t)),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroTurno = value;
                  _curricularRadioValue = null;
                  _grupoSeleccionado = null;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cursoController,
              decoration: InputDecoration(
                labelText: 'Curso / grado (opcional)',
                hintText: 'Ej.: 1.º, 2.º, 4.º A',
                border: const OutlineInputBorder(),
                suffixIcon: _filtroCurso.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        onPressed: _limpiarFiltrosVacante,
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            if (_filtroTurno != null || _filtroCurso.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _limpiarFiltrosVacante,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Mostrar todas las opciones'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _uiCurricular() {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final grupos = _gruposFiltrados;

    if (_gruposPorTurno.values.every((e) => e.isEmpty)) {
      return Expanded(child: Center(child: Text(l.alumnoSeleccionGrupoNoSlots)));
    }

    return Expanded(
      child: Column(
        children: [
          _filtrosCurriculares(),
          Expanded(
            child: grupos.isEmpty
                ? Center(
                    child: Text(
                      'No hay grupos que coincidan con los filtros seleccionados.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: grupos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final g = grupos[i];
                      final enabled = _tieneCupo(g);
                      return Card(
                        child: RadioListTile<String>(
                          value: g.id,
                          groupValue: _curricularRadioValue,
                          onChanged: enabled
                              ? (v) {
                                  if (v != null) _seleccionarCurricularRadio(v);
                                }
                              : null,
                          title: Text(_nombreGrupo(g)),
                          subtitle: Text(_subtitleCurricular(l, g)),
                          secondary: enabled
                              ? const Icon(Icons.school_outlined)
                              : Icon(Icons.block, color: cs.error),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipBloque(BloqueExtracurricular b) {
    final sel = _bloqueSeleccionado == b;
    return ChoiceChip(
      label: Text(b.label),
      selected: sel,
      onSelected: (_) {
        setState(() {
          _bloqueSeleccionado = sel ? null : b;
          _actividadSeleccionada = null;
          _extraRadioValue = null;
        });
      },
    );
  }

  Widget _uiExtracurricular() {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_cargandoExtra) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    final filtered = _extraFiltradas;
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.alumnoSeleccionGrupoExtraFilterByBlock,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final b in _orderedBloques()) ...[
                  _chipBloque(b),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l.alumnoSeleccionGrupoExtraEmpty,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = filtered[i];
                      final selected = _extraRadioValue == a.id;
                      final parts = <String>[];
                      final desc = (a.descripcion ?? '').trim();
                      if (desc.isNotEmpty) parts.add(desc);
                      final hor = (a.horario ?? '').trim();
                      if (hor.isNotEmpty) parts.add(l.commonScheduleLabel(hor));
                      final edad = (a.edades ?? '').trim();
                      if (edad.isNotEmpty) parts.add(l.commonAgeLabel(edad));
                      if (a.cupoMaximo > 0) {
                        parts.add(l.commonSlotsLabel('${a.cuposDisponibles}/${a.cupoMaximo}'));
                      }
                      final subtitle = parts.isEmpty
                          ? a.bloque.label
                          : '${a.bloque.label}\n${parts.join('\n')}';
                      return Card(
                        child: RadioListTile<String>(
                          value: a.id,
                          groupValue: _extraRadioValue,
                          onChanged: a.tieneCuposDisponibles
                              ? (v) {
                                  if (v == null) return;
                                  final act = _findActividadById(v);
                                  if (act == null || !act.tieneCuposDisponibles) return;
                                  setState(() {
                                    _extraRadioValue = v;
                                    _actividadSeleccionada = act;
                                  });
                                }
                              : null,
                          title: Text(a.nombre),
                          subtitle: Text(subtitle),
                          secondary: selected
                              ? const Icon(Icons.check_circle)
                              : const Icon(Icons.circle_outlined),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _selectorModo() {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isCurr = _modo == ModoSolicitudUI.curricular;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _cargando
                  ? null
                  : () => setState(() => _modo = ModoSolicitudUI.curricular),
              style: FilledButton.styleFrom(
                backgroundColor: isCurr ? null : cs.surfaceContainerHighest,
                foregroundColor: isCurr ? null : cs.onSurface,
              ),
              child: Text(l.alumnoSeleccionGrupoModeCurricular),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: (_cargando || _cargandoExtra)
                  ? null
                  : () async {
                      setState(() => _modo = ModoSolicitudUI.extracurricular);
                      await _cargarExtracurricularesSiHaceFalta();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: !isCurr ? null : cs.surfaceContainerHighest,
                foregroundColor: !isCurr ? null : cs.onSurface,
              ),
              child: Text(l.alumnoSeleccionGrupoModeExtracurricular),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(l.alumnoSeleccionGrupoTitle(l.commonInstitution))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_perfilInst == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.alumnoSeleccionGrupoTitle(l.commonInstitution))),
        body: Center(child: Text(l.alumnoSeleccionGrupoInstitutionLoadFailed)),
      );
    }

    final instNombre = _perfilInst!.nombre;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.alumnoSeleccionGrupoTitle(instNombre)),
        actions: [
          IconButton(
            onPressed: (_cargando || _cargandoExtra) ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
            tooltip: l.commonRefresh,
          ),
          if (_modo == ModoSolicitudUI.extracurricular)
            IconButton(
              onPressed: (_cargando || _cargandoExtra) ? null : _refrescarExtracurriculares,
              icon: const Icon(Icons.refresh),
              tooltip: l.alumnoSeleccionGrupoExtraRefresh,
            ),
        ],
      ),
      body: Column(
        children: [
          _selectorModo(),
          if ((_alumno?.nombre ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.commonProfileLabel((_alumno?.nombre ?? '').trim()),
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          if (_modo == ModoSolicitudUI.curricular) _uiCurricular() else _uiExtracurricular(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _puedeSolicitar ? _accionSolicitar : null,
                icon: const Icon(Icons.send),
                label: Text(
                  _modo == ModoSolicitudUI.curricular
                      ? l.alumnoSeleccionGrupoCtaCurricular
                      : l.alumnoSeleccionGrupoCtaExtracurricular,
                ),
              ),
            ),
          ),
          if (_modo == ModoSolicitudUI.curricular && _grupoSeleccionado == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                'Explorá libremente las opciones. Los filtros son opcionales; para solicitar una vacante elegí una alternativa disponible.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          if (_modo == ModoSolicitudUI.extracurricular &&
              _actividadSeleccionada != null &&
              !_actividadSeleccionada!.tieneCuposDisponibles)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                l.alumnoSeleccionGrupoExtraNoSlots,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
