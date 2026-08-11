// ─────────────────────────────────────────────
// ATENA – UI ALUMNO: SELECCIONAR GRUPO EXTRACURRICULAR (OWNER-ONLY)
// Archivo: lib/screens/alumnos/alumno_seleccion_grupo_extracurricular_page.dart
// ─────────────────────────────────────────────
//
// HARDENING (fase 2):
// - Evita setState después de dispose en _cargar/_abrirSolicitud (mounted checks consistentes).
// - Normaliza y valida inputs mínimos (institucionId/owner/perfil).
// - Filtro: usa normalización estable y no rompe por nulls.
// - UI: mejora de accesibilidad (semantics), y ListTile denso (info compacta).
// - Dropdown: usa lista canónica BloqueExtracurricularX.ordered() para orden estable.
// - Perf: _filtrar no recalcula toLowerCase repetido (pre-normalización local por item).
// - UX: botón “Reintentar” cuando falla la carga (sin snack infinito).
//
// ✅ FIX (feb 2026 · anti-doble carga + timeouts):
// - _cargar() tiene guard real (si ya está cargando, ignora).
// - Token de carga (_loadSeq) evita aplicar resultados stale.
// - Timeout en carga de grupos.
//
// Nota:
// - Se mantiene alumnoDocumento solo por compat (no llave de dominio).
// - No introduce flujos paralelos; mantiene owner/perfil como requeridos para solicitar.
//
// ─────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';

// ✅ ATENA usa l10n generado en /lib/l10n/gen (no flutter_gen)
import '../../l10n/gen/app_localizations.dart';

import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/extracurriculares/grupo_extracurricular.dart';
import '../../services/extracurriculares_service.dart';

import 'alumno_solicitar_vacante_page.dart';

class AlumnoSeleccionGrupoExtracurricularPage extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  /// ⚠️ compat (no key lógica)
  final String alumnoDocumento;

  /// ✅ canónico
  final String ownerAccountId;
  final String perfilId;

  /// Filtros iniciales (vienen desde la pantalla anterior)
  final BloqueExtracurricular? bloqueInicial;
  final String? filtroInicial;

  const AlumnoSeleccionGrupoExtracurricularPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.alumnoDocumento,
    required this.ownerAccountId,
    required this.perfilId,
    this.bloqueInicial,
    this.filtroInicial,
  });

  @override
  State<AlumnoSeleccionGrupoExtracurricularPage> createState() =>
      _AlumnoSeleccionGrupoExtracurricularPageState();
}

