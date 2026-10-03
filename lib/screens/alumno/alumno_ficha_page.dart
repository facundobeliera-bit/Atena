// lib/screens/alumno/alumno_ficha_page.dart
//
// ATENA – Ficha del alumno.
// Foto, datos personales (con acceso a editarlos), instituciones donde tiene
// la vacante confirmada y la ficha en PDF para descargar o imprimir.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../pdf/atena_pdf.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import '../alumnos/explorar_instituciones_page.dart';
import '../alumnos/mis_solicitudes_page.dart';
import 'alumno_perfil_form_page.dart';
import 'widgets/ficha_al_encabezado.dart';
import 'widgets/ficha_al_foto.dart';

enum _Pdf { descargar, imprimir }

class AlumnoFichaPage extends StatefulWidget {
  final String cuentaId;
  final String perfilId;

  const AlumnoFichaPage({
    super.key,
    required this.cuentaId,
    required this.perfilId,
  });

  @override
  State<AlumnoFichaPage> createState() => _AlumnoFichaPageState();
}

class _AlumnoFichaPageState extends State<AlumnoFichaPage> {
  PerfilAlumno? _perfil;
  Uint8List? _foto;
  List<Solicitud> _confirmadas = const [];

  bool _loading = true;
  Object? _error;
  bool _guardandoFoto = false;

  /// PDF que se está generando (bloquea ambas acciones).
  _Pdf? _generando;

  Timer? _recarga;

