// ─────────────────────────────────────────────
// ATENA – UI ALUMNO: BUSCAR EXTRACURRICULARES (OWNER-ONLY)
// Archivo: lib/screens/alumnos/alumno_buscar_extracurriculares_page.dart
// ─────────────────────────────────────────────
//
// ✅ CIERRE FASE 2:
// - ✅ i18n REAL: AppLocalizations.of(context).<key> (sin fallbacks)
// - ✅ Theme/ColorScheme real (sin Colors.* fijo)
// - Hardening: refresh disabled mientras carga, mounted checks consistentes
// - Perf/UX: carga con timeout + anti-resultados viejos (token), sin locks “colgados”
//
// Nota canónica:
// - ownerAccountId → perfiles → perfilId (se pasa al siguiente screen).
// - alumnoDni se mantiene solo COMPAT visual (no lógica).

import 'dart:async';

import 'package:flutter/material.dart';

// ✅ ATENA usa l10n generado en /lib/l10n/gen (no flutter_gen)
import '../../l10n/gen/app_localizations.dart';

import '../../models/instituciones/instituciones_integrado.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/extracurriculares/grupo_extracurricular.dart';

import '../../services/instituciones_helpers.dart' as ih;
import '../../services/extracurriculares_service.dart';

import 'alumno_seleccion_grupo_extracurricular_page.dart';

class AlumnoBuscarExtracurricularesPage extends StatefulWidget {
  /// ⚠️ COMPAT (no usar como key lógica)
  final String alumnoDni;

  /// ✅ canónico
  final String ownerAccountId;
  final String perfilId;

  const AlumnoBuscarExtracurricularesPage({
    super.key,
    required this.alumnoDni,
    required this.ownerAccountId,
    required this.perfilId,
  });

  @override
  State<AlumnoBuscarExtracurricularesPage> createState() =>
      _AlumnoBuscarExtracurricularesPageState();
}

