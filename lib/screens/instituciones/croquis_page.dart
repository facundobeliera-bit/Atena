// lib/screens/instituciones/croquis_page.dart
//
// ATENA – Croquis de aula de la institución.
// Lista de croquis con su miniatura, tamaño, ocupación y vacante asociada;
// alta de un croquis nuevo y acceso al editor.

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'croquis_editor_page.dart';
import 'widgets/crq_hojas.dart';
import 'widgets/crq_miniatura.dart';

class CroquisPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;

  const CroquisPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
  });

  @override
  Widget build(BuildContext context) {
    // El tema del área envuelve toda la página para que las hojas y los
    // diálogos también usen los colores de la institución.
    return AtenaRoleTheme(
      role: AtenaRole.institucion,
      child: _CroquisLista(
        institucionId: institucionId,
        institucionNombre: institucionNombre,
      ),
    );
  }
}

class _CroquisLista extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  const _CroquisLista({
    required this.institucionId,
    required this.institucionNombre,
  });

  @override
  State<_CroquisLista> createState() => _CroquisListaState();
}

class _CroquisListaState extends State<_CroquisLista> {
  List<Croquis> _items = const [];
  List<Oferta> _ofertas = const [];
  bool _loading = true;
  bool _creando = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait<Object>([
        CroquisRepo.instance.listar(widget.institucionId),
        OfertasRepo.instance.listar(widget.institucionId),
      ]);
      if (!mounted) return;
      setState(() {
        _items = r[0] as List<Croquis>;
        _ofertas = r[1] as List<Oferta>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _abrir(Croquis croquis) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CroquisEditorPage(
          institucionId: widget.institucionId,
          institucionNombre: widget.institucionNombre,
          croquis: croquis,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _nuevo() async {
    if (_creando) return;
    final t = AppLocalizations.of(context);
    final datos = await crqPedirNuevo(context, ofertas: _ofertas);
    if (datos == null || !mounted) return;

    setState(() => _creando = true);
    try {
      final croquis = await CroquisRepo.instance.crear(
        institucionId: widget.institucionId,
        nombre: datos.nombre,
        ofertaId: datos.ofertaId,
        filas: datos.filas,
        columnas: datos.columnas,
      );
      if (!mounted) return;
      await _abrir(croquis);
    } catch (e) {
      if (mounted) AtenaFeedback.error(context, coreErrorText(t, e));
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final listo = !_loading && _error == null;

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: t.instActionCroquis,
        subtitle: widget.institucionNombre,
      ),
      // Sin croquis, el estado vacío ya trae el botón para crear el primero.
      floatingActionButton: listo && _items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _creando ? null : _nuevo,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.crqNuevo),
            )
          : null,
      body: _cuerpo(t),
    );
  }

  Widget _tarjeta(Croquis croquis) {
    return _CroquisTarjeta(
      croquis: croquis,
      oferta: _ofertas.where((o) => o.id == croquis.ofertaId).firstOrNull,
      onTap: () => _abrir(croquis),
    );
  }

  Widget _cuerpo(AppLocalizations t) {
    if (_loading) return const AtenaLoading();
    final error = _error;
    if (error != null) {
      return AtenaErrorState(
        title: t.crqErrorCarga,
        message: coreErrorText(t, error),
        onRetry: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: atenaPagePadding(context, top: 12, bottom: 112),
        children: [
          if (_items.isEmpty)
            AtenaEmptyState(
              icon: Icons.grid_view_rounded,
              title: t.crqVacioTitulo,
              message: t.crqVacioMensaje,
              action: FilledButton.icon(
                onPressed: _creando ? null : _nuevo,
                icon: const Icon(Icons.add_rounded),
                label: Text(t.crqNuevo),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                // Una columna en teléfono y dos en pantallas anchas, con las
                // tarjetas de cada fila a la misma altura.
                const gap = 12.0;
                final columnas = c.maxWidth >= 640 ? 2 : 1;
                return Column(
                  children: [
                    for (var i = 0; i < _items.length; i += columnas) ...[
                      if (i > 0) const SizedBox(height: gap),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var j = i; j < i + columnas; j++) ...[
                              if (j > i) const SizedBox(width: gap),
                              Expanded(
                                child: j < _items.length
                                    ? _tarjeta(_items[j])
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CroquisTarjeta extends StatelessWidget {
  final Croquis croquis;

  /// Vacante asociada (null si no tiene o ya no existe).
  final Oferta? oferta;

  final VoidCallback onTap;

  const _CroquisTarjeta({
    required this.croquis,
    required this.oferta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final asociada = oferta;
    final total = croquis.asientos.length;
    final ocupados = croquis.ocupados;

    final (IconData, String)? vacante = asociada != null
        ? (iconoOferta(asociada), asociada.nombreCompleto)
        : croquis.ofertaId.isNotEmpty
        ? (Icons.warning_amber_rounded, t.crqVacanteNoDisponible)
        : null;

    return AtenaCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: CrqMiniatura.de(croquis),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  croquis.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  t.crqFilasColumnas(croquis.filas, croquis.columnas),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : ocupados / total,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.crqOcupados(ocupados, total),
                  style: theme.textTheme.bodySmall,
                ),
                if (vacante != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(vacante.$1, size: 15, color: cs.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          vacante.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
