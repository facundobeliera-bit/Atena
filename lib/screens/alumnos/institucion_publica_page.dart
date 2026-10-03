// lib/screens/alumnos/institucion_publica_page.dart
//
// ATENA – Ficha pública de una institución vista por el alumno.
// Portada con fotos y logo, descripción, vacantes activas agrupadas por nivel
// o actividad (con el pedido de vacante), horarios, servicios y contacto.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/cuentas/cuenta.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'mis_solicitudes_page.dart';
import 'widgets/explorar_comun.dart';
import 'widgets/explorar_contacto.dart';
import 'widgets/explorar_galeria.dart';
import 'widgets/explorar_oferta_card.dart';
import 'widgets/sol_al_pedir_vacante_sheet.dart';

class InstitucionPublicaPage extends StatefulWidget {
  final String cuentaId;
  final String perfilId;
  final String institucionId;

  const InstitucionPublicaPage({
    super.key,
    required this.cuentaId,
    required this.perfilId,
    required this.institucionId,
  });

  @override
  State<InstitucionPublicaPage> createState() => _InstitucionPublicaPageState();
}

class _InstitucionPublicaPageState extends State<InstitucionPublicaPage> {
  Institucion? _inst;
  PerfilPublico _perfil = const PerfilPublico();
  Uint8List? _logo;
  List<OfertaConCupo> _ofertas = const [];

  /// Solicitud activa del alumno por oferta.
  Map<String, Solicitud> _activas = const {};
  PerfilAlumno? _alumno;
  Uint8List? _fotoAlumno;
  TipoOferta? _tipo;

  bool _loading = true;
  bool _noEncontrada = false;
  Object? _error;

