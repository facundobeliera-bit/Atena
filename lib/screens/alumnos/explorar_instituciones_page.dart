// lib/screens/alumnos/explorar_instituciones_page.dart
//
// ATENA – Explorar instituciones (alumno).
// Buscador por nombre o ubicación con filtros por nivel, actividad, modalidad
// y edad del alumno. Resultados en lista (teléfono) o grilla (escritorio);
// cada tarjeta lleva a la ficha pública de la institución.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'institucion_publica_page.dart';
import 'mis_solicitudes_page.dart';
import 'widgets/explorar_comun.dart';
import 'widgets/explorar_filtros.dart';
import 'widgets/explorar_institucion_card.dart';

class ExplorarInstitucionesPage extends StatefulWidget {
  final String cuentaId;
  final String perfilId;

  const ExplorarInstitucionesPage({
    super.key,
    required this.cuentaId,
    required this.perfilId,
  });

  @override
  State<ExplorarInstitucionesPage> createState() =>
      _ExplorarInstitucionesPageState();
}

class _ExplorarInstitucionesPageState extends State<ExplorarInstitucionesPage> {
  static const Duration _espera = Duration(milliseconds: 250);
  static const double _anchoTarjeta = 360;

  final _texto = TextEditingController();
  Timer? _timer;

  ExplorarFiltrosData _filtros = const ExplorarFiltrosData();
  String _nombreAlumno = '';
  ExplorarAlumnoEdad? _alumno;

  List<InstitucionResumen> _resultados = const [];
  int _publicadas = 0;
  bool _cargando = true;
  Object? _error;

  /// Descarta respuestas de búsquedas anteriores que lleguen tarde.
  int _busqueda = 0;

  /// Cambia al refrescar para que las tarjetas vuelvan a pedir sus datos.
  int _version = 0;

  // Carga perezosa: cada institución se consulta una sola vez por versión.
  final Map<String, Future<Uint8List?>> _logos = {};
  final Map<String, Future<List<OfertaConCupo>?>> _ofertas = {};

  @override
  void initState() {
    super.initState();
    _inicial();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _texto.dispose();
    super.dispose();
  }

  bool get _hayFiltros => _filtros.activos || _texto.text.trim().isNotEmpty;

  Future<void> _inicial() async {
    try {
      final perfil = await AlumnosRepo.instance.perfil(widget.perfilId);
      if (perfil != null && mounted) {
        final nombre = perfil.nombre.trim().isEmpty
            ? perfil.displayName
            : perfil.nombre.trim();
        final nacimiento = perfil.fechaNacimiento;
        setState(() {
          _nombreAlumno = nombre;
          _alumno = nombre.isEmpty || nacimiento.millisecondsSinceEpoch == 0
              ? null
              : (nombre: nombre, edad: edadEnAnios(nacimiento));
        });
      }
    } catch (_) {
      // Sin los datos del alumno solo se pierde el filtro por edad.
    }
    await _buscar();
  }

