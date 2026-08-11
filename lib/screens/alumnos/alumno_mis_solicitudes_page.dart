// lib/screens/alumnos/alumno_mis_solicitudes_page.dart
//
// ATENA – ALUMNO / MIS SOLICITUDES
// CANÓNICO (owner → perfiles)
//
// Objetivos:
// - Vista completa de solicitudes del alumno.
// - Soporte: por perfil (perfilId) o todas las del owner (modo owner-all)
// - UI simple + robusta.
// - Cancelación por alumno.
// - Hard-delete SOLO curricular pendiente (utilidad prototipo).
// - Descarga PDF de solicitud (comprobante).
// - Sin legacy, sin parches.
//
// Alineado a:
// - SolicitudAlumno
// - SolicitudesService
// - moduleKey canónica (extracurriculares)
// - SolicitudPdfService (PDF local)
//
// FIX (enero 2026):
// - Blindaje setState async (mounted).
// - Evita doble tap en acciones mientras genera PDF.
// - Snackbars robustos (maybeOf + sin cola).
// - Captura context pre-await en diálogos/async.
// - i18n/dark-mode: AppLocalizations + Theme/ColorScheme.

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/solicitudes/solicitud_alumno.dart';

import '../../services/pdf/solicitud_pdf_service.dart';
import '../../services/solicitudes_service.dart';

class AlumnoMisSolicitudesPage extends StatefulWidget {
  /// Owner account (CANÓNICO)
  final String ownerAccountId;

  /// Perfil opcional:
  /// - si viene → solo solicitudes de ese perfil
  /// - si es null → modo OWNER (todas las solicitudes)
  final String? perfilId;

  /// Opcional: nombre del perfil (solo UI)
  final String? perfilNombre;

  const AlumnoMisSolicitudesPage({
    super.key,
    required this.ownerAccountId,
    this.perfilId,
    this.perfilNombre,
  });

  @override
  State<AlumnoMisSolicitudesPage> createState() =>
      _AlumnoMisSolicitudesPageState();
}

class _AlumnoMisSolicitudesPageState extends State<AlumnoMisSolicitudesPage> {
  bool _cargando = true;
  bool _generandoPdf = false;
  int _loadSeq = 0;

  List<SolicitudAlumno> _pendientes = <SolicitudAlumno>[];
  List<SolicitudAlumno> _confirmadas = <SolicitudAlumno>[];
  List<SolicitudAlumno> _rechazadas = <SolicitudAlumno>[];
  List<SolicitudAlumno> _canceladas = <SolicitudAlumno>[];

  bool get _modoOwner =>
      widget.perfilId == null || widget.perfilId!.trim().isEmpty;

