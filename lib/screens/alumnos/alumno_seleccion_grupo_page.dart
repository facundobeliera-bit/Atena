// lib/screens/alumnos/alumno_seleccion_grupo_page.dart

import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/actividad_extracurricular.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/grupo_curricular.dart';
import '../../services/instituciones_helpers.dart' as ih;
import 'alumno_solicitar_vacante_page.dart';

enum ModoSolicitudUI { curricular, extracurricular }

enum _OrdenVacantes { curso, vacantes, horario }

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
  static const Duration _loadTimeout = Duration(seconds: 15);

  bool _cargando = true;
  String? _errorCarga;

  ModoSolicitudUI _modo = ModoSolicitudUI.curricular;

  List<GrupoCurricular> _grupos = <GrupoCurricular>[];
  GrupoCurricular? _grupoSeleccionado;
  String? _curricularRadioValue;

  TurnoCurricular? _filtroTurno;
  final TextEditingController _cursoController = TextEditingController();
  bool _soloConVacantes = true;
  _OrdenVacantes _orden = _OrdenVacantes.curso;

  bool _cargandoExtra = false;
  bool _extraCargadoUnaVez = false;
  bool _extraCargandoAhora = false;
  BloqueExtracurricular? _bloqueSeleccionado;
  List<ActividadExtracurricular> _actividadesExtra =
      <ActividadExtracurricular>[];
  ActividadExtracurricular? _actividadSeleccionada;
  String? _extraRadioValue;

  String get _instId => widget.institucionId.trim();
  String get _owner => widget.ownerAccountId.trim();
  String get _perfilId => widget.perfilId.trim();

  String get _nombreInstitucion {
    final n = (widget.institucionNombre ?? '').trim();
    return n.isEmpty ? 'Institución' : n;
  }

  @override
  void initState() {
    super.initState();
    _cursoController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _cursoController.dispose();
    super.dispose();
  }

  bool _tieneCupo(GrupoCurricular g) => g.tieneCuposDisponibles;

  String _nombreGrupo(GrupoCurricular g) {
    final n = g.nombreCurso.trim();
    return n.isEmpty ? 'Curso' : n;
  }

  String _labelTurno(AppLocalizations l, TurnoCurricular t) {
    switch (t) {
      case TurnoCurricular.manana:
        return l.commonShiftMorning;
      case TurnoCurricular.tarde:
        return l.commonShiftAfternoon;
      case TurnoCurricular.noche:
        return l.commonShiftNight;
    }
  }

  String _horario(GrupoCurricular g) {
    final hi = (g.horaInicio ?? '').trim();
    final hf = (g.horaFin ?? '').trim();
    if (hi.isEmpty && hf.isEmpty) return '';
    return '${hi.isEmpty ? '--:--' : hi} - ${hf.isEmpty ? '--:--' : hf}';
  }

  String _turnoHorario(AppLocalizations l, GrupoCurricular g) {
    final turno = _labelTurno(l, g.turno);
    final horario = _horario(g);
    return horario.isEmpty ? turno : '$turno • $horario';
  }

  List<GrupoCurricular> get _gruposFiltrados {
    final query = _cursoController.text.trim().toLowerCase();
    final filtered = _grupos.where((g) {
      if (_filtroTurno != null && g.turno != _filtroTurno) return false;
      if (_soloConVacantes && !_tieneCupo(g)) return false;
      if (query.isNotEmpty &&
          !_nombreGrupo(g).toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_orden == _OrdenVacantes.vacantes) {
        final c = b.cuposDisponibles.compareTo(a.cuposDisponibles);
        if (c != 0) return c;
      }

      if (_orden == _OrdenVacantes.horario) {
        final c = (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
        if (c != 0) return c;
      }

      final curso = _nombreGrupo(a).toLowerCase().compareTo(
            _nombreGrupo(b).toLowerCase(),
          );
      if (curso != 0) return curso;

      final turno = a.turno.index.compareTo(b.turno.index);
      if (turno != 0) return turno;

      if (_orden != _OrdenVacantes.horario) {
        final hora = (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
        if (hora != 0) return hora;
      }
      return a.id.compareTo(b.id);
    });

    return filtered;
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroTurno = null;
      _cursoController.clear();
      _soloConVacantes = true;
      _orden = _OrdenVacantes.curso;
      _grupoSeleccionado = null;
      _curricularRadioValue = null;
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _errorCarga = null;
    });

    if (_instId.isEmpty) {
      setState(() {
        _cargando = false;
        _errorCarga = 'No se recibió una institución válida.';
      });
      return;
    }

    try {
      // Esta pantalla no necesita cargar el perfil del alumno ni volver a
      // cargar la institución completa para mostrar las vacantes. La fuente
      // canónica de cursos/aulas es cargarGruposCurricularesInstitucion.
      final grupos = await ih
          .cargarGruposCurricularesInstitucion(_instId)
          .timeout(_loadTimeout);

      if (!mounted) return;
      setState(() {
        _grupos = List<GrupoCurricular>.from(grupos);
        _grupoSeleccionado = null;
        _curricularRadioValue = null;
        _cargando = false;
      });

      dev.log(
        '[ATENA][ALUMNO][VACANTES] institución=$_instId grupos=${_grupos.length}',
      );
    } catch (e, st) {
      dev.log(
        '[ATENA][ALUMNO][VACANTES] error cargando institución=$_instId',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _grupos = <GrupoCurricular>[];
        _grupoSeleccionado = null;
        _curricularRadioValue = null;
        _cargando = false;
        _errorCarga =
            'No pudimos cargar las vacantes de esta institución. Podés reintentar.';
      });
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

    try {
      final acts = await ih
          .cargarActividadesExtracurricularesPorInstitucion(_instId)
          .timeout(_loadTimeout);
      if (!mounted) return;
      setState(() {
        _actividadesExtra = acts;
        _extraCargadoUnaVez = true;
        _cargandoExtra = false;
      });
    } catch (e, st) {
      dev.log(
        '[ATENA][ALUMNO][VACANTES] error extracurricular',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _extraCargadoUnaVez = true;
        _cargandoExtra = false;
        _actividadesExtra = <ActividadExtracurricular>[];
      });
      _mostrarMensaje('No pudimos cargar las propuestas extracurriculares.');
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

  void _mostrarMensaje(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _seleccionarGrupo(GrupoCurricular g) {
    if (!_tieneCupo(g)) {
      _mostrarMensaje('Esta opción no tiene vacantes disponibles.');
      return;
    }
    setState(() {
      _grupoSeleccionado = g;
      _curricularRadioValue = g.id;
    });
  }

  Future<void> _solicitarCurricular() async {
    final g = _grupoSeleccionado;
    if (g == null) {
      _mostrarMensaje('Seleccioná una vacante disponible para continuar.');
      return;
    }
    if (!_tieneCupo(g)) {
      _mostrarMensaje('La vacante seleccionada ya no está disponible.');
      return;
    }
    if (_owner.isEmpty || _perfilId.isEmpty) {
      _mostrarMensaje('La sesión del alumno no es válida.');
      return;
    }

    try {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: widget.alumnoDocumento,
            institucionId: _instId,
            institucionNombre: _nombreInstitucion,
            actividadNombre: _nombreGrupo(g),
            esCurricular: true,
            aula: _nombreGrupo(g),
            turno: _turnoHorario(AppLocalizations.of(context), g),
            grupoCurricularId: g.id,
            ownerAccountId: _owner,
            perfilId: _perfilId,
          ),
        ),
      );

      if (!mounted) return;
      if (ok == true) {
        _mostrarMensaje(AppLocalizations.of(context).commonRequestCreated);
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      dev.log('[ATENA][ALUMNO][VACANTES] error abriendo solicitud',
          error: e, stackTrace: st);
      _mostrarMensaje('No pudimos abrir la solicitud de vacante.');
    }
  }

  Future<void> _solicitarExtracurricular() async {
    final act = _actividadSeleccionada;
    if (act == null) {
      _mostrarMensaje('Seleccioná una propuesta disponible para continuar.');
      return;
    }
    if (!act.tieneCuposDisponibles) {
      _mostrarMensaje('Esta propuesta no tiene vacantes disponibles.');
      return;
    }
    if (_owner.isEmpty || _perfilId.isEmpty) {
      _mostrarMensaje('La sesión del alumno no es válida.');
      return;
    }

    try {
      final horario = (act.horario ?? '').trim();
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: widget.alumnoDocumento,
            institucionId: _instId,
            institucionNombre: _nombreInstitucion,
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
        _mostrarMensaje(AppLocalizations.of(context).commonRequestCreated);
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      dev.log('[ATENA][ALUMNO][VACANTES] error abriendo solicitud extra',
          error: e, stackTrace: st);
      _mostrarMensaje('No pudimos abrir la solicitud.');
    }
  }

  Widget _filtrosCurriculares() {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encontrá la vacante que buscás',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'La institución ya fue seleccionada en la búsqueda anterior. Acá podés explorar todas sus opciones y afinar la búsqueda sin perder las demás vacantes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cursoController,
              decoration: InputDecoration(
                labelText: 'Curso / grado / sala',
                hintText: 'Ej.: 1.º, 2.º, 4.º A, sala de 5',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _cursoController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () => _cursoController.clear(),
                        icon: const Icon(Icons.clear),
                      ),
              ),
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
                for (final t in TurnoCurricular.values)
                  DropdownMenuItem<TurnoCurricular?>(
                    value: t,
                    child: Text(_labelTurno(l, t)),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroTurno = value;
                  _grupoSeleccionado = null;
                  _curricularRadioValue = null;
                });
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar solo vacantes disponibles'),
              subtitle: const Text('Podés desactivarlo para consultar también cursos completos.'),
              value: _soloConVacantes,
              onChanged: (value) {
                setState(() {
                  _soloConVacantes = value;
                  if (!value && _grupoSeleccionado != null) {
                    _curricularRadioValue = null;
                    _grupoSeleccionado = null;
                  }
                });
              },
            ),
            DropdownButtonFormField<_OrdenVacantes>(
              value: _orden,
              decoration: const InputDecoration(
                labelText: 'Ordenar resultados',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: _OrdenVacantes.curso,
                  child: Text('Curso → turno → horario'),
                ),
                DropdownMenuItem(
                  value: _OrdenVacantes.vacantes,
                  child: Text('Más vacantes disponibles primero'),
                ),
                DropdownMenuItem(
                  value: _OrdenVacantes.horario,
                  child: Text('Por horario'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _orden = value);
              },
            ),
            if (_filtroTurno != null ||
                _cursoController.text.trim().isNotEmpty ||
                !_soloConVacantes ||
                _orden != _OrdenVacantes.curso) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Restablecer filtros'),
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

    if (_grupos.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'Esta institución no tiene vacantes curriculares cargadas.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          _filtrosCurriculares(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${grupos.length} opción${grupos.length == 1 ? '' : 'es'} encontrada${grupos.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: grupos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No hay vacantes que coincidan con estos filtros. Probá ampliar la búsqueda para ver las demás opciones de la institución.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: grupos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final g = grupos[index];
                      final disponible = _tieneCupo(g);
                      final selected = _curricularRadioValue == g.id;
                      final horario = _horario(g);
                      final cupos =
                          '${g.cuposDisponibles} ${g.cuposDisponibles == 1 ? 'vacante disponible' : 'vacantes disponibles'}';

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: RadioListTile<String>(
                          value: g.id,
                          groupValue: _curricularRadioValue,
                          onChanged: disponible
                              ? (_) => _seleccionarGrupo(g)
                              : null,
                          title: Text(
                            _nombreGrupo(g),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              [
                                _labelTurno(l, g.turno),
                                if (horario.isNotEmpty) horario,
                                cupos,
                              ].join(' • '),
                            ),
                          ),
                          secondary: disponible
                              ? Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.school_outlined,
                                )
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
    final selected = _bloqueSeleccionado == b;
    return ChoiceChip(
      label: Text(b.label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _bloqueSeleccionado = selected ? null : b;
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final b in BloqueExtracurricularX.ordered()) ...[
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
                    itemBuilder: (context, index) {
                      final a = filtered[index];
                      final selected = _extraRadioValue == a.id;
                      final parts = <String>[];
                      final desc = (a.descripcion ?? '').trim();
                      if (desc.isNotEmpty) parts.add(desc);
                      final horario = (a.horario ?? '').trim();
                      if (horario.isNotEmpty) {
                        parts.add(l.commonScheduleLabel(horario));
                      }
                      final edades = (a.edades ?? '').trim();
                      if (edades.isNotEmpty) {
                        parts.add(l.commonAgeLabel(edades));
                      }
                      if (a.cupoMaximo > 0) {
                        parts.add(l.commonSlotsLabel(
                            '${a.cuposDisponibles}/${a.cupoMaximo}'));
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
                                  setState(() {
                                    _extraRadioValue = v;
                                    _actividadSeleccionada = a;
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
    final curricular = _modo == ModoSolicitudUI.curricular;

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
                backgroundColor:
                    curricular ? null : cs.surfaceContainerHighest,
                foregroundColor: curricular ? null : cs.onSurface,
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
                backgroundColor:
                    !curricular ? null : cs.surfaceContainerHighest,
                foregroundColor: !curricular ? null : cs.onSurface,
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
        appBar: AppBar(
          title: Text(l.alumnoSeleccionGrupoTitle(_nombreInstitucion)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorCarga != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.alumnoSeleccionGrupoTitle(_nombreInstitucion)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(_errorCarga!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final puedeSolicitar = _modo == ModoSolicitudUI.curricular
        ? _grupoSeleccionado != null && _tieneCupo(_grupoSeleccionado!)
        : _actividadSeleccionada != null &&
            _actividadSeleccionada!.tieneCuposDisponibles;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.alumnoSeleccionGrupoTitle(_nombreInstitucion)),
        actions: [
          IconButton(
            onPressed: _cargando || _cargandoExtra ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
            tooltip: l.commonRefresh,
          ),
          if (_modo == ModoSolicitudUI.extracurricular)
            IconButton(
              onPressed: _cargandoExtra ? null : _refrescarExtracurriculares,
              icon: const Icon(Icons.refresh),
              tooltip: l.alumnoSeleccionGrupoExtraRefresh,
            ),
        ],
      ),
      body: Column(
        children: [
          _selectorModo(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Explorá las opciones disponibles dentro de esta institución.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (_modo == ModoSolicitudUI.curricular)
            _uiCurricular()
          else
            _uiExtracurricular(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: puedeSolicitar
                      ? (_modo == ModoSolicitudUI.curricular
                          ? _solicitarCurricular
                          : _solicitarExtracurricular)
                      : null,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _modo == ModoSolicitudUI.curricular
                        ? l.alumnoSeleccionGrupoCtaCurricular
                        : l.alumnoSeleccionGrupoCtaExtracurricular,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