  final Map<String, Future<Uint8List?>> _fotos = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = InstitucionesRepo.instance;
      final inst = await repo.obtener(widget.institucionId);
      if (inst == null || inst.nombre.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _noEncontrada = true;
          _loading = false;
          _error = null;
        });
        return;
      }

      final perfil = await repo.perfilPublico(inst.id);
      final r = await Future.wait<Object?>([
        repo.imagen(perfil.logoId),
        OfertasRepo.instance.conCupo(inst.id, soloActivas: true),
        SolicitudesRepo.instance.porPerfil(widget.perfilId),
        AlumnosRepo.instance.perfilDeCuenta(widget.cuentaId, widget.perfilId),
        AlumnosRepo.instance.foto(widget.perfilId),
      ]);

      final ofertas = r[1] as List<OfertaConCupo>;
      final activas = <String, Solicitud>{};
      for (final s in r[2] as List<Solicitud>) {
        if (s.estado.esActiva) activas.putIfAbsent(s.ofertaId, () => s);
      }
      final tipos = {for (final o in ofertas) o.oferta.tipo};

      if (!mounted) return;
      setState(() {
        _inst = inst;
        _perfil = perfil;
        _logo = r[0] as Uint8List?;
        _ofertas = ofertas;
        _activas = activas;
        _alumno = r[3] as PerfilAlumno?;
        _fotoAlumno = r[4] as Uint8List?;
        _tipo = tipos.contains(_tipo)
            ? _tipo
            : (tipos.isEmpty ? null : tipos.first);
        _noEncontrada = false;
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

  ExplorarAlumnoEdad? get _alumnoEdad {
    final p = _alumno;
    if (p == null || p.fechaNacimiento.millisecondsSinceEpoch == 0) {
      return null;
    }
    final nombre = p.nombre.trim().isEmpty ? p.displayName : p.nombre.trim();
    return (nombre: nombre, edad: edadEnAnios(p.fechaNacimiento));
  }

  Future<Uint8List?> _foto(String id) =>
      _fotos.putIfAbsent(id, () => InstitucionesRepo.instance.imagen(id));

  Future<void> _verFotos(int inicial) => abrirExplorarGaleria(
    context,
    fotoIds: _perfil.fotoIds,
    inicial: inicial,
    cargar: _foto,
  );

  Future<void> _pedir(OfertaConCupo item) async {
    final t = AppLocalizations.of(context);
    final inst = _inst;
    final alumno = _alumno;
    if (inst == null || alumno == null) {
      AtenaFeedback.error(context, t.errNoAutorizado);
      return;
    }
    final creada = await mostrarPedirVacanteSheet(
      context,
      cuentaId: widget.cuentaId,
      alumno: alumno,
      fotoAlumno: _fotoAlumno,
      institucionNombre: inst.nombre.trim(),
      oferta: item,
    );
    if (!mounted) return;
    if (creada != null) {
      AtenaFeedback.show(
        context,
        t.solAlEnviadaOk,
        kind: AtenaFeedbackKind.success,
        action: SnackBarAction(
          label: t.commonView,
          onPressed: () => _verSolicitud(creada.id),
        ),
      );
    }
    await _load();
  }

  Future<void> _verSolicitud(String solicitudId) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SolicitudAlumnoDetallePage(
          cuentaId: widget.cuentaId,
          perfilId: widget.perfilId,
          solicitudId: solicitudId,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final inst = _inst;
    final nombre = inst?.nombre.trim() ?? '';

    return AtenaScaffold(
      role: AtenaRole.alumno,
      appBar: AtenaAppBar(
        title: nombre.isEmpty || _noEncontrada ? t.commonInstitution : nombre,
      ),
      body: _loading
          ? const AtenaLoading()
          : _error != null
          ? AtenaErrorState(
              message: coreErrorText(t, _error!),
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : _noEncontrada || inst == null
          ? AtenaEmptyState(
              icon: Icons.domain_disabled_rounded,
              title: t.explorarInstNoEncontradaTitulo,
              message: t.explorarInstNoEncontradaMensaje,
              action: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(t.commonBack),
              ),
            )
          : _contenido(context, inst),
    );
  }

  Widget _contenido(BuildContext context, Institucion inst) {
    final t = AppLocalizations.of(context);
    final escritorio = AtenaLayout.isDesktop(context);
    final p = _perfil;
    final direccion = explorarDireccion(inst);
    final links = explorarLinksContacto(t, p, direccion: direccion);
    final descripcion = p.descripcion.trim();
    final atencion = p.horarioAtencion.trim();
    final clases = p.horarioClases.trim();
    final servicios = [
      for (final s in p.servicios)
        if (s.trim().isNotEmpty) s.trim(),
    ];
    const gap = SizedBox(height: AtenaSpace.md);

    final portada = _Portada(
      inst: inst,
      logo: _logo,
      fotoIds: p.fotoIds,
      direccion: direccion,
      libres: _ofertas.fold<int>(0, (acc, o) => acc + o.disponibles),
      cargarFoto: _foto,
      onAbrirFoto: _verFotos,
    );

    final sobre = descripcion.isEmpty
        ? null
        : _Seccion(
            titulo: t.explorarSobre,
            child: AtenaCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: _TextoExpandible(texto: descripcion),
            ),
          );

    final vacantes = _SeccionVacantes(
      ofertas: _ofertas,
      tipo: _tipo,
      onTipo: (x) => setState(() => _tipo = x),
      activas: _activas,
      alumno: _alumnoEdad,
      onPedir: _pedir,
      onVerSolicitud: (s) => _verSolicitud(s.id),
    );

    final horarios = atencion.isEmpty && clases.isEmpty
        ? null
        : _Seccion(
            titulo: t.explorarHorarios,
            child: AtenaCard(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  if (atencion.isNotEmpty)
                    AtenaInfoRow(
                      icon: Icons.storefront_rounded,
                      label: t.explorarHorarioAtencion,
                      value: atencion,
                    ),
                  if (clases.isNotEmpty)
                    AtenaInfoRow(
                      icon: Icons.school_rounded,
                      label: t.explorarHorarioClases,
                      value: clases,
                    ),
                ],
              ),
            ),
          );

    final serviciosSeccion = servicios.isEmpty
        ? null
        : _Seccion(
            titulo: t.explorarServicios,
            child: AtenaCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in servicios)
                    ExplorarEtiqueta(icon: Icons.check_rounded, label: s),
                ],
              ),
            ),
          );

    final contacto = links.isEmpty
        ? null
        : _Seccion(
            titulo: t.explorarContacto,
            child: ExplorarContactoCard(links: links),
          );

    final principal = <Widget>[
      if (sobre != null) ...[sobre, gap],
      vacantes,
    ];
    final lateral = [contacto, horarios, serviciosSeccion].whereType<Widget>();

    final List<Widget> children;
    if (!escritorio) {
      children = [
        portada,
        gap,
        ...principal,
        for (final w in lateral) ...[gap, w],
      ];
    } else {
      children = [
        portada,
        const SizedBox(height: AtenaSpace.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: principal,
              ),
            ),
            if (lateral.isNotEmpty) ...[
              const SizedBox(width: AtenaSpace.xl),
              SizedBox(
                width: 340,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, w) in lateral.indexed) ...[
                      if (i > 0) gap,
                      w,
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ];
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: atenaPagePadding(
          context,
          maxWidth: escritorio ? 1080 : AtenaLayout.content,
        ),
        children: children,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Portada
// -----------------------------------------------------------------------------

class _Portada extends StatelessWidget {
  static const double _avatar = 88;

  final Institucion inst;
  final Uint8List? logo;
  final List<String> fotoIds;
  final String direccion;
  final int libres;
  final ExplorarCargarFoto cargarFoto;
  final ValueChanged<int> onAbrirFoto;

  const _Portada({
    required this.inst,
    required this.logo,
    required this.fotoIds,
    required this.direccion,
    required this.libres,
    required this.cargarFoto,
    required this.onAbrirFoto,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final escritorio = AtenaLayout.isDesktop(context);
    final ancho = MediaQuery.sizeOf(context).width;
    final double alto = fotoIds.isEmpty
        ? (escritorio ? 150 : 116)
        : (escritorio ? 340 : (ancho * 0.56).clamp(190, 300).toDouble());

    return AtenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: alto,
                    child: fotoIds.isEmpty
                        ? const _PortadaMarca()
                        : ExplorarCarrusel(
                            fotoIds: fotoIds,
                            cargar: cargarFoto,
                            alto: alto,
                            onAbrir: onAbrirFoto,
                          ),
                  ),
                  const SizedBox(height: _avatar / 2 + 4),
                ],
              ),
              Positioned(
                left: 20,
                top: alto - _avatar / 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AtenaAvatar(
                    name: inst.nombre,
                    imageBytes: logo,
                    size: _avatar - 8,
                    fallbackIcon: Icons.account_balance_rounded,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inst.nombre.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: escritorio
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AtenaStatusChip(
                      label: t.tipoInstitucion(inst.tipoInstitucion),
                      color: cs.primary,
                      icon: Icons.account_balance_rounded,
                    ),
                    AtenaStatusChip(
                      label: t.modalidad(inst.modalidad),
                      color: AtenaColors.indigo,
                      icon: iconoModalidad(inst.modalidad),
                    ),
                    AtenaStatusChip(
                      label: t.lblCupos(libres),
                      color: libres > 0
                          ? AtenaColors.success
                          : AtenaStatusColors.cancelled,
                      icon: libres > 0
                          ? Icons.event_seat_rounded
                          : Icons.event_busy_rounded,
                    ),
                  ],
                ),
                if (direccion.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          direccion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Portada sin fotos: gradiente del área con el emblema de ATENA.
class _PortadaMarca extends StatelessWidget {
  const _PortadaMarca();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AtenaBrand.of(context).gradient),
      child: Align(
        alignment: const Alignment(0.9, 0),
        child: AtenaMark(
          size: 104,
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Secciones
// -----------------------------------------------------------------------------

class _Seccion extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;

  const _Seccion({required this.titulo, this.subtitulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtenaSectionHeader(title: titulo, subtitle: subtitulo),
        child,
      ],
    );
  }
}

/// Texto largo con "Leer más" cuando no entra en pocas líneas.
class _TextoExpandible extends StatefulWidget {
  final String texto;

  const _TextoExpandible({required this.texto});

  @override
  State<_TextoExpandible> createState() => _TextoExpandibleState();
}

class _TextoExpandibleState extends State<_TextoExpandible> {
  static const int _lineas = 5;
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final estilo = Theme.of(context).textTheme.bodyLarge;

    return LayoutBuilder(
      builder: (context, c) {
        final painter = TextPainter(
          text: TextSpan(text: widget.texto, style: estilo),
          maxLines: _lineas,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: c.maxWidth);
        final excede = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: AtenaMotion.medium,
              curve: AtenaMotion.curve,
              alignment: Alignment.topCenter,
              child: Text(
                widget.texto,
                style: estilo,
                maxLines: _abierto ? null : _lineas,
                overflow: _abierto
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (excede)
              TextButton(
                onPressed: () => setState(() => _abierto = !_abierto),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(_abierto ? t.explorarLeerMenos : t.explorarLeerMas),
              )
            else
              const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}

class _SeccionVacantes extends StatelessWidget {
  final List<OfertaConCupo> ofertas;
  final TipoOferta? tipo;
  final ValueChanged<TipoOferta> onTipo;
  final Map<String, Solicitud> activas;
  final ExplorarAlumnoEdad? alumno;
  final ValueChanged<OfertaConCupo> onPedir;
  final ValueChanged<Solicitud> onVerSolicitud;

  const _SeccionVacantes({
    required this.ofertas,
    required this.tipo,
    required this.onTipo,
    required this.activas,
    required this.alumno,
    required this.onPedir,
    required this.onVerSolicitud,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (ofertas.isEmpty) {
      return _Seccion(
        titulo: t.explorarVacantes,
        child: AtenaCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AtenaIconBadge(
                icon: Icons.event_busy_rounded,
                color: AtenaColors.neutral,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.explorarSinVacantesTitulo,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.explorarSinVacantesMensaje,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tipos = {for (final o in ofertas) o.oferta.tipo};
    final actual = tipo != null && tipos.contains(tipo) ? tipo! : tipos.first;
    final libres = ofertas.fold<int>(0, (acc, o) => acc + o.disponibles);

    // La lista ya viene ordenada por tipo y nivel/bloque: se agrupan los
    // consecutivos.
    final grupos =
        <({IconData icon, String titulo, List<OfertaConCupo> items})>[];
    Object? clave;
    for (final item in ofertas.where((o) => o.oferta.tipo == actual)) {
      final o = item.oferta;
      final Object? k = o.esCurricular ? o.nivel : o.bloque;
      if (grupos.isEmpty || k != clave) {
        clave = k;
        grupos.add((
          icon: iconoOferta(o),
          titulo: t.categoriaOferta(o),
          items: [item],
        ));
      } else {
        grupos.last.items.add(item);
      }
    }

    return _Seccion(
      titulo: t.explorarVacantes,
      subtitulo:
          '${t.explorarPropuestas(ofertas.length)} · ${t.lblCupos(libres)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tipos.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SegmentedButton<TipoOferta>(
                segments: [
                  ButtonSegment(
                    value: TipoOferta.curricular,
                    icon: const Icon(Icons.school_rounded),
                    label: Text(t.lblCurricular),
                  ),
                  ButtonSegment(
                    value: TipoOferta.extracurricular,
                    icon: const Icon(Icons.interests_rounded),
                    label: Text(t.lblExtracurricular),
                  ),
                ],
                selected: {actual},
                showSelectedIcon: false,
                onSelectionChanged: (s) => onTipo(s.first),
              ),
            ),
          for (final g in grupos) ...[
            _GrupoHeader(
              icon: g.icon,
              titulo: g.titulo,
              cantidad: g.items.length,
            ),
            for (final item in g.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AtenaSpace.sm),
                child: ExplorarOfertaCard(
                  item: item,
                  solicitud: activas[item.oferta.id],
                  alumno: alumno,
                  onPedir: () => onPedir(item),
                  onVerSolicitud: () {
                    final s = activas[item.oferta.id];
                    if (s != null) onVerSolicitud(s);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GrupoHeader extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final int cantidad;

  const _GrupoHeader({
    required this.icon,
    required this.titulo,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          AtenaIconBadge(icon: icon, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t.explorarPropuestas(cantidad),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