class _AlumnoBuscarExtracurricularesPageState
    extends State<AlumnoBuscarExtracurricularesPage> {
  bool _cargando = true;

  final _busquedaCtrl = TextEditingController();
  String _filtro = '';

  BloqueExtracurricular? _bloque;

  List<Institucion> _instituciones = [];

  /// Cache: por institución → grupos
  final Map<String, List<GrupoExtracurricular>> _gruposPorInst = {};

  int _loadSeq = 0;

  static String _norm(String v) => v.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _busquedaCtrl.addListener(_onFiltro);
    // ignore: discarded_futures
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.removeListener(_onFiltro);
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _onFiltro() {
    if (!mounted) return;
    setState(() => _filtro = _norm(_busquedaCtrl.text));
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    if (_cargando == true && _instituciones.isNotEmpty) return;

    // Capturamos l10n antes del await para evitar lint.
    final l10n = AppLocalizations.of(context);
    final mySeq = ++_loadSeq;

    setState(() => _cargando = true);

    try {
      final insts = await ih.cargarInstitucionesRegistradas().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) return;
      if (mySeq != _loadSeq) return;

      _gruposPorInst.clear();

      final onlyExtra = insts.where((i) => i.extracurricular == true).toList();

      // Cargamos grupos por institución con timeout para evitar “quedarse colgado”.
      for (final inst in onlyExtra) {
        final id = inst.id.trim();
        if (id.isEmpty) continue;

        final grupos = await ExtracurricularesService.instance
            .cargarGrupos(id)
            .timeout(const Duration(seconds: 10));

        if (!mounted) return;
        if (mySeq != _loadSeq) return;

        _gruposPorInst[id] = grupos;
      }

      if (!mounted) return;
      if (mySeq != _loadSeq) return;

      setState(() {
        _instituciones = onlyExtra;
        _cargando = false;
      });
    } on TimeoutException catch (_) {
      if (!mounted) return;
      if (mySeq != _loadSeq) return;

      setState(() {
        _instituciones = [];
        _gruposPorInst.clear();
        _cargando = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.commonGenericError)));
    } catch (e) {
      if (!mounted) return;
      if (mySeq != _loadSeq) return;

      setState(() {
        _instituciones = [];
        _gruposPorInst.clear();
        _cargando = false;
      });

      if (!mounted) return;

      final msg =
          '${l10n.alumnoBuscarExtracurricularesErrorCargar} ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  List<_ItemResultado> _armarResultados() {
    final out = <_ItemResultado>[];
    final filtro = _filtro;
    final bloqueSel = _bloque;

    for (final inst in _instituciones) {
      final id = inst.id.trim();
      if (id.isEmpty) continue;

      final grupos = _gruposPorInst[id] ?? const <GrupoExtracurricular>[];
      if (grupos.isEmpty) continue;

      // filtros
      var filtrados = grupos.where((g) => g.tieneCupos).toList();

      if (bloqueSel != null) {
        filtrados = filtrados.where((g) => g.bloque == bloqueSel).toList();
      }

      if (filtro.isNotEmpty) {
        final instName = _norm(inst.nombre);
        filtrados = filtrados.where((g) {
          final act = _norm(g.actividadNombre);
          final grp = _norm(g.nombreGrupo);
          return act.contains(filtro) ||
              grp.contains(filtro) ||
              instName.contains(filtro);
        }).toList();
      }

      if (filtrados.isEmpty) continue;

      // agrupamos por actividadNombre para preview
      final actividades = <String, int>{};
      for (final g in filtrados) {
        final k = g.actividadNombre.trim();
        if (k.isEmpty) continue;
        actividades[k] = (actividades[k] ?? 0) + 1;
      }

      out.add(
        _ItemResultado(
          institucion: inst,
          totalGrupos: filtrados.length,
          previewActividades: actividades.keys.take(3).toList(),
        ),
      );
    }

    out.sort(
      (a, b) => a.institucion.nombre.toLowerCase().compareTo(
        b.institucion.nombre.toLowerCase(),
      ),
    );

    return out;
  }

  Future<void> _abrirInstitucion(Institucion inst) async {
    final id = inst.id.trim();
    if (id.isEmpty) return;
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AlumnoSeleccionGrupoExtracurricularPage(
          institucionId: id,
          institucionNombre: inst.nombre,
          alumnoDocumento: widget.alumnoDni, // compat
          ownerAccountId: widget.ownerAccountId,
          perfilId: widget.perfilId,
          bloqueInicial: _bloque,
          filtroInicial: _filtro,
        ),
      ),
    );

    if (!mounted) return;
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resultados = _armarResultados();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final inputFill = cs.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.55 : 1.0,
    );

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.alumnoBuscarExtracurricularesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alumnoBuscarExtracurricularesTitle),
        actions: [
          IconButton(
            onPressed: _cargando
                ? null
                : () {
                    // ignore: discarded_futures
                    _cargar();
                  },
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: l10n.alumnoBuscarExtracurricularesHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: inputFill,
                suffixIcon: _filtro.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _busquedaCtrl.clear(),
                        tooltip: l10n.commonClear,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ FIX (Flutter): DropdownButtonFormField.value deprecado → usar DropdownButton (no deprecado)
            // Mantiene el mismo look&feel (InputDecorator + fill + label).
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.alumnoBuscarExtracurricularesBloqueOpcional,
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BloqueExtracurricular?>(
                  isExpanded: true,
                  value: _bloque,
                  items: [
                    DropdownMenuItem<BloqueExtracurricular?>(
                      value: null,
                      child: Text(l10n.commonAll),
                    ),
                    ...BloqueExtracurricularX.ordered().map(
                      (b) => DropdownMenuItem<BloqueExtracurricular?>(
                        value: b,
                        child: Text(b.label),
                      ),
                    ),
                  ],
                  onChanged: _cargando
                      ? null
                      : (v) {
                          if (!mounted) return;
                          setState(() => _bloque = v);
                        },
                ),
              ),
            ),

            const SizedBox(height: 12),
            Expanded(
              child: resultados.isEmpty
                  ? Center(
                      child: Text(
                        l10n.alumnoBuscarExtracurricularesEmpty,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: resultados.length,
                      separatorBuilder: (ctx, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = resultados[i];
                        final preview = r.previewActividades.isEmpty
                            ? '-'
                            : r.previewActividades.join(' • ');

                        final gruposLinea =
                            '${l10n.alumnoBuscarExtracurricularesGruposConCupo} ${r.totalGrupos}';
                        final previewLinea = '${l10n.commonPreview} $preview';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(
                                alpha: isDark ? 0.55 : 0.35,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(r.institucion.nombre),
                            subtitle: Text('$gruposLinea\n$previewLinea'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _abrirInstitucion(r.institucion),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemResultado {
  final Institucion institucion;
  final int totalGrupos;
  final List<String> previewActividades;

  _ItemResultado({
    required this.institucion,
    required this.totalGrupos,
    required this.previewActividades,
  });
}
