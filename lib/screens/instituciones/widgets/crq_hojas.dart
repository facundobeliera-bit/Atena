// lib/screens/instituciones/widgets/crq_hojas.dart
//
// ATENA – Hojas y diálogos del croquis de aula: crear un croquis, cambiar el
// tamaño, renombrar, elegir la vacante asociada y asignar un alumno a un banco.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'crq_miniatura.dart';

/// Datos de un croquis nuevo.
typedef CrqNuevoDatos = ({
  String nombre,
  String ofertaId,
  int filas,
  int columnas,
});

/// Tamaño elegido para un croquis.
typedef CrqTamano = ({int filas, int columnas});

/// Alumno que se puede ubicar en un banco.
class CrqAlumnoOpcion {
  /// Nombre que se guarda en el banco.
  final String nombre;

  /// Nombre como se muestra en la lista ("Apellido, Nombre").
  final String etiqueta;

  final String detalle;

  const CrqAlumnoOpcion({
    required this.nombre,
    required this.etiqueta,
    this.detalle = '',
  });
}

/// Lugares ocupados que quedarían fuera al pasar a [filas] × [columnas].
int crqLugaresPerdidos(Croquis c, int filas, int columnas) {
  var perdidos = 0;
  for (var f = 0; f < c.filas; f++) {
    for (var col = 0; col < c.columnas; col++) {
      final fuera = f >= filas || col >= columnas;
      if (fuera && c.asiento(f, col).trim().isNotEmpty) perdidos++;
    }
  }
  return perdidos;
}

// -----------------------------------------------------------------------------
// Aperturas
// -----------------------------------------------------------------------------

Future<T?> _abrirHoja<T>(BuildContext context, Widget hoja) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => hoja,
  );
}

/// Pide los datos de un croquis nuevo (null si se cancela).
Future<CrqNuevoDatos?> crqPedirNuevo(
  BuildContext context, {
  required List<Oferta> ofertas,
}) => _abrirHoja<CrqNuevoDatos>(context, _NuevoHoja(ofertas: ofertas));

/// Pide un tamaño nuevo para el croquis (null si se cancela).
Future<CrqTamano?> crqPedirTamano(BuildContext context, Croquis croquis) =>
    _abrirHoja<CrqTamano>(context, _TamanoHoja(croquis: croquis));

/// Elige la vacante asociada: devuelve su id, '' para ninguna o null si se
/// cancela.
Future<String?> crqElegirVacante(
  BuildContext context, {
  required List<Oferta> ofertas,
  required String actual,
}) =>
    _abrirHoja<String>(context, _VacanteHoja(ofertas: ofertas, actual: actual));

/// Elige quién ocupa un banco: devuelve el nombre, '' para dejarlo libre o
/// null si se cancela.
Future<String?> crqAsignar(
  BuildContext context, {
  required int numero,
  required String actual,
  required List<CrqAlumnoOpcion> alumnos,
  required String tituloLista,
  required bool hayConfirmados,
  required bool errorCarga,
}) => _abrirHoja<String>(
  context,
  _AsignarHoja(
    numero: numero,
    actual: actual,
    alumnos: alumnos,
    tituloLista: tituloLista,
    hayConfirmados: hayConfirmados,
    errorCarga: errorCarga,
  ),
);

/// Pide un nombre para el croquis (null si se cancela).
Future<String?> crqPedirNombre(
  BuildContext context, {
  required String titulo,
  required String inicial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NombreDialogo(titulo: titulo, inicial: inicial),
  );
}

// -----------------------------------------------------------------------------
// Piezas compartidas
// -----------------------------------------------------------------------------

/// Contador compacto con botones − / + (para filas y columnas).
class CrqContador extends StatelessWidget {
  final String etiqueta;
  final int valor;
  final int minimo;
  final int maximo;
  final ValueChanged<int> onChanged;

