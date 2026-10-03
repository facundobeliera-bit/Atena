// lib/screens/instituciones/widgets/sol_inst_detalle.dart
//
// ATENA – Detalle de una solicitud para la institución (también es la ficha
// del alumno confirmado). Hoja inferior en teléfono y panel lateral en
// escritorio: datos y contacto del alumno, vacante con su ocupación, mensaje
// de la familia, historial y acciones según el estado.
//
// Se mantiene al día con los datos guardados: si la solicitud cambia o deja
// de existir (la familia eliminó su cuenta), lo muestra sin cerrarse de golpe.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../pdf/atena_pdf.dart';
import '../../../ui/atena_format.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'sol_inst_acciones.dart';
import 'sol_inst_comun.dart';

/// Abre el detalle de una solicitud. Si cambia de estado (confirmada, no
/// aceptada o dada de baja) se cierra y devuelve el mensaje para mostrar.
Future<String?> showSolInstDetalle(
  BuildContext context, {
  required Solicitud solicitud,
  required String institucionId,
  required String institucionNombre,
  OfertaConCupo? cupo,
}) {
  SolInstDetalle detalle({required bool panel}) => SolInstDetalle(
    solicitud: solicitud,
    institucionId: institucionId,
    institucionNombre: institucionNombre,
    cupo: cupo,
    panel: panel,
  );

  if (AtenaLayout.isDesktop(context)) {
    final theme = Theme.of(context);
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: theme.colorScheme.scrim.withValues(alpha: 0.4),
      transitionDuration: AtenaMotion.medium,
      pageBuilder: (_, _, _) => Theme(
        data: theme,
        child: _PanelLateral(child: detalle(panel: true)),
      ),
      transitionBuilder: (_, animacion, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animacion,
                curve: AtenaMotion.curve,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
        child: child,
      ),
    );
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
      ),
      child: detalle(panel: false),
    ),
  );
}

/// Panel anclado al borde derecho (escritorio).
class _PanelLateral extends StatelessWidget {
  final Widget child;

  const _PanelLateral({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ancho = math.min(560.0, MediaQuery.sizeOf(context).width);
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: cs.surface,
        elevation: 8,
        shadowColor: cs.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(AtenaRadius.xl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: ancho,
          height: double.infinity,
          child: SafeArea(left: false, child: child),
        ),
      ),
    );
  }
}

typedef _Aviso = ({String texto, bool error});

enum _Accion { confirmar, rechazar, baja, comprobante }

class SolInstDetalle extends StatefulWidget {
  final Solicitud solicitud;
  final String institucionId;
  final String institucionNombre;

  /// Ocupación conocida de la vacante (null si ya no está publicada).
  final OfertaConCupo? cupo;

  /// true = panel de alto completo; false = hoja que se ajusta al contenido.
  final bool panel;

  const SolInstDetalle({
    super.key,
    required this.solicitud,
    required this.institucionId,
    required this.institucionNombre,
    this.cupo,
    this.panel = false,
  });

  @override
  State<SolInstDetalle> createState() => _SolInstDetalleState();
}

class _SolInstDetalleState extends State<SolInstDetalle> {
  late Solicitud _s = widget.solicitud;
  late OfertaConCupo? _cupo = widget.cupo;
  bool _eliminada = false;
  _Accion? _accion;
  _Aviso? _aviso;
  Timer? _avisoTimer;
  Timer? _recarga;

  @override
  void initState() {
    super.initState();
    AtenaStore.instance.revision.addListener(_alCambiarDatos);
  }

  @override
  void dispose() {
    AtenaStore.instance.revision.removeListener(_alCambiarDatos);
    _avisoTimer?.cancel();
    _recarga?.cancel();
    super.dispose();
  }

  /// Algo cambió en los datos guardados: se vuelve a leer la solicitud.
  void _alCambiarDatos() {
    _recarga?.cancel();
    _recarga = Timer(const Duration(milliseconds: 300), _refrescar);
  }

  Future<void> _refrescar() async {
    if (!mounted) return;
    try {
      final actual = await SolicitudesRepo.instance.obtener(_s.id);
      final ofertas = await OfertasRepo.instance.conCupo(widget.institucionId);
      if (!mounted) return;
      setState(() {
        if (actual == null) {
          _eliminada = true;
          return;
        }
        _s = actual;
        _cupo = ofertas
            .where((o) => o.oferta.id == actual.ofertaId)
            .firstOrNull;
      });
    } catch (_) {
      // Se conserva lo que ya se muestra.
    }
  }