  /// En teléfonos se puede sacar la foto con la cámara; en web y escritorio
  /// se elige una imagen guardada.
  bool get _conCamara =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    AtenaStore.instance.revision.addListener(_alCambiarDatos);
    _load();
  }

  @override
  void dispose() {
    AtenaStore.instance.revision.removeListener(_alCambiarDatos);
    _recarga?.cancel();
    super.dispose();
  }

  /// Los datos cambiaron (edición del alumno, respuesta de una institución o
  /// su baja): vuelve a cargar cuando terminan las escrituras.
  void _alCambiarDatos() {
    _recarga?.cancel();
    _recarga = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final alumnos = AlumnosRepo.instance;
      final perfil = await alumnos.perfilDeCuenta(
        widget.cuentaId,
        widget.perfilId,
      );
      if (perfil == null) throw const AtenaException(AtenaError.noEncontrado);
      final foto = await alumnos.foto(widget.perfilId);
      final solicitudes = await SolicitudesRepo.instance.porPerfil(
        widget.perfilId,
      );

      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _foto = foto;
        _confirmadas = solicitudes
            .where((s) => s.estado == EstadoSolicitud.confirmada)
            .toList();
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

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  Future<void> _editar(PerfilAlumno perfil) async {
    await Navigator.of(context).push<PerfilAlumno>(
      MaterialPageRoute(
        builder: (_) =>
            AlumnoPerfilFormPage(cuentaId: widget.cuentaId, perfil: perfil),
      ),
    );
    if (mounted) await _load();
  }

  // ---------------------------------------------------------------------------
  // Foto
  // ---------------------------------------------------------------------------

  Future<void> _cambiarFoto() async {
    if (_guardandoFoto) return;
    final tieneFoto = _foto != null;
    final accion = !_conCamara && !tieneFoto
        ? FichaAlFotoAccion.galeria
        : await mostrarFichaAlFotoOpciones(
            context,
            tieneFoto: tieneFoto,
            camara: _conCamara,
          );
    if (accion == null || !mounted) return;
    switch (accion) {
      case FichaAlFotoAccion.camara:
        await _elegirFoto(ImageSource.camera);
      case FichaAlFotoAccion.galeria:
        await _elegirFoto(ImageSource.gallery);
      case FichaAlFotoAccion.quitar:
        await _quitarFoto();
    }
  }

  Future<void> _elegirFoto(ImageSource fuente) async {
    final t = AppLocalizations.of(context);

    final Uint8List? bytes;
    try {
      final elegida = await ImagePicker().pickImage(
        source: fuente,
        maxWidth: 800,
        imageQuality: 80,
      );
      bytes = elegida == null
          ? null
          : await ajustarFotoFichaAl(await elegida.readAsBytes());
    } catch (_) {
      if (mounted) AtenaFeedback.error(context, t.fichaAlFotoError);
      return;
    }
    if (bytes == null || !mounted) return;

    setState(() => _guardandoFoto = true);
    try {
      await AlumnosRepo.instance.guardarFoto(widget.perfilId, bytes);
      if (!mounted) return;
      setState(() => _foto = bytes);
      AtenaFeedback.success(context, t.fichaAlFotoGuardada);
    } catch (e) {
      if (!mounted) return;
      AtenaFeedback.error(context, coreErrorText(t, e));
    } finally {
      if (mounted) setState(() => _guardandoFoto = false);
    }
  }

  Future<void> _quitarFoto() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.fichaAlQuitarFotoConfirm,
      message: t.fichaAlQuitarFotoMensaje,
      confirmLabel: t.fichaAlQuitarFoto,
      destructive: true,
      icon: Icons.no_photography_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _guardandoFoto = true);
    try {
      await AlumnosRepo.instance.eliminarFoto(widget.perfilId);
      if (!mounted) return;
      setState(() => _foto = null);
      AtenaFeedback.success(context, t.fichaAlFotoEliminada);
    } catch (e) {
      if (!mounted) return;
      AtenaFeedback.error(context, coreErrorText(t, e));
    } finally {
      if (mounted) setState(() => _guardandoFoto = false);
    }
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  Future<void> _pdf(PerfilAlumno perfil, _Pdf accion) async {
    if (_generando != null) return;
    final t = AppLocalizations.of(context);
    setState(() => _generando = accion);
    try {
      final bytes = await AtenaPdf.fichaAlumno(
        t: t,
        perfil: perfil,
        foto: _foto,
        solicitudes: _confirmadas,
      );
      if (!mounted) return;
      final nombre = _nombrePdf(perfil);
      switch (accion) {
        case _Pdf.descargar:
          await AtenaPdf.compartir(context, bytes, nombre);
        case _Pdf.imprimir:
          await AtenaPdf.imprimir(context, bytes, nombre);
      }
    } catch (_) {
      if (mounted) AtenaFeedback.error(context, t.fichaAlPdfError);
    } finally {
      if (mounted) setState(() => _generando = null);
    }
  }

  // ---------------------------------------------------------------------------
  // Vista
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final perfil = _perfil;
    final error = _error;

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AtenaAppBar(title: t.fichaAlTitulo),
      body: _loading
          ? const AtenaLoading()
          : error != null || perfil == null
          ? AtenaErrorState(
              message: coreErrorText(
                t,
                error ?? const AtenaException(AtenaError.noEncontrado),
              ),
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _contenido(context, perfil),
            ),
    );
  }

  Widget _contenido(BuildContext context, PerfilAlumno perfil) {
    final t = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: atenaPagePadding(context, maxWidth: 760),
      children: [
        FichaAlEncabezado(
          perfil: perfil,
          foto: _foto,
          guardando: _guardandoFoto,
          onFoto: _cambiarFoto,
        ),
        const SizedBox(height: 20),
        AtenaSectionHeader(
          title: t.fichaAlDatosPersonales,
          action: TextButton.icon(
            onPressed: () => _editar(perfil),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(t.fichaAlEditarDatos),
          ),
        ),
        _Datos(perfil: perfil),
        const SizedBox(height: 16),
        AtenaSectionHeader(
          title: t.fichaAlInstituciones,
          subtitle: t.fichaAlInstitucionesSub,
        ),
        if (_confirmadas.isEmpty)
          _SinInstituciones(
            onExplorar: () => _go(
              ExplorarInstitucionesPage(
                cuentaId: widget.cuentaId,
                perfilId: widget.perfilId,
              ),
            ),
          )
        else
          AtenaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, s) in _confirmadas.indexed) ...[
                  if (i > 0) const Divider(indent: 72),
                  _InstitucionTile(
                    solicitud: s,
                    onTap: () => _go(
                      SolicitudAlumnoDetallePage(
                        cuentaId: widget.cuentaId,
                        perfilId: widget.perfilId,
                        solicitudId: s.id,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        AtenaSectionHeader(title: t.fichaAlPdf, subtitle: t.fichaAlPdfSub),
        _AccionesPdf(
          generando: _generando,
          onDescargar: () => _pdf(perfil, _Pdf.descargar),
          onImprimir: () => _pdf(perfil, _Pdf.imprimir),
        ),
      ],
    );
  }
}

/// Nombre del archivo PDF: la palabra "ficha" seguida del apellido
/// (sin acentos ni espacios), por ejemplo "ficha-gonzalez.pdf".
String _nombrePdf(PerfilAlumno perfil) {
  const conAcento = 'áàâãäéèêëíìîïóòôõöúùûüñç';
  const sinAcento = 'aaaaaeeeeiiiiooooouuuunc';
  final base = perfil.apellido.trim().isEmpty ? perfil.nombre : perfil.apellido;
  final limpio = base
      .toLowerCase()
      .split('')
      .map((c) {
        final i = conAcento.indexOf(c);
        return i < 0 ? c : sinAcento[i];
      })
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return limpio.isEmpty ? 'ficha.pdf' : 'ficha-$limpio.pdf';
}

