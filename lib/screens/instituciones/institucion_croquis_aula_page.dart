// lib/screens/instituciones/institucion_croquis_aula_page.dart
//
// ATENA – INSTITUCIÓN · CROQUIS AULA (V1 · CANÓNICO)
//
// Objetivo (V1):
// - Editar un croquis por AULA + TURNO en grilla (default 10x10).
// - Cada celda guarda NOMBRE visible (sin DNI).
// - Soporta "grupos" (rectángulos) desde el modelo (UI mínima, opcional).
//
// Persistencia (prototipo local, backend-ready):
// - SharedPreferences con JSON (CroquisAula.toMap / fromMap).
// - Key canónica: croquis_aula_v1_<instId>_<aula>_<turnoKey>
//
// Nota:
// - El lock canónico POR ÁREA + POR ACTIVIDAD lo maneja InstitucionAreaGuard
//   (desde InstitucionAreaPage). Acá no duplicamos locks.
//
// ✅ HARDENING (cierre):
// - Normaliza aula/turno y evita estados “inconsistentes”.
// - Guardado: deshabilita acciones mientras _saving.
// - UX: confirma salida si hay cambios sin guardar.
// - DropdownButtonFormField: value estable + hardening.
// - Preserva colorHex de CroquisGrupo.
// - i18n REAL: NO strings hardcodeadas (labels por L10N).
// - Dark mode REAL: Theme/ColorScheme/TextTheme.
//
// ✅ FIX analyzer (feb 2026):
// - PopScope.onPopInvoked deprecated -> onPopInvokedWithResult.
// - Evita use_build_context_synchronously en pop (captura Navigator antes de await).
// - DropdownButtonFormField.value deprecated -> initialValue + Key para refresh.
//

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/croquis/croquis_aula.dart';
import '../../repositories/croquis_repository_prefs.dart';

// ─────────────────────────────────────────────
// Turnos (CANÓNICO)
// ─────────────────────────────────────────────

class _TurnoKey {
  static const String morning = 'morning';
  static const String afternoon = 'afternoon';
  static const String night = 'night';
  static const String fullDay = 'full_day';

  static const List<String> all = <String>[morning, afternoon, night, fullDay];

  static bool isValid(String v) => all.contains(v);

  static String label(AppLocalizations l10n, String key) {
    // ✅ Labels traducibles (no afectan persistencia)
    switch (key) {
      case morning:
        return l10n.croquisTurnoMorning;
      case afternoon:
        return l10n.croquisTurnoAfternoon;
      case night:
        return l10n.croquisTurnoNight;
      case fullDay:
        return l10n.croquisTurnoFullDay;
      default:
        return l10n.croquisTurnoMorning;
    }
  }

  static String tryParseAny(String raw, AppLocalizations l10n) {
    final v = _norm(raw).toLowerCase();

    // 1) Canonical keys
    if (v == morning) return morning;
    if (v == afternoon) return afternoon;
    if (v == night) return night;
    if (v == fullDay) return fullDay;

    // 2) Compat labels legacy (ES)
    if (v == 'mañana' || v == 'manana') return morning;
    if (v == 'tarde') return afternoon;
    if (v == 'noche') return night;
    if (v == 'jornada completa' || v == 'completa') return fullDay;

    // 3) Compat labels ya traducidos (si vinieran desde UI)
    //    Best-effort: comparamos contra los labels actuales
    final m = _TurnoKey.label(l10n, morning).toLowerCase();
    final a = _TurnoKey.label(l10n, afternoon).toLowerCase();
    final n = _TurnoKey.label(l10n, night).toLowerCase();
    final f = _TurnoKey.label(l10n, fullDay).toLowerCase();

    if (v == m) return morning;
    if (v == a) return afternoon;
    if (v == n) return night;
    if (v == f) return fullDay;

    return morning;
  }
}

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

