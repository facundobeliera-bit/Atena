// lib/screens/cuentas/cuenta_home_page.dart
//
// ATENA – CUENTA HOME (CANÓNICO)
// ownerAccountId (cuentaId) → perfiles → perfilId
//
// ✅ Gateway recomendado:
// 1) Si llega deeplink (notificación) -> resolver primero (perfilId/date/itemId/...)
// 2) Si no, aplicar “continuar último perfil” (recordarme) SIN forzar navegación automática
//    (evita bloquear “Crear perfil” cuando el usuario quiere gestionar perfiles).
// 3) Mantener flujo canónico (sin flujos paralelos)
//
// Deeplinks canónicos esperados:
// - /calendario?perfilId=...&date=...&itemId=...
// - /documentos?perfilId=...(&documentoId=...)
// - ✅ /documentos?perfilId=...(&solicitudId=...)
//
// ✅ FIX BLOQUEANTE (FASE 2 · AHORA · INSTITUCIONES):
// - Si la cuenta tiene SOLO perfiles de institución (y cero alumnos), esta pantalla NO debe mostrarse.
// - Auto-redirige a InstitucionMenuPage (prioriza último perfil institución; si no, primero).
//
// ✅ FIX (feb 2026 · E2E):
// - Sesión institucional usa userId = institucionPerfilId (para compat con guards que comparan institucionId logueada).
// - OwnerAccountId operativo institucional se guarda en v2_session_instOwnerAccountId (SessionService.setInstitucionOwnerAccountId).
//
// ✅ FIX (feb 2026 · session persist):
// - Para evitar “pantalla cargando” en InstitucionMenuPage cuando rememberMe=false,
//   SIEMPRE persistimos SessionService.setSession(... rememberMe: true) para el runtime actual.
//   El “Recordarme OFF” se controla con CuentaService (sesión temporal) y se limpia en boot/logout.
//
// ✅ FIX ANTI-BUG SILENCIOSO (feb 2026 · AHORA):
// - Nunca “return” silencioso al abrir perfil institución.
// - Si no se puede resolver instPerfilId: banner + snack + logs.
// - En ONLY-INSTITUCIONES: si falla el auto-redirect, se desactiva modo redirect y se muestra UI normal.
//
// ✅ FIX CRÍTICO (feb 2026 · mismatch “sesión inválida” / cuenta cruzada):
// - NO sobreescribir ownerId desde CuentaService.getSesionCuentaId() (puede venir stale de otra cuenta).
//   En CuentaHome, el owner canónico SIEMPRE es widget.cuentaId.
//
// ✅ FIX CRÍTICO (feb 2026 · compat API real):
// - Se elimina wrapper best-effort de setSesionCuentaId: ahora llamamos DIRECTO a CuentaService.setSesionCuentaId()
//
// ✅ FIX CRÍTICO (feb 2026 · BUG REAL “ownerTienePerfil=false” en InstitucionMenuPage):
// - Antes de navegar a InstitucionMenuPage, hacemos “self-heal” canónico:
//   si por cualquier razón el perfil institución NO está persistido en la lista del owner,
//   lo insertamos en Cuenta.perfilesInstitucionIds y guardamos Cuenta (sin inventar perfiles).
//
// ✅ FIX (feb 2026 · CONSISTENCIA CON CuentaService):
// - Normalización local para comparar/guardar ids (trim + elimina whitespace interno) igual que CuentaService._normIdKey.
// - Encode “último perfil” (A| / I|) guarda ids normalizados para evitar mismatch al recuperar.
//
// ✅ FIX CLAVE (feb 2026 · BUG REAL “queda cargando al abrir institución”):
// - Resolver institucionPerfilId CANÓNICO de forma robusta:
//   algunos modelos/fixtures pueden tener `id == ownerAccountId` (o `accountId`) y el
//   perfil real en `institucionPerfilId/perfilId/institucionId`.
// - Si detectamos candidate == ownerId y existe otro candidate distinto, priorizamos el distinto.
//
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/alumnos/alumnos_integrados.dart' show Alumno;
import '../../models/cuentas/cuenta.dart';
import '../../routes/atena_deeplink.dart';
import '../../services/alumno_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/session_service.dart';
import '../../ui/atena_assets.dart';

import '../alumno/alumno_area_page.dart';
import '../alumno/alumno_perfil_registro_page.dart';
import '../alumnos/alumno_calendario_page.dart';
import '../alumnos/alumno_documentos_page.dart';

// ✅ Institución: entrada FASE 2 (HOME institucional)
import '../instituciones/institucion_menu_page.dart';

class CuentaHomePage extends StatefulWidget {
  final String cuentaId;

  /// ✅ Deeplink opcional (por ejemplo desde Notificaciones).
  final String? initialDeeplink;

  const CuentaHomePage({
    super.key,
    required this.cuentaId,
    this.initialDeeplink,
  });

  @override
  State<CuentaHomePage> createState() => _CuentaHomePageState();
}

class _CuentaHomePageState extends State<CuentaHomePage> {
  bool _cargando = true;

  /// ✅ Guardia anti-doble navegación.
  bool _navegando = false;

  /// ✅ Guardia anti-loop: auto-redirect institucional (solo instituciones)
  bool _autoRedirectInstitucionHecho = false;

