// lib/screens/instituciones/institucion_perfil_page.dart
//
// ATENA – INSTITUCIÓN · PERFIL
// FASE 2 · CANÓNICO · E2E SAFE
//
// RESPONSABILIDAD:
// - Visualizar y editar perfil institucional (administrativo) + “Perfil público”.
// - Validar sesión canónica (owner o sesión institucional).
// - Nunca dejar spinners colgados.
// - No decidir reglas de plan ni locks.
//
// NOTAS IMPORTANTES (feb 2026):
// - Este archivo NO cambia IDs ni flujo canónico.
// - NO toca locks, NO navega a plan.
// - Persistencia EXTRA (perfil público) se guarda local en SharedPreferences,
//   keyed por institucionPerfilId (canónico) y lista para backend.
//
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/cuenta_service.dart';
import '../../services/instituciones_helpers.dart';
import '../../services/session_service.dart';
import '../../ui/atena_assets.dart';

class InstitucionPerfilPage extends StatefulWidget {
  final String ownerAccountId;
  final String institucionPerfilId;

  /// Si viene precargada desde menú, evita fetch inicial.
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

enum _FatalReason { noSession, sessionMismatch, cannotLoadInstitution }

class _InstitucionPerfilPageState extends State<InstitucionPerfilPage> {
  bool _cargando = true;
  bool _guardando = false;
  bool _editando = false;

  _FatalReason? _fatalReason;
  Institucion? _inst;

  // ✅ Perfil público (extras) – store local backend-ready
  bool _cargandoPublico = true;
  bool _guardandoPublico = false;
  bool _editandoPublico = false;

  _InstitucionPublicProfileExtra _publico =
      const _InstitucionPublicProfileExtra();

  final _formKey = GlobalKey<FormState>();
  final _publicFormKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _cuitCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;

  late final TextEditingController _direccionCtrl;
  late final TextEditingController _paisCtrl;
  late final TextEditingController _provinciaCtrl;
  late final TextEditingController _ciudadCtrl;

  // ✅ Público: contacto + web + redes + atención
  late final TextEditingController _publicDescripcionCtrl;
  late final TextEditingController _publicAdminHoursCtrl;
  late final TextEditingController _publicClassHoursCtrl; // ✅ aulas/cursada
  late final TextEditingController _publicTelefonoCtrl; // opcional (público)
  late final TextEditingController _publicWebsiteCtrl;

  late final TextEditingController _publicInstagramCtrl;
  late final TextEditingController _publicFacebookCtrl;
  late final TextEditingController _publicTiktokCtrl;
  late final TextEditingController _publicYoutubeCtrl;
  late final TextEditingController _publicXCtrl;
  late final TextEditingController _publicLinkedInCtrl;

  // ✅ Público: oferta / servicios / cursos
  late final TextEditingController _publicServiciosCtrl; // CSV/lineas
  bool _publicOfreceCursosCortos = false;
  final List<_CursoCorto> _publicCursosCortos = [];

  ModalidadCursado _modalidad = ModalidadCursado.presencial;
  TipoInstitucion _tipo = TipoInstitucion.otra;

  bool _curricular = true;
  bool _extracurricular = true;

  // ─────────────────────────────────────────────
  // Helpers
  static String _n(String? v) => (v ?? '').trim();
  static String _norm(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  String get _owner => _norm(widget.ownerAccountId);
  String get _perfilId => _norm(widget.institucionPerfilId);
  // ─────────────────────────────────────────────

  // ✅ Assets (centralizados)
  // Nota: el background base SIEMPRE viene por AtenaAssets.backgroundForRole(role: institucionPerfil)
  // para mantener fullscreen + fallback canónico (igual que MenuPage).
  String get _glow => AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow);

  // Perfil público – fotos: evitar explotar SharedPrefs (prototipo local)
  static const int _maxPublicPhotos = 5;

  // ✅ AJUSTE solicitado:
  // - 1MB por foto (prototipo). OJO: base64 crece ~33%. Ideal: Storage + URLs.
  static const int _maxPhotoBytes = 1024 * 1024; // 1MB