  String get _owner => widget.ownerAccountId.trim();
  String get _perfil => (widget.perfilId ?? '').trim();

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _cargar();
    });
  }

  // ----------------------------------------------------
  // Helpers UI
  // ----------------------------------------------------

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

  String _estadoLabel(EstadoSolicitud e) {
    switch (e) {
      case EstadoSolicitud.pendiente:
        return _l10n.commonPending;
      case EstadoSolicitud.confirmada:
        return _l10n.commonConfirmed;
      case EstadoSolicitud.rechazada:
        return _l10n.commonRejected;
      case EstadoSolicitud.canceladaPorAlumno:
        return _l10n.alumnoMisSolicitudesStatusCancelledYou;
      case EstadoSolicitud.canceladaPorInstitucion:
        return _l10n.alumnoMisSolicitudesStatusCancelledInstitution;
    }
  }

  String _moduleLabel(String moduleKey) {
    final mk = moduleKey.trim();
    if (mk.isEmpty) return '';
    final b = BloqueExtracurricularX.fromKey(mk.toLowerCase());
    return b?.label ?? _l10n.commonModule;
  }

  // ----------------------------------------------------
  // CARGA
  // ----------------------------------------------------

  Future<void> _cargar() async {
    final int token = ++_loadSeq;

    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      if (_owner.isEmpty) {
        if (!mounted) return;
        setState(() => _cargando = false);
        _snack(_l10n.alumnoMisSolicitudesInvalidOwner);
        return;
      }

      final List<SolicitudAlumno> list;

      if (_modoOwner) {
        list = await SolicitudesService.cargarSolicitudesPorOwner(
          ownerAccountId: _owner,
        );
      } else {
        if (_perfil.isEmpty) {
          if (!mounted) return;
          setState(() => _cargando = false);
          _snack(_l10n.alumnoMisSolicitudesInvalidPerfil);
          return;
        }
        list = await SolicitudesService.cargarSolicitudesPorPerfil(
          ownerAccountId: _owner,
          perfilId: _perfil,
        );
      }

      if (token != _loadSeq) return;

      final pend = <SolicitudAlumno>[];
      final conf = <SolicitudAlumno>[];
      final rech = <SolicitudAlumno>[];
      final canc = <SolicitudAlumno>[];

      for (final s in list) {
        switch (s.estado) {
          case EstadoSolicitud.pendiente:
            pend.add(s);
            break;
          case EstadoSolicitud.confirmada:
            conf.add(s);
            break;
          case EstadoSolicitud.rechazada:
            rech.add(s);
            break;
          case EstadoSolicitud.canceladaPorAlumno:
          case EstadoSolicitud.canceladaPorInstitucion:
            canc.add(s);
            break;
        }
      }

      int byFechaDesc(SolicitudAlumno a, SolicitudAlumno b) =>
          b.fechaCreacion.compareTo(a.fechaCreacion);

      pend.sort(byFechaDesc);
      conf.sort(byFechaDesc);
      rech.sort(byFechaDesc);
      canc.sort(byFechaDesc);

      if (!mounted) return;
      setState(() {
        _pendientes = pend;
        _confirmadas = conf;
        _rechazadas = rech;
        _canceladas = canc;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _snack(_l10n.alumnoMisSolicitudesLoadError(e.toString()));
    }
  }

  // ----------------------------------------------------
  // ACCIONES
  // ----------------------------------------------------

  Future<void> _cancelar(SolicitudAlumno s) async {
    if (_generandoPdf) return;

    if (s.estado != EstadoSolicitud.pendiente) {
      _snack(_l10n.alumnoMisSolicitudesNotPending);
      return;
    }

    if (!mounted) return;

    final dialogContext = context;

    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.alumnoMisSolicitudesCancelTitle),
        content: Text(_l10n.alumnoMisSolicitudesCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l10n.commonNo),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l10n.alumnoMisSolicitudesCancelCta),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      await SolicitudesService.cancelarSolicitudDesdePerfil(
        ownerAccountId: (s.ownerAccountId ?? _owner),
        perfilId: (s.perfilId ?? _perfil),
        solicitudId: s.id,
        institucionId: s.institucionId,
        institucionNombre: s.institucionNombre,
        actividadNombre: s.actividadNombre,
        aula: s.aula,
        turno: s.turno,
      );

      if (!mounted) return;
      await _cargar();
      _snack(_l10n.alumnoMisSolicitudesCancelledOk);
    } catch (e) {
      if (!mounted) return;
      _snack(_l10n.alumnoMisSolicitudesCancelError(e.toString()));
    }
  }

  Future<void> _hardDeleteCurricularPendiente(SolicitudAlumno s) async {
    if (_generandoPdf) return;
    if (!mounted) return;

    final dialogContext = context;

    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.alumnoMisSolicitudesDeleteTitle),
        content: Text(_l10n.alumnoMisSolicitudesDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l10n.commonDelete),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      await SolicitudesService.eliminarSolicitudCurricularPendiente(
        ownerAccountId: (s.ownerAccountId ?? _owner),
        perfilId: (s.perfilId ?? _perfil),
        solicitudId: s.id,
      );

      if (!mounted) return;
      await _cargar();
      _snack(_l10n.alumnoMisSolicitudesDeletedOk);
    } catch (e) {
      if (!mounted) return;
      _snack(_l10n.commonErrorWithDetails(e.toString()));
    }
  }

  Future<void> _descargarPdfSolicitud(SolicitudAlumno s) async {
    if (_generandoPdf) return;

    final owner = (s.ownerAccountId ?? _owner).trim();
    final perfil = (s.perfilId ?? _perfil).trim();

    if (owner.isEmpty || perfil.isEmpty) {
      _snack(_l10n.alumnoMisSolicitudesCanonicalContextMissing);
      return;
    }

    if (!mounted) return;
    setState(() => _generandoPdf = true);

    try {
      final path = await SolicitudPdfService.generarPdfSolicitud(
        ownerAccountId: owner,
        perfilId: perfil,
        solicitudId: s.id,
      );

      if (!mounted) return;
      _snack(_l10n.alumnoMisSolicitudesPdfGenerated(path));
    } catch (e) {
      if (!mounted) return;
      _snack(_l10n.alumnoMisSolicitudesPdfError(e.toString()));
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  // ----------------------------------------------------
  // UI
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final titulo = _modoOwner
        ? _l10n.alumnoMisSolicitudesTitleOwner
        : _l10n.alumnoMisSolicitudesTitlePerfil(
            widget.perfilNombre?.trim().isNotEmpty == true
                ? widget.perfilNombre!.trim()
                : _l10n.commonProfile,
          );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: _l10n.commonRefresh,
              onPressed: (_cargando || _generandoPdf)
                  ? null
                  : () {
                      // ignore: discarded_futures
                      _cargar();
                    },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                text: _l10n.alumnoMisSolicitudesTabPendingCount(
                  _pendientes.length,
                ),
              ),
              Tab(
                text: _l10n.alumnoMisSolicitudesTabConfirmedCount(
                  _confirmadas.length,
                ),
              ),
              Tab(
                text: _l10n.alumnoMisSolicitudesTabRejectedCount(
                  _rechazadas.length,
                ),
              ),
              Tab(
                text: _l10n.alumnoMisSolicitudesTabCancelledCount(
                  _canceladas.length,
                ),
              ),
            ],
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _listaPendientes(_pendientes),
                  _listaReadOnly(_confirmadas),
                  _listaReadOnly(_rechazadas),
                  _listaReadOnly(_canceladas),
                ],
              ),
      ),
    );
  }

  Widget _listaReadOnly(List<SolicitudAlumno> list) {
    if (list.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(_l10n.alumnoMisSolicitudesEmptySection)),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _cardBody(list[i], acciones: false),
        ),
      ),
    );
  }

  Widget _listaPendientes(List<SolicitudAlumno> list) {
    if (list.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(_l10n.alumnoMisSolicitudesEmptyPending)),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _cardBody(list[i], acciones: true),
        ),
      ),
    );
  }

  Widget _cardBody(SolicitudAlumno s, {required bool acciones}) {
    final tipo = s.esCurricular
        ? _l10n.commonCurricular
        : _l10n.commonExtracurricular;

    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

    final isBusy = _generandoPdf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.actividadNombre,
          style: titleStyle ?? const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text('${_l10n.commonInstitution}: ${s.institucionNombre}'),
        Text('${_l10n.commonType}: $tipo'),
        if (!s.esCurricular && s.moduleKey.isNotEmpty)
          Text('${_l10n.commonModule}: ${_moduleLabel(s.moduleKey)}'),
        if (s.aula.isNotEmpty) Text('${_l10n.commonClassGroup}: ${s.aula}'),
        if (s.turno.isNotEmpty) Text('${_l10n.commonShift}: ${s.turno}'),
        const SizedBox(height: 6),
        Text('${_l10n.commonStatus}: ${_estadoLabel(s.estado)}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                isBusy
                    ? _l10n.commonGenerating
                    : _l10n.alumnoMisSolicitudesDownloadPdf,
              ),
              onPressed: isBusy
                  ? null
                  : () {
                      // ignore: discarded_futures
                      _descargarPdfSolicitud(s);
                    },
            ),
            if (acciones) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: Text(_l10n.commonCancel),
                onPressed: isBusy
                    ? null
                    : () {
                        // ignore: discarded_futures
                        _cancelar(s);
                      },
              ),
              if (s.esCurricular)
                TextButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: Text(_l10n.commonDelete),
                  onPressed: isBusy
                      ? null
                      : () {
                          // ignore: discarded_futures
                          _hardDeleteCurricularPendiente(s);
                        },
                ),
            ],
          ],
        ),
      ],
    );
  }
}
