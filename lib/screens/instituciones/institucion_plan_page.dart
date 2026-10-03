// lib/screens/instituciones/institucion_plan_page.dart
//
// ATENA – Plan de la institución.
// - Registro (paso 2 de 2): se eligen niveles y módulos y se crea la
//   institución con su cuenta, su perfil y su sesión.
// - Gestión: se cambian los niveles y módulos del plan vigente.
// Todavía no hay pagos: un plan con costo arranca con 30 días de prueba.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../core/atena_core.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../routes/atena_nav.dart';
import '../../services/auth_errors.dart';
import '../../services/auth_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/institucion_service.dart';
import '../../ui/atena_format.dart';
import '../../ui/atena_labels.dart';
import '../../ui/atena_ui.dart';
import 'widgets/pln_encabezado.dart';
import 'widgets/pln_opcion_card.dart';
import 'widgets/pln_precios.dart';
import 'widgets/pln_promo_card.dart';
import 'widgets/pln_resumen.dart';

/// Datos del paso 1 del registro (InstitucionRegistroPage).
class InstitucionRegistroDraft {
  final String nombre;
  final String cuit;
  final String direccion;

  final String pais;
  final String provincia;
  final String ciudad;

  final ModalidadCursado modalidad;

  final String email;
  final String telefono;
  final String pass;

  final TipoInstitucion tipo;

  final List<NivelCurricular> nivelesSeleccionados;
  final List<BloqueExtracurricular> bloquesSeleccionados;

  const InstitucionRegistroDraft({
    required this.nombre,
    required this.cuit,
    required this.direccion,
    required this.pais,
    required this.provincia,
    required this.ciudad,
    required this.modalidad,
    required this.email,
    required this.telefono,
    required this.pass,
    required this.tipo,
    required this.nivelesSeleccionados,
    required this.bloquesSeleccionados,
  });

  bool get tieneCurricular => nivelesSeleccionados.isNotEmpty;
  bool get tieneExtracurricular => bloquesSeleccionados.isNotEmpty;
}

class InstitucionPlanPage extends StatefulWidget {
  /// Con borrador = registro; sin borrador = gestión del plan vigente.
  final InstitucionRegistroDraft? draft;

  final String? ownerAccountId;
  final String? institucionPerfilId;
  final String? institucionNombre;

  const InstitucionPlanPage({
    super.key,
    this.draft,
    this.ownerAccountId,
    this.institucionPerfilId,
    this.institucionNombre,
  });

  const InstitucionPlanPage.manage({
    super.key,
    required String this.ownerAccountId,
    required String this.institucionPerfilId,
    this.institucionNombre,
  }) : draft = null;

  @override
  State<InstitucionPlanPage> createState() => _InstitucionPlanPageState();
}

class _InstitucionPlanPageState extends State<InstitucionPlanPage> {
  /// Ancho del resumen fijo en escritorio.
  static const double _anchoResumen = 372;

  final _promoCtrl = TextEditingController();
  final _resumenKey = GlobalKey();

  // Selección en pantalla.
  final Set<NivelCurricular> _niveles = <NivelCurricular>{};
  final Set<BloqueExtracurricular> _bloques = <BloqueExtracurricular>{};
  bool _promo = false;
  bool _comprobandoPromo = false;
  String? _promoError;

  // Gestión: plan guardado.
  Institucion? _inst;
  List<Oferta> _ofertas = const <Oferta>[];
  Set<NivelCurricular> _nivelesGuardados = const <NivelCurricular>{};
  Set<BloqueExtracurricular> _bloquesGuardados =
      const <BloqueExtracurricular>{};
  bool _promoGuardada = false;
  bool _cargando = false;
  Object? _errorCarga;

  // Envío. En el registro se recuerda lo ya creado para poder reintentar.
  bool _enviando = false;
  Object? _errorEnvio;
  String? _ownerCreado;
  String? _perfilCreado;