  /// ✅ Si el auto-redirect falla, deshabilitamos el modo “only instituciones redirecting”
  /// para que NO quede una UI “preparando” indefinida.
  bool _autoRedirectInstitucionFallido = false;

  Cuenta? _cuenta;

  // ✅ Perfiles Alumno
  List<PerfilAlumno> _perfilesAlumno = <PerfilAlumno>[];

  // ✅ Perfiles Institución
  List<PerfilInstitucion> _perfilesInstitucion = <PerfilInstitucion>[];

  String? _error;

  // Deeplink (estado)
  bool _deeplinkProcesado = false;
  String? _deeplinkEfectivo;
  String? _deeplinkRawAplicado;

  // ✅ Deeplink pendiente cuando falta perfilId y hay múltiples perfiles alumno.
  AtenaDeeplink? _deeplinkPendienteSinPerfil;

  // ✅ “Recordarme”: sugerencia de último perfil (SIN auto-navegar)
  PerfilAlumno? _perfilAlumnoSugerido;
  PerfilInstitucion? _perfilInstitucionSugerida;
  bool _mostrarSugerenciaUltimoPerfil = false;

  // =====================================================
  // NORMALIZACIÓN LOCAL (match CuentaService._normIdKey)
  // =====================================================
  String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  // =====================================================
  // ✅ ÚLTIMO PERFIL (evitar cruce Alumno/Institución)
  // Guardamos tags: A|<id> / I|<id>
  // Backward-compatible con legacy: <id>
  // =====================================================
  static const String _lpAlumno = 'A|';
  static const String _lpInstitucion = 'I|';

  String _encodeUltimoAlumno(String perfilId) =>
      '$_lpAlumno${_normIdKey(perfilId)}';

  String _encodeUltimoInstitucion(String perfilId) =>
      '$_lpInstitucion${_normIdKey(perfilId)}';

  ({String tipo, String id}) _decodeUltimoPerfil(String raw) {
    final s = raw.trim();
    if (s.startsWith(_lpAlumno)) {
      final id = s.substring(_lpAlumno.length).trim();
      return (tipo: 'alumno', id: _normIdKey(id));
    }
    if (s.startsWith(_lpInstitucion)) {
      final id = s.substring(_lpInstitucion.length).trim();
      return (tipo: 'institucion', id: _normIdKey(id));
    }
    return (tipo: 'legacy', id: _normIdKey(s));
  }

  int _alpha(double opacity) {
    final v = (opacity * 255).round();
    if (v < 0) return 0;
    if (v > 255) return 255;
    return v;
  }

  // =====================================================
  // PERFIL INSTITUCIÓN – Helpers tolerantes a modelos
  // =====================================================

  /// Devuelve lista de candidatos en orden CANÓNICO (más confiable primero).
  /// OJO: algunos modelos pueden tener `id/accountId == ownerId` y el perfil real en otros campos.
  List<String> _instPerfilIdCandidates(PerfilInstitucion p) {
    final d = p as dynamic;

    final out = <String>[];

    void addCandidate(Object? v) {
      if (v is! String) return;
      final s = v.trim();
      if (s.isEmpty) return;
      out.add(s);
    }

    // ✅ Orden CANÓNICO: primero los campos explícitos de perfil institución
    try {
      addCandidate(d.institucionPerfilId);
    } catch (_) {}
    try {
      addCandidate(d.perfilId);
    } catch (_) {}
    try {
      addCandidate(d.institucionId);
    } catch (_) {}

    // Luego id / accountId (pueden ser ownerId en ciertos fixtures)
    try {
      addCandidate(d.id);
    } catch (_) {}
    try {
      addCandidate(d.accountId);
    } catch (_) {}

    // De-dup por norm
    final seen = <String>{};
    final uniq = <String>[];
    for (final s in out) {
      final k = _normIdKey(s);
      if (k.isEmpty) continue;
      if (seen.add(k)) uniq.add(s);
    }
    return uniq;
  }

  /// Resolve CANÓNICO: si detecta que el primer candidato == ownerId y hay otro distinto, usa el distinto.
  String _resolveInstPerfilId({
    required PerfilInstitucion perfil,
    required String ownerAccountId,
  }) {
    final owner = _normIdKey(ownerAccountId);
    final cands = _instPerfilIdCandidates(perfil);
    if (cands.isEmpty) return '';

    // Preferir candidatos distintos al owner (cuando existen)
    if (owner.isNotEmpty) {
      for (final c in cands) {
        final k = _normIdKey(c);
        if (k.isEmpty) continue;
        if (k != owner) return c.trim();
      }
    }

    // Si todos son iguales al owner (o owner vacío), usar el primero
    return cands.first.trim();
  }

  String _instNombre(PerfilInstitucion p) {
    final d = p as dynamic;

    try {
      final v = d.nombre;
      if (v is String) return v;
    } catch (_) {}

    try {
      final v = d.nombreInstitucion;
      if (v is String) return v;
    } catch (_) {}

    return '';
  }

  bool get _onlyInstitucionesUI =>
      _perfilesAlumno.isEmpty &&
      _perfilesInstitucion.isNotEmpty &&
      !_autoRedirectInstitucionFallido;

