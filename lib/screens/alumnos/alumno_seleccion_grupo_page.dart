// lib/screens/alumnos/alumno_seleccion_grupo_page.dart

import 'dart:developer' as dev;

import 'package:flutter/material.dart';

// ✅ ATENA usa l10n generado en /lib/l10n/gen (no flutter_gen)
import '../../l10n/gen/app_localizations.dart';

// Servicios
import '../../services/alumno_service.dart';
import '../../services/instituciones_helpers.dart' as ih;

// Modelos
import '../../models/instituciones/instituciones_integrado.dart';
import '../../models/instituciones/grupo_curricular.dart';
import '../../models/alumnos/alumnos_integrados.dart';

// ✅ Dominio extracurriculares (FUENTE DE VERDAD)
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/extracurriculares/actividad_extracurricular.dart';

// Pantalla que confirma y crea la solicitud real
import 'alumno_solicitar_vacante_page.dart';

enum ModoSolicitudUI { curricular, extracurricular }

class AlumnoSeleccionGrupoPage extends StatefulWidget {
  final String institucionId;
  final String? institucionNombre;

  /// Alumno doc (si ya está canónico en backend, ok; si no, migramos luego al id canónico)
  final String alumnoDocumento;

  /// owner-only (canónico)
  final String ownerAccountId;

  /// perfil activo
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

  // ─────────────────────────────────────────────
  // Modo (Curricular vs Extracurricular)
  // ─────────────────────────────────────────────
  ModoSolicitudUI _modo = ModoSolicitudUI.curricular;

  // ─────────────────────────────────────────────
  // Curricular (CANÓNICO: fuente única ih.cargarGruposCurricularesInstitucion)
  // ─────────────────────────────────────────────
  final Map<TurnoCurricular, List<GrupoCurricular>> _gruposPorTurno = {
    TurnoCurricular.manana: <GrupoCurricular>[],
    TurnoCurricular.tarde: <GrupoCurricular>[],
    TurnoCurricular.noche: <GrupoCurricular>[],
  };

  GrupoCurricular? _grupoSeleccionado;

  // ✅ selección curricular (radio) — por GrupoCurricular.id (estable)
  String? _curricularRadioValue;

  // ─────────────────────────────────────────────
  // Extracurricular (E2E)
  // ─────────────────────────────────────────────
  bool _cargandoExtra = false;
  bool _extraCargadoUnaVez = false;
  bool _extraCargandoAhora = false;

  BloqueExtracurricular? _bloqueSeleccionado;
  List<ActividadExtracurricular> _actividadesExtra =
      <ActividadExtracurricular>[];
  ActividadExtracurricular? _actividadSeleccionada;

  // ✅ selección extracurricular (radio)
  String? _extraRadioValue;

  String get _owner => widget.ownerAccountId.trim();
  String get _perfilId => widget.perfilId.trim();
  String get _instId => widget.institucionId.trim();

  int _alpha255(double opacity) {
    final v = (opacity * 255).round();
    return v.clamp(0, 255);
  }

  @override
  void initState() {
    super.initState();
    dev.log(
      '[ATENA][ALUMNO][SEL_GRUPO] initState: owner="$_owner" perfilId="$_perfilId" institucionId(raw)="${widget.institucionId}" institucionId(trim)="$_instId"',
    );
    // ignore: discarded_futures
    _cargarDatos();
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

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

  /// ✅ Turno serializado canónico (best-effort) para UI + snapshot:
  /// `"<Turno> • <HH:MM>-<HH:MM>"` si hay horario; si no, solo `"<Turno>"`.
  String _turnoUiForGrupo(AppLocalizations l, GrupoCurricular g) {
    final base = _labelTurnoCurricular(l, g.turno).trim();
    final hi = (g.horaInicio ?? '').trim();
    final hf = (g.horaFin ?? '').trim();

    if (hi.isEmpty && hf.isEmpty) return base;
    final rango =
        '${hi.isNotEmpty ? hi : '--:--'}-${hf.isNotEmpty ? hf : '--:--'}';
    return '$base • $rango';
  }

  /// ✅ Subtitle curricular: muestra turno+horario + disponibilidad (y estado)
  String _subtitleCurricular(AppLocalizations l, GrupoCurricular g) {
    final turnoTxt = _turnoUiForGrupo(l, g);
    final slotsTxt = l.alumnoSeleccionGrupoSlotsAvailable(g.cuposDisponibles);
    if (_tieneCupo(g)) {
      return '$turnoTxt\n$slotsTxt';
    }
    // Si no hay cupo: mostramos igualmente (para que el padre vea capacidad/estado)
    return '$turnoTxt\n$slotsTxt\n${l.alumnoSeleccionGrupoNoSlotsShort}';
  }

  void _snack(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      // NO-OP
    }
  }