  const CrqContador({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
    this.minimo = 1,
    this.maximo = 10,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            etiqueta,
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: AtenaRadius.field,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                IconButton(
                  tooltip: t.crqQuitarUno,
                  onPressed: valor > minimo ? () => onChanged(valor - 1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '$valor',
                    textAlign: TextAlign.center,
                    semanticsLabel: '$etiqueta: $valor',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: t.crqAgregarUno,
                  onPressed: valor < maximo ? () => onChanged(valor + 1) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final Widget child;

  const _VistaPrevia({required this.child});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        children: [
          Text(t.crqVistaPrevia, style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Estructura común de las hojas: título, ayuda, contenido y margen para el
/// teclado.
class _Hoja extends StatelessWidget {
  final String titulo;
  final String? ayuda;
  final List<Widget> children;

  const _Hoja({required this.titulo, this.ayuda, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ayudaTexto = (ayuda ?? '').trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: theme.textTheme.headlineSmall),
            if (ayudaTexto.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                ayudaTexto,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BotonesHoja extends StatelessWidget {
  final String confirmar;
  final VoidCallback? onConfirmar;

  const _BotonesHoja({required this.confirmar, required this.onConfirmar});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.commonCancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: onConfirmar, child: Text(confirmar)),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Nuevo croquis
// -----------------------------------------------------------------------------

class _NuevoHoja extends StatefulWidget {
  final List<Oferta> ofertas;

  const _NuevoHoja({required this.ofertas});

  @override
  State<_NuevoHoja> createState() => _NuevoHojaState();
}

class _NuevoHojaState extends State<_NuevoHoja> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();

  String _ofertaId = '';
  String _nombreSugerido = '';
  int _filas = 5;
  int _columnas = 6;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  /// Al elegir una vacante se propone su nombre para el croquis, salvo que ya
  /// se haya escrito otro.
  void _elegirOferta(String? id) {
    final elegido = id ?? '';
    final oferta = widget.ofertas.where((o) => o.id == elegido).firstOrNull;
    setState(() {
      _ofertaId = elegido;
      final actual = _nombre.text.trim();
      if (oferta != null && (actual.isEmpty || actual == _nombreSugerido)) {
        _nombreSugerido = oferta.nombreCompleto;
        _nombre.text = _nombreSugerido;
      }
    });
  }

  void _crear() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop<CrqNuevoDatos>((
      nombre: _nombre.text.trim(),
      ofertaId: _ofertaId,
      filas: _filas,
      columnas: _columnas,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: _Hoja(
        titulo: t.crqNuevo,
        children: [
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: InputDecoration(
              labelText: t.crqNombreLabel,
              helperText: t.crqNombreHelper,
              prefixIcon: const Icon(Icons.grid_view_rounded),
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? t.commonRequiredField : null,
          ),
          if (widget.ofertas.isNotEmpty) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _ofertaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.crqVacanteAsociada,
                helperText: t.crqVacanteAsociadaHelper,
                prefixIcon: const Icon(Icons.event_seat_rounded),
              ),
              items: [
                DropdownMenuItem(value: '', child: Text(t.crqSinVacante)),
                for (final o in widget.ofertas)
                  DropdownMenuItem(
                    value: o.id,
                    child: Text(
                      '${o.nombreCompleto} · ${t.categoriaOferta(o)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _elegirOferta,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CrqContador(
                  etiqueta: t.crqFilas,
                  valor: _filas,
                  maximo: Croquis.maxFilas,
                  onChanged: (v) => setState(() => _filas = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CrqContador(
                  etiqueta: t.crqColumnas,
                  valor: _columnas,
                  maximo: Croquis.maxColumnas,
                  onChanged: (v) => setState(() => _columnas = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _VistaPrevia(
            child: CrqMiniatura(
              filas: _filas,
              columnas: _columnas,
              celdas: List<CrqCelda>.filled(_filas * _columnas, CrqCelda.libre),
              ancho: 220,
              alto: 130,
            ),
          ),
          const SizedBox(height: 20),
          _BotonesHoja(confirmar: t.crqCrear, onConfirmar: _crear),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Cambiar tamaño
// -----------------------------------------------------------------------------

class _TamanoHoja extends StatefulWidget {
  final Croquis croquis;

  const _TamanoHoja({required this.croquis});

  @override
  State<_TamanoHoja> createState() => _TamanoHojaState();
}

class _TamanoHojaState extends State<_TamanoHoja> {
  late int _filas = widget.croquis.filas;
  late int _columnas = widget.croquis.columnas;

  /// Estado de un lugar al pasar del tamaño actual al elegido.
  CrqCelda _celda(int fila, int columna) {
    final c = widget.croquis;
    final existe = fila < c.filas && columna < c.columnas;
    final ocupado = existe && c.asiento(fila, columna).trim().isNotEmpty;
    if (fila < _filas && columna < _columnas) {
      return ocupado ? CrqCelda.ocupado : CrqCelda.libre;
    }
    if (!existe) return CrqCelda.vacia;
    return ocupado ? CrqCelda.perdido : CrqCelda.fuera;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = widget.croquis;
    final filas = math.max(c.filas, _filas);
    final columnas = math.max(c.columnas, _columnas);
    final perdidos = crqLugaresPerdidos(c, _filas, _columnas);
    final cambio = _filas != c.filas || _columnas != c.columnas;

    return _Hoja(
      titulo: t.crqTamanoTitulo,
      ayuda: t.crqTamanoAyuda,
      children: [
        Row(
          children: [
            Expanded(
              child: CrqContador(
                etiqueta: t.crqFilas,
                valor: _filas,
                maximo: Croquis.maxFilas,
                onChanged: (v) => setState(() => _filas = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CrqContador(
                etiqueta: t.crqColumnas,
                valor: _columnas,
                maximo: Croquis.maxColumnas,
                onChanged: (v) => setState(() => _columnas = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _VistaPrevia(
          child: CrqMiniatura(
            filas: filas,
            columnas: columnas,
            celdas: [
              for (var f = 0; f < filas; f++)
                for (var col = 0; col < columnas; col++) _celda(f, col),
            ],
            ancho: 220,
            alto: 130,
          ),
        ),
        if (perdidos > 0) ...[
          const SizedBox(height: 12),
          AtenaBanner(
            tone: AtenaBannerTone.warning,
            message: t.crqTamanoPierde(perdidos),
          ),
        ],
        const SizedBox(height: 20),
        _BotonesHoja(
          confirmar: t.crqAplicar,
          onConfirmar: cambio
              ? () => Navigator.of(
                  context,
                ).pop<CrqTamano>((filas: _filas, columnas: _columnas))
              : null,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Renombrar
// -----------------------------------------------------------------------------

class _NombreDialogo extends StatefulWidget {
  final String titulo;
  final String inicial;

  const _NombreDialogo({required this.titulo, required this.inicial});

  @override
  State<_NombreDialogo> createState() => _NombreDialogoState();
}

class _NombreDialogoState extends State<_NombreDialogo> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.inicial,
  );

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _aceptar() {
    final nombre = _nombre.text.trim();
    if (nombre.isNotEmpty) Navigator.of(context).pop(nombre);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _nombre,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        inputFormatters: [LengthLimitingTextInputFormatter(60)],
        decoration: InputDecoration(labelText: t.crqNombreLabel),
        onSubmitted: (_) => _aceptar(),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonCancel),
        ),
        ListenableBuilder(
          listenable: _nombre,
          builder: (context, _) => FilledButton(
            onPressed: _nombre.text.trim().isEmpty ? null : _aceptar,
            child: Text(t.commonSave),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Vacante asociada
// -----------------------------------------------------------------------------

class _VacanteHoja extends StatelessWidget {
  final List<Oferta> ofertas;
  final String actual;

  const _VacanteHoja({required this.ofertas, required this.actual});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget opcion({
      required String id,
      required IconData icono,
      required String titulo,
      String? detalle,
    }) {
      final elegida = id == actual;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        selected: elegida,
        leading: AtenaIconBadge(icon: icono, size: 40),
        title: Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: detalle == null ? null : Text(detalle),
        trailing: elegida
            ? Icon(Icons.check_circle_rounded, color: cs.primary)
            : null,
        onTap: () => Navigator.of(context).pop(id),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.crqVacanteAsociada,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.crqVacanteAsociadaHelper,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  opcion(
                    id: '',
                    icono: Icons.link_off_rounded,
                    titulo: t.crqSinVacante,
                  ),
                  for (final o in ofertas)
                    opcion(
                      id: o.id,
                      icono: iconoOferta(o),
                      titulo: o.nombreCompleto,
                      detalle: t.categoriaOferta(o),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Asignar un banco
// -----------------------------------------------------------------------------

class _AsignarHoja extends StatefulWidget {
  final int numero;
  final String actual;
  final List<CrqAlumnoOpcion> alumnos;
  final String tituloLista;
  final bool hayConfirmados;
  final bool errorCarga;

  const _AsignarHoja({
    required this.numero,
    required this.actual,
    required this.alumnos,
    required this.tituloLista,
    required this.hayConfirmados,
    required this.errorCarga,
  });

  @override
  State<_AsignarHoja> createState() => _AsignarHojaState();
}

class _AsignarHojaState extends State<_AsignarHoja> {
  static const _claveLibre = ValueKey<String>('crq-nombre-libre');

  final _libre = TextEditingController();
  final _focoBusqueda = FocusNode();
  final _focoLibre = FocusNode();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _focoBusqueda.addListener(_alCambiarFoco);
    _focoLibre.addListener(_alCambiarFoco);
  }

  @override
  void dispose() {
    _libre.dispose();
    _focoBusqueda.dispose();
    _focoLibre.dispose();
    super.dispose();
  }

  /// Con el teclado abierto queda poco lugar: al buscar se muestran solo los
  /// resultados y al escribir un nombre, solo ese campo.
  void _alCambiarFoco() => setState(() {});

  void _usarNombreLibre() {
    final nombre = _libre.text.trim();
    if (nombre.isNotEmpty) Navigator.of(context).pop(nombre);
  }

  Widget _mensaje(IconData icono, String texto) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icono, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lista(AppLocalizations t) {
    if (widget.errorCarga) {
      return _mensaje(Icons.cloud_off_rounded, t.crqErrorAlumnos);
    }
    if (widget.alumnos.isEmpty) {
      return widget.hayConfirmados
          ? _mensaje(Icons.task_alt_rounded, t.crqTodosSentados)
          : _mensaje(Icons.info_outline_rounded, t.crqSinConfirmados);
    }
    final visibles = _busqueda.isEmpty
        ? widget.alumnos
        : [
            for (final a in widget.alumnos)
              if (normalizarBusqueda(a.etiqueta).contains(_busqueda)) a,
          ];
    if (visibles.isEmpty) {
      return _mensaje(Icons.search_off_rounded, t.crqSinResultados);
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: visibles.length,
      itemBuilder: (context, i) {
        final a = visibles[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: AtenaAvatar(name: a.nombre, size: 40),
          title: Text(a.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: a.detalle.isEmpty
              ? null
              : Text(a.detalle, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.of(context).pop(a.nombre),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ocupado = widget.actual.isNotEmpty;
    final teclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    final buscando = teclado && _focoBusqueda.hasFocus;
    final escribiendo = teclado && _focoLibre.hasFocus;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AtenaIconBadge(icon: Icons.event_seat_rounded),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.crqBanco(widget.numero),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ocupado
                              ? t.crqOcupadoPor(widget.actual)
                              : t.crqBancoLibre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!escribiendo) ...[
                Text(
                  widget.tituloLista,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (widget.alumnos.length > 6) ...[
                  TextField(
                    focusNode: _focoBusqueda,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: t.crqBuscarAlumno,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        setState(() => _busqueda = normalizarBusqueda(v)),
                  ),
                  const SizedBox(height: 6),
                ],
                Flexible(child: _lista(t)),
              ],
              if (!buscando) ...[
                if (!escribiendo) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 14),
                ],
                Text(t.crqNombreLibre, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  // La clave conserva el campo (y su foco) cuando el resto de
                  // la hoja se reacomoda.
                  key: _claveLibre,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _libre,
                        focusNode: _focoLibre,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        decoration: InputDecoration(
                          labelText: t.crqNombreLibreLabel,
                          prefixIcon: const Icon(Icons.person_rounded),
                        ),
                        onSubmitted: (_) => _usarNombreLibre(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ListenableBuilder(
                      listenable: _libre,
                      builder: (context, _) => FilledButton.tonal(
                        onPressed: _libre.text.trim().isEmpty
                            ? null
                            : _usarNombreLibre,
                        child: Text(t.crqAsignar),
                      ),
                    ),
                  ],
                ),
                if (ocupado && !escribiendo) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(''),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    ),
                    icon: const Icon(Icons.person_off_rounded),
                    label: Text(t.crqDejarLibre),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
