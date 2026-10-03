// lib/screens/instituciones/institucion_perfil_page.dart
//
// ATENA – Perfil de la institución.
// - Datos: identificación, ubicación y contacto administrativo.
// - Perfil público: logo, fotos, descripción, horarios, contacto y servicios
//   (lo que ven las familias), con un indicador de completitud.
// - Vista previa de la ficha pública.
// Los textos se guardan juntos con "Guardar"; el logo y las fotos se guardan
// en el momento de elegirlos o quitarlos.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/cuenta_service.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/perf_inst_campos.dart';
import 'widgets/perf_inst_completitud.dart';
import 'widgets/perf_inst_form_datos.dart';
import 'widgets/perf_inst_form_publico.dart';
import 'widgets/perf_inst_fotos.dart';
import 'widgets/perf_inst_vista.dart';

class InstitucionPerfilPage extends StatefulWidget {
  final String ownerAccountId;
  final String institucionPerfilId;

  /// Datos ya cargados por quien abre la pantalla (se usan si la institución
  /// todavía no está guardada).
  final Institucion? institucionInicial;

  const InstitucionPerfilPage({
    super.key,
    required this.ownerAccountId,
    required this.institucionPerfilId,
    this.institucionInicial,
  });

  @override
  State<InstitucionPerfilPage> createState() => _InstitucionPerfilPageState();
}

/// Operación en curso: mientras dura, no se inicia otra.
enum _Tarea { ninguna, guardando, subiendoLogo, subiendoFoto, quitandoImagen }