  @override
  void initState() {
    super.initState();

    _nombreCtrl = TextEditingController();
    _cuitCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();

    _direccionCtrl = TextEditingController();
    _paisCtrl = TextEditingController();
    _provinciaCtrl = TextEditingController();
    _ciudadCtrl = TextEditingController();

    _publicDescripcionCtrl = TextEditingController();
    _publicAdminHoursCtrl = TextEditingController();
    _publicClassHoursCtrl = TextEditingController();
    _publicTelefonoCtrl = TextEditingController();
    _publicWebsiteCtrl = TextEditingController();

    _publicInstagramCtrl = TextEditingController();
    _publicFacebookCtrl = TextEditingController();
    _publicTiktokCtrl = TextEditingController();
    _publicYoutubeCtrl = TextEditingController();
    _publicXCtrl = TextEditingController();
    _publicLinkedInCtrl = TextEditingController();

    _publicServiciosCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // ✅ Precache CANÓNICO: mismo asset que usa backgroundForRole(role: institucionPerfil)
        // ignore: discarded_futures
        precacheImage(
          AssetImage(
            AtenaAssets.ensureCanonical(
              AtenaAssets.backgroundPathForRole(
                AtenaBackgroundRole.institucionPerfil,
              ),
            ),
          ),
          context,
        );
        // ignore: discarded_futures
        precacheImage(AssetImage(_glow), context);
      } catch (_) {
        // NO-OP
      }
    });

    // ignore: discarded_futures
    _bootstrap();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cuitCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _paisCtrl.dispose();
    _provinciaCtrl.dispose();
    _ciudadCtrl.dispose();

    _publicDescripcionCtrl.dispose();
    _publicAdminHoursCtrl.dispose();
    _publicClassHoursCtrl.dispose();
    _publicTelefonoCtrl.dispose();
    _publicWebsiteCtrl.dispose();

    _publicInstagramCtrl.dispose();
    _publicFacebookCtrl.dispose();
    _publicTiktokCtrl.dispose();
    _publicYoutubeCtrl.dispose();
    _publicXCtrl.dispose();
    _publicLinkedInCtrl.dispose();

    _publicServiciosCtrl.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Prefs safe
  Future<SharedPreferences> _prefsSafe() {
    return SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
  }

  String _prefsKeyPublicExtra() => 'inst_public_profile_v1_$_perfilId';

  // ─────────────────────────────────────────────
  // L10N SAFE (best-effort, sin inventar keys)
  //
  // ⚠️ Importante:
  // - Los dynamic getters que pueden NO existir deben ser evaluados LAZY (closures),
  //   para no explotar con NoSuchMethodError antes del try/catch.
  String _l10nTxt(AppLocalizations l10n, List<dynamic> cands, String fallback) {
    try {
      for (final m in cands) {
        if (m is String && m.trim().isNotEmpty) return m.trim();
        if (m is Function) {
          final out = m();
          if (out is String && out.trim().isNotEmpty) return out.trim();
        }
      }
    } catch (_) {}
    return fallback;
  }

  // --- Labels safe para los getters que NO existen en tu ARB actual ---
  String _tModalidad(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).modalidad,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).modality,
  ], 'Modalidad');

  String _tCuitLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).cuitLabel,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).cuit,
  ], 'CUIT');

  String _tAddress(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).address,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).direccion,
  ], 'Dirección');

  String _tCity(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).city,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).ciudad,
  ], 'Ciudad');

  String _tProvince(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).province,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).provincia,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).state,
  ], 'Provincia');

  String _tCountry(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).country,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).pais,
  ], 'País');

  String _tInstitutionType(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).institutionType,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).tipoInstitucion,
  ], 'Tipo de institución');

  String _tPerfilPublico(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).publicProfile,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).perfilPublico,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).institutionPublicProfile,
  ], 'Perfil público');

  String _tVistaAlumno(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).studentView,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).vistaAlumno,
  ], 'Vista alumno');

  String _tDescripcion(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).description,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).descripcion,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).commonDescription,
  ], 'Descripción');

  String _tHorariosAtencion(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).adminHours,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).horariosDeAtencion,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).attentionHours,
  ], 'Horarios de atención');

  String _tHorariosAulas(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).classHours,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).horariosDeAulas,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).schedule,
  ], 'Horarios de aulas');

  String _tTelefonoPublico(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).publicPhone,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).telefonoPublico,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).phoneOptional,
  ], 'Teléfono (opcional)');

  String _tWebsite(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).website,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).sitioWeb,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).web,
  ], 'Sitio web');

  String _tRedes(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).socialNetworks,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).redesSociales,
  ], 'Redes sociales');

  String _tServicios(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).services,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).servicios,
  ], 'Servicios');

  String _tCursosCortos(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).shortCourses,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).cursosCortos,
  ], 'Cursos cortos');

  String _tDuracion(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).duration,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).duracion,
  ], 'Duración');

  String _tPrecio(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).price,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).precio,
  ], 'Precio');

  String _tFotos(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).photos,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).fotos,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).images,
  ], 'Fotos');

  String _tAgregar(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).add,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).agregar,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).commonAdd,
  ], 'Agregar');

  String _tEliminar(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).delete,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).eliminar,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).commonDelete,
  ], 'Eliminar');

  String _tClose(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).close,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).commonClose,
  ], 'Cerrar');

  String _tSchedules(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).schedules,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).horarios,
  ], 'Horarios');

  String _tContact(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).contact,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).contacto,
  ], 'Contacto');

  String _tInvalidUrl(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).invalidUrl,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).commonInvalidUrl,
  ], 'URL inválida');

  String _tNoCourses(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).noCoursesLoaded,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).noItems,
  ], 'Sin cursos cargados');

  String _tNoPhotos(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).noPhotos,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).noImages,
  ], 'Sin fotos');

  String _tPrototypeLimit(AppLocalizations l10n, int mb) => _l10nTxt(
    l10n,
    [
      // ignore: avoid_dynamic_calls
      () => (l10n as dynamic).prototypePhotoLimit?.call(mb),
    ],
    'Límite prototipo: máx. $mb MB por foto (se guarda en prefs como base64).',
  );

  String _tPhotoTooLarge(AppLocalizations l10n, int mb) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).commonFileTooLarge?.call(mb),
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).fileTooLarge?.call(mb),
  ], _tPrototypeLimit(l10n, mb));

  String _tInstagramLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).instagram,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).instagramLabel,
  ], 'Instagram');

  String _tFacebookLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).facebook,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).facebookLabel,
  ], 'Facebook');

  String _tTiktokLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).tiktok,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).tiktokLabel,
  ], 'TikTok');

  String _tYoutubeLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).youtube,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).youtubeLabel,
  ], 'YouTube');

  String _tXLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).xLabel,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).twitter,
  ], 'X');

  String _tLinkedInLabel(AppLocalizations l10n) => _l10nTxt(l10n, [
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).linkedin,
    // ignore: avoid_dynamic_calls
    () => (l10n as dynamic).linkedIn,
  ], 'LinkedIn');

  // ─────────────────────────────────────────────
  // Sesión canónica (MISMA lógica que menú)
  Future<String?> _resolveOwnerIdSafe() async {
    try {
      final id = await CuentaService.getSesionCuentaId().timeout(
        const Duration(seconds: 3),
      );
      final v = _norm(_n(id));
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _sessionMatchesInstitutionPerfilSafe() async {
    try {
      final s = await SessionService.getSession().timeout(
        const Duration(seconds: 3),
      );
      if (s == null) return false;
      if (s.role != SessionRole.institucion) return false;
      return _norm(s.userId.toString()) == _perfilId;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────

  void _toast(String msg) {
    if (!mounted) return;
    final m = msg.trim();
    if (m.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(m)));
  }

  // ─────────────────────────────────────────────
  // Bootstrap (ANTI-SPINNER)
  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _fatalReason = null;
      _cargandoPublico = true;
    });

    _FatalReason? fatal;
    Institucion? instResolved;

    try {
      if (_owner.isEmpty || _perfilId.isEmpty) {
        fatal = _FatalReason.cannotLoadInstitution;
      } else {
        final sesOwner = await _resolveOwnerIdSafe();

        final okByOwner = (sesOwner != null && sesOwner == _owner);
        final okBySession = okByOwner
            ? true
            : await _sessionMatchesInstitutionPerfilSafe();

        if (!okBySession) {
          fatal = (sesOwner == null)
              ? _FatalReason.noSession
              : _FatalReason.sessionMismatch;
        } else {
          instResolved = widget.institucionInicial;

          // ✅ FIX: loaders desde helpers (NO clase InstitucionesHelpers)
          instResolved ??=
              (await cargarInstitucionCachePorId(
                _perfilId,
              ).timeout(const Duration(seconds: 4)) ??
              await cargarInstitucionPorId(
                _perfilId,
              ).timeout(const Duration(seconds: 5)));

          if (instResolved == null) {
            fatal = _FatalReason.cannotLoadInstitution;
          }
        }
      }
    } catch (_) {
      fatal = _FatalReason.cannotLoadInstitution;
    }

    if (!mounted) return;

    if (fatal != null || instResolved == null) {
      setState(() {
        _cargando = false;
        _cargandoPublico = false;
        _fatalReason = fatal ?? _FatalReason.cannotLoadInstitution;
      });
      return;
    }

    _inst = instResolved;
    _hidratarForm(instResolved);

    // ✅ Cargar perfil público (extras) desde prefs
    await _loadPublicExtra();

    if (!mounted) return;
    setState(() {
      _cargando = false;
      _editando = false;
      _fatalReason = null;
    });
  }

  // ─────────────────────────────────────────────

  void _hidratarForm(Institucion inst) {
    _nombreCtrl.text = _n(inst.nombre);
    _cuitCtrl.text = _n(inst.cuit);
    _emailCtrl.text = _n(inst.email);
    _telefonoCtrl.text = _n(inst.telefono);

    _direccionCtrl.text = _n(inst.direccion);
    _paisCtrl.text = _n(inst.pais);
    _provinciaCtrl.text = _n(inst.provincia);
    _ciudadCtrl.text = _n(inst.ciudad);

    _modalidad = inst.modalidad;
    _tipo = inst.tipoInstitucion;
    _curricular = inst.curricular;
    _extracurricular = inst.extracurricular;
  }

  Future<void> _loadPublicExtra() async {
    try {
      final prefs = await _prefsSafe();
      final raw = (prefs.getString(_prefsKeyPublicExtra()) ?? '').trim();
      final extra = _InstitucionPublicProfileExtra.fromJson(raw);
      _publico = extra;

      _publicDescripcionCtrl.text = _publico.descripcion;
      _publicAdminHoursCtrl.text = _publico.horariosAtencion;
      _publicClassHoursCtrl.text = _publico.horariosAulas;
      _publicTelefonoCtrl.text = _publico.telefonoPublico;
      _publicWebsiteCtrl.text = _publico.website;

      _publicInstagramCtrl.text = _publico.instagram;
      _publicFacebookCtrl.text = _publico.facebook;
      _publicTiktokCtrl.text = _publico.tiktok;
      _publicYoutubeCtrl.text = _publico.youtube;
      _publicXCtrl.text = _publico.x;
      _publicLinkedInCtrl.text = _publico.linkedin;

      _publicServiciosCtrl.text = _publico.servicios.join('\n');
      _publicOfreceCursosCortos = _publico.ofreceCursosCortos;
      _publicCursosCortos
        ..clear()
        ..addAll(_publico.cursosCortos);
    } catch (_) {
      _publico = const _InstitucionPublicProfileExtra();
    }

    if (!mounted) return;
    setState(() {
      _cargandoPublico = false;
      _editandoPublico = false;
    });
  }

  bool _isEmailValidOrEmpty(String s) {
    final v = _n(s);
    if (v.isEmpty) return true;
    return v.contains('@') && v.contains('.');
  }

  bool _isUrlValidOrEmpty(String s) {
    final v = _n(s);
    if (v.isEmpty) return true;
    // Prototipo: aceptamos http/https.
    return v.startsWith('http://') || v.startsWith('https://');
  }

  void _toggleEditar() {
    final inst = _inst;
    if (inst == null) return;

    setState(() {
      _editando = !_editando;
      if (!_editando) {
        _hidratarForm(inst);
      }
    });
  }

  void _toggleEditarPublico() {
    setState(() {
      _editandoPublico = !_editandoPublico;
      if (!_editandoPublico) {
        _hidratarPublicFormFromState();
      }
    });
  }

  void _hidratarPublicFormFromState() {
    _publicDescripcionCtrl.text = _publico.descripcion;
    _publicAdminHoursCtrl.text = _publico.horariosAtencion;
    _publicClassHoursCtrl.text = _publico.horariosAulas;
    _publicTelefonoCtrl.text = _publico.telefonoPublico;
    _publicWebsiteCtrl.text = _publico.website;

    _publicInstagramCtrl.text = _publico.instagram;
    _publicFacebookCtrl.text = _publico.facebook;
    _publicTiktokCtrl.text = _publico.tiktok;
    _publicYoutubeCtrl.text = _publico.youtube;
    _publicXCtrl.text = _publico.x;
    _publicLinkedInCtrl.text = _publico.linkedin;

    _publicServiciosCtrl.text = _publico.servicios.join('\n');
    _publicOfreceCursosCortos = _publico.ofreceCursosCortos;
    _publicCursosCortos
      ..clear()
      ..addAll(_publico.cursosCortos);
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    final l10n = AppLocalizations.of(context);
    final inst = _inst;
    if (inst == null) {
      _toast(l10n.cannotLoadInstitutionTryAgain);
      return;
    }

    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      _toast(l10n.completeRequiredFields);
      return;
    }

    final updated = inst.copyWith(
      nombre: _n(_nombreCtrl.text),
      cuit: _n(_cuitCtrl.text),
      email: _n(_emailCtrl.text),
      telefono: _n(_telefonoCtrl.text),
      direccion: _n(_direccionCtrl.text),
      pais: _n(_paisCtrl.text).isEmpty ? inst.pais : _n(_paisCtrl.text),
      provincia: _n(_provinciaCtrl.text),
      ciudad: _n(_ciudadCtrl.text),
      modalidad: _modalidad,
      tipoInstitucion: _tipo,
      curricular: _curricular,
      extracurricular: _extracurricular,
    );

    setState(() => _guardando = true);

    // Capturar navigator antes del async gap (evita lint futuro).
    final navigator = Navigator.of(context);

    // Persistencia real se conecta luego
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;

    setState(() {
      _inst = updated;
      _guardando = false;
      _editando = false;
    });

    if (navigator.canPop()) {
      navigator.pop(updated);
    }
  }

  Future<void> _guardarPublico() async {
    if (_guardandoPublico) return;

    final l10n = AppLocalizations.of(context);
    final form = _publicFormKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      _toast(l10n.completeRequiredFields);
      return;
    }

    setState(() => _guardandoPublico = true);

    try {
      final servicios = _publicServiciosCtrl.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Seguridad: limitar max fotos guardadas (prototipo)
      final fotos = List<String>.from(_publico.fotos)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(_maxPublicPhotos)
          .toList();

      final updated = _publico.copyWith(
        descripcion: _n(_publicDescripcionCtrl.text),
        horariosAtencion: _n(_publicAdminHoursCtrl.text),
        horariosAulas: _n(_publicClassHoursCtrl.text),
        telefonoPublico: _n(_publicTelefonoCtrl.text),
        website: _n(_publicWebsiteCtrl.text),
        instagram: _n(_publicInstagramCtrl.text),
        facebook: _n(_publicFacebookCtrl.text),
        tiktok: _n(_publicTiktokCtrl.text),
        youtube: _n(_publicYoutubeCtrl.text),
        x: _n(_publicXCtrl.text),
        linkedin: _n(_publicLinkedInCtrl.text),
        servicios: servicios,
        ofreceCursosCortos: _publicOfreceCursosCortos,
        cursosCortos: List<_CursoCorto>.from(_publicCursosCortos),
        fotos: fotos,
      );

      final prefs = await _prefsSafe();
      await prefs.setString(_prefsKeyPublicExtra(), updated.toJson());

      if (!mounted) return;
      setState(() {
        _publico = updated;
        _guardandoPublico = false;
        _editandoPublico = false;
      });

      _toast(
        _l10nTxt(l10n, [
          // ignore: avoid_dynamic_calls
          () => (l10n as dynamic).commonSaved,
          // ignore: avoid_dynamic_calls
          () => (l10n as dynamic).saved,
        ], l10n.commonSave),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardandoPublico = false);
      _toast(l10n.cannotLoadInstitutionTryAgain);
    }
  }

  Future<void> _logoutAndHome() async {
    try {
      await CuentaService.logoutCuenta();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _fatalMessage(_FatalReason reason) {
    final l10n = AppLocalizations.of(context);
    switch (reason) {
      case _FatalReason.noSession:
        return l10n.noActiveSessionGoBackToLogin;
      case _FatalReason.sessionMismatch:
        return l10n.invalidSessionForThisAccount;
      case _FatalReason.cannotLoadInstitution:
        return l10n.cannotLoadInstitutionTryAgain;
    }
  }

  // ─────────────────────────────────────────────
  // Background institucional (ALINEADO a InstitucionMenuPage)
  Color _overlayScrim(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return cs.scrim.withValues(alpha: isDark ? 0.60 : 0.16);
  }

  double _glowOpacity(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark ? 0.16 : 0.08;
  }

  // ✅ Fondo institucional canónico: base (role) + scrim + glow + child.
  Widget _withBackground(BuildContext context, Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ✅ CANÓNICO: background centralizado (fullscreen + fallback)
        Positioned.fill(
          child: AtenaAssets.backgroundForRole(
            context,
            role: AtenaBackgroundRole.institucionPerfil,
          ),
        ),

        // Scrim (legibilidad)
        Positioned.fill(child: ColoredBox(color: _overlayScrim(context))),

        // Glow sutil (estética)
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: _glowOpacity(context),
              child: Image.asset(
                _glow,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }

  Widget _fatalView(String msg) {
    final l10n = AppLocalizations.of(context);

    final transparentSurface = Theme.of(
      context,
    ).colorScheme.surface.withAlpha(0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.profileUpper),
        backgroundColor: transparentSurface,
        surfaceTintColor: transparentSurface,
      ),
      extendBodyBehindAppBar: true,
      body: _withBackground(
        context,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(msg, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logoutAndHome,
                    icon: const Icon(Icons.home),
                    label: Text(l10n.backToHome),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI
  InputDecoration _dec({required String label, IconData? icon, String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withAlpha(153),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: padding, child: child),
    );
  }

  // ─────────────────────────────────────────────
  // Público – Fotos (hasta 5, bytes)
  Future<void> _pickPublicPhoto() async {
    if (!_editandoPublico) return;
    if (_publico.fotos.length >= _maxPublicPhotos) return;

    final l10n = AppLocalizations.of(context);

    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.image,
      );

      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) return;

      if (bytes.length > _maxPhotoBytes) {
        final maxMb = _maxPhotoBytes ~/ (1024 * 1024);
        _toast(_tPhotoTooLarge(l10n, maxMb));
        return;
      }

      final b64 = base64Encode(bytes);

      setState(() {
        final next = [..._publico.fotos, b64].take(_maxPublicPhotos).toList();
        _publico = _publico.copyWith(fotos: next);
      });
    } catch (_) {
      // no-op
    }
  }

  void _removePublicPhotoAt(int idx) {
    if (!_editandoPublico) return;
    if (idx < 0 || idx >= _publico.fotos.length) return;
    final next = [..._publico.fotos]..removeAt(idx);
    setState(() => _publico = _publico.copyWith(fotos: next));
  }

  Uint8List? _b64ToBytesSafe(String b64) {
    final t = b64.trim();
    if (t.isEmpty) return null;
    try {
      return base64Decode(t);
    } catch (_) {
      return null;
    }
  }

  void _openPhotoViewer(Uint8List bytes) {
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: cs.surface,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: _tClose(l10n),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Público – Cursos cortos
  Future<void> _addCursoCortoDialog() async {
    if (!_editandoPublico) return;

    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    ModalidadCursado modalidad = _modalidad;

    bool? ok;
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(_tCursosCortos(l10n)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(
                      label: l10n.commonNameLabel,
                      icon: Icons.book,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: durCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(
                      label: _tDuracion(l10n),
                      icon: Icons.timer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: _dec(
                      label: _tPrecio(l10n),
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ModalidadCursado>(
                    initialValue: modalidad,
                    decoration: _dec(
                      label: _tModalidad(l10n),
                      icon: Icons.public,
                    ),
                    items: ModalidadCursado.values
                        .map(
                          (m) =>
                              DropdownMenuItem(value: m, child: Text(m.name)),
                        )
                        .toList(),
                    onChanged: (v) => modalidad = v ?? modalidad,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.commonSave),
              ),
            ],
          );
        },
      );
    } finally {
      nameCtrl.dispose();
      durCtrl.dispose();
      priceCtrl.dispose();
    }

    if (ok != true) return;

    final n = _n(nameCtrl.text);
    final d = _n(durCtrl.text);
    final p = _n(priceCtrl.text);

    if (n.isEmpty) return;

    setState(() {
      _publicCursosCortos.add(
        _CursoCorto(
          nombre: n,
          duracion: d,
          precio: p,
          modalidad: modalidad.name,
        ),
      );
    });
  }

  void _removeCursoCortoAt(int idx) {
    if (!_editandoPublico) return;
    if (idx < 0 || idx >= _publicCursosCortos.length) return;
    setState(() => _publicCursosCortos.removeAt(idx));
  }

  // ─────────────────────────────────────────────
  // PREVIEW: cómo lo ve el alumno
  Widget _publicPreviewCard(AppLocalizations l10n, Institucion inst) {
    final cs = Theme.of(context).colorScheme;

    final nombre = _n(inst.nombre).isNotEmpty
        ? _n(inst.nombre)
        : l10n.institutionGeneric;
    final ciudad = _n(inst.ciudad);
    final provincia = _n(inst.provincia);
    final direccion = _n(inst.direccion);

    final ubicacion = [
      if (ciudad.isNotEmpty) ciudad,
      if (provincia.isNotEmpty) provincia,
    ].join(', ');

    final servicios = _publico.servicios
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final desc = _n(_publico.descripcion);
    final atencion = _n(_publico.horariosAtencion);
    final aulas = _n(_publico.horariosAulas);
    final tel = _n(_publico.telefonoPublico);
    final web = _n(_publico.website);

    final fotosBytes = _publico.fotos
        .map(_b64ToBytesSafe)
        .whereType<Uint8List>()
        .toList(growable: false);

    Widget badge(String text, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(140),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withAlpha(120)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(text, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
    }

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_tVistaAlumno(l10n)} · ${_tPerfilPublico(l10n)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          // Header público “tarjeta”
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(110),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withAlpha(120)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (ubicacion.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(ubicacion)),
                    ],
                  ),
                if (direccion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(child: Text(direccion)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    badge(inst.modalidad.name, Icons.public),
                    badge(inst.tipoInstitucion.name, Icons.apartment),
                    if (inst.curricular) badge(l10n.curricular, Icons.school),
                    if (inst.extracurricular)
                      badge(l10n.extracurricular, Icons.sports_soccer),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (fotosBytes.isNotEmpty) ...[
            Text(
              _tFotos(l10n),
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < fotosBytes.length; i++)
                  InkWell(
                    onTap: () => _openPhotoViewer(fotosBytes[i]),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 98,
                      height: 98,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outlineVariant.withAlpha(120),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(fotosBytes[i], fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (desc.isNotEmpty) ...[
            Text(
              _tDescripcion(l10n),
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(desc),
            const SizedBox(height: 12),
          ],

          if (atencion.isNotEmpty || aulas.isNotEmpty) ...[
            Text(
              _tSchedules(l10n),
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            if (atencion.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.access_time, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${_tHorariosAtencion(l10n)}: $atencion'),
                  ),
                ],
              ),
            if (aulas.isNotEmpty) ...[
              if (atencion.isNotEmpty) const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${_tHorariosAulas(l10n)}: $aulas')),
                ],
              ),
            ],
            const SizedBox(height: 12),
          ],

          if (tel.isNotEmpty || web.isNotEmpty) ...[
            Text(
              _tContact(l10n),
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            if (tel.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.phone_in_talk,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(tel)),
                ],
              ),
            if (web.isNotEmpty) ...[
              if (tel.isNotEmpty) const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.language, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text(web)),
                ],
              ),
            ],
            const SizedBox(height: 12),
          ],

          if (servicios.isNotEmpty) ...[
            Text(
              _tServicios(l10n),
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in servicios)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: cs.outlineVariant.withAlpha(120),
                      ),
                    ),
                    child: Text(s),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (_publico.ofreceCursosCortos &&
              _publicCursosCortos.isNotEmpty) ...[
            Text(
              _tCursosCortos(l10n),
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final c in _publicCursosCortos)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withAlpha(110),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withAlpha(120),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nombre,
                          style: Theme.of(context).textTheme.titleSmall!
                              .copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (c.duracion.trim().isNotEmpty)
                              '${_tDuracion(l10n)}: ${c.duracion}',
                            if (c.precio.trim().isNotEmpty)
                              '${_tPrecio(l10n)}: ${c.precio}',
                            if (c.modalidad.trim().isNotEmpty)
                              '${_tModalidad(l10n)}: ${c.modalidad}',
                          ].join(' · '),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final transparentSurface = cs.surface.withAlpha(0);

    // ✅ FIX CANÓNICO (feb 2026):
    // - Ya estamos en SafeArea, así que NO sumamos MediaQuery.padding.top acá
    //   para evitar “doble notch” (espaciado excesivo arriba).
    final topSpace = kToolbarHeight + 12;

    if (_cargando) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.profileUpper),
          backgroundColor: transparentSurface,
          surfaceTintColor: transparentSurface,
        ),
        extendBodyBehindAppBar: true,
        body: _withBackground(
          context,
          const SafeArea(child: Center(child: CircularProgressIndicator())),
        ),
      );
    }

    if (_fatalReason != null) {
      return _fatalView(_fatalMessage(_fatalReason!));
    }

    final inst = _inst;
    if (inst == null) {
      return _fatalView(l10n.cannotLoadInstitutionTryAgain);
    }

    final nombre = _n(inst.nombre).isNotEmpty
        ? _n(inst.nombre)
        : l10n.institutionGeneric;
    final fotosCount = _publico.fotos.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('${l10n.profileUpper} · $nombre'),
        backgroundColor: transparentSurface,
        surfaceTintColor: transparentSurface,
        actions: [
          IconButton(
            onPressed: (_guardando || _guardandoPublico) ? null : _bootstrap,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
          TextButton(
            onPressed: _guardando ? null : _toggleEditar,
            child: Text(_editando ? l10n.commonCancel : l10n.commonEdit),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _withBackground(
        context,
        SafeArea(
          child: AbsorbPointer(
            absorbing: _guardando || _guardandoPublico,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              children: [
                SizedBox(height: topSpace),
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.institutionProfileIdLabel(_perfilId)),
                      const SizedBox(height: 2),
                      Text(l10n.accountLabel(_owner)),
                      const SizedBox(height: 8),
                      Text(
                        l10n.planAndStatusLine(
                          inst.tipoPlan,
                          inst.estadoPlan.name,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ PREVIEW “Vista alumno”
                _publicPreviewCard(l10n, inst),

                const SizedBox(height: 12),

                // ─────────────────────────────
                // ADMIN / PERFIL INSTITUCIONAL (existente)
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileUpper,
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nombreCtrl,
                              enabled: _editando,
                              decoration: _dec(
                                label: l10n.commonNameLabel,
                                icon: Icons.badge,
                              ),
                              validator: (v) => _n(v).isEmpty
                                  ? l10n.commonFieldRequired
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _cuitCtrl,
                              enabled: _editando,
                              decoration: _dec(
                                label: _tCuitLabel(l10n),
                                icon: Icons.numbers,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _emailCtrl,
                              enabled: _editando,
                              decoration: _dec(
                                label: l10n.commonEmailLabel,
                                icon: Icons.email,
                              ),
                              validator: (v) => _isEmailValidOrEmpty(v ?? '')
                                  ? null
                                  : l10n.commonEmailInvalid,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _telefonoCtrl,
                              enabled: _editando,
                              decoration: _dec(
                                label: l10n.commonPhoneLabel,
                                icon: Icons.phone,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _direccionCtrl,
                              enabled: _editando,
                              decoration: _dec(
                                label: _tAddress(l10n),
                                icon: Icons.location_on,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ciudadCtrl,
                                    enabled: _editando,
                                    decoration: _dec(
                                      label: _tCity(l10n),
                                      icon: Icons.location_city,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _provinciaCtrl,
                                    enabled: _editando,
                                    decoration: _dec(
                                      label: _tProvince(l10n),
                                      icon: Icons.map,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _paisCtrl,
                              enabled: _editando,
                              decoration: _dec(
                                label: _tCountry(l10n),
                                icon: Icons.flag,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<ModalidadCursado>(
                              initialValue: _modalidad,
                              decoration: _dec(
                                label: _tModalidad(l10n),
                                icon: Icons.public,
                              ),
                              items: ModalidadCursado.values
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _editando
                                  ? (v) => setState(() {
                                      _modalidad = v ?? _modalidad;
                                    })
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<TipoInstitucion>(
                              initialValue: _tipo,
                              decoration: _dec(
                                label: _tInstitutionType(l10n),
                                icon: Icons.apartment,
                              ),
                              items: TipoInstitucion.values
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _editando
                                  ? (v) => setState(() {
                                      _tipo = v ?? _tipo;
                                    })
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile.adaptive(
                              value: _curricular,
                              onChanged: _editando
                                  ? (v) => setState(() => _curricular = v)
                                  : null,
                              title: Text(l10n.curricular),
                            ),
                            SwitchListTile.adaptive(
                              value: _extracurricular,
                              onChanged: _editando
                                  ? (v) => setState(() => _extracurricular = v)
                                  : null,
                              title: Text(l10n.extracurricular),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (!_editando || _guardando)
                              ? null
                              : _guardar,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _guardando ? l10n.commonSaving : l10n.commonSave,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─────────────────────────────
                // PERFIL PÚBLICO (visible para alumno en buscador)
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tPerfilPublico(l10n),
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          TextButton(
                            onPressed: _cargandoPublico
                                ? null
                                : _toggleEditarPublico,
                            child: Text(
                              _editandoPublico
                                  ? l10n.commonCancel
                                  : l10n.commonEdit,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.losPerfilesDeTrabajoSonInternos,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (_cargandoPublico)
                        const Center(child: CircularProgressIndicator())
                      else
                        Form(
                          key: _publicFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _publicDescripcionCtrl,
                                enabled: _editandoPublico,
                                maxLines: 4,
                                decoration: _dec(
                                  label: _tDescripcion(l10n),
                                  icon: Icons.description,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicAdminHoursCtrl,
                                enabled: _editandoPublico,
                                maxLines: 2,
                                decoration: _dec(
                                  label: _tHorariosAtencion(l10n),
                                  icon: Icons.access_time,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicClassHoursCtrl,
                                enabled: _editandoPublico,
                                maxLines: 3,
                                decoration: _dec(
                                  label: _tHorariosAulas(l10n),
                                  icon: Icons.schedule,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicTelefonoCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tTelefonoPublico(l10n),
                                  icon: Icons.phone_in_talk,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicWebsiteCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tWebsite(l10n),
                                  icon: Icons.language,
                                  hint: 'https://',
                                ),
                                validator: (v) => _isUrlValidOrEmpty(v ?? '')
                                    ? null
                                    : _tInvalidUrl(l10n),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tRedes(l10n),
                                style: Theme.of(context).textTheme.titleSmall!
                                    .copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _publicInstagramCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tInstagramLabel(l10n),
                                  icon: Icons.alternate_email,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicFacebookCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tFacebookLabel(l10n),
                                  icon: Icons.public,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicTiktokCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tTiktokLabel(l10n),
                                  icon: Icons.music_note,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicYoutubeCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tYoutubeLabel(l10n),
                                  icon: Icons.play_circle,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicXCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tXLabel(l10n),
                                  icon: Icons.chat_bubble_outline,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _publicLinkedInCtrl,
                                enabled: _editandoPublico,
                                decoration: _dec(
                                  label: _tLinkedInLabel(l10n),
                                  icon: Icons.work_outline,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _publicServiciosCtrl,
                                enabled: _editandoPublico,
                                maxLines: 4,
                                decoration: _dec(
                                  label: _tServicios(l10n),
                                  icon: Icons.checklist,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SwitchListTile.adaptive(
                                value: _publicOfreceCursosCortos,
                                onChanged: _editandoPublico
                                    ? (v) => setState(() {
                                        _publicOfreceCursosCortos = v;
                                      })
                                    : null,
                                title: Text(_tCursosCortos(l10n)),
                              ),
                              if (_publicOfreceCursosCortos) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _tCursosCortos(l10n),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _editandoPublico
                                          ? _addCursoCortoDialog
                                          : null,
                                      icon: const Icon(Icons.add),
                                      label: Text(_tAgregar(l10n)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (_publicCursosCortos.isEmpty)
                                  Text(
                                    _tNoCourses(l10n),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  )
                                else
                                  Column(
                                    children: [
                                      for (
                                        int i = 0;
                                        i < _publicCursosCortos.length;
                                        i++
                                      )
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            _publicCursosCortos[i].nombre,
                                          ),
                                          subtitle: Text(
                                            [
                                              if (_publicCursosCortos[i]
                                                  .duracion
                                                  .trim()
                                                  .isNotEmpty)
                                                '${_tDuracion(l10n)}: ${_publicCursosCortos[i].duracion}',
                                              if (_publicCursosCortos[i].precio
                                                  .trim()
                                                  .isNotEmpty)
                                                '${_tPrecio(l10n)}: ${_publicCursosCortos[i].precio}',
                                              '${_tModalidad(l10n)}: ${_publicCursosCortos[i].modalidad}',
                                            ].join(' · '),
                                          ),
                                          trailing: _editandoPublico
                                              ? IconButton(
                                                  onPressed: () =>
                                                      _removeCursoCortoAt(i),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                  ),
                                                  tooltip: _tEliminar(l10n),
                                                )
                                              : null,
                                        ),
                                    ],
                                  ),
                              ],
                              const SizedBox(height: 14),

                              // Fotos
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_tFotos(l10n)} ($fotosCount/$_maxPublicPhotos)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed:
                                        (_editandoPublico &&
                                            _publico.fotos.length <
                                                _maxPublicPhotos)
                                        ? _pickPublicPhoto
                                        : null,
                                    icon: const Icon(Icons.photo_library),
                                    label: Text(_tAgregar(l10n)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _tPrototypeLimit(
                                  l10n,
                                  _maxPhotoBytes ~/ (1024 * 1024),
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              if (_publico.fotos.isEmpty)
                                Text(
                                  _tNoPhotos(l10n),
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (
                                      int i = 0;
                                      i < _publico.fotos.length;
                                      i++
                                    )
                                      _PublicPhotoThumb(
                                        bytes: _b64ToBytesSafe(
                                          _publico.fotos[i],
                                        ),
                                        index: i,
                                        canRemove: _editandoPublico,
                                        onRemove: () => _removePublicPhotoAt(i),
                                        onOpen: (b) => _openPhotoViewer(b),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      (!_editandoPublico || _guardandoPublico)
                                      ? null
                                      : _guardarPublico,
                                  icon: _guardandoPublico
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                    _guardandoPublico
                                        ? l10n.commonSaving
                                        : l10n.commonSave,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Public Profile – EXTRA (Backend-ready, local prefs)
// ─────────────────────────────────────────────────────────────

class _InstitucionPublicProfileExtra {
  final String descripcion;
  final String horariosAtencion;
  final String horariosAulas;
  final String telefonoPublico;
  final String website;

  final String instagram;
  final String facebook;
  final String tiktok;
  final String youtube;
  final String x;
  final String linkedin;

  final List<String> servicios;
  final bool ofreceCursosCortos;
  final List<_CursoCorto> cursosCortos;

  final List<String> fotos; // base64 (max 5)

  const _InstitucionPublicProfileExtra({
    this.descripcion = '',
    this.horariosAtencion = '',
    this.horariosAulas = '',
    this.telefonoPublico = '',
    this.website = '',
    this.instagram = '',
    this.facebook = '',
    this.tiktok = '',
    this.youtube = '',
    this.x = '',
    this.linkedin = '',
    this.servicios = const [],
    this.ofreceCursosCortos = false,
    this.cursosCortos = const [],
    this.fotos = const [],
  });

  _InstitucionPublicProfileExtra copyWith({
    String? descripcion,
    String? horariosAtencion,
    String? horariosAulas,
    String? telefonoPublico,
    String? website,
    String? instagram,
    String? facebook,
    String? tiktok,
    String? youtube,
    String? x,
    String? linkedin,
    List<String>? servicios,
    bool? ofreceCursosCortos,
    List<_CursoCorto>? cursosCortos,
    List<String>? fotos,
  }) {
    return _InstitucionPublicProfileExtra(
      descripcion: descripcion ?? this.descripcion,
      horariosAtencion: horariosAtencion ?? this.horariosAtencion,
      horariosAulas: horariosAulas ?? this.horariosAulas,
      telefonoPublico: telefonoPublico ?? this.telefonoPublico,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      youtube: youtube ?? this.youtube,
      x: x ?? this.x,
      linkedin: linkedin ?? this.linkedin,
      servicios: servicios ?? this.servicios,
      ofreceCursosCortos: ofreceCursosCortos ?? this.ofreceCursosCortos,
      cursosCortos: cursosCortos ?? this.cursosCortos,
      fotos: fotos ?? this.fotos,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'descripcion': descripcion,
      'horariosAtencion': horariosAtencion,
      'horariosAulas': horariosAulas,
      'telefonoPublico': telefonoPublico,
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'tiktok': tiktok,
      'youtube': youtube,
      'x': x,
      'linkedin': linkedin,
      'servicios': servicios,
      'ofreceCursosCortos': ofreceCursosCortos,
      'cursosCortos': cursosCortos.map((e) => e.toMap()).toList(),
      'fotos': fotos,
    };
  }

  String toJson() => jsonEncode(toMap());

  static _InstitucionPublicProfileExtra fromJson(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return const _InstitucionPublicProfileExtra();
    try {
      final decoded = jsonDecode(t);
      if (decoded is! Map) return const _InstitucionPublicProfileExtra();
      final m = decoded.cast<String, dynamic>();

      final serviciosRaw = (m['servicios'] is List)
          ? (m['servicios'] as List)
          : const [];
      final servicios = serviciosRaw
          .map((e) => (e ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final cursosRaw = (m['cursosCortos'] is List)
          ? (m['cursosCortos'] as List)
          : const [];
      final cursos = <_CursoCorto>[];
      for (final c in cursosRaw) {
        if (c is Map) {
          cursos.add(_CursoCorto.fromMap(c.cast<String, dynamic>()));
        }
      }

      final fotosRaw = (m['fotos'] is List) ? (m['fotos'] as List) : const [];
      final fotos = fotosRaw
          .map((e) => (e ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();

      bool b(dynamic v) {
        if (v is bool) return v;
        if (v is num) return v != 0;
        final s = (v ?? '').toString().trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'si' || s == 'sí' || s == 'yes';
      }

      return _InstitucionPublicProfileExtra(
        descripcion: (m['descripcion'] ?? '').toString(),
        horariosAtencion: (m['horariosAtencion'] ?? '').toString(),
        horariosAulas: (m['horariosAulas'] ?? '').toString(),
        telefonoPublico: (m['telefonoPublico'] ?? '').toString(),
        website: (m['website'] ?? '').toString(),
        instagram: (m['instagram'] ?? '').toString(),
        facebook: (m['facebook'] ?? '').toString(),
        tiktok: (m['tiktok'] ?? '').toString(),
        youtube: (m['youtube'] ?? '').toString(),
        x: (m['x'] ?? '').toString(),
        linkedin: (m['linkedin'] ?? '').toString(),
        servicios: servicios,
        ofreceCursosCortos: b(m['ofreceCursosCortos']),
        cursosCortos: cursos,
        fotos: fotos,
      );
    } catch (_) {
      return const _InstitucionPublicProfileExtra();
    }
  }
}

class _CursoCorto {
  final String nombre;
  final String duracion;
  final String precio; // texto (opcional)
  final String modalidad; // string (presencial/remoto/hibrido)

  const _CursoCorto({
    required this.nombre,
    this.duracion = '',
    this.precio = '',
    this.modalidad = '',
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'nombre': nombre,
    'duracion': duracion,
    'precio': precio,
    'modalidad': modalidad,
  };

  static _CursoCorto fromMap(Map<String, dynamic> m) {
    return _CursoCorto(
      nombre: (m['nombre'] ?? '').toString(),
      duracion: (m['duracion'] ?? '').toString(),
      precio: (m['precio'] ?? '').toString(),
      modalidad: (m['modalidad'] ?? '').toString(),
    );
  }
}

class _PublicPhotoThumb extends StatelessWidget {
  final Uint8List? bytes;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final void Function(Uint8List bytes) onOpen;

  const _PublicPhotoThumb({
    required this.bytes,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        InkWell(
          onTap: bytes == null ? null : () => onOpen(bytes!),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withAlpha(120)),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                  )
                : Image.memory(bytes!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
        if (canRemove)
          Positioned(
            left: 6,
            top: 6,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withAlpha(220),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.close, size: 16, color: cs.onErrorContainer),
              ),
            ),
          ),
      ],
    );
  }
}