class InstitucionCroquisAulaPage extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  /// Opcional: se usan para preseleccionar (si llega vacío, se deja editable)
  final String aulaInicial;

  /// CANÓNICO preferido: turnoKey estable (morning/afternoon/night/full_day).
  /// Compat legacy: si llega label (“Mañana”), se mapea best-effort.
  final String turnoInicial;

  const InstitucionCroquisAulaPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    this.aulaInicial = '',
    this.turnoInicial = _TurnoKey.morning,
  });

  @override
  State<InstitucionCroquisAulaPage> createState() =>
      _InstitucionCroquisAulaPageState();
}

class _InstitucionCroquisAulaPageState
    extends State<InstitucionCroquisAulaPage> {
  final CroquisRepositoryPrefs _repo = CroquisRepositoryPrefs();

  bool _loading = true;
  bool _saving = false;

  late final TextEditingController _aulaCtrl;

  /// ✅ Persistimos y operamos con turnoKey estable
  late String _turnoKey;

  CroquisAula? _croquis;

  int _lastSavedHash = 0;

  String get _instId => _norm(widget.institucionId);

  @override
  void initState() {
    super.initState();

    _aulaCtrl = TextEditingController(text: widget.aulaInicial.trim());

    // Nota: l10n todavía no está disponible en initState de forma segura para label compare,
    // pero sí para parse canonical/legacy ES. El resto se “heal” en build/bootstrap.
    _turnoKey = _norm(widget.turnoInicial);
    if (!_TurnoKey.isValid(_turnoKey)) {
      // Compat “Mañana/Tarde/…” sin depender de l10n aún
      final v = _turnoKey.toLowerCase();
      if (v == 'mañana' || v == 'manana') {
        _turnoKey = _TurnoKey.morning;
      } else if (v == 'tarde') {
        _turnoKey = _TurnoKey.afternoon;
      } else if (v == 'noche') {
        _turnoKey = _TurnoKey.night;
      } else if (v == 'jornada completa' || v == 'completa') {
        _turnoKey = _TurnoKey.fullDay;
      } else {
        _turnoKey = _TurnoKey.morning;
      }
    }

    // ignore: discarded_futures
    _bootstrap();
  }

  @override
  void dispose() {
    _aulaCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // State helpers
  // ─────────────────────────────────────────────

  int _hashCroquis(CroquisAula? c) {
    if (c == null) return 0;

    int h = 17;
    h = 37 * h + c.institucionId.hashCode;
    h = 37 * h + c.aula.hashCode;
    h = 37 * h + c.turno.hashCode;
    h = 37 * h + c.filas.hashCode;
    h = 37 * h + c.columnas.hashCode;

    final cells = c.celdas;
    final take = cells.length <= 160 ? cells.length : 160;
    for (int i = 0; i < take; i++) {
      final v = cells[i];
      h = 37 * h + (v == null ? 0 : v.hashCode);
    }

    for (final g in c.grupos) {
      h = 37 * h + g.titulo.hashCode;
      h = 37 * h + g.fila.hashCode;
      h = 37 * h + g.col.hashCode;
      h = 37 * h + g.alto.hashCode;
      h = 37 * h + g.ancho.hashCode;
      h = 37 * h + (g.colorHex ?? '').hashCode;
    }

    return h;
  }

  bool get _hasUnsavedChanges {
    final c = _croquis;
    if (c == null) return false;
    return _hashCroquis(c) != _lastSavedHash;
  }

  CroquisAula _healCroquis(CroquisAula c) {
    int filas = c.filas;
    int columnas = c.columnas;
    if (filas <= 0) filas = 10;
    if (columnas <= 0) columnas = 10;

    final expected = filas * columnas;
    final next = List<String?>.from(c.celdas);

    if (next.length < expected) {
      next.addAll(List<String?>.filled(expected - next.length, null));
    } else if (next.length > expected) {
      next.removeRange(expected, next.length);
    }

    final changed =
        filas != c.filas ||
        columnas != c.columnas ||
        next.length != c.celdas.length;

    if (!changed) return c;

    return c.copyWith(
      filas: filas,
      columnas: columnas,
      celdas: next,
      grupos: List<CroquisGrupo>.from(c.grupos),
    );
  }

  CroquisAula _newEmpty({
    required String instId,
    required String aula,
    required String turnoKey,
  }) {
    return CroquisAula(
      institucionId: instId,
      aula: aula,
      turno: turnoKey, // ✅ persistimos turnoKey
      filas: 10,
      columnas: 10,
      celdas: List<String?>.filled(100, null),
      grupos: const <CroquisGrupo>[],
    );
  }

  // ─────────────────────────────────────────────
  // UX helpers
  // ─────────────────────────────────────────────

  void _snack(String msg) {
    if (!mounted) return;
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      // NO-OP
    }
  }

  String _pageTitle(AppLocalizations l10n) {
    final name = widget.institucionNombre.trim();
    return name.isEmpty ? l10n.croquisTitle : '${l10n.croquisTitle} · $name';
  }

  // ─────────────────────────────────────────────
  // Data flow
  // ─────────────────────────────────────────────

  Future<void> _bootstrap() async {
    final l10n = AppLocalizations.of(context);

    // Heal turnoKey usando l10n (por si vino label traducido)
    final healedTurno = _TurnoKey.tryParseAny(_turnoKey, l10n);
    if (healedTurno != _turnoKey && mounted) {
      setState(() => _turnoKey = healedTurno);
    }

    if (_instId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(l10n.croquisSnackInvalidInstitution);
      return;
    }

    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final l10n = AppLocalizations.of(context);

    final instId = _instId;
    final aula = _norm(_aulaCtrl.text);
    final turnoKey = _TurnoKey.tryParseAny(_turnoKey, l10n);

    if (turnoKey != _turnoKey && mounted) {
      setState(() => _turnoKey = turnoKey);
    }

    if (aula.isEmpty) {
      final empty = _newEmpty(instId: instId, aula: '', turnoKey: turnoKey);

      if (!mounted) return;
      setState(() {
        _croquis = empty;
        _loading = false;
        _lastSavedHash = _hashCroquis(empty);
      });
      return;
    }

    CroquisAula? loaded;
    try {
      loaded = await _repo.load(
        institucionId: instId,
        aula: aula,
        turno: turnoKey, // ✅ key estable
      );
    } catch (_) {
      loaded = null;
    }

    final base =
        loaded ?? _newEmpty(instId: instId, aula: aula, turnoKey: turnoKey);
    final healed = _healCroquis(base);

    if (!mounted) return;
    setState(() {
      _croquis = healed;
      _loading = false;
      _lastSavedHash = _hashCroquis(healed);
    });
  }

  Future<void> _save({bool silent = false}) async {
    if (_saving) return;

    final c = _croquis;
    if (c == null) return;

    final l10n = AppLocalizations.of(context);
    final aula = _norm(_aulaCtrl.text);
    if (aula.isEmpty) {
      if (!silent) _snack(l10n.croquisSnackEnterAulaBeforeSave);
      return;
    }

    final turnoKey = _TurnoKey.tryParseAny(_turnoKey, l10n);
    if (turnoKey != _turnoKey && mounted) {
      setState(() => _turnoKey = turnoKey);
    }

    if (!mounted) return;
    setState(() => _saving = true);

    try {
      final fixed = _healCroquis(
        c.copyWith(institucionId: _instId, aula: aula, turno: turnoKey),
      );

      await _repo.save(fixed);

      if (!mounted) return;
      setState(() {
        _croquis = fixed;
        _lastSavedHash = _hashCroquis(fixed);
      });

      if (!silent) _snack(l10n.croquisSnackSaved);
    } catch (e) {
      if (!silent) _snack(l10n.croquisSnackSaveError('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearGrid() async {
    final c = _croquis;
    if (c == null) return;

    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final cancel = MaterialLocalizations.of(dialogCtx).cancelButtonLabel;
        final okLabel = MaterialLocalizations.of(dialogCtx).okButtonLabel;

        return AlertDialog(
          title: Text(l10n.croquisDialogClearTitle),
          content: Text(l10n.croquisDialogClearBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(okLabel),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final cleared = _healCroquis(
      c.copyWith(
        celdas: List<String?>.filled(c.filas * c.columnas, null),
        grupos: const <CroquisGrupo>[],
      ),
    );

    if (!mounted) return;
    setState(() => _croquis = cleared);

    final aula = _norm(_aulaCtrl.text);
    if (aula.isNotEmpty) {
      // ignore: discarded_futures
      _save(silent: true);
    }
  }

  Future<void> _editCell(int fila, int col) async {
    final c0 = _croquis;
    if (c0 == null) return;

    final l10n = AppLocalizations.of(context);

    final c = _healCroquis(c0);
    if (!identical(c, c0) && mounted) setState(() => _croquis = c);

    final current = (c.nombreEn(fila, col) ?? '').trim();
    final ctrl = TextEditingController(text: current);

    final res = await showDialog<String?>(
      context: context,
      builder: (dialogCtx) {
        final cancel = MaterialLocalizations.of(dialogCtx).cancelButtonLabel;
        final save = MaterialLocalizations.of(dialogCtx).saveButtonLabel;

        return AlertDialog(
          title: Text(l10n.croquisDialogCellTitle),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: l10n.croquisFieldNameLabel,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => Navigator.of(dialogCtx).pop(ctrl.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(null),
              child: Text(cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(ctrl.text),
              child: Text(save),
            ),
          ],
        );
      },
    );

    ctrl.dispose();
    if (res == null) return;

    final name = _norm(res);
    final idx = c.indexOf(fila, col);

    final next = List<String?>.from(c.celdas);
    if (idx >= 0 && idx < next.length) {
      next[idx] = name.isEmpty ? null : name;
    }

    final updated = _healCroquis(c.conCeldas(next));

    if (!mounted) return;
    setState(() => _croquis = updated);

    final aula = _norm(_aulaCtrl.text);
    if (aula.isNotEmpty) {
      // ignore: discarded_futures
      _save(silent: true);
    }
  }

  Future<void> _addGrupo() async {
    final c = _croquis;
    if (c == null) return;

    final l10n = AppLocalizations.of(context);

    final tituloCtrl = TextEditingController();
    final filaCtrl = TextEditingController(text: '0');
    final colCtrl = TextEditingController(text: '0');
    final altoCtrl = TextEditingController(text: '1');
    final anchoCtrl = TextEditingController(text: '1');
    final colorCtrl = TextEditingController();

    CroquisGrupo? res;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final cancel = MaterialLocalizations.of(dialogCtx).cancelButtonLabel;
        final save = MaterialLocalizations.of(dialogCtx).saveButtonLabel;

        return AlertDialog(
          title: Text(l10n.croquisDialogNewGroupTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.croquisFieldGroupTitleLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: colorCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.croquisFieldGroupColorLabel,
                    hintText: l10n.croquisFieldGroupColorHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: filaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.croquisFieldRowLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: colCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.croquisFieldColLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: altoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.croquisFieldHeightLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: anchoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.croquisFieldWidthLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(cancel),
            ),
            ElevatedButton(
              onPressed: () {
                int parseI(String s, int fb) => int.tryParse(s.trim()) ?? fb;

                final titulo = _norm(tituloCtrl.text);
                final fila = parseI(filaCtrl.text, 0);
                final col = parseI(colCtrl.text, 0);
                final alto = parseI(altoCtrl.text, 1);
                final ancho = parseI(anchoCtrl.text, 1);

                final colorRaw = _norm(colorCtrl.text);
                final colorHex = colorRaw.isEmpty ? null : colorRaw;

                res = CroquisGrupo(
                  titulo: titulo,
                  fila: fila < 0 ? 0 : fila,
                  col: col < 0 ? 0 : col,
                  alto: alto <= 0 ? 1 : alto,
                  ancho: ancho <= 0 ? 1 : ancho,
                  colorHex: colorHex,
                );

                Navigator.of(dialogCtx).pop();
              },
              child: Text(save),
            ),
          ],
        );
      },
    );

    tituloCtrl.dispose();
    filaCtrl.dispose();
    colCtrl.dispose();
    altoCtrl.dispose();
    anchoCtrl.dispose();
    colorCtrl.dispose();

    if (res == null) return;

    final next = List<CroquisGrupo>.from(c.grupos)..add(res!);
    final updated = _healCroquis(c.copyWith(grupos: next));

    if (!mounted) return;
    setState(() => _croquis = updated);

    final aula = _norm(_aulaCtrl.text);
    if (aula.isNotEmpty) {
      // ignore: discarded_futures
      _save(silent: true);
    }
  }

  Future<void> _removeGrupo(int index) async {
    final c = _croquis;
    if (c == null) return;
    if (index < 0 || index >= c.grupos.length) return;

    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final cancel = MaterialLocalizations.of(dialogCtx).cancelButtonLabel;
        final okLabel = MaterialLocalizations.of(dialogCtx).okButtonLabel;

        return AlertDialog(
          title: Text(l10n.croquisDialogDeleteGroupTitle),
          content: Text(l10n.croquisDialogDeleteGroupBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(okLabel),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final next = List<CroquisGrupo>.from(c.grupos)..removeAt(index);
    final updated = _healCroquis(c.copyWith(grupos: next));

    if (!mounted) return;
    setState(() => _croquis = updated);

    final aula = _norm(_aulaCtrl.text);
    if (aula.isNotEmpty) {
      // ignore: discarded_futures
      _save(silent: true);
    }
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  Widget _grid(CroquisAula c) {
    final cols = c.columnas;
    final rows = c.filas;

    const maxCell = 48.0;
    const minCell = 26.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cs = Theme.of(context).colorScheme;

        final width = constraints.maxWidth;
        final cell = (width / cols).clamp(minCell, maxCell);
        final gridWidth = cell * cols;

        final borderColor = Theme.of(
          context,
        ).dividerColor.withAlpha(_alpha(0.70));
        final filledColor = cs.primary.withAlpha(_alpha(0.10));

        return Center(
          child: SizedBox(
            width: gridWidth,
            child: Column(
              children: List.generate(rows, (r) {
                return Row(
                  children: List.generate(cols, (cc) {
                    final name = (c.nombreEn(r, cc) ?? '').trim();
                    final has = name.isNotEmpty;

                    return InkWell(
                      onTap: (_loading || _saving)
                          ? null
                          : () => _editCell(r, cc),
                      child: Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          color: has ? filledColor : null,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(2),
                        child: Text(
                          has ? _shortName(name) : '',
                          textAlign: TextAlign.center,
                          style:
                              (Theme.of(context).textTheme.bodySmall ??
                                      const TextStyle(fontSize: 12))
                                  .copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  String _shortName(String n) {
    final parts = n.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return n;
    if (parts.length == 1) return parts.first;
    final first = parts.first;
    final last = parts.last;
    final initial = last.isNotEmpty ? '${last[0].toUpperCase()}.' : '';
    return '$first $initial';
  }

  Future<bool> _confirmLeaveIfDirty() async {
    if (_loading || _saving) return true;
    if (!_hasUnsavedChanges) return true;

    final l10n = AppLocalizations.of(context);
    final res = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final cancel = MaterialLocalizations.of(dialogCtx).cancelButtonLabel;
        final okLabel = MaterialLocalizations.of(dialogCtx).okButtonLabel;

        return AlertDialog(
          title: Text(l10n.croquisDialogUnsavedTitle),
          content: Text(l10n.croquisDialogUnsavedBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(okLabel),
            ),
          ],
        );
      },
    );

    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _croquis;

    // ✅ Captura navigator para no usar context tras await en pop handler.
    final nav = Navigator.of(context);

    // ✅ Valor estable (turnoKey)
    final String safeTurnoKey = _TurnoKey.isValid(_turnoKey)
        ? _turnoKey
        : _TurnoKey.morning;

    return PopScope(
      canPop: !_loading && !_saving && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final ok = await _confirmLeaveIfDirty();
        if (!mounted) return;

        if (ok) {
          try {
            nav.pop();
          } catch (_) {
            // NO-OP
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pageTitle(l10n)),
          actions: [
            IconButton(
              onPressed: (_loading || _saving) ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.actionLoad,
            ),
            IconButton(
              onPressed: (_loading || _saving) ? null : () => _save(),
              icon: const Icon(Icons.save),
              tooltip: l10n.actionSave,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: (_loading || _saving) ? null : () => _save(),
          icon: const Icon(Icons.save),
          label: Text(_saving ? l10n.actionSaving : l10n.actionSave),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (c == null)
              ? Center(child: Text(l10n.croquisErrorInit))
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.croquisSectionAulaTurno,
                              style:
                                  (Theme.of(context).textTheme.titleMedium ??
                                          const TextStyle(fontSize: 16))
                                      .copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _aulaCtrl,
                                    decoration: InputDecoration(
                                      labelText: l10n.croquisFieldAulaLabel,
                                      hintText: l10n.croquisFieldAulaHint,
                                      border: const OutlineInputBorder(),
                                    ),
                                    textInputAction: TextInputAction.search,
                                    enabled: !_saving,
                                    onSubmitted: (_) => _load(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey<String>(safeTurnoKey),
                                    initialValue: safeTurnoKey,
                                    decoration: InputDecoration(
                                      labelText: l10n.croquisFieldTurnoLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: _TurnoKey.all
                                        .map(
                                          (k) => DropdownMenuItem<String>(
                                            value: k,
                                            child: Text(
                                              _TurnoKey.label(l10n, k),
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (_loading || _saving)
                                        ? null
                                        : (v) {
                                            if (v == null) return;
                                            if (v == _turnoKey) return;
                                            setState(() => _turnoKey = v);
                                            // ignore: discarded_futures
                                            _load();
                                          },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: (_loading || _saving)
                                      ? null
                                      : _clearGrid,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(l10n.croquisActionClearGrid),
                                ),
                                OutlinedButton.icon(
                                  onPressed: (_loading || _saving)
                                      ? null
                                      : _addGrupo,
                                  icon: const Icon(Icons.select_all),
                                  label: Text(l10n.croquisActionAddGroup),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(l10n.croquisTipTapCellAutosave),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.croquisSectionGrid,
                              style:
                                  (Theme.of(context).textTheme.titleMedium ??
                                          const TextStyle(fontSize: 16))
                                      .copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 10),
                            _grid(c),
                            const SizedBox(height: 10),
                            Text(l10n.croquisGridSizeLine(c.filas, c.columnas)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.croquisSectionGroups,
                              style:
                                  (Theme.of(context).textTheme.titleMedium ??
                                          const TextStyle(fontSize: 16))
                                      .copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            if (c.grupos.isEmpty)
                              Text(l10n.croquisGroupsEmpty)
                            else
                              ...List.generate(c.grupos.length, (i) {
                                final g = c.grupos[i];
                                final titulo = g.titulo.trim().isEmpty
                                    ? l10n.croquisGroupFallbackTitle
                                    : g.titulo.trim();

                                final color = (g.colorHex ?? '').trim();
                                final colorLine = color.isEmpty
                                    ? ''
                                    : ' · $color';

                                final subtitle =
                                    '${g.fila}, ${g.col} · ${g.alto}x${g.ancho}$colorLine';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(titulo),
                                  subtitle: Text(subtitle),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: (_loading || _saving)
                                        ? null
                                        : () => _removeGrupo(i),
                                    tooltip: l10n.actionDelete,
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Utils (archivo-local, mínimos, sin dependencia extra)
// ─────────────────────────────────────────────

String _norm(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  return parts.join(' ');
}

int _alpha(double opacity) {
  final v = (opacity * 255).round();
  if (v < 0) return 0;
  if (v > 255) return 255;
  return v;
}