  void _avisar(String texto, {bool error = false}) {
    if (!mounted) return;
    _avisoTimer?.cancel();
    setState(() => _aviso = (texto: texto, error: error));
    _avisoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _aviso = null);
    });
  }

  void _ocupado(_Accion accion, bool activo) {
    if (!mounted) return;
    setState(() => _accion = activo ? accion : null);
  }

  /// Si la acción cambió el estado, cierra el detalle con el mensaje para la
  /// pantalla anterior; si no, actualiza lo que se muestra.
  Future<void> _resultado(String? mensaje) async {
    if (!mounted) return;
    if (mensaje != null) {
      Navigator.of(context).pop(mensaje);
      return;
    }
    await _refrescar();
  }

  Future<void> _confirmar() async {
    final mensaje = await solInstConfirmar(
      context,
      _s,
      institucionId: widget.institucionId,
      institucionNombre: widget.institucionNombre,
      onProcesando: (activo) => _ocupado(_Accion.confirmar, activo),
      onError: (m) => _avisar(m, error: true),
    );
    await _resultado(mensaje);
  }

  Future<void> _rechazar() async {
    final mensaje = await solInstRechazar(
      context,
      _s,
      institucionId: widget.institucionId,
      onProcesando: (activo) => _ocupado(_Accion.rechazar, activo),
      onError: (m) => _avisar(m, error: true),
    );
    await _resultado(mensaje);
  }

  Future<void> _darDeBaja() async {
    final mensaje = await solInstDarDeBaja(
      context,
      _s,
      institucionId: widget.institucionId,
      onProcesando: (activo) => _ocupado(_Accion.baja, activo),
      onError: (m) => _avisar(m, error: true),
    );
    await _resultado(mensaje);
  }

  Future<void> _pedirDocumento() async {
    final mensaje = await solInstPedirDocumento(
      context,
      _s,
      institucionId: widget.institucionId,
      institucionNombre: widget.institucionNombre,
    );
    if (mensaje != null) _avisar(mensaje);
  }

  Future<void> _comprobante() async {
    final t = AppLocalizations.of(context);
    final s = _s;
    _ocupado(_Accion.comprobante, true);
    await solInstCompartirPdf(
      context,
      generar: () => AtenaPdf.comprobanteSolicitud(t: t, solicitud: s),
      nombreArchivo: solInstNombreArchivo(
        t.solInstArchivoComprobante,
        s.alumno.apellidoNombre,
      ),
      onError: (m) => _avisar(m, error: true),
    );
    _ocupado(_Accion.comprobante, false);
  }

  Future<void> _irAVacantes() async {
    await solInstAbrirVacantes(
      context,
      institucionId: widget.institucionId,
      institucionNombre: widget.institucionNombre,
    );
    await _refrescar();
  }

  Future<void> _abrir(Uri uri) async {
    final t = AppLocalizations.of(context);
    final abierto = await solInstAbrirEnlace(uri);
    if (!abierto) _avisar(t.solInstNoSePudoAbrir, error: true);
  }

  Future<void> _copiar(String valor) async {
    final t = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: valor));
    _avisar(t.solInstCopiado);
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_eliminada) return _YaNoExiste(panel: widget.panel);

    final contenido = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _secciones(context),
      ),
    );
    final aviso = _aviso;

    return Column(
      mainAxisSize: widget.panel ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Encabezado(
          solicitud: _s,
          panel: widget.panel,
          generando: _accion == _Accion.comprobante,
          onComprobante: _accion == null ? _comprobante : null,
        ),
        const Divider(height: 1),
        if (widget.panel)
          Expanded(child: contenido)
        else
          Flexible(child: contenido),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: AtenaMotion.fast,
                alignment: Alignment.bottomCenter,
                child: aviso == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Semantics(
                          liveRegion: true,
                          child: AtenaBanner(
                            tone: aviso.error
                                ? AtenaBannerTone.error
                                : AtenaBannerTone.success,
                            message: aviso.texto,
                          ),
                        ),
                      ),
              ),
              ?_barraAcciones(context),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _secciones(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = _s;
    final cupo = _cupo;
    final oferta = cupo?.oferta ?? s.oferta;
    final edad = s.alumno.edad;
    final pendiente = s.estado == EstadoSolicitud.pendiente;
    final ocupado = _accion != null;
    final mensaje = s.mensaje.trim();
    const separador = SizedBox(height: 24);

    return [
      if (pendiente) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            style: _botonCompacto,
            onPressed: ocupado ? null : _pedirDocumento,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(t.solInstPedirDocumento),
          ),
        ),
        if (cupo != null && cupo.completa) ...[
          const SizedBox(height: 16),
          AtenaBanner(
            tone: AtenaBannerTone.warning,
            message: t.solInstSinCupoAviso,
            action: TextButton(
              onPressed: ocupado ? null : _irAVacantes,
              child: Text(t.solInstIrAVacantes),
            ),
          ),
        ],
        if (edad != null && !oferta.aceptaEdad(edad)) ...[
          const SizedBox(height: 12),
          AtenaBanner(
            icon: Icons.cake_outlined,
            message: t.solInstEdadFueraDeRango(
              t.lblEdadAnios(edad),
              t.rangoEdad(oferta.edadMinima, oferta.edadMaxima),
            ),
          ),
        ],
        separador,
      ],
      _Seccion(
        titulo: t.authStudentSection,
        child: _Caja(
          child: Column(
            children: [
              AtenaInfoRow(
                icon: Icons.badge_outlined,
                label: t.authDniLabel,
                value: s.alumno.dni,
              ),
              AtenaInfoRow(
                icon: Icons.cake_outlined,
                label: t.authBirthDate,
                value: _nacimiento(context, s.alumno),
              ),
            ],
          ),
        ),
      ),
      separador,
      _Seccion(titulo: t.solInstSecContacto, child: _contacto(context)),
      separador,
      _Seccion(titulo: t.solInstSecVacante, child: _vacante(context)),
      if (mensaje.isNotEmpty) ...[
        separador,
        _Seccion(
          titulo: t.solInstSecMensaje,
          child: _Mensaje(texto: mensaje),
        ),
      ],
      separador,
      _Seccion(
        titulo: t.solInstSecHistorial,
        child: _Historial(cambios: _historial(s)),
      ),
    ];
  }

  String _nacimiento(BuildContext context, AlumnoSnapshot a) {
    final fecha = a.fechaNacimiento;
    if (fecha == null) return '';
    final t = AppLocalizations.of(context);
    return [
      AtenaFormat.fechaNumerica(context, fecha),
      t.lblEdadAnios(edadEnAnios(fecha)),
    ].join(' · ');
  }

  Widget _contacto(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final email = _s.alumno.email.trim();
    final telefono = _s.alumno.telefono.trim();
    final digitos = telefono.replaceAll(RegExp(r'\D'), '');

    if (email.isEmpty && telefono.isEmpty) {
      return _Caja(
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.solInstSinContacto,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email.isNotEmpty)
            _FilaContacto(
              icono: Icons.alternate_email_rounded,
              etiqueta: t.commonEmail,
              valor: email,
              onCopiar: () => _copiar(email),
            ),
          if (telefono.isNotEmpty)
            _FilaContacto(
              icono: Icons.phone_rounded,
              etiqueta: t.commonPhone,
              valor: telefono,
              onCopiar: () => _copiar(telefono),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (digitos.isNotEmpty) ...[
                FilledButton.tonalIcon(
                  style: _botonCompacto,
                  onPressed: () => _abrir(
                    Uri(
                      scheme: 'tel',
                      path: telefono.startsWith('+') ? '+$digitos' : digitos,
                    ),
                  ),
                  icon: const Icon(Icons.call_rounded),
                  label: Text(t.solInstLlamar),
                ),
                FilledButton.tonalIcon(
                  style: _botonCompacto,
                  onPressed: () => _abrir(Uri.https('wa.me', '/$digitos')),
                  icon: const Icon(Icons.chat_rounded),
                  label: Text(t.solInstWhatsapp),
                ),
              ],
              if (email.isNotEmpty)
                FilledButton.tonalIcon(
                  style: _botonCompacto,
                  onPressed: () => _abrir(Uri(scheme: 'mailto', path: email)),
                  icon: const Icon(Icons.mail_rounded),
                  label: Text(t.solInstEscribirEmail),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vacante(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cupo = _cupo;
    final o = cupo?.oferta ?? _s.oferta;
    final detalles = [
      t.categoriaOferta(o),
      t.turno(o.turno),
      t.rangoEdad(o.edadMinima, o.edadMaxima),
    ].where((x) => x.isNotEmpty).join(' · ');
    final horario = [
      o.dias.trim(),
      o.horario.trim(),
    ].where((x) => x.isNotEmpty).join(' · ');

    return _Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtenaIconBadge(icon: iconoOferta(o)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.nombreCompleto, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(detalles, style: theme.textTheme.bodySmall),
                    if (horario.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(horario, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (cupo == null)
            Text(t.solInstVacanteNoDisponible, style: theme.textTheme.bodySmall)
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.solInstOcupacion,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                if (!o.activa) ...[
                  AtenaStatusChip(
                    label: t.solInstVacantePausada,
                    color: AtenaStatusColors.cancelled,
                    icon: Icons.pause_circle_rounded,
                    dense: true,
                  ),
                  const SizedBox(width: 6),
                ],
                if (cupo.completa)
                  AtenaStatusChip(
                    label: t.solInstVacanteCompleta,
                    color: AtenaStatusColors.pending,
                    icon: Icons.event_busy_rounded,
                    dense: true,
                  )
                else
                  Text(
                    t.lblCuposDeTotal(cupo.disponibles, o.cupoTotal),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: cupo.ocupacion,
              color: cupo.completa ? AtenaBrand.of(context).warning : null,
              semanticsLabel: t.solInstOcupacion,
            ),
            if (cupo.pendientes > 0) ...[
              const SizedBox(height: 8),
              Text(
                t.solInstPendientesOferta(cupo.pendientes),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Acciones principales, fijas al pie. null si el estado no admite ninguna.
  Widget? _barraAcciones(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final ocupado = _accion != null;
    final destructivo = OutlinedButton.styleFrom(
      foregroundColor: cs.error,
      side: BorderSide(color: cs.error.withValues(alpha: 0.5), width: 1.2),
    );

    final botones = switch (_s.estado) {
      EstadoSolicitud.pendiente => (
        OutlinedButton.icon(
          style: destructivo,
          onPressed: ocupado ? null : _rechazar,
          icon: _accion == _Accion.rechazar
              ? const SolInstSpinner()
              : const Icon(Icons.close_rounded),
          label: _etiqueta(t.solInstNoAceptar),
        ),
        FilledButton.icon(
          onPressed: ocupado ? null : _confirmar,
          icon: _accion == _Accion.confirmar
              ? const SolInstSpinner()
              : const Icon(Icons.check_rounded),
          label: _etiqueta(t.solInstConfirmarVacante),
        ),
      ),
      EstadoSolicitud.confirmada => (
        OutlinedButton.icon(
          style: destructivo,
          onPressed: ocupado ? null : _darDeBaja,
          icon: _accion == _Accion.baja
              ? const SolInstSpinner()
              : const Icon(Icons.person_remove_rounded),
          label: _etiqueta(t.solInstDarDeBaja),
        ),
        FilledButton.tonalIcon(
          onPressed: ocupado ? null : _pedirDocumento,
          icon: const Icon(Icons.upload_file_rounded),
          label: _etiqueta(t.solInstPedirDocumento),
        ),
      ),
      _ => null,
    };
    if (botones == null) return null;
    final (secundario, principal) = botones;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 460) {
              return Row(
                children: [
                  Expanded(child: secundario),
                  const SizedBox(width: 12),
                  Expanded(child: principal),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [principal, const SizedBox(height: 8), secundario],
            );
          },
        ),
      ),
    );
  }
}

const ButtonStyle _botonCompacto = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 44)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
);

Widget _etiqueta(String texto) =>
    Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis);

/// Historial en orden cronológico (se reconstruye si la solicitud no lo trae).
List<CambioEstado> _historial(Solicitud s) {
  final cambios = [...s.historial]..sort((a, b) => a.fecha.compareTo(b.fecha));
  if (cambios.isNotEmpty) return cambios;
  return [
    CambioEstado(estado: EstadoSolicitud.pendiente, fecha: s.creadaEl),
    if (s.estado != EstadoSolicitud.pendiente)
      CambioEstado(estado: s.estado, fecha: s.actualizadaEl, nota: s.respuesta),
  ];
}

/// Fecha en que la solicitud llegó a su estado actual.
DateTime _fechaDelEstado(Solicitud s) {
  if (s.estado == EstadoSolicitud.pendiente) return s.creadaEl;
  for (final c in s.historial.reversed) {
    if (c.estado == s.estado) return c.fecha;
  }
  return s.actualizadaEl;
}

class _Encabezado extends StatelessWidget {
  final Solicitud solicitud;
  final bool panel;

  /// Se está generando el comprobante en PDF.
  final bool generando;

  /// null = hay otra acción en curso.
  final VoidCallback? onComprobante;

  const _Encabezado({
    required this.solicitud,
    required this.panel,
    required this.generando,
    required this.onComprobante,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = solicitud;
    final momento = _fechaDelEstado(s);
    final fecha = AtenaFormat.fechaCorta(context, momento);
    final hora = AtenaFormat.hora(context, momento);
    final cuando = switch (s.estado) {
      EstadoSolicitud.pendiente => t.solInstRecibidaEl(fecha, hora),
      EstadoSolicitud.confirmada => t.solInstConfirmadaEl(fecha, hora),
      EstadoSolicitud.rechazada => t.solInstRechazadaEl(fecha, hora),
      EstadoSolicitud.canceladaPorAlumno => t.solInstCanceladaEl(fecha, hora),
      EstadoSolicitud.canceladaPorInstitucion => t.solInstBajaEl(fecha, hora),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(24, panel ? 20 : 0, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtenaAvatar(name: s.alumno.nombreCompleto, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.alumno.apellidoNombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                AtenaStatusChip(
                  label: t.estadoSolicitud(s.estado),
                  color: colorEstadoSolicitud(s.estado),
                  icon: iconoEstadoSolicitud(s.estado),
                  dense: true,
                ),
                const SizedBox(height: 8),
                Text(cuando, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: t.solInstDescargarComprobante,
            onPressed: onComprobante,
            icon: generando
                ? const SolInstSpinner(size: 20)
                : const Icon(Icons.download_rounded),
          ),
          IconButton(
            tooltip: t.uiClose,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// La solicitud dejó de existir mientras se estaba viendo.
class _YaNoExiste extends StatelessWidget {
  final bool panel;

  const _YaNoExiste({required this.panel});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final estado = AtenaEmptyState(
      icon: Icons.person_off_rounded,
      title: t.solInstYaNoExisteTitulo,
      message: t.solInstYaNoExisteMsg,
      compact: !panel,
      action: FilledButton.tonal(
        onPressed: () => Navigator.of(context).maybePop(),
        child: Text(t.uiClose),
      ),
    );
    return SafeArea(
      top: false,
      child: panel ? estado : SingleChildScrollView(child: estado),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _Caja extends StatelessWidget {
  final Widget child;

  const _Caja({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AtenaRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _FilaContacto extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final VoidCallback onCopiar;

  const _FilaContacto({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icono, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              SelectableText(valor, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        IconButton(
          tooltip: t.solInstCopiar,
          onPressed: onCopiar,
          icon: const Icon(Icons.content_copy_rounded, size: 20),
        ),
      ],
    );
  }
}

class _Mensaje extends StatelessWidget {
  final String texto;

  const _Mensaje({required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AtenaRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(texto, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Historial extends StatelessWidget {
  final List<CambioEstado> cambios;

  const _Historial({required this.cambios});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < cambios.length; i++)
          _Hito(cambio: cambios[i], ultimo: i == cambios.length - 1),
      ],
    );
  }
}

class _Hito extends StatelessWidget {
  final CambioEstado cambio;
  final bool ultimo;

  const _Hito({required this.cambio, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tono = AtenaTone.of(context, colorEstadoSolicitud(cambio.estado));
    final nota = cambio.nota.trim();
    final titulo = switch (cambio.estado) {
      EstadoSolicitud.pendiente => t.solInstHistRecibida,
      EstadoSolicitud.confirmada => t.solInstHistConfirmada,
      EstadoSolicitud.rechazada => t.solInstHistRechazada,
      EstadoSolicitud.canceladaPorAlumno => t.solInstHistCanceladaFamilia,
      EstadoSolicitud.canceladaPorInstitucion => t.solInstHistBaja,
    };
    final cuando = [
      AtenaFormat.fechaCorta(context, cambio.fecha),
      AtenaFormat.hora(context, cambio.fecha),
    ].join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tono.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconoEstadoSolicitud(cambio.estado),
                  size: 18,
                  color: tono.foreground,
                ),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: cs.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: ultimo ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(cuando, style: theme.textTheme.bodySmall),
                  if (nota.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AtenaRadius.sm),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(nota, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
