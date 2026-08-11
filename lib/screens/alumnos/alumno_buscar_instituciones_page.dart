// ─────────────────────────────────────────────
// ATENA – UI ALUMNO: BUSCAR INSTITUCIONES (OWNER-ONLY)
// Archivo: lib/screens/alumnos/alumno_buscar_instituciones_page.dart
// ─────────────────────────────────────────────
//
// Notas canónicas (enero 2026):
// - Filtro extracurricular usa BloqueExtracurricular como fuente de verdad.
// - “Otros” incluido.
// - Guía/leyenda NO se hardcodea: BloqueExtracurricular.descripcionCorta/ejemplos.
//
// OPTIMIZACIÓN – BÚSQUEDA/PAGINACIÓN (backend-ready):
// - buscarInstitucionesPaginado(query, offset, limit) → índice liviano.
// - Hidrata institución completa solo al entrar (en pantalla siguiente).
//
// ✅ CIERRE FASE 2:
// - ✅ i18n REAL: AppLocalizations.of(context).<key> (sin fallbacks)
// - ✅ Theme/ColorScheme real (sin Colors.* fijo)
// - ✅ Hardening: refresh disabled mientras carga
// - ✅ Simplificación: menos helpers, mismo comportamiento
//
// ✅ E2E (feb 2026):
// - Botón "Extracurricular" navega a selección de grupo extracurricular por institución.
//
// ✅ EXTENSIÓN (feb 2026):
// - Previsualización del “perfil público” (cómo lo ve el alumno) on-demand,
//   sin romper paginación: hidrata institución solo para preview.
//
// ✅ HARDENING (feb 2026) – ESTE ARCHIVO:
// - Bootstrapping post-frame (evita depender de l10n en initState).
// - Timeouts cortos en IO (helpers/prefs) para evitar awaits colgados.
// - Public preview: manejo de snap.hasError (no queda “silencioso”).
// - Prefs keys: institucionId normalizado para key (trim + remove whitespace interno).
// - No cambia IDs de DATA (para navegación), solo normaliza para keys de prefs.
//
// ✅ HARDENING (feb 2026 · diagnóstico):
// - Logs [ATENA][ALUMNO][BUSCAR_INST] para rastrear institucionId y navegación.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ ATENA usa l10n generado en /lib/l10n/gen (no flutter_gen)
import '../../l10n/gen/app_localizations.dart';

// Modelos (solo lo necesario para el filtro)
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';

// Servicios
import '../../services/instituciones_helpers.dart' as ih;

// Pantallas siguientes del flujo
import 'alumno_seleccion_grupo_extracurricular_page.dart';
import 'alumno_seleccion_grupo_page.dart';

class AlumnoBuscarInstitucionesPage extends StatefulWidget {
  final String alumnoDni;
  final String ownerAccountId;
  final String perfilId;

  const AlumnoBuscarInstitucionesPage({
    super.key,
    required this.alumnoDni,
    required this.ownerAccountId,
    required this.perfilId,
  });

  @override
  State<AlumnoBuscarInstitucionesPage> createState() =>
      _AlumnoBuscarInstitucionesPageState();
}