/// Datos personales en una o dos columnas según el ancho.
class _Datos extends StatelessWidget {
  final PerfilAlumno perfil;

  const _Datos({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sinNacimiento = perfil.fechaNacimiento.millisecondsSinceEpoch == 0;
    final filas = [
      AtenaInfoRow(
        icon: Icons.person_outline_rounded,
        label: t.commonNameLabel,
        value: perfil.nombre,
      ),
      AtenaInfoRow(
        icon: Icons.people_outline_rounded,
        label: t.commonLastNameLabel,
        value: perfil.apellido,
      ),
      AtenaInfoRow(
        icon: Icons.badge_outlined,
        label: t.authDniLabel,
        value: fichaAlFormatearDni(perfil.documento),
      ),
      AtenaInfoRow(
        icon: Icons.cake_outlined,
        label: t.authBirthDate,
        value: sinNacimiento
            ? ''
            : AtenaFormat.fechaNumerica(context, perfil.fechaNacimiento),
      ),
      AtenaInfoRow(
        icon: Icons.alternate_email_rounded,
        label: t.commonEmail,
        value: perfil.email,
      ),
      AtenaInfoRow(
        icon: Icons.phone_outlined,
        label: t.commonPhone,
        value: perfil.telefono,
      ),
    ];

    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 520) return Column(children: filas);
          const separacion = 24.0;
          final ancho = (c.maxWidth - separacion) / 2;
          return Wrap(
            spacing: separacion,
            children: [for (final f in filas) SizedBox(width: ancho, child: f)],
          );
        },
      ),
    );
  }
}

class _InstitucionTile extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback onTap;

  const _InstitucionTile({required this.solicitud, required this.onTap});

  /// Fecha en que la institución confirmó la vacante.
  DateTime get _confirmadaEl {
    for (final cambio in solicitud.historial.reversed) {
      if (cambio.estado == EstadoSolicitud.confirmada) return cambio.fecha;
    }
    return solicitud.actualizadaEl;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = solicitud;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            AtenaIconBadge(icon: iconoOferta(s.oferta), size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.institucionNombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.ofertaNombre} · ${t.categoriaOferta(s.oferta)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  // Se achica si no entra (pantallas angostas con letra grande).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: AtenaStatusChip(
                      label: t.fichaAlConfirmadaEl(
                        AtenaFormat.fechaCorta(context, _confirmadaEl),
                      ),
                      color: colorEstadoSolicitud(s.estado),
                      icon: iconoEstadoSolicitud(s.estado),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
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

class _SinInstituciones extends StatelessWidget {
  final VoidCallback onExplorar;

  const _SinInstituciones({required this.onExplorar});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AtenaCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AtenaIconBadge(
                icon: Icons.account_balance_rounded,
                color: AtenaColors.indigo,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t.fichaAlSinInstituciones,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onExplorar,
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text(t.homeActionExplore),
            ),
          ),
        ],
      ),
    );
  }
}

/// Descargar e imprimir la ficha (lado a lado si hay lugar).
class _AccionesPdf extends StatelessWidget {
  final _Pdf? generando;
  final VoidCallback onDescargar;
  final VoidCallback onImprimir;

  const _AccionesPdf({
    required this.generando,
    required this.onDescargar,
    required this.onImprimir,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    Widget accion({
      required _Pdf tipo,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Color? accent,
    }) {
      final enCurso = generando == tipo;
      return AtenaActionTile(
        icon: icon,
        title: title,
        subtitle: enCurso ? t.fichaAlGenerando : subtitle,
        accent: accent,
        enabled: generando == null || enCurso,
        onTap: generando == null ? onTap : null,
        trailing: enCurso
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : null,
      );
    }

    final descargar = accion(
      tipo: _Pdf.descargar,
      icon: Icons.picture_as_pdf_rounded,
      title: t.fichaAlDescargarPdf,
      subtitle: t.fichaAlDescargarPdfSub,
      onTap: onDescargar,
    );
    final imprimir = accion(
      tipo: _Pdf.imprimir,
      icon: Icons.print_rounded,
      title: t.fichaAlImprimir,
      subtitle: t.fichaAlImprimirSub,
      accent: AtenaColors.indigo,
      onTap: onImprimir,
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 600) {
          return Column(
            children: [descargar, const SizedBox(height: 10), imprimir],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: descargar),
              const SizedBox(width: 12),
              Expanded(child: imprimir),
            ],
          ),
        );
      },
    );
  }
}