  void _snack(String msg) {
    final m = msg.trim();
    if (m.isEmpty) return;
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(m)));
    } catch (_) {
      // NO-OP
    }
  }

  // =====================================================
  // ✅ SELF-HEAL CANÓNICO: asegurar que el owner “tenga” el perfil institución
  // (para que InstitucionMenuPage no marque ownerTienePerfil=false)
  // =====================================================
  Future<void> _ensureOwnerHasInstitucionPerfil({
    required String ownerAccountId,
    required String institucionPerfilId,
  }) async {
    final owner = _normIdKey(ownerAccountId);
    final pid = _normIdKey(institucionPerfilId);
    if (owner.isEmpty || pid.isEmpty) return;

    bool has = false;
    try {
      has = await CuentaService.ownerTienePerfil(
        ownerAccountId: owner,
        perfilId: pid,
      );
    } catch (_) {
      has = false;
    }
    if (has) return;

    debugPrint(
      '[ATENA][CUENTA-HOME][SELF-HEAL] ownerTienePerfil=false -> insertando perfil institución en Cuenta (owner=$owner pid=$pid)',
    );

    final c = await CuentaService.getCuentaById(owner);
    if (c == null) return;

    final ids = c.perfilesInstitucionIds.map(_normIdKey).toList();
    if (!ids.contains(pid)) {
      c.perfilesInstitucionIds = List<String>.from(ids)..add(pid);
      try {
        await CuentaService.actualizarCuenta(c);
      } catch (e) {
        debugPrint(
          '[ATENA][CUENTA-HOME][SELF-HEAL] actualizarCuenta failed: $e',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final dl = (widget.initialDeeplink ?? '').trim();
    _deeplinkEfectivo = dl.isEmpty ? null : dl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.bgAlumnoHome)),
          context,
        );
        // ignore: discarded_futures
        precacheImage(
          AssetImage(
            AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionHome),
          ),
          context,
        );
        // ignore: discarded_futures
        precacheImage(
          AssetImage(AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow)),
          context,
        );
      } catch (_) {}
    });

    // ignore: discarded_futures
    _cargar();
  }

  Map<String, dynamic> _argsFrom(dynamic args) {
    if (args is Map<String, dynamic>) return args;

    if (args is Map) {
      final out = <String, dynamic>{};
      try {
        args.forEach((k, v) {
          final key = (k ?? '').toString().trim();
          if (key.isEmpty) return;
          out[key] = v;
        });
      } catch (_) {
        return <String, dynamic>{};
      }
      return out;
    }

    return <String, dynamic>{};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if ((_deeplinkEfectivo ?? '').trim().isNotEmpty) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null) return;

    String? picked;

    if (args is String && args.trim().isNotEmpty) {
      picked = args.trim();
    } else {
      try {
        final a = _argsFrom(args);

        String? pick(dynamic v) {
          final s = (v ?? '').toString().trim();
          return s.isEmpty ? null : s;
        }

        final raw =
            a['initialDeeplink'] ?? a['deeplink'] ?? a['route'] ?? a['name'];
        picked = pick(raw);
      } catch (_) {
        picked = null;
      }
    }

    if (picked == null) return;

    final pickedTrim = picked.trim();
    if (pickedTrim.isEmpty) return;

    final alreadyApplied =
        _deeplinkProcesado &&
        ((_deeplinkRawAplicado ?? '').trim() == pickedTrim);
    if (alreadyApplied) return;

    _deeplinkEfectivo = pickedTrim;

    if (mounted) {
      setState(() {
        _deeplinkProcesado = false;
        _deeplinkRawAplicado = null;
        _deeplinkPendienteSinPerfil = null;
      });
    } else {
      _deeplinkProcesado = false;
      _deeplinkRawAplicado = null;
      _deeplinkPendienteSinPerfil = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_cuenta == null) return;

      // ignore: discarded_futures
      _intentarResolverDeeplink(_perfilesAlumno);
    });
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    final hasDeeplink = ((_deeplinkEfectivo ?? '').trim().isNotEmpty);

    setState(() {
      _cargando = true;
      _navegando = false;
      _error = null;

      _deeplinkPendienteSinPerfil = null;

      _perfilAlumnoSugerido = null;
      _perfilInstitucionSugerida = null;
      _mostrarSugerenciaUltimoPerfil = false;

      // reset del hardening
      _autoRedirectInstitucionHecho = false;
      _autoRedirectInstitucionFallido = false;

      if (hasDeeplink) {
        _deeplinkProcesado = false;
        _deeplinkRawAplicado = null;
      }
    });

    try {
      final cuentaId = widget.cuentaId.trim();
      if (cuentaId.isEmpty) {
        throw Exception('Sesión inválida (cuentaId vacío).');
      }

      final c = await CuentaService.getCuentaById(cuentaId);
      if (c == null) {
        throw Exception('Cuenta no encontrada.');
      }

      final perfilesAlumno = await CuentaService.listarPerfilesAlumno(cuentaId);
      final perfilesInstitucion = await CuentaService.listarPerfilesInstitucion(
        cuentaId,
      );

      if (!mounted) return;

      setState(() {
        _cuenta = c;
        _perfilesAlumno = perfilesAlumno;
        _perfilesInstitucion = perfilesInstitucion;
      });

      // ✅ ONLY-INSTITUCIONES: auto-redirect (no mostrar HUB)
      if (!_autoRedirectInstitucionHecho &&
          perfilesAlumno.isEmpty &&
          perfilesInstitucion.isNotEmpty) {
        _autoRedirectInstitucionHecho = true;

        PerfilInstitucion? target;

        try {
          final ultimoRaw = await CuentaService.getUltimoPerfil(
            widget.cuentaId,
          );
          final up = (ultimoRaw ?? '').trim();
          if (up.isNotEmpty) {
            final decoded = _decodeUltimoPerfil(up);
            if (decoded.tipo == 'institucion') {
              final match = _buscarPerfilInstitucion(
                perfilesInstitucion,
                decoded.id,
              );
              if (match != null) target = match;
            }
          }
        } catch (_) {}

        target ??= perfilesInstitucion.first;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final ok = await _abrirPerfilInstitucion(target!);
          if (!mounted) return;

          // ✅ Si falló, salimos del “only instituciones redirecting”
          if (!ok) {
            final t = AppLocalizations.of(context);
            setState(() {
              _autoRedirectInstitucionFallido = true;
              _error ??= t.commonError;
            });
          }
        });

        return;
      }

      final handled = await _intentarResolverDeeplink(perfilesAlumno);
      if (handled) return;

      await _prepararSugerenciaUltimoPerfil(
        c,
        perfilesAlumno,
        perfilesInstitucion,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _asegurarFichaAlumno(PerfilAlumno p) async {
    final ownerId = widget.cuentaId.trim();
    final perfilId = p.id.trim();
    if (ownerId.isEmpty || perfilId.isEmpty) return;

    final existente = await AlumnoService.instance.getPerfilAlumnoByPerfilId(
      ownerAccountId: ownerId,
      perfilId: perfilId,
    );
    if (existente != null) return;

    final alumno = Alumno(
      documento: p.documento,
      nombre: p.nombre,
      apellido: p.apellido,
      fechaNacimiento: p.fechaNacimiento,
      email: p.email.trim(),
      telefono: p.telefono.trim(),
      fotoPerfilLocalPath: null,
    );

    await AlumnoService.instance.upsertPerfilAlumnoByPerfilId(
      ownerAccountId: ownerId,
      perfilId: perfilId,
      alumno: alumno,
    );
  }

  PerfilAlumno? _buscarPerfilAlumno(
    List<PerfilAlumno> perfiles,
    String perfilId,
  ) {
    final pid = _normIdKey(perfilId);
    if (pid.isEmpty) return null;
    for (final it in perfiles) {
      if (_normIdKey(it.id) == pid) return it;
    }
    return null;
  }

  PerfilInstitucion? _buscarPerfilInstitucion(
    List<PerfilInstitucion> perfiles,
    String perfilId,
  ) {
    final pid = _normIdKey(perfilId);
    if (pid.isEmpty) return null;

    for (final it in perfiles) {
      // Match contra TODOS los candidatos por seguridad (evita mismatch si el modelo cambió)
      final cands = _instPerfilIdCandidates(it).map(_normIdKey).toList();
      if (cands.contains(pid)) return it;
    }
    return null;
  }

  bool _deeplinkSoportado(AtenaDeeplink dl) =>
      dl.isCalendario || dl.isDocumentos;

  Future<void> _runNavigation(Future<void> Function() fn) async {
    if (!mounted) return;
    if (_navegando) return;
    setState(() => _navegando = true);

    try {
      await fn();
    } finally {
      if (mounted) setState(() => _navegando = false);
    }
  }

  Future<void> _navToCalendario({
    required String perfilId,
    String? dateKey,
    String? itemId,
  }) async {
    final dk = (dateKey ?? '').trim();
    final it = (itemId ?? '').trim();

    await _runNavigation(() async {
      if (!mounted) return;

      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AlumnoCalendarioPage(
            ownerAccountId: widget.cuentaId,
            perfilId: perfilId,
            initialDateKey: dk.isEmpty ? null : dk,
            initialItemId: it.isEmpty ? null : it,
          ),
        ),
      );
    });
  }

  Future<void> _navToDocumentos({
    required String perfilId,
    String? documentoId,
    String? solicitudId,
  }) async {
    final sid = (solicitudId ?? '').trim();
    final did = (documentoId ?? '').trim();

    await _runNavigation(() async {
      if (!mounted) return;

      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AlumnoDocumentosPage(
            ownerAccountId: widget.cuentaId,
            perfilId: perfilId.trim(),
            initialSolicitudId: sid.isEmpty ? null : sid,
            initialDocumentoId: (sid.isEmpty && did.isNotEmpty) ? did : null,
          ),
        ),
      );
    });
  }

  Future<bool> _intentarResolverDeeplink(
    List<PerfilAlumno> perfilesAlumno,
  ) async {
    final raw = (_deeplinkEfectivo ?? '').trim();
    if (raw.isEmpty) return false;

    if (_deeplinkProcesado && (_deeplinkRawAplicado ?? '').trim() == raw) {
      return false;
    }

    AtenaDeeplink dl;
    try {
      dl = AtenaDeeplink.parse(raw);
    } catch (_) {
      return false;
    }

    if (!_deeplinkSoportado(dl)) return false;

    final ownerDl = (dl.ownerAccountId ?? '').trim();
    final ownerActual = widget.cuentaId.trim();
    if (ownerDl.isNotEmpty &&
        ownerActual.isNotEmpty &&
        ownerDl != ownerActual) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        setState(() => _error = t.cuentaHomeDeeplinkOwnerMismatch);
      }
      return false;
    }

    if (perfilesAlumno.isEmpty) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        setState(() {
          _error = t.cuentaHomeDeeplinkAlumnoRequired;
        });
      }
      return false;
    }

    final pidRaw = (dl.perfilId ?? '').trim();

    if (pidRaw.isNotEmpty) {
      final p = _buscarPerfilAlumno(perfilesAlumno, pidRaw);
      if (p == null) return false;

      if (mounted) {
        setState(() {
          _deeplinkProcesado = true;
          _deeplinkRawAplicado = raw;
          _deeplinkPendienteSinPerfil = null;
          _error = null;
        });
      } else {
        _deeplinkProcesado = true;
        _deeplinkRawAplicado = raw;
        _deeplinkPendienteSinPerfil = null;
      }

      // ignore: discarded_futures
      CuentaService.setUltimoPerfil(widget.cuentaId, _encodeUltimoAlumno(p.id));
      // ignore: discarded_futures
      _asegurarFichaAlumno(p);

      if (!mounted) return true;

      final ensured = dl.ensureCanonico(
        ownerAccountId: widget.cuentaId,
        perfilId: p.id,
      );

      if (ensured.isCalendario) {
        await _navToCalendario(
          perfilId: p.id,
          dateKey: ensured.dateKey,
          itemId: ensured.itemId,
        );
        return true;
      }

      if (ensured.isDocumentos) {
        await _navToDocumentos(
          perfilId: p.id,
          documentoId: ensured.documentoId,
          solicitudId: ensured.solicitudId,
        );
        return true;
      }

      return false;
    }

    if (perfilesAlumno.length == 1) {
      final p = perfilesAlumno.first;

      if (mounted) {
        setState(() {
          _deeplinkProcesado = true;
          _deeplinkRawAplicado = raw;
          _deeplinkPendienteSinPerfil = null;
          _error = null;
        });
      } else {
        _deeplinkProcesado = true;
        _deeplinkRawAplicado = raw;
        _deeplinkPendienteSinPerfil = null;
      }

      // ignore: discarded_futures
      CuentaService.setUltimoPerfil(widget.cuentaId, _encodeUltimoAlumno(p.id));
      // ignore: discarded_futures
      _asegurarFichaAlumno(p);

      if (!mounted) return true;

      final ensured = dl.ensureCanonico(
        ownerAccountId: widget.cuentaId,
        perfilId: p.id,
      );

      if (ensured.isCalendario) {
        await _navToCalendario(
          perfilId: p.id,
          dateKey: ensured.dateKey,
          itemId: ensured.itemId,
        );
        return true;
      }

      if (ensured.isDocumentos) {
        await _navToDocumentos(
          perfilId: p.id,
          documentoId: ensured.documentoId,
          solicitudId: ensured.solicitudId,
        );
        return true;
      }

      return false;
    }

    if (mounted) {
      final t = AppLocalizations.of(context);
      setState(() {
        _deeplinkPendienteSinPerfil = dl;
        final destino = dl.isCalendario
            ? t.cuentaHomeDestinoCalendario
            : t.cuentaHomeDestinoDocumentos;
        _error = t.cuentaHomeDeeplinkMissingPerfilId(destino);
      });
    } else {
      _deeplinkPendienteSinPerfil = dl;
    }

    return true;
  }

  Future<void> _prepararSugerenciaUltimoPerfil(
    Cuenta cuenta,
    List<PerfilAlumno> perfilesAlumno,
    List<PerfilInstitucion> perfilesInstitucion,
  ) async {
    if (!mounted) return;
    if (perfilesAlumno.isEmpty && perfilesInstitucion.isEmpty) return;

    final recordar = (cuenta.recordarme == true);
    if (!recordar) return;

    final ultimoRaw = await CuentaService.getUltimoPerfil(widget.cuentaId);
    if (!mounted) return;

    final upRaw = (ultimoRaw ?? '').trim();
    if (upRaw.isEmpty) return;

    final decoded = _decodeUltimoPerfil(upRaw);
    final up = decoded.id.trim();
    if (up.isEmpty) return;

    if (decoded.tipo == 'alumno') {
      final pA = _buscarPerfilAlumno(perfilesAlumno, up);
      if (pA != null) {
        setState(() {
          _perfilAlumnoSugerido = pA;
          _perfilInstitucionSugerida = null;
          _mostrarSugerenciaUltimoPerfil = true;
        });
      }
      return;
    }

    if (decoded.tipo == 'institucion') {
      final pI = _buscarPerfilInstitucion(perfilesInstitucion, up);
      if (pI != null) {
        setState(() {
          _perfilAlumnoSugerido = null;
          _perfilInstitucionSugerida = pI;
          _mostrarSugerenciaUltimoPerfil = true;
        });
      }
      return;
    }

    final pA = _buscarPerfilAlumno(perfilesAlumno, up);
    final pI = _buscarPerfilInstitucion(perfilesInstitucion, up);

    if (pA != null && pI != null) {
      setState(() {
        _perfilAlumnoSugerido = null;
        _perfilInstitucionSugerida = null;
        _mostrarSugerenciaUltimoPerfil = false;
      });
      return;
    }

    if (pA != null) {
      setState(() {
        _perfilAlumnoSugerido = pA;
        _perfilInstitucionSugerida = null;
        _mostrarSugerenciaUltimoPerfil = true;
      });
      return;
    }

    if (pI != null) {
      setState(() {
        _perfilAlumnoSugerido = null;
        _perfilInstitucionSugerida = pI;
        _mostrarSugerenciaUltimoPerfil = true;
      });
    }
  }

  Future<void> _logout() async {
    if (_navegando) return;

    await CuentaService.logoutCuenta();
    await CuentaService.clearUltimoPerfil(widget.cuentaId);

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _crearPerfilAlumno() async {
    if (!mounted) return;
    if (_cargando || _navegando) return;

    setState(() {
      _error = null;
      _deeplinkRawAplicado = null;
      _deeplinkProcesado = false;
      _deeplinkPendienteSinPerfil = null;
    });

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            AlumnoPerfilRegistroPage(cuentaId: widget.cuentaId),
      ),
    );

    if (!mounted) return;

    if (ok == true) {
      await _cargar();
    }
  }

  Future<void> _crearPerfil() async {
    if (!mounted) return;
    if (_cargando || _navegando) return;

    await _crearPerfilAlumno();
  }

  Future<void> _abrirPerfilAlumno(PerfilAlumno p) async {
    if (_navegando) return;

    await _runNavigation(() async {
      // ignore: discarded_futures
      CuentaService.setUltimoPerfil(widget.cuentaId, _encodeUltimoAlumno(p.id));
      // ignore: discarded_futures
      _asegurarFichaAlumno(p);

      if (!mounted) return;

      final pend = _deeplinkPendienteSinPerfil;
      if (pend != null && _deeplinkSoportado(pend)) {
        final ensured = pend.ensureCanonico(
          ownerAccountId: widget.cuentaId,
          perfilId: p.id,
        );

        final raw = rawDeeplink();

        if (mounted) {
          setState(() {
            _deeplinkPendienteSinPerfil = null;
            _error = null;
            _deeplinkProcesado = true;
            _deeplinkRawAplicado = (raw ?? '').trim();
          });
        } else {
          _deeplinkPendienteSinPerfil = null;
          _deeplinkProcesado = true;
          _deeplinkRawAplicado = (raw ?? '').trim();
        }

        if (ensured.isCalendario) {
          await _navToCalendario(
            perfilId: p.id,
            dateKey: ensured.dateKey,
            itemId: ensured.itemId,
          );
          return;
        }
        if (ensured.isDocumentos) {
          await _navToDocumentos(
            perfilId: p.id,
            documentoId: ensured.documentoId,
            solicitudId: ensured.solicitudId,
          );
          return;
        }
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AlumnoAreaPage(
            documentoAlumno: p.documento,
            cuentaId: widget.cuentaId,
            perfilId: p.id,
          ),
        ),
      );
    });
  }

  String? rawDeeplink() {
    final v = (_deeplinkEfectivo ?? '').trim();
    return v.isEmpty ? null : v;
  }

  // ✅ HANDLER CANÓNICO E2E (institución)
  // ✅ devuelve bool: true si navegó / false si falló (anti-bug silencioso)
  Future<bool> _abrirPerfilInstitucion(PerfilInstitucion p) async {
    if (_navegando) return false;

    bool navigated = false;

    await _runNavigation(() async {
      final t = AppLocalizations.of(context);

      // ✅ Owner CANÓNICO en CuentaHome: SIEMPRE widget.cuentaId (evita cruce por sesión stale)
      final ownerId = _normIdKey(widget.cuentaId);

      final instIdRaw = _resolveInstPerfilId(
        perfil: p,
        ownerAccountId: ownerId,
      );
      final instId = _normIdKey(instIdRaw);

      if (instId.isEmpty) {
        debugPrint(
          '[ATENA][CUENTA-HOME][OPEN-INST][FATAL] instPerfilId vacío. Perfil=${p.runtimeType}',
        );
        if (mounted) {
          setState(() {
            _error = '${t.commonError}: perfil institución sin ID resoluble.';
          });
        }
        _snack('${t.commonError}: perfil institución sin ID.');
        navigated = false;
        return;
      }

      // Anti-bug fuerte: si por algún motivo quedó igual al owner, lo dejamos logueado,
      // pero avisamos (porque esto casi siempre rompe carga de Institucion por id=perfilId)
      if (ownerId.isNotEmpty && instId == ownerId) {
        debugPrint(
          '[ATENA][CUENTA-HOME][OPEN-INST][WARN] instPerfilId == ownerId (owner=$ownerId). Candidates=${_instPerfilIdCandidates(p)}',
        );
      }

      // ignore: discarded_futures
      CuentaService.setUltimoPerfil(
        widget.cuentaId,
        _encodeUltimoInstitucion(instId),
      );

      final c = _cuenta;
      final recordar = (c?.recordarme == true);

      final nombre = _instNombre(p).trim();

      debugPrint(
        '[ATENA][CUENTA-HOME][OPEN-INST] ownerId=$ownerId instPerfilId=$instId recordar=$recordar',
      );

      // 1) Mantener sesión CUENTA (runtime siempre; persistencia según recordar)
      // ✅ FIX CRÍTICO: NO envolver / no “best-effort”: API directa.
      try {
        await CuentaService.setSesionCuentaId(
          ownerId,
          recordarme: recordar,
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint(
          '[ATENA][CUENTA-HOME][OPEN-INST][ERR] setSesionCuentaId: $e',
        );
        if (!mounted) return;
        setState(() {
          _error =
              '${t.commonError}: ${e.toString().replaceFirst('Exception: ', '')}';
        });
        _snack(
          '${t.commonError}: ${e.toString().replaceFirst('Exception: ', '')}',
        );
        navigated = false;
        return;
      }

      // 2) Sesión institucional v2
      // ✅ FIX BLOQUEANTE: SIEMPRE persistimos SessionService para evitar guards “sin sesión”.
      try {
        await SessionService.setSession(
          userId: instId, // 👈 institución: userId = institucionPerfilId
          role: SessionRole.institucion,
          rememberMe: true, // 🔒 runtime always (evita pantalla cargando)
        ).timeout(const Duration(seconds: 4));

        // ✅ CLAVE: ownerAccountId explícito (evita mismatch cuando userId != ownerId)
        await SessionService.setInstitucionOwnerAccountId(
          ownerId,
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('[ATENA][CUENTA-HOME][OPEN-INST][ERR] SessionService: $e');
        if (!mounted) return;
        setState(() {
          _error =
              '${t.commonError}: ${e.toString().replaceFirst('Exception: ', '')}';
        });
        _snack(
          '${t.commonError}: ${e.toString().replaceFirst('Exception: ', '')}',
        );
        navigated = false;
        return;
      }

      // 3) ✅ SELF-HEAL: asegurar que el perfil institución esté persistido en CuentaService
      // (evita "ownerTienePerfil=false" en InstitucionMenuPage)
      try {
        await _ensureOwnerHasInstitucionPerfil(
          ownerAccountId: ownerId,
          institucionPerfilId: instId,
        );
      } catch (_) {
        // NO-OP
      }

      if (!mounted) return;

      debugPrint(
        '[ATENA][CUENTA-HOME][OPEN-INST] -> pushReplacement InstitucionMenuPage(owner=$ownerId inst=$instId)',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => InstitucionMenuPage(
            ownerAccountId: ownerId,
            institucionPerfilId: instId,
            institucionNombre: nombre.isEmpty
                ? t.cuentaHomeTipoInstitucion
                : nombre,
          ),
        ),
      );

      navigated = true;
    });

    return navigated;
  }

  // =========================
  // UI HELPERS
  // =========================
  Widget _buildBackground(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final overlayAlpha = _alpha(isDark ? 0.25 : 0.06);

    final bgPath = _onlyInstitucionesUI
        ? AtenaAssets.bgInstitucionHome
        : AtenaAssets.bgAlumnoHome;

    Widget bgFallback() => Container(color: cs.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AtenaAssets.ensureCanonical(bgPath),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stack) => bgFallback(),
        ),
        Container(color: cs.scrim.withAlpha(overlayAlpha)),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.35 : 0.20,
              child: Image.asset(
                AtenaAssets.ensureCanonical(AtenaAssets.highlightGlow),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildSugerenciaUltimoPerfilCard(BuildContext context) {
    if (!_mostrarSugerenciaUltimoPerfil) return const SizedBox.shrink();

    final pA = _perfilAlumnoSugerido;
    final pI = _perfilInstitucionSugerida;

    if (pA == null && pI == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    String subtitle;
    IconData icon;
    VoidCallback? onContinue;

    if (pA != null) {
      subtitle = '${pA.apellido}, ${pA.nombre}';
      icon = Icons.history;
      onContinue = (_cargando || _navegando)
          ? null
          : () => _abrirPerfilAlumno(pA);
    } else {
      final n = _instNombre(pI!).trim();
      subtitle = n.isEmpty ? t.cuentaHomeTipoInstitucion : n;
      icon = Icons.history;
      onContinue = (_cargando || _navegando)
          ? null
          : () {
              // ignore: discarded_futures
              _abrirPerfilInstitucion(pI);
            };
    }

    final cardColor = cs.surface.withAlpha(_alpha(isDark ? 0.86 : 0.94));
    final border = cs.outlineVariant.withAlpha(_alpha(isDark ? 0.35 : 0.40));

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurface),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.cuentaHomeContinuarUltimoPerfil,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onContinue,
              child: Text(t.commonContinue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String errorText) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = cs.errorContainer.withAlpha(_alpha(isDark ? 0.55 : 0.72));
    final fg = cs.onErrorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bg,
      ),
      child: Text(errorText, style: TextStyle(color: fg)),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        text,
        style:
            theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ) ??
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
      ),
    );
  }

  Widget _buildOnlyInstitucionesRedirecting(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final msg = (_autoRedirectInstitucionHecho && _navegando)
        ? t.cuentaHomeRedirectingInstitution
        : t.cuentaHomePreparingInstitution;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (_cargando || _navegando) ? null : _cargar,
              icon: const Icon(Icons.refresh),
              label: Text(t.retry),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuenta = _cuenta;
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = cs.surface.withAlpha(_alpha(isDark ? 0.86 : 0.94));
    final border = cs.outlineVariant.withAlpha(_alpha(isDark ? 0.35 : 0.40));

    final errorText = (_error ?? '').trim();

    final onlyInstituciones =
        _perfilesAlumno.isEmpty &&
        _perfilesInstitucion.isNotEmpty &&
        !_autoRedirectInstitucionFallido;

    final shouldHideFab = onlyInstituciones;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.cuentaHomeTitle),
        backgroundColor: cs.surface.withAlpha(0),
        surfaceTintColor: cs.surface.withAlpha(0),
        actions: [
          IconButton(
            onPressed: (_cargando || _navegando) ? null : _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: t.commonRefresh,
          ),
          IconButton(
            onPressed: (_cargando || _navegando) ? null : _logout,
            icon: const Icon(Icons.logout),
            tooltip: t.commonLogout,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: shouldHideFab
          ? null
          : FloatingActionButton.extended(
              onPressed: (_cargando || _navegando) ? null : _crearPerfil,
              icon: const Icon(Icons.person_add),
              label: Text(t.cuentaHomeCreateProfileCta),
            ),
      body: _buildBackground(
        context,
        _cargando
            ? const Center(child: CircularProgressIndicator())
            : (onlyInstituciones
                  ? _buildOnlyInstitucionesRedirecting(context)
                  : cuenta == null
                  ? Center(
                      child: Text(
                        errorText.isEmpty ? t.commonError : errorText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    )
                  : SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              t.cuentaHomeAccountLine(cuenta.email),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSugerenciaUltimoPerfilCard(context),
                            if (_mostrarSugerenciaUltimoPerfil &&
                                (_perfilAlumnoSugerido != null ||
                                    _perfilInstitucionSugerida != null)) ...[
                              const SizedBox(height: 12),
                            ],
                            if (errorText.isNotEmpty) ...[
                              _buildErrorBanner(context, errorText),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child:
                                  (_perfilesAlumno.isEmpty &&
                                      _perfilesInstitucion.isEmpty)
                                  ? Center(
                                      child: Text(
                                        t.cuentaHomeNoProfiles,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: cs.onSurface),
                                      ),
                                    )
                                  : ListView(
                                      children: [
                                        if (_perfilesInstitucion
                                            .isNotEmpty) ...[
                                          _sectionHeader(
                                            context,
                                            t.cuentaHomeInstitutionsSection,
                                          ),
                                          ..._perfilesInstitucion.map((p) {
                                            final n = _instNombre(p).trim();

                                            final ownerId = _normIdKey(
                                              widget.cuentaId,
                                            );
                                            final instIdResolved =
                                                _resolveInstPerfilId(
                                                  perfil: p,
                                                  ownerAccountId: ownerId,
                                                );
                                            final showId = instIdResolved
                                                .trim()
                                                .isNotEmpty;

                                            final warnOwnerEq =
                                                ownerId.isNotEmpty &&
                                                _normIdKey(instIdResolved) ==
                                                    ownerId;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Card(
                                                color: cardColor,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: border,
                                                    ),
                                                  ),
                                                  child: ListTile(
                                                    leading: const Icon(
                                                      Icons.apartment,
                                                    ),
                                                    title: Text(
                                                      n.isEmpty
                                                          ? t.cuentaHomeTipoInstitucion
                                                          : n,
                                                    ),
                                                    subtitle: Text(
                                                      showId
                                                          ? (warnOwnerEq
                                                                ? '${t.cuentaHomeInstitutionIdLine(instIdResolved)} • ${t.commonError}'
                                                                : t.cuentaHomeInstitutionIdLine(
                                                                    instIdResolved,
                                                                  ))
                                                          : '${t.commonError}: perfil institución sin ID',
                                                    ),
                                                    trailing: const Icon(
                                                      Icons.chevron_right,
                                                    ),
                                                    onTap: _navegando
                                                        ? null
                                                        : () async {
                                                            final ok =
                                                                await _abrirPerfilInstitucion(
                                                                  p,
                                                                );
                                                            if (!ok &&
                                                                mounted) {
                                                              setState(() {
                                                                _error ??= t
                                                                    .commonError;
                                                              });
                                                            }
                                                          },
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 6),
                                        ],
                                        _sectionHeader(
                                          context,
                                          t.cuentaHomeStudentsSection,
                                        ),
                                        if (_perfilesAlumno.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Text(t.cuentaHomeNoStudents),
                                          )
                                        else
                                          ..._perfilesAlumno.map((p) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Card(
                                                color: cardColor,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: border,
                                                    ),
                                                  ),
                                                  child: ListTile(
                                                    leading: const Icon(
                                                      Icons.person,
                                                    ),
                                                    title: Text(
                                                      '${p.apellido}, ${p.nombre}',
                                                    ),
                                                    subtitle: Text(
                                                      t.cuentaHomeStudentDniLine(
                                                        p.documento,
                                                      ),
                                                    ),
                                                    trailing: const Icon(
                                                      Icons.chevron_right,
                                                    ),
                                                    onTap: _navegando
                                                        ? null
                                                        : () =>
                                                              _abrirPerfilAlumno(
                                                                p,
                                                              ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        const SizedBox(height: 80),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    )),
      ),
    );
  }
}
