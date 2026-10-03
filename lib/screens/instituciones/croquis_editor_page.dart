// lib/screens/instituciones/croquis_editor_page.dart
//
// ATENA – Editor de un croquis de aula.
// Grilla de bancos frente al pizarrón: se toca un banco para ubicar a un alumno
// confirmado (o escribir un nombre) y se arrastra para intercambiar lugares.
// Desde la barra de acciones se renombra, se cambia el tamaño, se vacía, se
// exporta a PDF o se elimina el croquis. Cada cambio se guarda solo.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../pdf/atena_pdf.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/crq_banco.dart';
import 'widgets/crq_hojas.dart';

class CroquisEditorPage extends StatelessWidget {
  final String institucionId;
  final String institucionNombre;
  final Croquis croquis;

  const CroquisEditorPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.croquis,
  });

  @override
  Widget build(BuildContext context) {
    return AtenaRoleTheme(
      role: AtenaRole.institucion,
      child: _Editor(page: this),
    );
  }
}

class _Editor extends StatefulWidget {
  final CroquisEditorPage page;

  const _Editor({required this.page});

  @override
  State<_Editor> createState() => _EditorState();
}

enum _Guardado { listo, guardando, error }

/// Medidas de la grilla según el ancho disponible.
typedef _Medida = ({
  double tamano,
  double gap,
  double anchoGrilla,
  bool desborda,
});

class _EditorState extends State<_Editor> {
  /// Lado mínimo de un banco (área táctil cómoda).
  static const double _bancoMinimo = 44;

  late Croquis _c;
  List<Oferta> _ofertas = const [];
  List<Solicitud> _confirmadas = const [];
  late Future<void> _carga;
  bool _cargandoAlumnos = true;
  bool _errorAlumnos = false;

  _Guardado _guardado = _Guardado.listo;
  int _version = 0;
  bool _exportando = false;
  bool _eliminando = false;
  final _pdfKey = GlobalKey();

  String get _institucionId => widget.page.institucionId;

  Oferta? get _oferta => _c.ofertaId.isEmpty
      ? null
      : _ofertas.where((o) => o.id == _c.ofertaId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _c = widget.page.croquis;
    _carga = _cargarAlumnos();
  }

  // ---------------------------------------------------------------------------
  // Datos
  // ---------------------------------------------------------------------------

  /// Vacantes de la institución y alumnos confirmados de la vacante asociada
  /// (o de toda la institución si el croquis no tiene una).
  Future<void> _cargarAlumnos() async {
    final ofertaId = _c.ofertaId;
    try {
      final r = await Future.wait<Object>([
        OfertasRepo.instance.listar(_institucionId),
        SolicitudesRepo.instance.confirmadas(
          _institucionId,
          ofertaId: ofertaId.isEmpty ? null : ofertaId,
        ),
      ]);
      if (!mounted) return;

      final vistos = <String>{};
      final confirmadas = [
        for (final s in r[1] as List<Solicitud>)
          if (vistos.add(s.alumno.perfilId.isEmpty ? s.id : s.alumno.perfilId))
            s,
      ];
      confirmadas.sort(
        (a, b) => normalizarBusqueda(
          a.alumno.apellidoNombre,
        ).compareTo(normalizarBusqueda(b.alumno.apellidoNombre)),
      );

      setState(() {
        _ofertas = r[0] as List<Oferta>;
        _confirmadas = confirmadas;
        _cargandoAlumnos = false;
        _errorAlumnos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargandoAlumnos = false;
        _errorAlumnos = true;
      });
    }
  }