class _InstitucionPerfilPageState extends State<InstitucionPerfilPage>
    with SingleTickerProviderStateMixin {
  static const int _tabDatos = 0;
  static const int _tabPublico = 1;

  /// Ancho máximo (px) con el que se guardan el logo y las fotos.
  static const int _anchoLogo = 512;
  static const int _anchoFoto = 1280;

  final _repo = InstitucionesRepo.instance;
  final _picker = ImagePicker();
  final _campos = PerfInstCampos();

  // Se entra desde "Perfil público": esa es la pestaña que se abre primero.
  late final TabController _tabs = TabController(
    length: 3,
    initialIndex: _tabPublico,
    vsync: this,
  );

  // Las claves se renuevan al descartar para limpiar los errores mostrados.
  var _datosKey = GlobalKey<FormState>();
  var _publicoKey = GlobalKey<FormState>();

  // Lo guardado.
  Institucion? _inst;
  PerfilPublico _publico = const PerfilPublico();
  Uint8List? _logo;
  final Map<String, Uint8List?> _fotos = <String, Uint8List?>{};

  // Lo editado que no vive en un campo de texto.
  TipoInstitucion _tipo = TipoInstitucion.otra;
  ModalidadCursado _modalidad = ModalidadCursado.presencial;
  List<String> _servicios = const <String>[];

  bool _cargando = true;
  Object? _error;
  _Tarea _tarea = _Tarea.ninguna;
  bool _sucio = false;
  bool _hidratando = false;
  AutovalidateMode _autovalidar = AutovalidateMode.disabled;

  String get _id => widget.institucionPerfilId.trim();
  bool get _ocupado => _tarea != _Tarea.ninguna;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_alCambiarPestana);
    _campos.cambios.addListener(_alEditar);
    _cargar();
  }

  @override
  void dispose() {
    _campos.cambios.removeListener(_alEditar);
    _campos.dispose();
    _tabs
      ..removeListener(_alCambiarPestana)
      ..dispose();
    super.dispose();
  }

  void _alCambiarPestana() {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _alEditar() {
    if (_hidratando) return;
    final sucio = _calcularSucio();
    if (sucio != _sucio) setState(() => _sucio = sucio);
  }

  /// Aplica un cambio que no pasa por un campo de texto.
  void _cambiar(VoidCallback cambio) => setState(() {
    cambio();
    _sucio = _calcularSucio();
  });

  // ---------------------------------------------------------------------------
  // Carga
  // ---------------------------------------------------------------------------

  Future<void> _cargar() async {
    try {
      final inst = await _repo.obtener(_id) ?? widget.institucionInicial;
      if (inst == null) throw const AtenaException(AtenaError.noEncontrado);
      final publico = _normalizar(await _repo.perfilPublico(_id));
      final imagenes = await Future.wait([
        _repo.imagen(publico.logoId),
        for (final id in publico.fotoIds) _repo.imagen(id),
      ]);

      if (!mounted) return;
      setState(() {
        _inst = inst;
        _publico = publico;
        _logo = imagenes.first;
        _fotos
          ..clear()
          ..addAll({
            for (final (i, id) in publico.fotoIds.indexed) id: imagenes[i + 1],
          });
        _hidratar();
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e;
      });
    }
  }

  void _reintentar() {
    setState(() {
      _cargando = true;
      _error = null;
    });
    _cargar();
  }

  /// Vuelca lo guardado en el formulario.
  void _hidratar() {
    final inst = _inst;
    if (inst == null) return;
    final p = _publico;
    final c = _campos;

    _hidratando = true;
    c.nombre.text = inst.nombre.trim();
    c.cuit.text = PerfInstFormato.soloDigitos(inst.cuit);
    c.direccion.text = inst.direccion.trim();
    c.ciudad.text = inst.ciudad.trim();
    c.provincia.text = inst.provincia.trim();
    c.pais.text = inst.pais.trim();
    c.email.text = inst.email.trim();
    c.telefono.text = inst.telefono.trim();
    c.descripcion.text = p.descripcion;
    c.horarioAtencion.text = p.horarioAtencion;
    c.horarioClases.text = p.horarioClases;
    c.telefonoPublico.text = p.telefono;
    c.whatsapp.text = p.whatsapp;
    c.emailPublico.text = p.email;
    c.web.text = p.sitioWeb;
    c.instagram.text = p.instagram;
    c.facebook.text = p.facebook;
    c.youtube.text = p.youtube;
    _hidratando = false;

    _tipo = inst.tipoInstitucion;
    _modalidad = inst.modalidad;
    _servicios = List<String>.of(p.servicios);
    _sucio = false;
  }

  // ---------------------------------------------------------------------------
  // Del formulario a los modelos
  // ---------------------------------------------------------------------------

  /// Deja los textos sin espacios sobrantes y los enlaces con formato.
  PerfilPublico _normalizar(PerfilPublico p) => p.copyWith(
    descripcion: p.descripcion.trim(),
    horarioAtencion: p.horarioAtencion.trim(),
    horarioClases: p.horarioClases.trim(),
    telefono: p.telefono.trim(),
    whatsapp: p.whatsapp.trim(),
    email: p.email.trim(),
    sitioWeb: PerfInstFormato.normalizarWeb(p.sitioWeb),
    instagram: PerfInstFormato.normalizarRed(p.instagram),
    facebook: PerfInstFormato.normalizarRed(p.facebook),
    youtube: PerfInstFormato.normalizarRed(p.youtube),
    servicios: [
      for (final s in p.servicios)
        if (s.trim().isNotEmpty) s.trim(),
    ],
  );

  /// Perfil público con lo que hay en pantalla (el logo y las fotos son los
  /// guardados).
  PerfilPublico _publicoEditado() => _normalizar(
    _publico.copyWith(
      descripcion: _campos.descripcion.text,
      horarioAtencion: _campos.horarioAtencion.text,
      horarioClases: _campos.horarioClases.text,
      telefono: _campos.telefonoPublico.text,
      whatsapp: _campos.whatsapp.text,
      email: _campos.emailPublico.text,
      sitioWeb: _campos.web.text,
      instagram: _campos.instagram.text,
      facebook: _campos.facebook.text,
      youtube: _campos.youtube.text,
      servicios: _servicios,
    ),
  );

  Institucion _institucionEditada(Institucion inst) => inst.copyWith(
    nombre: _campos.nombre.text.trim(),
    cuit: PerfInstFormato.soloDigitos(_campos.cuit.text),
    direccion: _campos.direccion.text.trim(),
    ciudad: _campos.ciudad.text.trim(),
    provincia: _campos.provincia.text.trim(),
    pais: _campos.pais.text.trim(),
    email: _campos.email.text.trim().toLowerCase(),
    telefono: _campos.telefono.text.trim(),
    tipoInstitucion: _tipo,
    modalidad: _modalidad,
  );

  bool _datosCambiaron(Institucion inst) {
    final e = _institucionEditada(inst);
    return e.nombre != inst.nombre.trim() ||
        e.cuit != PerfInstFormato.soloDigitos(inst.cuit) ||
        e.direccion != inst.direccion.trim() ||
        e.ciudad != inst.ciudad.trim() ||
        e.provincia != inst.provincia.trim() ||
        e.pais != inst.pais.trim() ||
        e.email != inst.email.trim().toLowerCase() ||
        e.telefono != inst.telefono.trim() ||
        e.tipoInstitucion != inst.tipoInstitucion ||
        e.modalidad != inst.modalidad;
  }

  bool _publicoCambio(PerfilPublico e) {
    final p = _publico;
    return e.descripcion != p.descripcion ||
        e.horarioAtencion != p.horarioAtencion ||
        e.horarioClases != p.horarioClases ||
        e.telefono != p.telefono ||
        e.whatsapp != p.whatsapp ||
        e.email != p.email ||
        e.sitioWeb != p.sitioWeb ||
        e.instagram != p.instagram ||
        e.facebook != p.facebook ||
        e.youtube != p.youtube ||
        !listEquals(e.servicios, p.servicios);
  }

  bool _calcularSucio() {
    final inst = _inst;
    if (inst == null) return false;
    return _datosCambiaron(inst) || _publicoCambio(_publicoEditado());
  }

  PerfInstCompletitud _completitud() {
    final p = _publicoEditado();
    return PerfInstCompletitud.calcular(
      largoDescripcion: p.descripcion.length,
      fotos: p.fotoIds.length,
      logo: p.logoId.isNotEmpty,
      telefono: p.telefono.isNotEmpty || p.whatsapp.isNotEmpty,
      horarioAtencion: p.horarioAtencion.isNotEmpty,
      servicios: p.servicios.isNotEmpty,
      horarioClases: p.horarioClases.isNotEmpty,
      emailOWeb: p.email.isNotEmpty || p.sitioWeb.isNotEmpty,
      redes:
          p.instagram.isNotEmpty ||
          p.facebook.isNotEmpty ||
          p.youtube.isNotEmpty,
    );
  }

  PerfInstVista _vista(Institucion inst) {
    final plan = inst.planSafe;
    return PerfInstVista(
      nombre: _campos.nombre.text.trim(),
      tipo: _tipo,
      modalidad: _modalidad,
      ubicacion: [
        _campos.ciudad.text.trim(),
        _campos.provincia.text.trim(),
      ].where((s) => s.isNotEmpty).join(', '),
      direccion: _campos.direccion.text.trim(),
      logo: _logo,
      fotos: [
        for (final id in _publico.fotoIds)
          if (_fotos[id] case final bytes?) bytes,
      ],
      publico: _publicoEditado(),
      niveles: [
        if (inst.curricular)
          for (final n in plan.niveles)
            if (n.habilitado) n.nivel,
      ],
      bloques: [
        if (inst.extracurricular)
          for (final m in plan.modulos)
            if (m.habilitado) m.bloque,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Guardar, descartar y salir
  // ---------------------------------------------------------------------------

  Future<void> _guardar() async {
    final inst = _inst;
    if (inst == null || _ocupado) return;
    final t = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();

    final datosOk = _datosKey.currentState?.validate() ?? true;
    final publicoOk = _publicoKey.currentState?.validate() ?? true;
    if (!datosOk || !publicoOk) {
      setState(() => _autovalidar = AutovalidateMode.onUserInteraction);
      // Muestra una pestaña con errores (si no se está viendo ya una).
      final conErrores = [if (!datosOk) _tabDatos, if (!publicoOk) _tabPublico];
      if (!conErrores.contains(_tabs.index)) _tabs.animateTo(conErrores.first);
      AtenaFeedback.error(context, t.perfInstRevisarCampos);
      return;
    }

    final editada = _institucionEditada(inst);
    final publico = _publicoEditado();
    final cambiaronDatos = _datosCambiaron(inst);
    final cambioPublico = _publicoCambio(publico);

    setState(() => _tarea = _Tarea.guardando);
    try {
      if (cambiaronDatos) {
        await _repo.guardar(editada);
        _inst = editada;
        if (editada.nombre != inst.nombre.trim()) {
          await _renombrarPerfilDeCuenta(editada);
        }
      }
      if (cambioPublico) {
        await _repo.guardarPerfilPublico(_id, publico);
        _publico = publico;
      }
      if (!mounted) return;
      setState(() {
        _hidratar();
        _autovalidar = AutovalidateMode.disabled;
        _tarea = _Tarea.ninguna;
      });
      AtenaFeedback.success(context, t.perfInstGuardado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tarea = _Tarea.ninguna;
        _sucio = _calcularSucio();
      });
      AtenaFeedback.error(context, coreErrorText(t, e));
    }
  }

  /// El perfil de la cuenta guarda una copia del nombre. Es un dato
  /// secundario: si no se puede actualizar, la institución ya quedó guardada.
  Future<void> _renombrarPerfilDeCuenta(Institucion inst) async {
    try {
      final perfil = await CuentaService.getPerfilInstitucionById(inst.id);
      if (perfil == null) return;
      perfil.nombre = inst.nombre;
      await CuentaService.actualizarPerfilInstitucion(perfil);
    } catch (_) {}
  }

  Future<void> _descartar() async {
    if (_ocupado) return;
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.perfInstDescartarTitulo,
      message: t.perfInstDescartarMensaje,
      confirmLabel: t.perfInstDescartar,
      destructive: true,
      icon: Icons.undo_rounded,
    );
    if (!ok || !mounted || _ocupado) return;
    setState(() {
      _hidratar();
      _datosKey = GlobalKey<FormState>();
      _publicoKey = GlobalKey<FormState>();
      _autovalidar = AutovalidateMode.disabled;
    });
  }

  Future<void> _confirmarSalida() async {
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.perfInstSalirTitulo,
      message: t.perfInstSalirMensaje,
      confirmLabel: t.perfInstSalir,
      destructive: true,
      icon: Icons.warning_amber_rounded,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Logo y fotos (se guardan al momento)
  // ---------------------------------------------------------------------------

  Future<Uint8List?> _elegirImagen(
    AppLocalizations t, {
    required int anchoMaximo,
    required int calidad,
  }) async {
    try {
      final archivo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: anchoMaximo.toDouble(),
        imageQuality: calidad,
      );
      if (archivo == null) return null;
      final bytes = await archivo.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      if (mounted) AtenaFeedback.error(context, t.perfInstGaleriaError);
      return null;
    }
  }

  /// Guarda la imagen elegida (reducida si hace falta). Devuelve su id y los
  /// bytes que quedaron guardados.
  Future<({String id, Uint8List bytes})> _guardarImagen(
    Uint8List elegida, {
    required int anchoMaximo,
  }) async {
    final bytes = await perfInstAjustarImagen(
      elegida,
      anchoMaximo: anchoMaximo,
      maxBytes: InstitucionesRepo.maxBytesImagen,
    );
    return (id: await _repo.guardarImagen(bytes), bytes: bytes);
  }

  Future<void> _borrarImagen(String blobId) async {
    if (blobId.isEmpty) return;
    try {
      await _repo.eliminarImagen(blobId);
    } catch (_) {}
  }

  void _terminarConError(AppLocalizations t, Object error) {
    if (!mounted) return;
    setState(() => _tarea = _Tarea.ninguna);
    AtenaFeedback.error(context, coreErrorText(t, error));
  }

  Future<void> _elegirLogo() async {
    if (_ocupado) return;
    final t = AppLocalizations.of(context);
    final elegida = await _elegirImagen(
      t,
      anchoMaximo: _anchoLogo,
      calidad: 85,
    );
    if (elegida == null || !mounted || _ocupado) return;

    setState(() => _tarea = _Tarea.subiendoLogo);
    String? sinUsar;
    try {
      final imagen = await _guardarImagen(elegida, anchoMaximo: _anchoLogo);
      sinUsar = imagen.id;
      final anterior = _publico.logoId;
      final actualizado = _publico.copyWith(logoId: imagen.id);
      await _repo.guardarPerfilPublico(_id, actualizado);
      sinUsar = null;
      await _borrarImagen(anterior);

      if (!mounted) return;
      setState(() {
        _publico = actualizado;
        _logo = imagen.bytes;
        _tarea = _Tarea.ninguna;
      });
      AtenaFeedback.success(context, t.perfInstLogoListo);
    } catch (e) {
      if (sinUsar != null) await _borrarImagen(sinUsar);
      _terminarConError(t, e);
    }
  }

  Future<void> _quitarLogo() async {
    if (_ocupado || _publico.logoId.isEmpty) return;
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.perfInstLogoQuitarTitulo,
      message: t.perfInstLogoQuitarMensaje,
      confirmLabel: t.perfInstLogoQuitar,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted || _ocupado) return;

    setState(() => _tarea = _Tarea.quitandoImagen);
    try {
      final anterior = _publico.logoId;
      final actualizado = _publico.copyWith(logoId: '');
      await _repo.guardarPerfilPublico(_id, actualizado);
      await _borrarImagen(anterior);

      if (!mounted) return;
      setState(() {
        _publico = actualizado;
        _logo = null;
        _tarea = _Tarea.ninguna;
      });
      AtenaFeedback.success(context, t.perfInstLogoQuitado);
    } catch (e) {
      _terminarConError(t, e);
    }
  }

  Future<void> _agregarFoto() async {
    if (_ocupado || _publico.fotoIds.length >= PerfilPublico.maxFotos) return;
    final t = AppLocalizations.of(context);
    final elegida = await _elegirImagen(
      t,
      anchoMaximo: _anchoFoto,
      calidad: 80,
    );
    if (elegida == null || !mounted || _ocupado) return;

    setState(() => _tarea = _Tarea.subiendoFoto);
    String? sinUsar;
    try {
      final imagen = await _guardarImagen(elegida, anchoMaximo: _anchoFoto);
      sinUsar = imagen.id;
      final actualizado = _publico.copyWith(
        fotoIds: [..._publico.fotoIds, imagen.id],
      );
      await _repo.guardarPerfilPublico(_id, actualizado);
      sinUsar = null;

      if (!mounted) return;
      setState(() {
        _publico = actualizado;
        _fotos[imagen.id] = imagen.bytes;
        _tarea = _Tarea.ninguna;
      });
      AtenaFeedback.success(context, t.perfInstFotoAgregada);
    } catch (e) {
      if (sinUsar != null) await _borrarImagen(sinUsar);
      _terminarConError(t, e);
    }
  }

  Future<void> _quitarFoto(String id) async {
    if (_ocupado) return;
    final t = AppLocalizations.of(context);
    final ok = await showAtenaConfirm(
      context,
      title: t.perfInstFotoQuitarTitulo,
      message: t.perfInstFotoQuitarMensaje,
      confirmLabel: t.perfInstFotoQuitar,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted || _ocupado) return;

    setState(() => _tarea = _Tarea.quitandoImagen);
    try {
      final actualizado = _publico.copyWith(
        fotoIds: [
          for (final x in _publico.fotoIds)
            if (x != id) x,
        ],
      );
      await _repo.guardarPerfilPublico(_id, actualizado);
      await _borrarImagen(id);

      if (!mounted) return;
      setState(() {
        _publico = actualizado;
        _fotos.remove(id);
        _tarea = _Tarea.ninguna;
      });
      AtenaFeedback.success(context, t.perfInstFotoQuitada);
    } catch (e) {
      _terminarConError(t, e);
    }
  }

  void _verFoto(Uint8List bytes) => perfInstVerFoto(context, bytes);

  // ---------------------------------------------------------------------------
  // Pestañas
  // ---------------------------------------------------------------------------

  Widget _pestana(Widget child) {
    return SingleChildScrollView(
      primary: false,
      padding: atenaPagePadding(
        context,
        maxWidth: AtenaLayout.narrow,
        top: AtenaSpace.md,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: child,
    );
  }

  Widget _pestanaDatos() {
    return _pestana(
      Form(
        key: _datosKey,
        autovalidateMode: _autovalidar,
        child: PerfInstFormDatos(
          campos: _campos,
          habilitado: !_ocupado,
          tipo: _tipo,
          modalidad: _modalidad,
          onTipo: (x) => _cambiar(() => _tipo = x),
          onModalidad: (m) => _cambiar(() => _modalidad = m),
        ),
      ),
    );
  }

  Widget _pestanaPublico() {
    return _pestana(
      Form(
        key: _publicoKey,
        autovalidateMode: _autovalidar,
        child: PerfInstFormPublico(
          campos: _campos,
          habilitado: !_ocupado,
          completitud: ListenableBuilder(
            listenable: _campos.cambios,
            builder: (context, _) =>
                PerfInstCompletitudCard(completitud: _completitud()),
          ),
          logo: PerfInstLogoEditor(
            nombre: _campos.nombre.text.trim(),
            logo: _logo,
            cargando: _tarea == _Tarea.subiendoLogo,
            habilitado: !_ocupado,
            onElegir: _elegirLogo,
            onQuitar: _publico.logoId.isEmpty ? null : _quitarLogo,
          ),
          galeria: PerfInstGaleria(
            ids: _publico.fotoIds,
            imagenes: _fotos,
            maximo: PerfilPublico.maxFotos,
            subiendo: _tarea == _Tarea.subiendoFoto,
            habilitado: !_ocupado,
            onAgregar: _agregarFoto,
            onQuitar: _quitarFoto,
            onVer: _verFoto,
          ),
          servicios: _servicios,
          onServicios: (lista) => _cambiar(() => _servicios = lista),
        ),
      ),
    );
  }

  Widget _pestanaVista(AppLocalizations t, Institucion inst) {
    return ListenableBuilder(
      listenable: _campos.cambios,
      builder: (context, _) => _pestana(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtenaBanner(
              icon: Icons.visibility_rounded,
              title: t.perfInstVistaTitulo,
              message: _sucio
                  ? '${t.perfInstVistaAyuda} ${t.perfInstVistaSinGuardar}'
                  : t.perfInstVistaAyuda,
              action: _completitud().completo
                  ? null
                  : TextButton.icon(
                      onPressed: () => _tabs.animateTo(_tabPublico),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(t.perfInstVistaCompletar),
                    ),
            ),
            const SizedBox(height: AtenaSpace.md),
            PerfInstVistaPrevia(datos: _vista(inst), onVerFoto: _verFoto),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final inst = _inst;

    final Widget cuerpo;
    if (_cargando) {
      cuerpo = const AtenaLoading();
    } else if (inst == null) {
      cuerpo = AtenaErrorState(
        title: t.perfInstErrorCarga,
        message: coreErrorText(
          t,
          _error ?? const AtenaException(AtenaError.noEncontrado),
        ),
        onRetry: _reintentar,
      );
    } else {
      // Las tres pestañas quedan montadas: así se validan los dos formularios
      // al guardar y cada una conserva su posición.
      cuerpo = IndexedStack(
        index: _tabs.index,
        sizing: StackFit.expand,
        children: [_pestanaDatos(), _pestanaPublico(), _pestanaVista(t, inst)],
      );
    }

    final guardando = _tarea == _Tarea.guardando;

    return PopScope<Object?>(
      canPop: !_sucio && !_ocupado,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _ocupado) return;
        _confirmarSalida();
      },
      child: AtenaScaffold(
        role: AtenaRole.institucion,
        appBar: AtenaAppBar(
          title: t.perfInstTitulo,
          subtitle: inst?.nombre ?? widget.institucionInicial?.nombre,
          bottom: inst == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(kTextTabBarHeight),
                  child: Align(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AtenaLayout.narrow + 2 * AtenaSpace.page,
                      ),
                      child: TabBar(
                        controller: _tabs,
                        tabs: [
                          Tab(text: t.perfInstTabDatos),
                          Tab(text: t.perfInstTabPublico),
                          Tab(text: t.perfInstTabVista),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        body: cuerpo,
        bottomNavigationBar: AnimatedSwitcher(
          duration: AtenaMotion.medium,
          switchInCurve: AtenaMotion.curve,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
          child: inst != null && (_sucio || guardando)
              ? PerfInstBarraGuardar(
                  guardando: guardando,
                  habilitada: !_ocupado,
                  onGuardar: _guardar,
                  onDescartar: _descartar,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
