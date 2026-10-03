// lib/screens/instituciones/alumnos_institucion_page.dart
//
// ATENA – Alumnos confirmados de la institución.
// Agrupados por vacante en secciones desplegables (con su ocupación), con
// búsqueda por nombre o DNI, ficha de cada alumno (contacto, pedido de
// documentos, baja) y exportación del listado en PDF, completo o por vacante.
//
// La lista se actualiza sola cuando cambian los datos guardados (por ejemplo,
// si una familia elimina su cuenta y libera su lugar).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../pdf/atena_pdf.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'solicitudes_institucion_page.dart';
import 'widgets/sol_inst_acciones.dart';
import 'widgets/sol_inst_comun.dart';
import 'widgets/sol_inst_detalle.dart';

class AlumnosInstitucionPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;

  const AlumnosInstitucionPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
  });

  @override
  Widget build(BuildContext context) {
    // El tema del área envuelve toda la página para que diálogos, menús y
    // hojas también usen los colores de la institución.
    return AtenaRoleTheme(
      role: AtenaRole.institucion,
      child: _AlumnosView(
        institucionId: institucionId,
        institucionNombre: institucionNombre,
      ),
    );
  }
}

/// Alumnos confirmados de una vacante. [total] cuenta a todos; [alumnos] son
/// los que coinciden con la búsqueda, por apellido.
typedef _Grupo = ({
  Oferta oferta,
  OfertaConCupo? cupo,
  int total,
  List<Solicitud> alumnos,
});

class _AlumnosView extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  const _AlumnosView({
    required this.institucionId,
    required this.institucionNombre,
  });

  @override
  State<_AlumnosView> createState() => _AlumnosViewState();
}

class _AlumnosViewState extends State<_AlumnosView> {
  /// Marca de exportación del listado completo (el resto son ids de vacante).
  static const String _todos = '*';

  final _buscar = TextEditingController();

  List<Solicitud> _confirmadas = const [];
  List<OfertaConCupo> _ofertas = const [];
  String _nombre = '';

  bool _loading = true;
  bool _cargado = false;
  bool _recargando = false;
  Object? _error;
  int _carga = 0;
  Timer? _recarga;

  String _consulta = '';
  final Set<String> _contraidas = <String>{};
  String? _exportando;