  /// Aplica un cambio y lo guarda. Si hay varios guardados en curso, el
  /// indicador refleja el último.
  Future<void> _guardar(Croquis nuevo) async {
    final version = ++_version;
    setState(() {
      _c = nuevo;
      _guardado = _Guardado.guardando;
    });
    try {
      await CroquisRepo.instance.guardar(nuevo);
      if (!mounted || version != _version) return;
      setState(() => _guardado = _Guardado.listo);
    } catch (_) {
      if (!mounted || version != _version) return;
      setState(() => _guardado = _Guardado.error);
      AtenaFeedback.error(
        context,
        AppLocalizations.of(context).crqErrorGuardar,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Bancos
  // ---------------------------------------------------------------------------

  Future<void> _tocarBanco(int indice) async {
    await _carga;
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final oferta = _oferta;
    final sentados = {
      for (final a in _c.asientos)
        if (a.trim().isNotEmpty) normalizarBusqueda(a),
    };

    final elegido = await crqAsignar(
      context,
      numero: indice + 1,
      actual: _c.asientos[indice].trim(),
      alumnos: [
        for (final s in _confirmadas)
          if (!sentados.contains(normalizarBusqueda(s.alumno.nombreCompleto)))
            CrqAlumnoOpcion(
              nombre: s.alumno.nombreCompleto,
              etiqueta: s.alumno.apellidoNombre,
              detalle: [
                if (_c.ofertaId.isEmpty) s.ofertaNombre,
                if (s.alumno.edad case final edad?) t.lblEdadAnios(edad),
              ].join(' · '),
            ),
      ],
      tituloLista: _c.ofertaId.isEmpty
          ? t.crqAlumnosInstitucion
          : (oferta == null
                ? t.instStatStudents
                : t.crqAlumnosDeVacante(oferta.nombreCompleto)),
      hayConfirmados: _confirmadas.isNotEmpty,
      errorCarga: _errorAlumnos,
    );
    if (elegido == null || !mounted) return;
    _asignar(indice, elegido);
  }

  /// Ubica a [nombre] en el banco ('' lo deja libre). Si ya estaba sentado en
  /// otro banco, se muda.
  void _asignar(int indice, String nombre) {
    final t = AppLocalizations.of(context);
    final columnas = _c.columnas;
    var limpio = nombre.trim();
    var nuevo = _c;
    int? origen;

    if (limpio.isNotEmpty) {
      final clave = normalizarBusqueda(limpio);
      // Los alumnos confirmados se guardan siempre con su nombre exacto.
      limpio =
          _confirmadas
              .map((s) => s.alumno.nombreCompleto)
              .where((n) => normalizarBusqueda(n) == clave)
              .firstOrNull ??
          limpio;
      for (var j = 0; j < nuevo.asientos.length; j++) {
        if (j != indice && normalizarBusqueda(nuevo.asientos[j]) == clave) {
          nuevo = nuevo.conAsiento(j ~/ columnas, j % columnas, '');
          origen = j;
          break;
        }
      }
    }

    nuevo = nuevo.conAsiento(indice ~/ columnas, indice % columnas, limpio);
    if (listEquals(nuevo.asientos, _c.asientos)) return;
    _guardar(nuevo);
    if (origen != null) {
      AtenaFeedback.info(
        context,
        t.crqMovidoDesde(limpio, origen + 1, indice + 1),
      );
    }
  }

  /// Intercambia lo que hay en dos bancos (o muda a un alumno a uno libre).
  void _mover(int desde, int hasta) {
    final total = _c.asientos.length;
    if (desde == hasta || desde >= total || hasta >= total) return;
    final columnas = _c.columnas;
    final a = _c.asientos[desde];
    final b = _c.asientos[hasta];
    _guardar(
      _c
          .conAsiento(desde ~/ columnas, desde % columnas, b)
          .conAsiento(hasta ~/ columnas, hasta % columnas, a),
    );
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _cambiarVacante() async {
    await _carga;
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final id = await crqElegirVacante(
      context,
      ofertas: _ofertas,
      actual: _c.ofertaId,
    );
    if (id == null || !mounted || id == _c.ofertaId) return;
    _guardar(_c.conOferta(id));
    setState(() => _cargandoAlumnos = true);
    _carga = _cargarAlumnos();
    AtenaFeedback.success(context, t.crqVacanteActualizada);
  }

  Future<void> _renombrar() async {
    final t = AppLocalizations.of(context);
    final nombre = await crqPedirNombre(
      context,
      titulo: t.crqRenombrarTitulo,
      inicial: _c.nombre,
    );
    if (nombre == null || !mounted || nombre.trim() == _c.nombre) return;
    _guardar(_c.renombrado(nombre));
  }

  Future<void> _cambiarTamano() async {
    final t = AppLocalizations.of(context);
    final tamano = await crqPedirTamano(context, _c);
    if (tamano == null || !mounted) return;
    if (tamano.filas == _c.filas && tamano.columnas == _c.columnas) return;

    final perdidos = crqLugaresPerdidos(_c, tamano.filas, tamano.columnas);
    if (perdidos > 0) {
      final ok = await showAtenaConfirm(
        context,
        title: t.crqTamanoConfirmarTitulo,
        message: t.crqTamanoPierde(perdidos),
        confirmLabel: t.crqAplicar,
        destructive: true,
        icon: Icons.warning_amber_rounded,
      );
      if (!ok || !mounted) return;
    }
    _guardar(_c.redimensionado(tamano.filas, tamano.columnas));
  }

  Future<void> _vaciar() async {
    final t = AppLocalizations.of(context);
    final ocupados = _c.ocupados;
    if (ocupados == 0) {
      AtenaFeedback.info(context, t.crqYaVacio);
      return;
    }
    final ok = await showAtenaConfirm(
      context,
      title: t.crqVaciarTitulo,
      message: t.crqVaciarMensaje(ocupados),
      confirmLabel: t.crqVaciar,
      destructive: true,
      icon: Icons.layers_clear_rounded,
    );
    if (!ok || !mounted) return;

    final anterior = _c;
    _guardar(
      Croquis.vacio(
        id: _c.id,
        institucionId: _c.institucionId,
        nombre: _c.nombre,
        ofertaId: _c.ofertaId,
        filas: _c.filas,
        columnas: _c.columnas,
      ),
    );
    AtenaFeedback.show(
      context,
      t.crqVaciadoOk,
      kind: AtenaFeedbackKind.success,
      action: SnackBarAction(
        label: t.uiUndo,
        onPressed: () => _restaurarLugares(anterior),
      ),
    );
  }

  /// Deshace el vaciado: recupera la distribución anterior con el nombre y la
  /// vacante actuales.
  void _restaurarLugares(Croquis anterior) {
    if (!mounted) return;
    _guardar(
      Croquis(
        id: _c.id,
        institucionId: _c.institucionId,
        nombre: _c.nombre,
        ofertaId: _c.ofertaId,
        filas: anterior.filas,
        columnas: anterior.columnas,
        asientos: List<String>.of(anterior.asientos),
        actualizadoEl: DateTime.now(),
      ),
    );
  }

  Future<void> _exportarPdf() async {
    if (_exportando) return;
    final t = AppLocalizations.of(context);
    setState(() => _exportando = true);
    try {
      final bytes = await AtenaPdf.croquis(
        t: t,
        institucionNombre: widget.page.institucionNombre,
        croquis: _c,
      );
      if (!mounted) return;
      // En tabletas el panel de compartir se abre desde el botón de PDF.
      await AtenaPdf.compartir(
        _pdfKey.currentContext ?? context,
        bytes,
        _nombreArchivo(t),
      );
    } catch (_) {
      if (mounted) AtenaFeedback.error(context, t.crqPdfError);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  String _nombreArchivo(AppLocalizations t) {
    final base = normalizarBusqueda(
      _c.nombre,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    final nombre = base.isEmpty ? '${_c.filas}x${_c.columnas}' : base;
    return '${t.crqPdfArchivo(nombre)}.pdf';
  }

  Future<void> _eliminar() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.crqEliminarTitulo(_c.nombre),
      message: t.crqEliminarMensaje,
      confirmLabel: t.commonDelete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _eliminando = true);
    try {
      await CroquisRepo.instance.eliminar(_institucionId, _c.id);
      if (!mounted) return;
      AtenaFeedback.success(context, t.crqEliminadoOk);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      AtenaFeedback.error(context, coreErrorText(t, e));
    }
  }

  // ---------------------------------------------------------------------------
  // Vista
  // ---------------------------------------------------------------------------

  _Medida _medir(
    double disponible, {
    required bool telefono,
    required bool escritorio,
  }) {
    final columnas = _c.columnas;
    final gap = telefono ? 5.0 : (escritorio ? 10.0 : 8.0);
    final maximo = escritorio ? 96.0 : 80.0;
    final ideal = (disponible - gap * (columnas - 1)) / columnas;
    final tamano = ideal.clamp(_bancoMinimo, maximo);
    final ancho = tamano * columnas + gap * (columnas - 1);
    return (
      tamano: tamano,
      gap: gap,
      anchoGrilla: ancho,
      desborda: ancho > disponible + 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final libre = !_eliminando;

    return AtenaScaffold(
      role: AtenaRole.institucion,
      appBar: AtenaAppBar(
        title: _c.nombre,
        subtitle: widget.page.institucionNombre,
        actions: [
          _IndicadorGuardado(
            estado: _guardado,
            onReintentar: () => _guardar(_c),
          ),
        ],
      ),
      bottomNavigationBar: _BarraAcciones(
        acciones: [
          _Accion(
            icono: Icons.drive_file_rename_outline_rounded,
            etiqueta: t.crqRenombrar,
            onTap: libre ? _renombrar : null,
          ),
          _Accion(
            icono: Icons.aspect_ratio_rounded,
            etiqueta: t.crqTamanoCorto,
            tooltip: t.crqTamanoTitulo,
            onTap: libre ? _cambiarTamano : null,
          ),
          _Accion(
            icono: Icons.layers_clear_rounded,
            etiqueta: t.crqVaciar,
            onTap: libre ? _vaciar : null,
          ),
          _Accion(
            key: _pdfKey,
            icono: Icons.picture_as_pdf_rounded,
            etiqueta: t.crqPdfCorto,
            tooltip: t.crqExportarPdf,
            cargando: _exportando,
            onTap: libre && !_exportando ? _exportarPdf : null,
          ),
          _Accion(
            icono: Icons.delete_outline_rounded,
            etiqueta: t.commonDelete,
            destructiva: true,
            onTap: libre ? _eliminar : null,
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _eliminando,
        child: LayoutBuilder(
          builder: (context, c) {
            final telefono = c.maxWidth < 600;
            final escritorio = c.maxWidth >= AtenaLayout.desktopBreakpoint;
            final lateral = telefono ? 12.0 : AtenaSpace.page;
            final relleno = telefono ? 10.0 : 16.0;
            final maximo = math.min(
              c.maxWidth - lateral * 2,
              AtenaLayout.content,
            );
            final medida = _medir(
              maximo - relleno * 2,
              telefono: telefono,
              escritorio: escritorio,
            );
            // La tarjeta abraza la grilla (con un mínimo cómodo para leer).
            final ancho = medida.desborda
                ? maximo
                : math.min(
                    maximo,
                    math.max(medida.anchoGrilla + relleno * 2, 460.0),
                  );
            final lado = (c.maxWidth - ancho) / 2;

            return ListView(
              padding: EdgeInsets.fromLTRB(lado, 8, lado, 24),
              children: [
                _Cabecera(
                  croquis: _c,
                  oferta: _oferta,
                  ofertaFaltante:
                      _c.ofertaId.isNotEmpty &&
                      !_cargandoAlumnos &&
                      !_errorAlumnos &&
                      _oferta == null,
                  onVacante: _cambiarVacante,
                ),
                const SizedBox(height: 14),
                _Aula(
                  croquis: _c,
                  medida: medida,
                  relleno: relleno,
                  onTocar: _tocarBanco,
                  onMover: _mover,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Indicador de guardado
// -----------------------------------------------------------------------------

class _IndicadorGuardado extends StatelessWidget {
  final _Guardado estado;
  final VoidCallback onReintentar;

  const _IndicadorGuardado({required this.estado, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final estilo = theme.textTheme.bodySmall;

    final Widget contenido = switch (estado) {
      _Guardado.guardando => Row(
        key: const ValueKey(_Guardado.guardando),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(t.commonSaving, style: estilo),
        ],
      ),
      _Guardado.listo => Row(
        key: const ValueKey(_Guardado.listo),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            size: 18,
            color: AtenaBrand.of(context).success,
          ),
          const SizedBox(width: 6),
          Text(t.crqGuardado, style: estilo),
        ],
      ),
      _Guardado.error => TextButton.icon(
        key: const ValueKey(_Guardado.error),
        onPressed: onReintentar,
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        icon: const Icon(Icons.cloud_off_rounded, size: 18),
        label: Text(t.crqSinGuardar),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: AnimatedSwitcher(duration: AtenaMotion.fast, child: contenido),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Encabezado: vacante asociada, ocupación y ayuda
// -----------------------------------------------------------------------------

class _Cabecera extends StatelessWidget {
  final Croquis croquis;
  final Oferta? oferta;
  final bool ofertaFaltante;
  final VoidCallback onVacante;

  const _Cabecera({
    required this.croquis,
    required this.oferta,
    required this.ofertaFaltante,
    required this.onVacante,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final asociada = oferta;
    final total = croquis.asientos.length;
    final ocupados = croquis.ocupados;

    final (icono, etiqueta) = asociada != null
        ? (iconoOferta(asociada), asociada.nombreCompleto)
        : ofertaFaltante
        ? (Icons.warning_amber_rounded, t.crqVacanteNoDisponible)
        : croquis.ofertaId.isNotEmpty
        // Tiene vacante, pero todavía se están cargando sus datos.
        ? (Icons.event_seat_rounded, t.crqVacanteAsociada)
        : (Icons.link_rounded, t.crqAsociarVacante);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActionChip(
          avatar: Icon(icono, size: 18),
          label: Text(etiqueta, overflow: TextOverflow.ellipsis),
          tooltip: t.crqCambiarVacante,
          onPressed: onVacante,
        ),
        const SizedBox(height: 10),
        Text(t.crqOcupados(ocupados, total), style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : ocupados / total,
            minHeight: 8,
            borderRadius: const BorderRadius.all(Radius.circular(99)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.touch_app_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(t.crqAyuda, style: theme.textTheme.bodySmall)),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Aula: pizarrón y grilla de bancos
// -----------------------------------------------------------------------------

class _Aula extends StatelessWidget {
  final Croquis croquis;
  final _Medida medida;
  final double relleno;
  final ValueChanged<int> onTocar;
  final void Function(int desde, int hasta) onMover;

  const _Aula({
    required this.croquis,
    required this.medida,
    required this.relleno,
    required this.onTocar,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final columnas = croquis.columnas;

    final grilla = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var f = 0; f < croquis.filas; f++) ...[
          if (f > 0) SizedBox(height: medida.gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < columnas; c++) ...[
                if (c > 0) SizedBox(width: medida.gap),
                _BancoArrastrable(
                  indice: f * columnas + c,
                  nombre: croquis.asiento(f, c),
                  tamano: medida.tamano,
                  onTocar: onTocar,
                  onMover: onMover,
                ),
              ],
            ],
          ),
        ],
      ],
    );

    return AtenaCard(
      padding: EdgeInsets.all(relleno),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Pizarron(),
          SizedBox(height: medida.gap + 12),
          if (medida.desborda) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: grilla,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    t.crqAyudaScroll,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ] else
            Center(child: grilla),
        ],
      ),
    );
  }
}

class _Pizarron extends StatelessWidget {
  const _Pizarron();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tono = AtenaTone.of(context, AtenaBrand.of(context).success);

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tono.background,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: tono.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.co_present_rounded, size: 18, color: tono.foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              t.crqFrente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: tono.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banco de la grilla: se toca para asignar y se arrastra (si está ocupado)
/// hasta otro banco para intercambiar lugares. Con el mouse el arrastre es
/// inmediato; con el dedo hay que mantener presionado, para no confundirlo
/// con el desplazamiento de la página.
class _BancoArrastrable extends StatelessWidget {
  final int indice;
  final String nombre;
  final double tamano;
  final ValueChanged<int> onTocar;
  final void Function(int desde, int hasta) onMover;

  const _BancoArrastrable({
    required this.indice,
    required this.nombre,
    required this.tamano,
    required this.onTocar,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      // Soltar un banco sobre sí mismo equivale a tocarlo (un clic con el
      // mouse apenas movido no debe perderse).
      onAcceptWithDetails: (d) =>
          d.data == indice ? onTocar(indice) : onMover(d.data, indice),
      builder: (context, candidatos, _) {
        final banco = CrqBanco(
          numero: indice + 1,
          nombre: nombre,
          tamano: tamano,
          resaltado: candidatos.any((c) => c != indice),
          onTap: () => onTocar(indice),
        );
        if (nombre.trim().isEmpty) return banco;

        // La vista arrastrada vive fuera de la página: se le pasa el tema del
        // área para conservar los colores.
        final arrastrado = Theme(
          data: Theme.of(context),
          child: CrqBanco(
            numero: indice + 1,
            nombre: nombre,
            tamano: tamano * 1.08,
            elevado: true,
          ),
        );
        final origen = CrqBanco(
          numero: indice + 1,
          nombre: nombre,
          tamano: tamano,
          fantasma: true,
        );

        return LongPressDraggable<int>(
          data: indice,
          feedback: arrastrado,
          childWhenDragging: origen,
          child: _ArrastreConMouse(
            data: indice,
            feedback: arrastrado,
            childWhenDragging: origen,
            child: banco,
          ),
        );
      },
    );
  }
}

/// Arrastre inmediato, solo para el mouse.
class _ArrastreConMouse extends Draggable<int> {
  const _ArrastreConMouse({
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.child,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) {
    return ImmediateMultiDragGestureRecognizer(
      supportedDevices: const {PointerDeviceKind.mouse},
    )..onStart = onStart;
  }
}

// -----------------------------------------------------------------------------
// Barra de acciones
// -----------------------------------------------------------------------------

class _Accion {
  /// Identifica el botón (para ubicarlo en pantalla).
  final Key? key;

  final IconData icono;
  final String etiqueta;

  /// Descripción completa cuando la etiqueta es una abreviatura.
  final String? tooltip;

  final VoidCallback? onTap;
  final bool destructiva;
  final bool cargando;

  const _Accion({
    this.key,
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.tooltip,
    this.destructiva = false,
    this.cargando = false,
  });
}

class _BarraAcciones extends StatelessWidget {
  final List<_Accion> acciones;

  const _BarraAcciones({required this.acciones});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    for (final a in acciones)
                      Expanded(
                        child: _BotonAccion(key: a.key, accion: a),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final _Accion accion;

  const _BotonAccion({super.key, required this.accion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final base = accion.destructiva ? cs.error : cs.onSurfaceVariant;
    final color = accion.onTap == null ? base.withValues(alpha: 0.38) : base;

    final boton = InkWell(
      onTap: accion.onTap,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (accion.cargando)
                const SizedBox.square(
                  dimension: 24,
                  child: Padding(
                    padding: EdgeInsets.all(3),
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              else
                Icon(accion.icono, color: color),
              const SizedBox(height: 4),
              Text(
                accion.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final tooltip = accion.tooltip;
    return tooltip == null ? boton : Tooltip(message: tooltip, child: boton);
  }
}