class _AlumnoBuscarInstitucionesPageState
    extends State<AlumnoBuscarInstitucionesPage> {
  // Estado UI
  bool _cargando = true;
  bool _cargandoMas = false;
  String? _errorCarga;

  // Búsqueda (con debounce)
  final _busquedaCtrl = TextEditingController();
  Timer? _debounce;
  String _filtroNombre = '';

  // Data source (local hoy, backend mañana)
  int _offset = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;

  // IO hardening
  static const Duration _ioTimeout = Duration(seconds: 6);

  // Cache liviana (fuente de UI)
  final List<ih.InstitucionSearchItem> _todas = [];
  List<ih.InstitucionSearchItem> _filtradas = [];

  final Set<BloqueExtracurricular> _bloquesSeleccionados = {};

  final ScrollController _scrollCtrl = ScrollController();

  // ─────────────────────────────────────────────
  // Normalizador para keys/prefs (NO para DATA IDs)
  static String _kid(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  @override
  void initState() {
    super.initState();
    _busquedaCtrl.addListener(_onBusquedaChanged);
    _scrollCtrl.addListener(_onScroll);

    // ✅ Bootstrapping post-frame: evita depender de InheritedWidgets (l10n/theme)
    // durante initState y elimina edge-cases tipo “cargando infinito”.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: discarded_futures
      _recargarDesdeCero(cargando: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaCtrl.removeListener(_onBusquedaChanged);
    _busquedaCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore) return;
    if (_cargandoMas || _cargando) return;
    if (!_scrollCtrl.hasClients) return;

    final pos = _scrollCtrl.position;
    if (pos.pixels >= (pos.maxScrollExtent - 240)) {
      // ignore: discarded_futures
      _cargarMas();
    }
  }

  void _onBusquedaChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;

      final nuevo = _busquedaCtrl.text.trim().toLowerCase();
      if (nuevo == _filtroNombre) return;

      setState(() {
        _filtroNombre = nuevo;
      });

      // ignore: discarded_futures
      _recargarDesdeCero(cargando: true);
    });
  }

  void _resetPaginacion({required bool cargando}) {
    _offset = 0;
    _hasMore = true;
    _todas.clear();
    _filtradas = [];
    _errorCarga = null;
    _cargando = cargando;
    _cargandoMas = false;
  }

  ih.InstitucionSearchQuery _buildQuery() {
    return ih.InstitucionSearchQuery(
      texto: _filtroNombre,
      bloquesExtra: Set<BloqueExtracurricular>.from(_bloquesSeleccionados),
    );
  }

  Future<void> _recargarDesdeCero({required bool cargando}) async {
    if (!mounted) return;

    // Capturamos l10n antes de awaits para evitar lint.
    final l10n = AppLocalizations.of(context);

    setState(() => _resetPaginacion(cargando: cargando));

    dev.log(
      '[ATENA][ALUMNO][BUSCAR_INST] recargarDesdeCero: owner="${widget.ownerAccountId}" perfil="${widget.perfilId}" filtro="$_filtroNombre" bloques=${_bloquesSeleccionados.length}',
    );

    try {
      await _cargarPagina().timeout(_ioTimeout);
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _aplicarOrdenLocal();
      });

      dev.log(
        '[ATENA][ALUMNO][BUSCAR_INST] OK: items=${_todas.length} hasMore=$_hasMore nextOffset=$_offset',
      );
    } catch (e) {
      if (!mounted) return;
      dev.log(
        '[ATENA][ALUMNO][BUSCAR_INST] ERROR recargarDesdeCero: $e',
        error: e,
      );
      setState(() {
        _cargando = false;
        _errorCarga = l10n.alumnoBuscarInstitucionesErrorCargar(e.toString());
      });
    }
  }

  Future<void> _cargarMas() async {
    if (!_hasMore || _cargandoMas || _cargando) return;
    if (!mounted) return;

    // Capturamos l10n antes de awaits para evitar lint.
    final l10n = AppLocalizations.of(context);

    setState(() {
      _cargandoMas = true;
      _errorCarga = null;
    });

    dev.log(
      '[ATENA][ALUMNO][BUSCAR_INST] cargarMas: offset=$_offset pageSize=$_pageSize',
    );

    try {
      await _cargarPagina().timeout(_ioTimeout);
      if (!mounted) return;
      setState(() {
        _cargandoMas = false;
        _aplicarOrdenLocal();
      });

      dev.log(
        '[ATENA][ALUMNO][BUSCAR_INST] OK cargarMas: items=${_todas.length} hasMore=$_hasMore nextOffset=$_offset',
      );
    } catch (e) {
      if (!mounted) return;
      dev.log('[ATENA][ALUMNO][BUSCAR_INST] ERROR cargarMas: $e', error: e);
      setState(() {
        _cargandoMas = false;
        _errorCarga = l10n.alumnoBuscarInstitucionesErrorCargarMas(
          e.toString(),
        );
      });
    }
  }

  Future<void> _cargarPagina() async {
    if (!_hasMore) return;

    final page = await ih
        .buscarInstitucionesPaginado(
          query: _buildQuery(),
          offset: _offset,
          limit: _pageSize,
        )
        .timeout(_ioTimeout);

    if (page.items.isEmpty) {
      _hasMore = false;
      return;
    }

    // Hardening: filtra IDs vacíos y evita duplicados por institucionId.
    final existingIds = _todas.map((e) => e.institucionId.trim()).toSet();
    final toAdd = <ih.InstitucionSearchItem>[];
    for (final it in page.items) {
      final id = it.institucionId.trim();
      if (id.isEmpty) continue;
      if (existingIds.contains(id)) continue;
      existingIds.add(id);
      toAdd.add(it);
    }

    _todas.addAll(toAdd);
    _offset = page.nextOffset;
    _hasMore = page.hasMore;
  }

  void _aplicarOrdenLocal() {
    if (_todas.isEmpty) {
      _filtradas = [];
      return;
    }

    final next = List<ih.InstitucionSearchItem>.from(
      _todas,
    )..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    _filtradas = next;
  }

  Future<void> _abrirInstitucionCurricular(
    ih.InstitucionSearchItem item,
  ) async {
    final id = item.institucionId.trim(); // DATA ID (solo trim)
    if (id.isEmpty) return;
    if (!mounted) return;

    dev.log(
      '[ATENA][ALUMNO][BUSCAR_INST] abrirCurricular: institucionId="$id" nombre="${item.nombre}"',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlumnoSeleccionGrupoPage(
          institucionId: id,
          institucionNombre: item.nombre,
          alumnoDocumento: widget.alumnoDni,
          ownerAccountId: widget.ownerAccountId,
          perfilId: widget.perfilId,
        ),
      ),
    );
  }

  Future<void> _abrirInstitucionExtracurricular(
    ih.InstitucionSearchItem item,
  ) async {
    final id = item.institucionId.trim(); // DATA ID (solo trim)
    if (id.isEmpty) return;
    if (!mounted) return;

    // Si el alumno filtró por 1 bloque, lo pasamos como inicial.
    BloqueExtracurricular? bloqueInicial;
    if (_bloquesSeleccionados.length == 1) {
      bloqueInicial = _bloquesSeleccionados.first;
    }

    dev.log(
      '[ATENA][ALUMNO][BUSCAR_INST] abrirExtracurricular: institucionId="$id" nombre="${item.nombre}" bloqueInicial=${bloqueInicial?.label ?? "-"}',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AlumnoSeleccionGrupoExtracurricularPage(
          institucionId: id,
          institucionNombre: item.nombre,
          alumnoDocumento: widget.alumnoDni, // compat visual
          ownerAccountId: widget.ownerAccountId,
          perfilId: widget.perfilId,
          bloqueInicial: bloqueInicial,
          filtroInicial: _filtroNombre,
        ),
      ),
    );
  }

  List<String> _previewBloques(
    Set<BloqueExtracurricular> bloques, {
    int max = 3,
  }) {
    if (bloques.isEmpty) return const [];
    final list = bloques.map((b) => b.label).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list.length <= max ? list : list.take(max).toList();
  }

  String _labelBloquesSeleccionados(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_bloquesSeleccionados.isEmpty) {
      return l10n.alumnoBuscarInstitucionesExtraAll;
    }
    final labels = _bloquesSeleccionados.map((b) => b.label).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return l10n.alumnoBuscarInstitucionesExtraSelected(labels.join(' • '));
  }

  String _subtitleBloque(BloqueExtracurricular b) {
    final desc = b.descripcionCorta.trim();
    final ej = b.ejemplos;
    final ejTxt = ej.isEmpty ? '' : ' • ${ej.first}';
    return desc.isEmpty ? ejTxt.trim() : '$desc$ejTxt';
  }

  Future<void> _abrirFiltroBloques() async {
    if (!mounted) return;
    if (_cargando || _cargandoMas) return;

    final l10n = AppLocalizations.of(context);

    final res = await showModalBottomSheet<Set<BloqueExtracurricular>>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final tmp = Set<BloqueExtracurricular>.from(_bloquesSeleccionados);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                Widget tile(BloqueExtracurricular b) {
                  final sel = tmp.contains(b);
                  return CheckboxListTile(
                    value: sel,
                    title: Text(b.label),
                    subtitle: Text(_subtitleBloque(b)),
                    onChanged: (v) {
                      setSheetState(() {
                        if (v == true) {
                          tmp.add(b);
                        } else {
                          tmp.remove(b);
                        }
                      });
                    },
                  );
                }

                final ordered = BloqueExtracurricularX.ordered();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.alumnoBuscarInstitucionesFiltroExtraTitle,
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setSheetState(() => tmp.clear()),
                          child: Text(l10n.commonClear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final b in ordered) tile(b),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, tmp),
                        child: Text(l10n.commonApply),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted || res == null) return;

    setState(() {
      _bloquesSeleccionados
        ..clear()
        ..addAll(res);
    });

    await _recargarDesdeCero(cargando: true);
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_cargandoMas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () {
              // ignore: discarded_futures
              _cargarMas();
            },
            icon: const Icon(Icons.expand_more),
            label: Text(l10n.commonLoadMore),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(l10n.commonEndOfResults, textAlign: TextAlign.center),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Preview del perfil público (cómo lo ve el alumno) – on demand
  static const int _maxPublicPhotos = 5;

  String _kPublicProfile(String institucionId) =>
      'inst_public_profile_v1_${_kid(institucionId)}';

  Future<_InstPublicExtra> _loadPublicExtra(String institucionId) async {
    final prefs = await SharedPreferences.getInstance().timeout(_ioTimeout);
    final key = _kPublicProfile(institucionId);
    final raw = (prefs.getString(key) ?? '').trim();
    return _InstPublicExtra.fromJson(raw);
  }

  Uint8List? _b64ToBytesSafe(String b64) {
    final t = b64.trim();
    if (t.isEmpty) return null;
    try {
      return base64Decode(t);
    } catch (_) {
      return null;
    }
  }

  void _openPhotoViewer(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: cs.surface,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirPreviewPerfilPublico(ih.InstitucionSearchItem item) async {
    final id = item.institucionId.trim(); // DATA ID (solo trim)
    if (id.isEmpty) return;
    if (!mounted) return;

    dev.log(
      '[ATENA][ALUMNO][BUSCAR_INST] previewPublico: institucionId="$id" nombre="${item.nombre}"',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;

        Future<_InstPreviewData> load() async {
          // Hidrata institución solo para preview (on-demand).
          final inst = await ih.cargarInstitucionPorId(id).timeout(_ioTimeout);
          final extra = await _loadPublicExtra(id);
          return _InstPreviewData(inst: inst, extra: extra);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: FutureBuilder<_InstPreviewData>(
              future: load(),
              builder: (ctx2, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // ✅ HARDENING: error explícito (sin quedar “vacío”)
                if (snap.hasError) {
                  return SizedBox(
                    height: 260,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                if (!snap.hasData || snap.data == null) {
                  return SizedBox(
                    height: 260,
                    child: Center(
                      child: Icon(Icons.error_outline, color: cs.onSurface),
                    ),
                  );
                }

                final data = snap.data!;
                final inst = data.inst;
                final extra = data.extra;

                final nombre = (inst?.nombre ?? item.nombre).trim();
                final ciudad = (inst?.ciudad ?? '').trim();
                final provincia = (inst?.provincia ?? '').trim();
                final direccion = (inst?.direccion ?? '').trim();

                final ubicacion = [
                  if (ciudad.isNotEmpty) ciudad,
                  if (provincia.isNotEmpty) provincia,
                ].join(', ');

                final fotosBytes = extra.fotos
                    .take(_maxPublicPhotos)
                    .map(_b64ToBytesSafe)
                    .whereType<Uint8List>()
                    .toList(growable: false);

                final desc = extra.descripcion.trim();
                final hAdmin = extra.horariosAtencion.trim();
                final hAulas = extra.horariosAulas.trim();
                final tel = extra.telefonoPublico.trim();
                final web = extra.website.trim();

                final servicios = extra.servicios
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(growable: false);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (ubicacion.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(ubicacion)),
                          ],
                        ),
                      if (direccion.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.place,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(direccion)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (fotosBytes.isNotEmpty) ...[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final b in fotosBytes)
                              InkWell(
                                onTap: () => _openPhotoViewer(b),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 98,
                                  height: 98,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: cs.outlineVariant.withValues(
                                        alpha:
                                            theme.brightness == Brightness.dark
                                            ? 0.55
                                            : 0.35,
                                      ),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.memory(b, fit: BoxFit.cover),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (desc.isNotEmpty) ...[
                        Text(desc),
                        const SizedBox(height: 12),
                      ],
                      if (hAdmin.isNotEmpty || hAulas.isNotEmpty) ...[
                        if (hAdmin.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(hAdmin)),
                            ],
                          ),
                        if (hAulas.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(hAulas)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                      if (tel.isNotEmpty || web.isNotEmpty) ...[
                        if (tel.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.phone_in_talk,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(tel)),
                            ],
                          ),
                        if (web.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.language,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(web)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                      if (servicios.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in servicios)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(
                                    alpha: theme.brightness == Brightness.dark
                                        ? 0.55
                                        : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(
                                      alpha: theme.brightness == Brightness.dark
                                          ? 0.55
                                          : 0.35,
                                    ),
                                  ),
                                ),
                                child: Text(s),
                              ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final inputFill = cs.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.55 : 1.0,
    );
    final outline = cs.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.35);

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.alumnoBuscarInstitucionesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alumnoBuscarInstitucionesTitle),
        actions: [
          IconButton(
            onPressed: (_cargando || _cargandoMas)
                ? null
                : () {
                    // ignore: discarded_futures
                    _recargarDesdeCero(cargando: true);
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
            if (_errorCarga != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.55 : 1.0,
                  ),
                  border: Border.all(color: outline),
                ),
                child: Text(
                  _errorCarga!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: l10n.alumnoBuscarInstitucionesHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: inputFill,
                suffixIcon: _filtroNombre.isEmpty
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
            InkWell(
              onTap: (_cargando || _cargandoMas)
                  ? null
                  : () {
                      // ignore: discarded_futures
                      _abrirFiltroBloques();
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 1.0,
                  ),
                  border: Border.all(color: outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _labelBloquesSeleccionados(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtradas.isEmpty
                  ? Center(
                      child: Text(
                        _todas.isEmpty
                            ? l10n.alumnoBuscarInstitucionesNoHayInstituciones
                            : l10n.alumnoBuscarInstitucionesNoResultadosConFiltro,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollCtrl,
                      itemCount: _filtradas.length + 1,
                      separatorBuilder: (ctx, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == _filtradas.length) {
                          return _buildFooter(context);
                        }

                        final item = _filtradas[i];
                        final previewBloques = _previewBloques(
                          item.bloquesExtra,
                        );

                        final curricularTxt = item.curricular == true
                            ? l10n.alumnoBuscarInstitucionesCurricularDisponible
                            : l10n.alumnoBuscarInstitucionesCurricularNoDisponible;

                        // Esta key acepta 1 argumento. Unificamos el contenido en 1 string.
                        final extraTxt = item.extracurricular == true
                            ? (item.bloquesExtra.isEmpty
                                  ? l10n.alumnoBuscarInstitucionesExtraSinModulos
                                  : l10n.alumnoBuscarInstitucionesExtraConModulos(
                                      '${item.bloquesExtra.length} • ${previewBloques.isEmpty ? '-' : previewBloques.join(' • ')}',
                                    ))
                            : l10n.alumnoBuscarInstitucionesExtraNoDisponible;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: outline),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(item.nombre),
                                  subtitle: Text('$curricularTxt\n\n$extraTxt'),
                                  trailing: IconButton(
                                    onPressed: () {
                                      // ignore: discarded_futures
                                      _abrirPreviewPerfilPublico(item);
                                    },
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: item.curricular == true
                                              ? () {
                                                  // ignore: discarded_futures
                                                  _abrirInstitucionCurricular(
                                                    item,
                                                  );
                                                }
                                              : null,
                                          icon: const Icon(
                                            Icons.school_outlined,
                                          ),
                                          label: Text(
                                            l10n.alumnoBuscarInstitucionesBtnCurricular,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              item.extracurricular == true
                                              ? () {
                                                  // ignore: discarded_futures
                                                  _abrirInstitucionExtracurricular(
                                                    item,
                                                  );
                                                }
                                              : null,
                                          icon: const Icon(Icons.sports_soccer),
                                          label: Text(
                                            l10n.alumnoBuscarInstitucionesBtnExtracurricular,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

// ─────────────────────────────────────────────
// Public extra (lectura) – mismo formato que Institución edita en su perfil.
// i18n: no agregamos labels acá; solo datos.
// ─────────────────────────────────────────────

class _InstPublicExtra {
  final String descripcion;
  final String horariosAtencion;
  final String horariosAulas;
  final String telefonoPublico;
  final String website;
  final List<String> servicios;
  final List<String> fotos;

  const _InstPublicExtra({
    this.descripcion = '',
    this.horariosAtencion = '',
    this.horariosAulas = '',
    this.telefonoPublico = '',
    this.website = '',
    this.servicios = const [],
    this.fotos = const [],
  });

  static _InstPublicExtra fromJson(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return const _InstPublicExtra();
    try {
      final decoded = jsonDecode(t);
      if (decoded is! Map) return const _InstPublicExtra();
      final m = decoded.cast<String, dynamic>();

      final serviciosRaw = (m['servicios'] is List)
          ? (m['servicios'] as List)
          : const [];
      final servicios = serviciosRaw
          .map((e) => (e ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final fotosRaw = (m['fotos'] is List) ? (m['fotos'] as List) : const [];
      final fotos = fotosRaw
          .map((e) => (e ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();

      return _InstPublicExtra(
        descripcion: (m['descripcion'] ?? '').toString(),
        horariosAtencion: (m['horariosAtencion'] ?? '').toString(),
        horariosAulas: (m['horariosAulas'] ?? '').toString(),
        telefonoPublico: (m['telefonoPublico'] ?? '').toString(),
        website: (m['website'] ?? '').toString(),
        servicios: servicios,
        fotos: fotos,
      );
    } catch (_) {
      return const _InstPublicExtra();
    }
  }
}

class _InstPreviewData {
  final Institucion? inst;
  final _InstPublicExtra extra;

  const _InstPreviewData({required this.inst, required this.extra});
}
