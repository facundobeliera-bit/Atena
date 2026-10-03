// lib/screens/instituciones/ofertas_page.dart
//
// ATENA – Vacantes (ofertas) de la institución.
// Pestañas Curricular / Extracurricular según el plan, resumen de cupos y
// vacantes agrupadas por nivel o categoría, con acciones sobre cada una:
// editar, pausar o reanudar, duplicar, ver solicitudes y eliminar.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'oferta_form_page.dart';
import 'solicitudes_institucion_page.dart';
import 'widgets/ofertas_campos.dart';
import 'widgets/ofertas_tarjeta.dart';

class OfertasPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;

  const OfertasPage({
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
      child: _OfertasView(
        institucionId: institucionId,
        institucionNombre: institucionNombre,
      ),
    );
  }
}

class _OfertasView extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  const _OfertasView({
    required this.institucionId,
    required this.institucionNombre,
  });

  @override
  State<_OfertasView> createState() => _OfertasViewState();
}

/// Vacantes de un nivel o categoría.
class _Grupo {
  final IconData icono;
  final String titulo;
  final List<OfertaConCupo> items;
  final bool fueraDelPlan;
  final VoidCallback? onAgregar;

  const _Grupo({
    required this.icono,
    required this.titulo,
    required this.items,
    this.fueraDelPlan = false,
    this.onAgregar,
  });
}