  Future<void> _buscar() async {
    final id = ++_busqueda;
    try {
      final repo = InstitucionesRepo.instance;
      final publicadas = await repo.listar();
      var lista = await repo.buscar(
        FiltroInstituciones(
          texto: _texto.text,
          nivel: _filtros.nivel,
          bloque: _filtros.bloque,
          modalidad: _filtros.modalidad,
        ),
      );
      final alumno = _alumno;
      if (_filtros.soloEdad && alumno != null) {
        final ofertas = await Future.wait(lista.map((i) => _ofertasDe(i.id)));
        lista = [
          for (var i = 0; i < lista.length; i++)
            if (_hayLugar(ofertas[i], alumno.edad)) lista[i],
        ];
      }
      if (!mounted || id != _busqueda) return;
      setState(() {
        _publicadas = publicadas.length;
        _resultados = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || id != _busqueda) return;
      setState(() {
        _cargando = false;
        _error = e;
      });
    }
  }

  static bool _hayLugar(List<OfertaConCupo>? ofertas, int edad) =>
      ofertas != null &&
      ofertas.any((o) => o.disponibles > 0 && o.oferta.aceptaEdad(edad));

  Future<Uint8List?> _logoDe(InstitucionResumen i) =>
      _logos.putIfAbsent(i.id, () => _leerLogo(i.logoId));

  Future<List<OfertaConCupo>?> _ofertasDe(String institucionId) =>
      _ofertas.putIfAbsent(institucionId, () => _leerOfertas(institucionId));

  static Future<Uint8List?> _leerLogo(String logoId) async {
    try {
      return await InstitucionesRepo.instance.imagen(logoId);
    } catch (_) {
      return null;
    }
  }

  static Future<List<OfertaConCupo>?> _leerOfertas(String id) async {
    try {
      return await OfertasRepo.instance.conCupo(id, soloActivas: true);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refrescar() async {
    _logos.clear();
    _ofertas.clear();
    setState(() => _version++);
    await _buscar();
  }

  void _reintentar() {
    setState(() {
      _cargando = true;
      _error = null;
    });
    _refrescar();
  }

  void _alEscribir(String _) {
    _timer?.cancel();
    _timer = Timer(_espera, _buscar);
  }

  void _buscarYa() {
    _timer?.cancel();
    _buscar();
  }

  void _borrarTexto() {
    _texto.clear();
    _buscarYa();
  }

  void _cambiarFiltros(ExplorarFiltrosData f) {
    setState(() => _filtros = f);
    _buscarYa();
  }

  void _limpiar() {
    _texto.clear();
    setState(() => _filtros = const ExplorarFiltrosData());
    _buscarYa();
  }

  Future<void> _abrir(InstitucionResumen i) async {
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstitucionPublicaPage(
          cuentaId: widget.cuentaId,
          perfilId: widget.perfilId,
          institucionId: i.id,
        ),
      ),
    );
    if (mounted) await _refrescar();
  }

  Future<void> _misSolicitudes() async {
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MisSolicitudesPage(
          cuentaId: widget.cuentaId,
          perfilId: widget.perfilId,
        ),
      ),
    );
    if (mounted) await _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final a = _alumno;
    final subtitulo = _nombreAlumno.isEmpty
        ? null
        : [
            t.explorarPara(_nombreAlumno),
            if (a != null) t.lblEdadAnios(a.edad),
          ].join(' · ');

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AtenaAppBar(
        title: t.explorarTitulo,
        subtitle: subtitulo,
        actions: [
          IconButton(
            tooltip: t.homeActionRequests,
            onPressed: _misSolicitudes,
            icon: const Icon(Icons.assignment_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AtenaLayout.isDesktop(context)
            ? _escritorio(context)
            : _telefono(context),
      ),
    );
  }

  Widget _telefono(BuildContext context) {
    final pad = atenaPagePadding(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad.left, 4, pad.right, 2),
          child: _campoBusqueda(context),
        ),
        ExplorarFiltrosChips(
          filtros: _filtros,
          alumno: _alumno,
          onChanged: _cambiarFiltros,
          padding: EdgeInsets.symmetric(horizontal: pad.left),
        ),
        Expanded(
          child: _areaResultados(context, lateral: pad.left, conLimpiar: true),
        ),
      ],
    );
  }

  Widget _escritorio(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AtenaLayout.wide),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AtenaSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AtenaSpace.xs),
              _campoBusqueda(context),
              const SizedBox(height: AtenaSpace.md),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 300,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: AtenaSpace.xxl),
                        child: ExplorarFiltrosPanel(
                          filtros: _filtros,
                          alumno: _alumno,
                          onChanged: _cambiarFiltros,
                          onLimpiar: _hayFiltros ? _limpiar : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AtenaSpace.xl),
                    // "Limpiar filtros" ya está en el panel lateral.
                    Expanded(
                      child: _areaResultados(
                        context,
                        lateral: 0,
                        conLimpiar: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// El campo vive fuera del área de resultados: buscar nunca le quita el
  /// foco ni lo reconstruye desde cero.
  Widget _campoBusqueda(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _texto,
      builder: (context, _) => TextField(
        controller: _texto,
        onChanged: _alEscribir,
        onSubmitted: (_) => _buscarYa(),
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: t.explorarBuscarHint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _texto.text.isEmpty
              ? null
              : IconButton(
                  tooltip: t.explorarBorrarBusqueda,
                  onPressed: _borrarTexto,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }

  Widget _areaResultados(
    BuildContext context, {
    required double lateral,
    required bool conLimpiar,
  }) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_cargando) return const AtenaLoading();
    if (_error != null) {
      return AtenaErrorState(
        message: coreErrorText(t, _error!),
        onRetry: _reintentar,
      );
    }

    if (_publicadas == 0) {
      return _Desplazable(
        onRefresh: _refrescar,
        child: AtenaEmptyState(
          icon: Icons.travel_explore_rounded,
          title: t.explorarVacioTitulo,
          message: t.explorarVacioMensaje,
          action: FilledButton.tonalIcon(
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.commonRefresh),
          ),
        ),
      );
    }

    if (_resultados.isEmpty) {
      return _Desplazable(
        onRefresh: _refrescar,
        child: AtenaEmptyState(
          icon: Icons.search_off_rounded,
          title: t.explorarSinResultadosTitulo,
          message: t.explorarSinResultadosMensaje,
          action: _hayFiltros
              ? OutlinedButton.icon(
                  onPressed: _limpiar,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: Text(t.explorarLimpiarFiltros),
                )
              : null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(lateral, 4, lateral / 2, 4),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.explorarResultados(_resultados.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (conLimpiar && _hayFiltros)
                  TextButton.icon(
                    onPressed: _limpiar,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: Text(t.explorarLimpiarFiltros),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refrescar,
            child: _grilla(lateral),
          ),
        ),
      ],
    );
  }

  Widget _grilla(double lateral) {
    return LayoutBuilder(
      builder: (context, c) {
        final util = c.maxWidth - lateral * 2;
        final cols = (util / _anchoTarjeta).floor().clamp(1, 3);
        final filas = (_resultados.length / cols).ceil();

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(lateral, 4, lateral, AtenaSpace.xxl),
          itemCount: filas,
          itemBuilder: (context, fila) {
            if (cols == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AtenaSpace.sm),
                child: _tarjeta(_resultados[fila], llenarAlto: false),
              );
            }
            final desde = fila * cols;
            return Padding(
              padding: const EdgeInsets.only(bottom: AtenaSpace.md),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < cols; j++) ...[
                      if (j > 0) const SizedBox(width: AtenaSpace.md),
                      Expanded(
                        child: desde + j < _resultados.length
                            ? _tarjeta(_resultados[desde + j], llenarAlto: true)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tarjeta(InstitucionResumen i, {required bool llenarAlto}) {
    return ExplorarInstitucionCard(
      key: ValueKey(i.id),
      institucion: i,
      version: _version,
      llenarAlto: llenarAlto,
      cargarLogo: () => _logoDe(i),
      cargarOfertas: () => _ofertasDe(i.id),
      onTap: () => _abrir(i),
    );
  }
}

/// Estado vacío que igual permite deslizar para actualizar.
class _Desplazable extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _Desplazable({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [child],
      ),
    );
  }
}