  @override
  void initState() {
    super.initState();
    _nombre = widget.institucionNombre.trim();
    AtenaStore.instance.revision.addListener(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    AtenaStore.instance.revision.removeListener(_alCambiarDatos);
    _recarga?.cancel();
    _buscar.dispose();
    super.dispose();
  }

  /// Los datos guardados cambiaron (una confirmación, una baja, una familia
  /// que elimina su cuenta…): se recarga sin interrumpir lo que se ve.
  void _alCambiarDatos() {
    _recarga?.cancel();
    _recarga = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool avisar = false}) async {
    final carga = ++_carga;
    try {
      final id = widget.institucionId;
      final confirmadas = await SolicitudesRepo.instance.confirmadas(id);
      final ofertas = await OfertasRepo.instance.conCupo(id);
      var nombre = _nombre;
      if (nombre.isEmpty) {
        final inst = await InstitucionesRepo.instance.obtener(id);
        nombre = inst?.nombre.trim() ?? '';
      }
      if (!mounted || carga != _carga) return;
      setState(() {
        _confirmadas = confirmadas;
        _ofertas = ofertas;
        _nombre = nombre;
        _loading = false;
        _cargado = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted || carga != _carga) return;
      setState(() {
        _loading = false;
        if (!_cargado) _error = e;
      });
      if (_cargado && avisar) {
        AtenaFeedback.error(
          context,
          coreErrorText(AppLocalizations.of(context), e),
        );
      }
    }
  }

  Future<void> _refrescar() async {
    setState(() => _recargando = true);
    await _load(avisar: true);
    if (mounted) setState(() => _recargando = false);
  }

  void _reintentar() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  /// Alumnos agrupados por vacante, en el orden de la pantalla de Vacantes.
  List<_Grupo> _grupos({bool filtrar = true}) {
    final porOferta = <String, List<Solicitud>>{};
    for (final s in _confirmadas) {
      porOferta.putIfAbsent(s.ofertaId, () => <Solicitud>[]).add(s);
    }

    _Grupo grupo(Oferta oferta, OfertaConCupo? cupo, List<Solicitud> todos) {
      final alumnos = filtrar
          ? todos.where((s) => solInstCoincide(s, _consulta)).toList()
          : [...todos];
      return (
        oferta: oferta,
        cupo: cupo,
        total: todos.length,
        alumnos: alumnos..sort(solInstPorApellido),
      );
    }

    final grupos = <_Grupo>[];
    for (final c in _ofertas) {
      final lista = porOferta.remove(c.oferta.id);
      if (lista != null) grupos.add(grupo(c.oferta, c, lista));
    }
    // Vacantes que ya no están publicadas: se usan los datos de la solicitud.
    final sueltas = [
      for (final lista in porOferta.values)
        grupo(lista.first.oferta, null, lista),
    ]..sort((a, b) => solInstOrdenOfertas(a.oferta, b.oferta));

    return [...grupos, ...sueltas];
  }

  Future<void> _abrirDetalle(Solicitud s, OfertaConCupo? cupo) async {
    final mensaje = await showSolInstDetalle(
      context,
      solicitud: s,
      institucionId: widget.institucionId,
      institucionNombre: _nombre,
      cupo: cupo,
    );
    if (!mounted) return;
    if (mensaje != null) AtenaFeedback.success(context, mensaje);
    await _load();
  }

  /// Exporta el listado completo o, con [oferta], solo el de esa vacante.
  Future<void> _exportar({Oferta? oferta}) async {
    if (_exportando != null) return;
    final t = AppLocalizations.of(context);
    final lista = [
      for (final g in _grupos(filtrar: false))
        if (oferta == null || g.oferta.id == oferta.id) ...g.alumnos,
    ];
    if (lista.isEmpty) return;

    final titulo = oferta?.nombreCompleto;
    setState(() => _exportando = oferta?.id ?? _todos);
    await solInstCompartirPdf(
      context,
      generar: () => AtenaPdf.listadoAlumnos(
        t: t,
        institucionNombre: _nombre,
        confirmadas: lista,
        titulo: titulo,
      ),
      nombreArchivo: solInstNombreArchivo(
        t.alumInstArchivoListado,
        titulo ?? _nombre,
      ),
    );
    if (mounted) setState(() => _exportando = null);
  }

  Future<void> _irAVacantes() async {
    await solInstAbrirVacantes(
      context,
      institucionId: widget.institucionId,
      institucionNombre: _nombre,
    );
    if (mounted) await _load();
  }

  Future<void> _irASolicitudes() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SolicitudesInstitucionPage(
          institucionId: widget.institucionId,
          institucionNombre: _nombre,
        ),
      ),
    );
    if (mounted) await _load();
  }

  void _limpiarBusqueda() {
    _buscar.clear();
    setState(() => _consulta = '');
  }

  void _alternar(String ofertaId) {
    setState(() {
      if (!_contraidas.remove(ofertaId)) _contraidas.add(ofertaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.instActionStudents,
        subtitle: _cargado ? t.alumInstSubtitulo(_confirmadas.length) : _nombre,
        actions: [
          IconButton(
            tooltip: t.commonRefresh,
            onPressed: _loading || _recargando ? null : _refrescar,
            icon: _recargando
                ? const SolInstSpinner(size: 20)
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: t.alumInstExportarPdf,
            onPressed: _confirmadas.isEmpty || _exportando != null
                ? null
                : _exportar,
            icon: _exportando == _todos
                ? const SolInstSpinner(size: 20)
                : const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: _loading
          ? const AtenaLoading()
          : _error != null
          ? AtenaErrorState(
              message: coreErrorText(t, _error!),
              onRetry: _reintentar,
            )
          : RefreshIndicator(
              onRefresh: () => _load(avisar: true),
              child: ListView(
                padding: atenaPagePadding(context),
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: _confirmadas.isEmpty
                    ? [_vacio(context)]
                    : _secciones(context),
              ),
            ),
    );
  }

  List<Widget> _secciones(BuildContext context) {
    final t = AppLocalizations.of(context);
    final buscando = _consulta.trim().isNotEmpty;
    final grupos = _grupos().where((g) => g.alumnos.isNotEmpty).toList();

    return [
      SolInstBuscador(
        controller: _buscar,
        onChanged: (v) => setState(() => _consulta = v),
      ),
      const SizedBox(height: AtenaSpace.md),
      if (grupos.isEmpty)
        AtenaEmptyState(
          icon: Icons.search_off_rounded,
          title: t.solInstSinResultadosTitulo,
          message: t.alumInstSinResultadosMsg,
          compact: true,
          action: OutlinedButton.icon(
            onPressed: _limpiarBusqueda,
            icon: const Icon(Icons.close_rounded),
            label: Text(t.solInstLimpiarBusqueda),
          ),
        )
      else
        for (final g in grupos)
          Padding(
            padding: const EdgeInsets.only(bottom: AtenaSpace.sm),
            child: _SeccionOferta(
              key: ValueKey(g.oferta.id),
              grupo: g,
              expandida: buscando || !_contraidas.contains(g.oferta.id),
              exportando: _exportando == g.oferta.id,
              onAlternar: buscando ? null : () => _alternar(g.oferta.id),
              onExportar: _exportando != null
                  ? null
                  : () => _exportar(oferta: g.oferta),
              onAlumno: (s) => _abrirDetalle(s, g.cupo),
            ),
          ),
    ];
  }

  Widget _vacio(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pendientes = _ofertas.fold<int>(0, (n, o) => n + o.pendientes);
    const iconoVacantes = Icon(Icons.event_seat_rounded);
    final textoVacantes = Text(t.solInstIrAVacantes);

    return AtenaEmptyState(
      icon: Icons.groups_rounded,
      title: t.alumInstVacioTitulo,
      message: t.alumInstVacioMsg,
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          if (pendientes > 0) ...[
            FilledButton.icon(
              onPressed: _irASolicitudes,
              icon: const Icon(Icons.move_to_inbox_rounded),
              label: Text(t.alumInstRevisarSolicitudes(pendientes)),
            ),
            OutlinedButton.icon(
              onPressed: _irAVacantes,
              icon: iconoVacantes,
              label: textoVacantes,
            ),
          ] else
            FilledButton.icon(
              onPressed: _irAVacantes,
              icon: iconoVacantes,
              label: textoVacantes,
            ),
        ],
      ),
    );
  }
}

/// Sección desplegable con los alumnos de una vacante.
class _SeccionOferta extends StatelessWidget {
  final _Grupo grupo;
  final bool expandida;
  final bool exportando;

  /// null = no se puede plegar (mientras se busca).
  final VoidCallback? onAlternar;

  /// null = hay otra exportación en curso.
  final VoidCallback? onExportar;

  final ValueChanged<Solicitud> onAlumno;

  const _SeccionOferta({
    super.key,
    required this.grupo,
    required this.expandida,
    required this.exportando,
    required this.onAlternar,
    required this.onExportar,
    required this.onAlumno,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final o = grupo.oferta;
    final cupo = grupo.cupo;
    final resumen = [
      t.alumInstCantidad(grupo.total),
      if (cupo != null)
        cupo.completa
            ? t.solInstVacanteCompleta
            : t.lblCuposDeTotal(cupo.disponibles, o.cupoTotal),
    ].join(' · ');

    return AtenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: expandida,
            child: InkWell(
              onTap: onAlternar,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  children: [
                    AtenaIconBadge(icon: iconoOferta(o)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.nombreCompleto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t.categoriaOferta(o)} · ${t.turno(o.turno)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(resumen, style: theme.textTheme.labelMedium),
                              if (cupo != null && !o.activa)
                                AtenaStatusChip(
                                  label: t.solInstVacantePausada,
                                  color: AtenaStatusColors.cancelled,
                                  icon: Icons.pause_circle_rounded,
                                  dense: true,
                                ),
                            ],
                          ),
                          if (cupo != null) ...[
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: LinearProgressIndicator(
                                value: cupo.ocupacion,
                                color: cupo.completa
                                    ? AtenaBrand.of(context).warning
                                    : null,
                                semanticsLabel: t.solInstOcupacion,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: t.alumInstExportarSeccion(o.nombreCompleto),
                      onPressed: onExportar,
                      icon: exportando
                          ? const SolInstSpinner(size: 20)
                          : const Icon(Icons.picture_as_pdf_outlined),
                    ),
                    if (onAlternar != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AnimatedRotation(
                          turns: expandida ? 0.5 : 0,
                          duration: AtenaMotion.fast,
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AtenaMotion.medium,
            curve: AtenaMotion.curve,
            alignment: Alignment.topCenter,
            child: !expandida
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      const Divider(),
                      for (final (i, s) in grupo.alumnos.indexed) ...[
                        if (i > 0) const Divider(indent: 72),
                        _FilaAlumno(solicitud: s, onTap: () => onAlumno(s)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilaAlumno extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback onTap;

  const _FilaAlumno({required this.solicitud, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = solicitud.alumno;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            AtenaAvatar(name: a.nombreCompleto, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.apellidoNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    solInstResumenAlumno(t, a),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