  /// ✅ Orden canónico estable (no alfabético)
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
    final x = id.trim();
    if (x.isEmpty) return null;
    for (final entry in _gruposPorTurno.entries) {
      for (final g in entry.value) {
        if (g.id == x) return g;
      }
    }
    return null;
  }

  void _seleccionarCurricularRadio(String grupoId) {
    final l = AppLocalizations.of(context);
    final g = _findGrupoById(grupoId);
    if (g == null) return;

    // ✅ No permitimos seleccionar sin cupos (pero lo seguimos mostrando en lista)
    if (!_tieneCupo(g)) {
      _snack(l.alumnoSeleccionGrupoNoSlotsShort);
      return;
    }

    if (!mounted) return;
    setState(() {
      _grupoSeleccionado = g;
      _curricularRadioValue = grupoId;
    });
  }

  // ------------------------------------------------------------
  // Carga CANÓNICA E2E
  // ------------------------------------------------------------

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    final l = AppLocalizations.of(context);

    try {
      if (_owner.isEmpty || _perfilId.isEmpty) {
        if (!mounted) return;
        setState(() => _cargando = false);
        _snack(l.commonInvalidSession);
        return;
      }

      if (_instId.isEmpty) {
        if (!mounted) return;
        setState(() => _cargando = false);
        _snack(l.alumnoSeleccionGrupoInstitutionLoadFailed);
        return;
      }

      dev.log(
        '[ATENA][ALUMNO][SEL_GRUPO] cargarDatos: instId="$_instId" owner="$_owner" perfilId="$_perfilId"',
      );

      // Perfil institución (E2E)
      final institucion = await ih.cargarInstitucionPorId(_instId);
      dev.log(
        '[ATENA][ALUMNO][SEL_GRUPO] cargarInstitucionPorId OK: instNombre="${(institucion?.nombre ?? '').trim()}"',
      );

      // Perfil alumno canónico por perfilId
      final alumno = await AlumnoService.instance.getPerfilAlumnoByPerfilId(
        ownerAccountId: _owner,
        perfilId: _perfilId,
      );
      dev.log(
        '[ATENA][ALUMNO][SEL_GRUPO] getPerfilAlumnoByPerfilId OK: alumnoNombre="${(alumno?.nombre ?? '').trim()}"',
      );

      // ✅ Fuente ÚNICA de verdad (Fase 2):
      // grupos curriculares SIEMPRE desde ih.cargarGruposCurricularesInstitucion()
      final gruposAll = await ih.cargarGruposCurricularesInstitucion(_instId);
      dev.log(
        '[ATENA][ALUMNO][SEL_GRUPO] cargarGruposCurricularesInstitucion OK: total=${gruposAll.length}',
      );

      // ✅ NO filtramos por cupos: el padre debe poder VER cursos sin vacantes.
      // ✅ Orden estable best-effort: nombre, horario, id
      final grupos = List<GrupoCurricular>.from(gruposAll)
        ..sort((a, b) {
          final an = _nombreGrupo(a).toLowerCase();
          final bn = _nombreGrupo(b).toLowerCase();
          final c = an.compareTo(bn);
          if (c != 0) return c;

          final ahi = (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
          if (ahi != 0) return ahi;
          final ahf = (a.horaFin ?? '').compareTo(b.horaFin ?? '');
          if (ahf != 0) return ahf;
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

      dev.log(
        '[ATENA][ALUMNO][SEL_GRUPO] gruposPorTurno: manana=${porTurno[TurnoCurricular.manana]!.length} tarde=${porTurno[TurnoCurricular.tarde]!.length} noche=${porTurno[TurnoCurricular.noche]!.length}',
      );

      if (!mounted) return;
      setState(() {
        _perfilInst = institucion;
        _alumno = alumno;

        _gruposPorTurno[TurnoCurricular.manana] =
            porTurno[TurnoCurricular.manana]!;
        _gruposPorTurno[TurnoCurricular.tarde] =
            porTurno[TurnoCurricular.tarde]!;
        _gruposPorTurno[TurnoCurricular.noche] =
            porTurno[TurnoCurricular.noche]!;

        // Limpieza de selección al recargar para evitar valores inválidos
        _curricularRadioValue = null;
        _grupoSeleccionado = null;

        _cargando = false;
      });

      // Señal útil: si llegó “0 grupos” mostramos log para diagnóstico UX
      final hayAlgo = _gruposPorTurno.values.any((e) => e.isNotEmpty);
      if (!hayAlgo) {
        dev.log(
          '[ATENA][ALUMNO][SEL_GRUPO] WARNING: no hay grupos curriculares para instId="$_instId" (institución sin cursos cargados o mismatch ID/key).',
        );
      }
    } catch (e) {
      dev.log('[ATENA][ALUMNO][SEL_GRUPO] ERROR cargarDatos: $e', error: e);
      if (!mounted) return;
      setState(() {
        _perfilInst = null;
        _alumno = null;

        _gruposPorTurno.updateAll((turno, lista) => <GrupoCurricular>[]);

        _curricularRadioValue = null;
        _grupoSeleccionado = null;

        _cargando = false;
      });
      _snack(l.alumnoSeleccionGrupoLoadError('$e'));
    }
  }

  // ------------------------------------------------------------
  // Extracurriculares – E2E
  // ------------------------------------------------------------

  Future<void> _cargarExtracurricularesSiHaceFalta() async {
    if (_extraCargadoUnaVez) return;
    await _refrescarExtracurriculares();
  }

  Future<void> _refrescarExtracurriculares() async {
    if (!mounted) return;
    if (_extraCargandoAhora) return;

    _extraCargandoAhora = true;

    setState(() {
      _cargandoExtra = true;
      _actividadSeleccionada = null;
      _extraRadioValue = null;
      _actividadesExtra = <ActividadExtracurricular>[];
    });

    final l = AppLocalizations.of(context);

    try {
      final instId = _instId;
      if (instId.isEmpty) {
        throw StateError(l.alumnoSeleccionGrupoInstitutionLoadFailed);
      }

      dev.log(
        '[ATENA][ALUMNO][SEL_GRUPO] cargarExtracurriculares: instId="$instId"',
      );

      final acts = await ih.cargarActividadesExtracurricularesPorInstitucion(
        instId,
      );

      dev.log(
        '[ATENA][ALUMNO][SEL_GRUPO] cargarActividadesExtracurriculares OK: total=${acts.length}',
      );

      if (!mounted) return;
      setState(() {
        _actividadesExtra = acts;
        _extraCargadoUnaVez = true;
        _cargandoExtra = false;
      });
    } catch (e) {
      dev.log('[ATENA][ALUMNO][SEL_GRUPO] ERROR extra: $e', error: e);
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
    final b = _bloqueSeleccionado;
    if (b == null) {
      return List<ActividadExtracurricular>.from(_actividadesExtra);
    }
    return _actividadesExtra.where((a) => a.bloque == b).toList();
  }

  // ------------------------------------------------------------
  // Acción
  // ------------------------------------------------------------

  Future<void> _irASolicitarVacanteCurricular() async {
    final l = AppLocalizations.of(context);
    final inst = _perfilInst;
    if (inst == null) {
      _snack(l.commonInstitutionUnavailable);
      return;
    }

    final g = _grupoSeleccionado;
    if (g == null) {
      _snack(l.alumnoSeleccionGrupoPickCourseAndShift);
      return;
    }

    if (!_tieneCupo(g)) {
      _snack(l.alumnoSeleccionGrupoNoSlotsShort);
      return;
    }

    final curso = _nombreGrupo(g);

    final instNombreOverride = (widget.institucionNombre ?? '').trim();
    final institucionNombreFinal = instNombreOverride.isNotEmpty
        ? instNombreOverride
        : inst.nombre;

    // ✅ Capturar handles antes de awaits (evita use_build_context_synchronously)
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    bool? ok;
    try {
      ok = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: widget.alumnoDocumento,
            institucionId: _instId, // ✅ usar trim canónico
            institucionNombre: institucionNombreFinal,
            actividadNombre: curso,
            esCurricular: true,

            // ✅ Snapshot/UI
            aula: curso,
            turno: _turnoUiForGrupo(l, g),

            // ✅ CANÓNICO curricular
            grupoCurricularId: g.id,

            ownerAccountId: _owner,
            perfilId: _perfilId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (messenger != null) {
        try {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.alumnoSeleccionGrupoOpenSolicitudError('$e')),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    if (!mounted) return;
    if (ok == true) {
      _snack(l.commonRequestCreated);
      navigator.pop();
    }
  }

  Future<void> _irASolicitarVacanteExtracurricular() async {
    final l = AppLocalizations.of(context);
    final inst = _perfilInst;
    if (inst == null) {
      _snack(l.commonInstitutionUnavailable);
      return;
    }

    final act = _actividadSeleccionada;
    if (act == null) {
      _snack(l.alumnoSeleccionGrupoPickExtraActivity);
      return;
    }

    if (!act.tieneCuposDisponibles) {
      _snack(l.alumnoSeleccionGrupoExtraNoSlots);
      return;
    }

    final horario = (act.horario ?? '').trim();
    final turnoTxt = horario.isEmpty ? null : horario;

    final instNombreOverride = (widget.institucionNombre ?? '').trim();
    final institucionNombreFinal = instNombreOverride.isNotEmpty
        ? instNombreOverride
        : inst.nombre;

    // ✅ Capturar handles antes de awaits (evita use_build_context_synchronously)
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    bool? ok;
    try {
      ok = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: widget.alumnoDocumento,
            institucionId: _instId, // ✅ usar trim canónico
            institucionNombre: institucionNombreFinal,
            actividadNombre: act.nombre,
            esCurricular: false,
            aula: null,
            turno: turnoTxt,
            ownerAccountId: _owner,
            perfilId: _perfilId,
            moduleKey: act.bloque.key,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (messenger != null) {
        try {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.alumnoSeleccionGrupoOpenSolicitudError('$e')),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    if (!mounted) return;
    if (ok == true) {
      _snack(l.commonRequestCreated);
      navigator.pop();
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
      // ✅ Solo si hay un grupo elegido Y tiene cupos
      final g = _grupoSeleccionado;
      return g != null && _tieneCupo(g);
    }
    return _actividadSeleccionada != null &&
        (_actividadSeleccionada?.tieneCuposDisponibles ?? false);
  }

  // ------------------------------------------------------------
  // UI – Curricular
  // ------------------------------------------------------------

  Widget _columnaTurno(TurnoCurricular turno) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final list = _gruposPorTurno[turno] ?? const <GrupoCurricular>[];

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: cs.surfaceContainerHighest.withAlpha(_alpha255(0.65)),
            ),
            child: Text(
              _labelTurnoCurricular(l, turno),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text(l.alumnoSeleccionGrupoNoSlotsShort))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int i) {
                      final g = list[i];
                      final nombre = _nombreGrupo(g);

                      // ✅ CANÓNICO: el value del radio es el ID estable
                      final value = g.id;

                      final subtitle = _subtitleCurricular(l, g);
                      final enabled = _tieneCupo(g);

                      return RadioListTile<String>(
                        value: value,
                        groupValue: _curricularRadioValue,
                        onChanged: enabled
                            ? (v) {
                                if (v == null) return;
                                _seleccionarCurricularRadio(v);
                              }
                            : null,
                        title: Text(nombre),
                        subtitle: Text(subtitle),
                        secondary: enabled
                            ? const Icon(Icons.school_outlined)
                            : Icon(
                                Icons.block,
                                color: Theme.of(context).colorScheme.error,
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _uiCurricular() {
    final l = AppLocalizations.of(context);

    final hayAlgo = _gruposPorTurno.values.any((e) => e.isNotEmpty);
    if (!hayAlgo) {
      return Expanded(
        child: Center(child: Text(l.alumnoSeleccionGrupoNoSlots)),
      );
    }

    return Expanded(
      child: Row(
        children: [
          _columnaTurno(TurnoCurricular.manana),
          _columnaTurno(TurnoCurricular.tarde),
          _columnaTurno(TurnoCurricular.noche),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI – Extracurricular
  // ------------------------------------------------------------

  Widget _chipBloque(BloqueExtracurricular b) {
    final sel = _bloqueSeleccionado == b;

    return ChoiceChip(
      label: Text(b.label),
      selected: sel,
      onSelected: (_) {
        if (!mounted) return;
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
    final cs = theme.colorScheme;

    if (_cargandoExtra) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    final filtered = _extraFiltradas;

    return Expanded(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.alumnoSeleccionGrupoExtraFilterByBlock,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface.withAlpha(_alpha255(0.85)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
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
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l.alumnoSeleccionGrupoExtraEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final a = filtered[i];
                      final selected = _extraRadioValue == a.id;

                      final subtitleParts = <String>[];

                      final desc = (a.descripcion ?? '').trim();
                      if (desc.isNotEmpty) subtitleParts.add(desc);

                      final hor = (a.horario ?? '').trim();
                      if (hor.isNotEmpty) {
                        subtitleParts.add(l.commonScheduleLabel(hor));
                      }

                      final edad = (a.edades ?? '').trim();
                      if (edad.isNotEmpty) {
                        subtitleParts.add(l.commonAgeLabel(edad));
                      }

                      if (a.cupoMaximo > 0) {
                        subtitleParts.add(
                          l.commonSlotsLabel(
                            '${a.cuposDisponibles}/${a.cupoMaximo}',
                          ),
                        );
                      }

                      final subtitle = subtitleParts.isEmpty
                          ? a.bloque.label
                          : '${a.bloque.label}\n${subtitleParts.join('\n')}';

                      return Card(
                        child: RadioListTile<String>(
                          value: a.id,
                          groupValue: _extraRadioValue,
                          onChanged: a.tieneCuposDisponibles
                              ? (v) {
                                  if (v == null) return;
                                  final act = _findActividadById(v);
                                  if (act == null) return;
                                  if (!act.tieneCuposDisponibles) return;

                                  if (!mounted) return;
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

  // ------------------------------------------------------------
  // UI – Top selector
  // ------------------------------------------------------------

  Widget _selectorModo() {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    final isCurr = _modo == ModoSolicitudUI.curricular;
    final isExtra = _modo == ModoSolicitudUI.extracurricular;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _cargando
                  ? null
                  : () {
                      if (!mounted) return;
                      setState(() => _modo = ModoSolicitudUI.curricular);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isCurr ? null : cs.surfaceContainerHighest,
                foregroundColor: isCurr ? null : cs.onSurface,
                elevation: isCurr ? 1 : 0,
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
                      if (!mounted) return;
                      setState(() => _modo = ModoSolicitudUI.extracurricular);
                      await _cargarExtracurricularesSiHaceFalta();
                      if (!mounted) return;
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isExtra ? null : cs.surfaceContainerHighest,
                foregroundColor: isExtra ? null : cs.onSurface,
                elevation: isExtra ? 1 : 0,
              ),
              child: Text(l.alumnoSeleccionGrupoModeExtracurricular),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.alumnoSeleccionGrupoTitle(l.commonInstitution)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_perfilInst == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.alumnoSeleccionGrupoTitle(l.commonInstitution)),
        ),
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
              onPressed: (_cargando || _cargandoExtra)
                  ? null
                  : _refrescarExtracurriculares,
              icon: const Icon(Icons.refresh),
              tooltip: l.alumnoSeleccionGrupoExtraRefresh,
            ),
        ],
      ),
      body: Column(
        children: [
          _selectorModo(),

          // Contexto mínimo canónico – no rompe nada
          if ((_alumno?.nombre ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.commonProfileLabel((_alumno?.nombre ?? '').trim()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          // Contenido según modo
          if (_modo == ModoSolicitudUI.curricular)
            _uiCurricular()
          else
            _uiExtracurricular(),

          // CTA
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

          // Helper visual cuando está inactivo por cupos (extra)
          if (_modo == ModoSolicitudUI.extracurricular &&
              _actividadSeleccionada != null &&
              !(_actividadSeleccionada?.tieneCuposDisponibles ?? true))
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