class _OfertasViewState extends State<_OfertasView>
    with TickerProviderStateMixin {
  Institucion? _inst;
  List<OfertaConCupo> _ofertas = const [];
  List<TipoOferta> _tipos = const [];
  TabController? _tabs;
  final Set<String> _procesando = <String>{};

  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final inst = await InstitucionesRepo.instance.obtener(
        widget.institucionId,
      );
      if (inst == null) throw const AtenaException(AtenaError.noEncontrado);
      final ofertas = await OfertasRepo.instance.conCupo(widget.institucionId);
      if (!mounted) return;
      setState(() {
        _inst = inst;
        _ofertas = ofertas;
        _loading = false;
        _error = null;
        _sincronizarPestanas(inst, ofertas);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// Muestra los tipos que habilita el plan y, además, los que ya tienen
  /// vacantes publicadas (para poder gestionarlas aunque el plan cambie).
  void _sincronizarPestanas(Institucion inst, List<OfertaConCupo> ofertas) {
    final tipos = [
      for (final tipo in TipoOferta.values)
        if (ofertasTipoHabilitado(inst, tipo) ||
            ofertas.any((o) => o.oferta.tipo == tipo))
          tipo,
    ];
    if (listEquals(tipos, _tipos)) return;

    final actual = _tipoActual;
    final anterior = _tabs;
    if (anterior != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => anterior.dispose());
    }
    _tipos = tipos;
    _tabs = tipos.length < 2
        ? null
        : TabController(
            length: tipos.length,
            vsync: this,
            initialIndex: actual == null
                ? 0
                : math.max(0, tipos.indexOf(actual)),
          );
  }

  TipoOferta? get _tipoActual {
    if (_tipos.isEmpty) return null;
    final tabs = _tabs;
    return tabs == null ? _tipos.first : _tipos[tabs.index];
  }

  void _mostrarTipo(TipoOferta tipo) {
    final tabs = _tabs;
    final i = _tipos.indexOf(tipo);
    if (tabs != null && i >= 0 && tabs.index != i) tabs.animateTo(i);
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _abrirFormulario({
    Oferta? oferta,
    Oferta? copiaDe,
    TipoOferta? tipo,
    NivelCurricular? nivel,
    BloqueExtracurricular? bloque,
    int confirmados = 0,
  }) async {
    final inst = _inst;
    if (inst == null) return;
    final guardada = await Navigator.of(context).push<Oferta>(
      MaterialPageRoute(
        builder: (_) => OfertaFormPage(
          institucion: inst,
          oferta: oferta,
          copiaDe: copiaDe,
          tipoInicial: tipo,
          nivelInicial: nivel,
          bloqueInicial: bloque,
          confirmados: confirmados,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    if (guardada != null && mounted) _mostrarTipo(guardada.tipo);
  }

  void _nueva() {
    final inst = _inst;
    if (inst == null) return;
    final actual = _tipoActual;
    final tipo = actual != null && ofertasTipoHabilitado(inst, actual)
        ? actual
        : TipoOferta.values.firstWhere(
            (x) => ofertasTipoHabilitado(inst, x),
            orElse: () => TipoOferta.curricular,
          );
    _abrirFormulario(tipo: tipo);
  }

  Future<void> _verSolicitudes(Oferta o) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SolicitudesInstitucionPage(
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
          ofertaId: o.id,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _cambiarActiva(Oferta o) async {
    if (!mounted || _procesando.contains(o.id)) return;
    final t = AppLocalizations.of(context);
    setState(() => _procesando.add(o.id));
    try {
      await OfertasRepo.instance.cambiarActiva(
        widget.institucionId,
        o.id,
        !o.activa,
      );
      await _load();
      if (!mounted) return;
      AtenaFeedback.show(
        context,
        o.activa ? t.ofertasPausadaOk : t.ofertasReanudadaOk,
        kind: AtenaFeedbackKind.success,
        action: SnackBarAction(
          label: t.uiUndo,
          onPressed: () => _restaurarActiva(o),
        ),
      );
    } catch (e) {
      if (mounted) AtenaFeedback.error(context, coreErrorText(t, e));
    } finally {
      if (mounted) setState(() => _procesando.remove(o.id));
    }
  }

  /// Deshace una pausa o reanudación.
  Future<void> _restaurarActiva(Oferta o) async {
    try {
      await OfertasRepo.instance.cambiarActiva(
        widget.institucionId,
        o.id,
        o.activa,
      );
    } catch (e) {
      if (mounted) {
        AtenaFeedback.error(
          context,
          coreErrorText(AppLocalizations.of(context), e),
        );
      }
    }
    if (mounted) await _load();
  }

  Future<void> _eliminar(Oferta o) async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.ofertasEliminarTitulo(o.nombreCompleto),
      message: t.ofertasEliminarMensaje,
      confirmLabel: t.commonDelete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _procesando.add(o.id));
    try {
      await OfertasRepo.instance.eliminar(widget.institucionId, o.id);
      await _load();
      if (!mounted) return;
      AtenaFeedback.success(context, t.ofertasEliminadaOk);
    } on AtenaException catch (e) {
      if (!mounted) return;
      final sugerirPausa =
          e.error == AtenaError.ofertaConSolicitudes && o.activa;
      AtenaFeedback.show(
        context,
        coreErrorText(t, e),
        kind: AtenaFeedbackKind.error,
        action: sugerirPausa
            ? SnackBarAction(
                label: t.ofertasPausar,
                onPressed: () => _cambiarActiva(o),
              )
            : null,
      );
    } catch (e) {
      if (mounted) AtenaFeedback.error(context, coreErrorText(t, e));
    } finally {
      if (mounted) setState(() => _procesando.remove(o.id));
    }
  }

  void _onAccion(OfertaConCupo item, OfertasAccion accion) {
    final o = item.oferta;
    switch (accion) {
      case OfertasAccion.editar:
        _abrirFormulario(oferta: o, confirmados: item.confirmados);
      case OfertasAccion.pausar:
        _cambiarActiva(o);
      case OfertasAccion.duplicar:
        _abrirFormulario(copiaDe: o);
      case OfertasAccion.solicitudes:
        _verSolicitudes(o);
      case OfertasAccion.eliminar:
        _eliminar(o);
    }
  }

  // ---------------------------------------------------------------------------
  // Vista
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final inst = _inst;
    final listo = !_loading && _error == null && inst != null;
    final puedeCrear =
        listo && TipoOferta.values.any((x) => ofertasTipoHabilitado(inst, x));
    final tabs = _tabs;

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.instActionOffers,
        subtitle: widget.institucionNombre,
        bottom: listo && tabs != null ? _barraPestanas(t, tabs) : null,
      ),
      // Sin vacantes, el estado vacío ya trae el botón para crear la primera.
      floatingActionButton: puedeCrear && _ofertas.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _nueva,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.ofertasNueva),
            )
          : null,
      body: _cuerpo(t),
    );
  }

  PreferredSizeWidget _barraPestanas(AppLocalizations t, TabController tabs) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AtenaLayout.content),
          child: TabBar(
            controller: tabs,
            tabs: [
              for (final tipo in _tipos)
                Tab(
                  child: _EtiquetaPestana(
                    icono: ofertasIconoTipo(tipo),
                    texto: t.tipoOferta(tipo),
                    cantidad: _ofertas
                        .where((o) => o.oferta.tipo == tipo)
                        .length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(AppLocalizations t) {
    if (_loading) return const AtenaLoading();
    final error = _error;
    if (error != null) {
      return AtenaErrorState(
        title: t.ofertasErrorCarga,
        message: coreErrorText(t, error),
        onRetry: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }
    if (_tipos.isEmpty) {
      return AtenaEmptyState(
        icon: Icons.workspace_premium_rounded,
        title: t.ofertasSinPlanTitulo,
        message: t.ofertasSinPlanMensaje,
        action: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text(t.ofertasVolverPanel),
        ),
      );
    }
    final tabs = _tabs;
    if (tabs == null) return _lista(t, _tipos.single);
    return TabBarView(
      controller: tabs,
      children: [for (final tipo in _tipos) _lista(t, tipo)],
    );
  }

  Widget _lista(AppLocalizations t, TipoOferta tipo) {
    final inst = _inst!;
    final habilitado = ofertasTipoHabilitado(inst, tipo);
    final items = [
      for (final o in _ofertas)
        if (o.oferta.tipo == tipo) o,
    ];

    final children = <Widget>[
      if (!habilitado) ...[
        AtenaBanner(
          tone: AtenaBannerTone.warning,
          message: t.ofertasTipoFueraDelPlan,
        ),
        const SizedBox(height: 16),
      ],
    ];

    if (items.isEmpty) {
      final curricular = tipo == TipoOferta.curricular;
      children.add(
        AtenaEmptyState(
          icon: ofertasIconoTipo(tipo),
          title: curricular
              ? t.ofertasVacioCurricularTitulo
              : t.ofertasVacioExtraTitulo,
          message: curricular
              ? t.ofertasVacioCurricularMensaje
              : t.ofertasVacioExtraMensaje,
          action: habilitado
              ? FilledButton.icon(
                  onPressed: () => _abrirFormulario(tipo: tipo),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(t.ofertasNueva),
                )
              : null,
        ),
      );
    } else {
      final activas = items.where((o) => o.oferta.activa).toList();
      children.add(
        OfertasResumen(
          libres: activas.fold<int>(0, (s, o) => s + o.disponibles),
          activas: activas.length,
          pendientes: items.fold<int>(0, (s, o) => s + o.pendientes),
        ),
      );
      for (final g in _grupos(t, inst, tipo, items, habilitado)) {
        final libres = g.items
            .where((o) => o.oferta.activa)
            .fold<int>(0, (s, o) => s + o.disponibles);
        children.add(
          OfertasGrupoEncabezado(
            icono: g.icono,
            titulo: g.titulo,
            detalle:
                '${t.ofertasNOfertas(g.items.length)} · ${t.ofertasNLibres(libres)}',
            fueraDelPlan: g.fueraDelPlan,
            onAgregar: g.onAgregar,
          ),
        );
        for (final item in g.items) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OfertasTarjeta(
                key: ValueKey(item.oferta.id),
                item: item,
                procesando: _procesando.contains(item.oferta.id),
                puedeDuplicar: ofertasCategoriaHabilitada(inst, item.oferta),
                onAccion: (a) => _onAccion(item, a),
              ),
            ),
          );
        }
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: PageStorageKey<TipoOferta>(tipo),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: atenaPagePadding(context, top: 16, bottom: 112),
        children: children,
      ),
    );
  }

  /// Agrupa por nivel (curricular) o categoría (extracurricular), en el orden
  /// habitual, con las vacantes activas primero.
  List<_Grupo> _grupos(
    AppLocalizations t,
    Institucion inst,
    TipoOferta tipo,
    List<OfertaConCupo> items,
    bool tipoHabilitado,
  ) {
    List<OfertaConCupo> ordenar(Iterable<OfertaConCupo> xs) => [
      ...xs.where((o) => o.oferta.activa),
      ...xs.where((o) => !o.oferta.activa),
    ];

    final grupos = <_Grupo>[];
    if (tipo == TipoOferta.curricular) {
      final habilitados = ofertasNivelesHabilitados(inst);
      for (final n in NivelCurricular.values) {
        final delNivel = items.where((o) => o.oferta.nivel == n);
        if (delNivel.isEmpty) continue;
        final ok = habilitados.contains(n);
        grupos.add(
          _Grupo(
            icono: iconoNivel(n),
            titulo: t.nivel(n),
            items: ordenar(delNivel),
            fueraDelPlan: tipoHabilitado && !ok,
            onAgregar: ok ? () => _abrirFormulario(tipo: tipo, nivel: n) : null,
          ),
        );
      }
      final sinNivel = items.where((o) => o.oferta.nivel == null);
      if (sinNivel.isNotEmpty) {
        grupos.add(
          _Grupo(
            icono: ofertasIconoTipo(tipo),
            titulo: t.tipoOferta(tipo),
            items: ordenar(sinNivel),
          ),
        );
      }
    } else {
      final habilitados = ofertasBloquesHabilitados(inst);
      for (final b in BloqueExtracurricularX.ordered()) {
        final delBloque = items.where((o) => o.oferta.bloque == b);
        if (delBloque.isEmpty) continue;
        final ok = habilitados.contains(b);
        grupos.add(
          _Grupo(
            icono: iconoBloque(b),
            titulo: t.bloque(b),
            items: ordenar(delBloque),
            fueraDelPlan: tipoHabilitado && !ok,
            onAgregar: ok
                ? () => _abrirFormulario(tipo: tipo, bloque: b)
                : null,
          ),
        );
      }
      final sinBloque = items.where((o) => o.oferta.bloque == null);
      if (sinBloque.isNotEmpty) {
        grupos.add(
          _Grupo(
            icono: ofertasIconoTipo(tipo),
            titulo: t.tipoOferta(tipo),
            items: ordenar(sinBloque),
          ),
        );
      }
    }
    return grupos;
  }
}

class _EtiquetaPestana extends StatelessWidget {
  final IconData icono;
  final String texto;
  final int cantidad;

  const _EtiquetaPestana({
    required this.icono,
    required this.texto,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
        if (cantidad > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AtenaRadius.pill,
            ),
            child: Text(
              '$cantidad',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