  bool get _registro => widget.draft != null;
  String get _institucionId => (widget.institucionPerfilId ?? '').trim();

  PlnCalculo get _calculo => PlnCalculo(
    niveles: _niveles.length,
    modulos: _bloques.length,
    promo: _promo,
  );

  PlnCalculo get _calculoGuardado => PlnCalculo(
    niveles: _nivelesGuardados.length,
    modulos: _bloquesGuardados.length,
    promo: _promoGuardada,
  );

  bool get _hayCambios =>
      !_registro &&
      _inst != null &&
      (!setEquals(_niveles, _nivelesGuardados) ||
          !setEquals(_bloques, _bloquesGuardados) ||
          _promo != _promoGuardada);

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft != null) {
      _niveles.addAll(draft.nivelesSeleccionados);
      _bloques.addAll(draft.bloquesSeleccionados);
      if (_niveles.isEmpty && _bloques.isEmpty) {
        final sugerido = _nivelSugerido(draft.tipo);
        if (sugerido != null) _niveles.add(sugerido);
      }
    } else if (_institucionId.isEmpty) {
      _errorCarga = const AtenaException(AtenaError.noEncontrado);
    } else {
      _cargando = true;
      _cargar();
    }
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  /// Nivel que se preselecciona según el tipo de institución del registro.
  static NivelCurricular? _nivelSugerido(TipoInstitucion tipo) =>
      switch (tipo) {
        TipoInstitucion.jardin => NivelCurricular.jardin,
        TipoInstitucion.primaria => NivelCurricular.primaria,
        TipoInstitucion.secundaria => NivelCurricular.secundaria,
        TipoInstitucion.tecnica => NivelCurricular.tecnica,
        TipoInstitucion.terciario => NivelCurricular.terciario,
        TipoInstitucion.taller ||
        TipoInstitucion.club ||
        TipoInstitucion.otra => null,
      };

  // ---------------------------------------------------------------------------
  // Carga (gestión)
  // ---------------------------------------------------------------------------

  Future<void> _cargar() async {
    try {
      final inst = await InstitucionesRepo.instance.obtener(_institucionId);
      if (inst == null) throw const AtenaException(AtenaError.noEncontrado);
      final ofertas = await OfertasRepo.instance.listar(inst.id);

      final plan = inst.planSafe;
      final niveles = <NivelCurricular>{
        if (inst.curricular)
          for (final n in plan.niveles)
            if (n.habilitado) n.nivel,
      };
      final bloques = <BloqueExtracurricular>{
        if (inst.extracurricular)
          for (final m in plan.modulos)
            if (m.habilitado) m.bloque,
      };
      final promo = plnPlanConPromo(inst.tipoPlan);

      if (!mounted) return;
      setState(() {
        _inst = inst;
        _ofertas = ofertas;
        _nivelesGuardados = niveles;
        _bloquesGuardados = bloques;
        _promoGuardada = promo;
        _niveles
          ..clear()
          ..addAll(niveles);
        _bloques
          ..clear()
          ..addAll(bloques);
        _promo = promo;
        _promoError = null;
        _cargando = false;
        _errorCarga = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCarga = e;
      });
    }
  }

  void _reintentar() {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    _cargar();
  }

  // ---------------------------------------------------------------------------
  // Selección y código promocional
  // ---------------------------------------------------------------------------

  void _alternarNivel(NivelCurricular n) => setState(() {
    if (!_niveles.remove(n)) _niveles.add(n);
    _errorEnvio = null;
  });

  void _alternarBloque(BloqueExtracurricular b) => setState(() {
    if (!_bloques.remove(b)) _bloques.add(b);
    _errorEnvio = null;
  });

  Future<void> _aplicarPromo() async {
    if (_comprobandoPromo || _enviando) return;
    final t = AppLocalizations.of(context);
    final ingresado = _promoCtrl.text;
    if (ingresado.trim().isEmpty) {
      setState(() => _promoError = t.plnPromoVacio);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _comprobandoPromo = true;
      _promoError = null;
    });

    try {
      final resultado = await PlnPromo.verificar(
        ingresado,
        institucionId: _registro ? null : _institucionId,
      );
      if (!mounted) return;
      setState(() {
        _comprobandoPromo = false;
        switch (resultado) {
          case PlnPromoResultado.valido:
            _promo = true;
            _errorEnvio = null;
            _promoCtrl.clear();
          case PlnPromoResultado.invalido:
            _promoError = t.plnPromoInvalido;
          case PlnPromoResultado.agotado:
            _promoError = t.plnPromoAgotado;
        }
      });
      if (resultado == PlnPromoResultado.valido) {
        AtenaFeedback.success(context, t.plnPromoValido(PlnPromo.porcentaje));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _comprobandoPromo = false);
      AtenaFeedback.error(context, coreErrorText(t, e));
    }
  }

  void _quitarPromo() => setState(() {
    _promo = false;
    _promoError = null;
  });

  /// Vuelve a controlar el cupo justo antes de confirmar. Devuelve false (y
  /// quita el código) si se agotó mientras tanto.
  Future<bool> _promoDisponible(
    AppLocalizations t,
    String? institucionId,
  ) async {
    if (!_promo || _promoGuardada) return true;
    if (await PlnPromo.hayCupo(institucionId: institucionId)) return true;
    if (!mounted) return false;
    setState(() {
      _enviando = false;
      _promo = false;
      _promoError = t.plnPromoAgotado;
    });
    AtenaFeedback.error(context, t.plnPromoAgotado);
    return false;
  }

  PlanInstitucionConfig _configPlan(PlanInstitucionConfig? previa) {
    final base =
        previa ??
        const PlanInstitucionConfig(
          niveles: <PlanNivelCurricular>[],
          modulos: <PlanModuloExtracurricular>[],
        );
    return base.copyWith(
      niveles: [
        for (final n in NivelCurricular.values)
          if (_niveles.contains(n))
            base.niveles
                    .where((x) => x.nivel == n)
                    .firstOrNull
                    ?.copyWith(habilitado: true) ??
                PlanNivelCurricular(nivel: n, habilitado: true),
      ],
      modulos: [
        for (final b in BloqueExtracurricularX.ordered())
          if (_bloques.contains(b))
            base.modulos
                    .where((x) => x.bloque == b)
                    .firstOrNull
                    ?.copyWith(habilitado: true) ??
                PlanModuloExtracurricular(bloque: b, habilitado: true),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Registro: crear la institución
  // ---------------------------------------------------------------------------

  Future<void> _crear() async {
    final draft = widget.draft;
    if (draft == null || _enviando || _calculo.vacio) return;
    final t = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _errorEnvio = null;
    });

    try {
      if (!await _promoDisponible(t, _perfilCreado)) return;

      var owner = _ownerCreado;
      if (owner == null) {
        final auth = await InstitucionService.registrarInstitucion(
          email: draft.email,
          passwordHash: draft.pass,
          nombre: draft.nombre,
        );
        owner = _ownerCreado = auth.institucionId;
      }

      var perfilId = _perfilCreado;
      if (perfilId == null) {
        final perfil = await CuentaService.crearPerfilInstitucion(
          cuentaId: owner,
          nombre: draft.nombre,
          emailContacto: draft.email,
          telefonoContacto: draft.telefono,
        );
        perfilId = _perfilCreado = perfil.id;
      }

      final calculo = _calculo;
      final ahora = DateTime.now();
      final inst = Institucion(
        id: perfilId,
        nombre: draft.nombre,
        cuit: draft.cuit,
        direccion: draft.direccion,
        pais: draft.pais,
        provincia: draft.provincia,
        ciudad: draft.ciudad,
        modalidad: draft.modalidad,
        email: draft.email,
        telefono: draft.telefono,
        curricular: _niveles.isNotEmpty,
        extracurricular: _bloques.isNotEmpty,
        tipoInstitucion: draft.tipo,
        tipoPlan: plnClavePlan(calculo),
        estadoPlan: calculo.gratis
            ? EstadoPlanInstitucion.activo
            : EstadoPlanInstitucion.enPrueba,
        planInicio: ahora,
        planFin: ahora.add(const Duration(days: PlnPrecios.diasPrueba)),
        planConfig: _configPlan(null),
      );
      await InstitucionesRepo.instance.guardar(inst);
      if (calculo.promo) await PlnPromo.canjear(perfilId);

      final sesion = await AuthService.iniciarSesionInstitucion(
        ownerAccountId: owner,
        institucionPerfilId: perfilId,
        remember: true,
        nombre: draft.nombre,
      );
      if (!mounted) return;
      AtenaFeedback.success(context, t.plnCreada);
      AtenaNav.toInstitucion(context, sesion);
    } catch (e) {
      _fallar(t, e);
    }
  }

  // ---------------------------------------------------------------------------
  // Gestión: guardar cambios
  // ---------------------------------------------------------------------------

  Future<void> _guardar() async {
    final inst = _inst;
    if (inst == null || _enviando || _calculo.vacio || !_hayCambios) return;
    final t = AppLocalizations.of(context);

    // Vacantes publicadas en lo que se quita del plan: se avisa y se pausan.
    final quitadosN = _nivelesGuardados.difference(_niveles);
    final quitadosB = _bloquesGuardados.difference(_bloques);
    bool quedaFuera(Oferta o) =>
        o.activa &&
        (o.esCurricular
            ? quitadosN.contains(o.nivel)
            : quitadosB.contains(o.bloque));

    final previstas = _ofertas.where(quedaFuera).toList();
    if (previstas.isNotEmpty) {
      final categorias = [
        for (final n in NivelCurricular.values)
          if (previstas.any((o) => o.esCurricular && o.nivel == n)) t.nivel(n),
        for (final b in BloqueExtracurricularX.ordered())
          if (previstas.any((o) => !o.esCurricular && o.bloque == b))
            t.bloque(b),
      ].join(', ');
      final ok = await showAtenaConfirm(
        context,
        title: t.plnPausarTitulo,
        message: t.plnPausarMensaje(categorias, previstas.length),
        confirmLabel: t.plnPausarAccion,
        icon: Icons.pause_circle_outline_rounded,
      );
      if (!ok || !mounted || _enviando) return;
    }

    setState(() {
      _enviando = true;
      _errorEnvio = null;
    });

    try {
      if (!await _promoDisponible(t, inst.id)) return;

      // Las fechas de prueba no se reinician al guardar: solo se fijan cuando
      // un plan sin costo pasa a tener costo por primera vez. Un plan
      // suspendido sigue suspendido.
      final calculo = _calculo;
      var estado = inst.estadoPlan;
      var inicio = inst.planInicio;
      var fin = inst.planFin;
      final eraSinCosto =
          estado == EstadoPlanInstitucion.activo ||
          estado == EstadoPlanInstitucion.sinPlan;
      if (estado != EstadoPlanInstitucion.suspendido) {
        if (calculo.gratis) {
          estado = EstadoPlanInstitucion.activo;
        } else if (eraSinCosto) {
          estado = EstadoPlanInstitucion.enPrueba;
          inicio = DateTime.now();
          fin = inicio.add(const Duration(days: PlnPrecios.diasPrueba));
        }
      }

      final actualizada = inst.copyWith(
        curricular: _niveles.isNotEmpty,
        extracurricular: _bloques.isNotEmpty,
        tipoPlan: plnClavePlan(calculo),
        estadoPlan: estado,
        planInicio: inicio,
        planFin: fin,
        planConfig: _configPlan(inst.planConfig),
      );
      await InstitucionesRepo.instance.guardar(actualizada);
      if (calculo.promo && !_promoGuardada) await PlnPromo.canjear(inst.id);

      // Se pausa lo que esté publicado en este momento.
      final ofertas = await OfertasRepo.instance.listar(inst.id);
      final pausadas = ofertas.where(quedaFuera).toList();
      for (final o in pausadas) {
        await OfertasRepo.instance.cambiarActiva(inst.id, o.id, false);
      }

      if (!mounted) return;
      AtenaFeedback.success(
        context,
        pausadas.isEmpty ? t.plnGuardado : t.plnPausadas(pausadas.length),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _fallar(t, e);
    }
  }

  /// Lleva el resumen a la vista (en teléfonos queda al final de la página).
  void _mostrarResumen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final destino = _resumenKey.currentContext;
      if (destino == null || !destino.mounted) return;
      Scrollable.ensureVisible(
        destino,
        duration: AtenaMotion.medium,
        curve: AtenaMotion.curve,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  /// Deja el error a la vista, junto al resumen, y lo avisa.
  void _fallar(AppLocalizations t, Object error) {
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _errorEnvio = error;
    });
    AtenaFeedback.error(context, coreErrorText(t, error));
    _mostrarResumen();
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
  // Presentación
  // ---------------------------------------------------------------------------

  /// Aviso del resumen: qué pasa con la prueba y con el cobro.
  PlnAviso _aviso(AppLocalizations t) {
    if (_calculo.gratis) {
      return PlnAviso(
        icon: Icons.celebration_rounded,
        tono: AtenaBannerTone.success,
        titulo: t.plnGratisTitulo,
        mensaje: t.plnGratisTexto,
      );
    }

    final prueba = t.plnPrueba(PlnPrecios.diasPrueba);
    final inst = _inst;
    if (inst == null) {
      return PlnAviso(
        icon: Icons.card_giftcard_rounded,
        tono: AtenaBannerTone.info,
        titulo: prueba,
        mensaje: t.plnPruebaTexto,
      );
    }

    final fecha = AtenaFormat.fechaCorta(context, inst.planFin);
    final vencida = DateTime.now().isAfter(inst.planFin);
    return switch (inst.estadoPlan) {
      EstadoPlanInstitucion.activo || EstadoPlanInstitucion.sinPlan => PlnAviso(
        icon: Icons.card_giftcard_rounded,
        tono: AtenaBannerTone.info,
        titulo: prueba,
        mensaje:
            '${t.plnPruebaEmpieza(PlnPrecios.diasPrueba)} ${t.plnPruebaTexto}',
      ),
      EstadoPlanInstitucion.enPrueba when !vencida => PlnAviso(
        icon: Icons.hourglass_bottom_rounded,
        tono: AtenaBannerTone.info,
        titulo: t.instPlanTrialUntil(fecha),
        mensaje: t.plnPruebaTexto,
      ),
      EstadoPlanInstitucion.enPrueba ||
      EstadoPlanInstitucion.vencido => PlnAviso(
        icon: Icons.timer_off_rounded,
        tono: AtenaBannerTone.warning,
        titulo: t.instPlanTrialEnded,
        mensaje: t.plnPruebaTerminada(fecha),
      ),
      EstadoPlanInstitucion.suspendido => PlnAviso(
        icon: Icons.pause_circle_rounded,
        tono: AtenaBannerTone.warning,
        titulo: t.instPlanSuspended,
        mensaje: t.plnSinCobros,
      ),
    };
  }

  ({String? texto, bool alerta}) _nota(
    AppLocalizations t, {
    required int activas,
    required bool seleccionada,
    required bool guardada,
  }) {
    if (activas == 0) return (texto: null, alerta: false);
    if (guardada && !seleccionada) {
      return (texto: t.plnSePausan(activas), alerta: true);
    }
    return (texto: t.plnVacantesActivas(activas), alerta: false);
  }

  Widget _tarjetaNivel(AppLocalizations t, NivelCurricular n, bool horizontal) {
    final seleccionada = _niveles.contains(n);
    final nota = _nota(
      t,
      activas: _ofertas
          .where((o) => o.activa && o.esCurricular && o.nivel == n)
          .length,
      seleccionada: seleccionada,
      guardada: _nivelesGuardados.contains(n),
    );
    return PlnOpcionCard(
      icon: iconoNivel(n),
      color: plnColorNivel(n),
      titulo: t.nivel(n),
      precio: t.plnPorMes(plnUsd(t, PlnPrecios.porNivel)),
      nota: nota.texto,
      notaAlerta: nota.alerta,
      seleccionada: seleccionada,
      horizontal: horizontal,
      onTap: _enviando ? null : () => _alternarNivel(n),
    );
  }

  Widget _tarjetaBloque(
    AppLocalizations t,
    BloqueExtracurricular b,
    bool horizontal,
  ) {
    final seleccionada = _bloques.contains(b);
    final nota = _nota(
      t,
      activas: _ofertas
          .where((o) => o.activa && !o.esCurricular && o.bloque == b)
          .length,
      seleccionada: seleccionada,
      guardada: _bloquesGuardados.contains(b),
    );
    return PlnOpcionCard(
      icon: iconoBloque(b),
      color: plnColorBloque(b),
      titulo: t.bloque(b),
      descripcion: plnDescripcionBloque(t, b),
      precio: t.plnPorMes(plnUsd(t, PlnPrecios.porModulo)),
      nota: nota.texto,
      notaAlerta: nota.alerta,
      seleccionada: seleccionada,
      horizontal: horizontal,
      onTap: _enviando ? null : () => _alternarBloque(b),
    );
  }

  List<Widget> _seleccion(AppLocalizations t) {
    final inst = _inst;
    final bloques = BloqueExtracurricularX.ordered();
    return [
      if (inst == null)
        const PlnEncabezadoRegistro()
      else
        PlnEncabezadoGestion(inst: inst, plan: _calculoGuardado),
      const SizedBox(height: 20),
      AtenaSectionHeader(
        title: t.plnNiveles,
        subtitle: t.plnNivelesAyuda(plnUsd(t, PlnPrecios.porNivel)),
      ),
      PlnGrilla(
        cantidad: NivelCurricular.values.length,
        anchoMinimo: 150,
        maxColumnas: 3,
        anchoHorizontal: 280,
        itemBuilder: (context, i, horizontal) =>
            _tarjetaNivel(t, NivelCurricular.values[i], horizontal),
      ),
      const SizedBox(height: 20),
      AtenaSectionHeader(
        title: t.plnModulos,
        subtitle: t.plnModulosAyuda(plnUsd(t, PlnPrecios.porModulo)),
      ),
      PlnGrilla(
        cantidad: bloques.length,
        anchoMinimo: 280,
        maxColumnas: 2,
        anchoHorizontal: 240,
        itemBuilder: (context, i, horizontal) =>
            _tarjetaBloque(t, bloques[i], horizontal),
      ),
      const SizedBox(height: 24),
      PlnPromoCard(
        controller: _promoCtrl,
        aplicado: _promo,
        fijo: _promo && _promoGuardada,
        comprobando: _comprobandoPromo,
        habilitado: !_enviando,
        error: _promoError,
        onAplicar: _aplicarPromo,
        onQuitar: _quitarPromo,
      ),
    ];
  }

  /// Acción del botón principal. Sin nada elegido, el botón explica qué
  /// falta; en gestión se habilita recién cuando hay cambios.
  VoidCallback? _alConfirmar(AppLocalizations t) {
    if (_enviando || (!_registro && !_hayCambios)) return null;
    if (_calculo.vacio) {
      return () => AtenaFeedback.info(context, t.plnElegiAlMenosUno);
    }
    return _registro ? _crear : _guardar;
  }

  Widget _accion(AppLocalizations t) {
    return PlnBotonAccion(
      label: _registro ? t.plnCrear : t.plnGuardar,
      cargandoLabel: _registro ? t.plnCreando : t.commonSaving,
      icon: _registro ? Icons.arrow_forward_rounded : Icons.check_rounded,
      cargando: _enviando,
      onPressed: _alConfirmar(t),
    );
  }

  Widget? _bannerError(AppLocalizations t) {
    final e = _errorEnvio;
    if (e == null) return null;
    // Errores que se corrigen volviendo al paso 1 del registro.
    final corregible =
        _registro &&
        e is AuthException &&
        const {
          AuthErrorCode.emailInUse,
          AuthErrorCode.invalidEmail,
          AuthErrorCode.weakPassword,
          AuthErrorCode.invalidName,
        }.contains(e.code);
    return AtenaBanner(
      tone: AtenaBannerTone.error,
      message: coreErrorText(t, e),
      action: corregible
          ? TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(t.plnCorregirDatos),
            )
          : null,
    );
  }

  Widget _resumen(AppLocalizations t, {required bool conAccion}) {
    return PlnResumen(
      key: _resumenKey,
      calculo: _calculo,
      niveles: [
        for (final n in NivelCurricular.values)
          if (_niveles.contains(n)) t.nivel(n),
      ],
      modulos: [
        for (final b in BloqueExtracurricularX.ordered())
          if (_bloques.contains(b)) t.bloque(b),
      ],
      aviso: _aviso(t),
      planActual: _hayCambios
          ? t.plnPlanActual(plnUsd(t, _calculoGuardado.total))
          : null,
      error: _bannerError(t),
      accion: conAccion ? _accion(t) : null,
    );
  }

  /// Escritorio: selección a la izquierda y resumen fijo al costado.
  Widget _escritorio(AppLocalizations t) {
    return LayoutBuilder(
      builder: (context, c) {
        // Los márgenes van dentro de cada columna para que las sombras no se
        // corten en el borde del área desplazable.
        final lado = math.max(
          AtenaSpace.page,
          (c.maxWidth - AtenaLayout.wide) / 2,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  lado,
                  AtenaSpace.xs,
                  AtenaSpace.xl,
                  AtenaSpace.xxl,
                ),
                children: _seleccion(t),
              ),
            ),
            SizedBox(
              width: _anchoResumen + lado,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  AtenaSpace.xs,
                  lado,
                  AtenaSpace.xxl,
                ),
                child: _resumen(t, conAccion: true),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Teléfono: todo en una columna; el total y la acción quedan en la barra.
  Widget _telefono(AppLocalizations t) {
    return SingleChildScrollView(
      padding: atenaPagePadding(context, maxWidth: 720),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._seleccion(t),
          const SizedBox(height: 24),
          _resumen(t, conAccion: false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final escritorio = AtenaLayout.isDesktop(context);
    final listo = _registro || _inst != null;
    final nombre =
        widget.draft?.nombre ?? _inst?.nombre ?? widget.institucionNombre;

    final Widget cuerpo;
    if (_cargando) {
      cuerpo = const AtenaLoading();
    } else if (!listo) {
      cuerpo = AtenaErrorState(
        title: t.plnErrorCarga,
        message: coreErrorText(
          t,
          _errorCarga ?? const AtenaException(AtenaError.noEncontrado),
        ),
        onRetry: _institucionId.isEmpty ? null : _reintentar,
      );
    } else {
      cuerpo = escritorio ? _escritorio(t) : _telefono(t);
    }

    return PopScope<Object?>(
      canPop: !_enviando && !_hayCambios,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _enviando) return;
        _confirmarSalida();
      },
      child: AtenaScaffold(
        role: AtenaRole.institucion,
        appBar: AtenaAppBar(
          title: _registro ? t.plnTitulo : t.instActionPlan,
          subtitle: nombre,
        ),
        body: cuerpo,
        bottomNavigationBar: listo && !_cargando && !escritorio
            ? PlnBarraTotal(
                calculo: _calculo,
                accion: _accion(t),
                onVerResumen: _mostrarResumen,
              )
            : null,
      ),
    );
  }
}