class _AlumnoSeleccionGrupoExtracurricularPageState
    extends State<AlumnoSeleccionGrupoExtracurricularPage> {
  // ✅ Importante: iniciamos NO cargando para que _cargar() se ejecute en initState.
  bool _cargando = false;
  Object? _error;

  List<GrupoExtracurricular> _grupos = <GrupoExtracurricular>[];
  BloqueExtracurricular? _bloque;

  final TextEditingController _busquedaCtrl = TextEditingController();
  String _filtro = '';

  // Anti-resultados viejos / carreras
  int _loadSeq = 0;

  static String _norm(String v) => v.trim().toLowerCase();

  String get _instId => widget.institucionId.trim();
  String get _owner => widget.ownerAccountId.trim();
  String get _perfil => widget.perfilId.trim();

  @override
  void initState() {
    super.initState();
    _bloque = widget.bloqueInicial;
    _filtro = _norm(widget.filtroInicial ?? '');
    _busquedaCtrl.text = widget.filtroInicial ?? '';
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

  void _snack(ScaffoldMessengerState? messenger, String msg) {
    if (messenger == null) return;
    final m = msg.trim();
    if (m.isEmpty) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(m)));
    } catch (_) {
      // NO-OP
    }
  }

  // ----------------------------------------------------
  // CARGA
  // ----------------------------------------------------

  Future<void> _cargar() async {
    if (!mounted) return;

    // ✅ Guard real anti doble carga
    if (_cargando) return;

    final l = AppLocalizations.of(context);

    if (_instId.isEmpty) {
      setState(() {
        _cargando = false;
        _error = l.alumnoGrupoExtraInvalidInstitution;
        _grupos = <GrupoExtracurricular>[];
      });
      return;
    }

    final mySeq = ++_loadSeq;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final grupos = await ExtracurricularesService.instance
          .cargarGrupos(_instId)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (mySeq != _loadSeq) return; // resultado stale

      setState(() {
        _grupos = grupos;
        _cargando = false;
        _error = null;
      });
    } on TimeoutException catch (_) {
      if (!mounted) return;
      if (mySeq != _loadSeq) return;

      setState(() {
        _grupos = <GrupoExtracurricular>[];
        _cargando = false;
        _error = l.commonGenericError;
      });
    } catch (e) {
      if (!mounted) return;
      if (mySeq != _loadSeq) return;

      setState(() {
        _grupos = <GrupoExtracurricular>[];
        _cargando = false;
        _error = e;
      });
    }
  }

  // ----------------------------------------------------
  // FILTRO + ORDEN
  // ----------------------------------------------------

  List<GrupoExtracurricular> _filtrar() {
    final filtro = _filtro; // ya normalizado
    final bloqueSel = _bloque;

    final out = <GrupoExtracurricular>[];

    for (final g in _grupos) {
      // ✅ En esta pantalla se muestran solo grupos con cupos (flujo directo a solicitud).
      if (!g.tieneCupos) continue;
      if (bloqueSel != null && g.bloque != bloqueSel) continue;

      if (filtro.isNotEmpty) {
        final a = _norm(g.actividadNombre);
        final n = _norm(g.nombreGrupo);
        final t = _norm(g.turno);
        if (!(a.contains(filtro) || n.contains(filtro) || t.contains(filtro))) {
          continue;
        }
      }

      out.add(g);
    }

    // Orden estable: bloque(label) → actividad → grupo → turno
    out.sort((a, b) {
      final ba = _norm(a.bloque.label);
      final bb = _norm(b.bloque.label);
      final c1 = ba.compareTo(bb);
      if (c1 != 0) return c1;

      final aa = _norm(a.actividadNombre);
      final ab = _norm(b.actividadNombre);
      final c2 = aa.compareTo(ab);
      if (c2 != 0) return c2;

      final ga = _norm(a.nombreGrupo);
      final gb = _norm(b.nombreGrupo);
      final c3 = ga.compareTo(gb);
      if (c3 != 0) return c3;

      final ta = _norm(a.turno);
      final tb = _norm(b.turno);
      return ta.compareTo(tb);
    });

    return out;
  }

  // ----------------------------------------------------
  // NAVEGACIÓN
  // ----------------------------------------------------

  Future<void> _abrirSolicitud(GrupoExtracurricular g) async {
    final l = AppLocalizations.of(context);

    if (_owner.isEmpty || _perfil.isEmpty) {
      if (!mounted) return;
      _snack(
        ScaffoldMessenger.maybeOf(context),
        l.alumnoGrupoExtraMissingOwnerPerfil,
      );
      return;
    }

    // ✅ Captura messenger/nav ANTES de await
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);

    bool? ok;
    try {
      ok = await nav.push<bool>(
        MaterialPageRoute(
          builder: (_) => AlumnoSolicitarVacantePage(
            alumnoDocumento: widget.alumnoDocumento,
            institucionId: _instId, // ✅ trim canónico
            institucionNombre: widget.institucionNombre,
            actividadNombre: g.actividadNombre,
            esCurricular: false,
            ownerAccountId: _owner,
            perfilId: _perfil,
            aula: g.nombreGrupo, // “grupo”
            turno: g.turno,
            moduleKey: g.bloque.key, // ✅ canónico para solicitudes por módulo
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(messenger, l.alumnoGrupoExtraOpenSolicitudError('$e'));
      return;
    }

    if (!mounted) return;
    if (ok == true) {
      // Evitar doble carga si ya está en curso.
      if (_cargando) return;
      await _cargar();
    }
  }

  // ----------------------------------------------------
  // UI
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final inputFill = cs.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.55 : 1.0,
    );
    final outline = cs.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.35);

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(l.alumnoGrupoExtraTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.alumnoGrupoExtraTitle),
          actions: [
            IconButton(
              onPressed: _cargando
                  ? null
                  : () {
                      // ignore: discarded_futures
                      _cargar();
                    },
              icon: const Icon(Icons.refresh),
              tooltip: l.commonRetry,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 10),
                Text(
                  l.alumnoGrupoExtraLoadErrorTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _cargando
                      ? null
                      : () {
                          // ignore: discarded_futures
                          _cargar();
                        },
                  icon: const Icon(Icons.refresh),
                  label: Text(l.commonRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = _filtrar();
    final instNombre = widget.institucionNombre.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.alumnoGrupoExtraTitle),
        actions: [
          IconButton(
            onPressed: _cargando
                ? null
                : () {
                    // ignore: discarded_futures
                    _cargar();
                  },
            icon: const Icon(Icons.refresh),
            tooltip: l.commonRefresh,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              instNombre.isEmpty ? l.commonInstitution : instNombre,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: l.alumnoGrupoExtraSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: inputFill,
                suffixIcon: _filtro.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _busquedaCtrl.clear(),
                        tooltip: l.commonClear,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 10),

            // Bloques en orden canónico estable
            DropdownButtonFormField<BloqueExtracurricular?>(
              value: _bloque,
              decoration: InputDecoration(
                labelText: l.alumnoGrupoExtraBlockOptionalLabel,
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem<BloqueExtracurricular?>(
                  value: null,
                  child: Text(l.commonAll),
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

            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        l.alumnoGrupoExtraEmptyFiltered,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final g = items[i];

                        final cupoTxt = (g.cupoMaximo <= 0)
                            ? l.alumnoGrupoExtraCupoUnmanaged
                            : l.alumnoGrupoExtraCupoManaged(
                                g.cuposDisponibles,
                                g.cupoMaximo,
                              );

                        final turno = g.turno.trim();
                        final turnoLine = turno.isEmpty ? '' : '\n$turno';

                        final semanticsLabel =
                            '${g.actividadNombre}. ${g.nombreGrupo}. ${g.bloque.label}. $cupoTxt';

                        return Semantics(
                          button: true,
                          label: semanticsLabel,
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: outline),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(g.actividadNombre),
                              subtitle: Text(
                                '${g.nombreGrupo}'
                                '$turnoLine'
                                '\n${g.bloque.label}'
                                '\n$cupoTxt',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: g.tieneCupos
                                  ? () => _abrirSolicitud(g)
                                  : null,
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
