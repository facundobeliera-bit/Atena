// lib/routes/atena_router.dart
//
// ATENA – Router canónico (onGenerateRoute)
//
// HARDENING (enero 2026):
// - onGenerateRoute NUNCA lanza excepción (try/catch global).
// - NO usa null-check operator (!) para params del deeplink.
// - Tolerante a rutas relativas (calendario?...), hash-routes (#/ruta?...).
// - Si faltan owner/perfil para rutas canónicas, cae al gateway (CuentaHomePage).
//
// ⚠️ No se introduce flujo paralelo: si la ruta es /calendario o /documentos
// pero no está completamente resoluble, se delega a CuentaHomePage para resolver sesión.
//
// ✅ AJUSTE (enero 2026):
// - Integra rutas nombradas AUTH (forgot + registro) sin romper el router canónico.
// - Mantiene AtenaDeeplink como ÚNICA fuente de verdad para parseo deeplink.
// - Si el nombre de ruta es desconocido: gateway best-effort con sesión (CuentaHomePage).
//
// ✅ EXTRA (enero 2026):
// - Enriquecimiento desde settings.arguments (Map o AtenaDeeplink) SOLO para completar faltantes,
//   sin re-parsear query ni duplicar lógica.
// - Prioridad práctica: settings.name (parse) -> settings.arguments (fill missing) -> sesión (gateway).
//
// ✅ NUEVO (feb 2026):
// - Ruta nombrada: /institucion/plan (gestión de plan desde InstitucionMenuPage).
// - Toma arguments Map: { ownerAccountId, institucionPerfilId, institucionNombre?, planStatus? } (case-insensitive / aliases).
// - Si faltan datos, cae a gateway best-effort.
//
// ✅ NUEVO (feb 2026):
// - Ruta nombrada: /institucion/perfil (perfil institucional + perfil público).
// - Toma arguments Map: { ownerAccountId, institucionPerfilId, institucionNombre?, institucionInicial? }.
// - institucionInicial (si viene) debe ser Institucion (modelo) para evitar fetch inicial.
// - Si faltan datos, cae a gateway best-effort.
//
// ✅ FIX CRÍTICO (feb 2026):
// - El fallback gateway YA NO manda a instituciones a CuentaHomePage.
//   Si SessionService.role == institucion, cae a InstitucionMenuPage usando:
//   - institucionPerfilId = SessionService.userId
//   - ownerAccountId = CuentaService.sesion_cuenta (o instOwner best-effort)
//   Esto cierra el bug “institución cae a Perfiles” ante rutas incompletas/desconocidas.
//
// ✅ HARDENING EXTRA (feb 2026 · canónico E2E):
// - Normaliza IDs (trim + sin whitespace interno) al leer arguments y al validar owner/perfil.
// - No forwardea URLs absolutas como initialDeeplink al gateway.
//
// ✅ i18n + Theme (canon):
// - Este router NO hardcodea strings de UI. Si necesita mostrar “ruta no reconocida / error”
//   lo hace sin textos (para no inventar keys ARB en el router).
//

import 'package:flutter/material.dart';

import 'atena_deeplink.dart';

// Pantallas
import '../screens/alumnos/alumno_calendario_page.dart';
import '../screens/alumnos/alumno_documentos_page.dart';
import '../screens/cuentas/cuenta_home_page.dart';

// ✅ Institución: Plan (gestión)
import '../screens/instituciones/institucion_plan_page.dart';

// ✅ Institución: Perfil
import '../screens/instituciones/institucion_perfil_page.dart';

// ✅ Institución: Menú (fallback rol institución)
import '../screens/instituciones/institucion_menu_page.dart';

// Auth (forgot + registro)
import '../screens/auth/alumno_forgot_password_page.dart';
import '../screens/auth/institucion_forgot_password_page.dart';
import '../screens/auth/alumno_registro_page.dart';

// Modelos (para tipar institucionInicial en /institucion/perfil)
import '../models/instituciones/instituciones_integrado.dart';

// Servicios
import '../services/cuenta_service.dart';
import '../services/session_service.dart';

class AtenaRouter {
  // =========================
  // Helpers
  // =========================

  static String _s(dynamic v) => (v ?? '').toString().trim();

  static bool _lowerEq(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  /// IDs: trim + elimina whitespace interno (key/lookup estable) – consistente con services.
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  /// Canoniza settings.name SIN romper URLs absolutas.
  /// - Si viene absoluto (https://... o scheme://...), no se le agrega "/" (lo parsea AtenaDeeplink).
  /// - Si viene relativo (calendario?...), se le agrega "/" para tener forma de ruta.
  static String _canonicalizeSettingsName(RouteSettings settings) {
    final raw = _s(settings.name);
    if (raw.isEmpty) return '/';

    // ✅ NO romper URLs absolutas
    if (raw.contains('://')) return raw;

    // ✅ tolerar "#/ruta?...":
    if (raw.startsWith('#')) return raw;

    if (!raw.startsWith('/')) return '/$raw';
    return raw;
  }

  /// Extrae PATH puro para comparar rutas nombradas (auth / institucion),
  /// tolerando:
  /// - "#/ruta?x=y"   -> "/ruta"
  /// - "/ruta?x=y"    -> "/ruta"
  /// - "ruta?x=y"     -> "/ruta"
  /// - "/ruta#..."    -> "/ruta"
  static String _normalizeToPath(String routeName) {
    var n = _s(routeName);
    if (n.isEmpty) return '/';

    // Si viene absoluto, devolvemos tal cual (no aplica a rutas nombradas).
    if (n.contains('://')) return n;

    // Hash-route: "#/x" o "#x"
    if (n.startsWith('#')) n = n.substring(1);

    // Si quedó "ruta?..." sin "/", agregamos.
    if (n.isNotEmpty && !n.startsWith('/')) n = '/$n';

    // Cortar query/hash
    final q = n.indexOf('?');
    if (q >= 0) n = n.substring(0, q);

    final h = n.indexOf('#');
    if (h >= 0) n = n.substring(0, h);

    if (n.isEmpty) return '/';
    return n;
  }

  static bool _hasCanonOwnerPerfil(AtenaDeeplink dl) {
    final o = _normIdKey(_s(dl.ownerAccountId));
    final p = _normIdKey(_s(dl.perfilId));
    return o.isNotEmpty && p.isNotEmpty;
  }

  static String? _pickArgString(Map<dynamic, dynamic> args, List<String> keys) {
    for (final k in keys) {
      for (final entry in args.entries) {
        final kk = _s(entry.key);
        if (kk.isEmpty) continue;
        if (_lowerEq(kk, k)) {
          final vv = _s(entry.value);
          final n = _normIdKey(vv);
          if (n.isNotEmpty) return n;
        }
      }
    }
    return null;
  }

  /// Completa SOLO faltantes en un deeplink ya parseado.
  /// No re-parsea query. No inventa datos.
  static AtenaDeeplink _enrichFromArguments(AtenaDeeplink dl, Object? args) {
    if (args == null) return dl;

    if (args is AtenaDeeplink) {
      final nextPerfil = _s(dl.perfilId).isNotEmpty
          ? dl.perfilId
          : args.perfilId;
      final nextOwner = _s(dl.ownerAccountId).isNotEmpty
          ? dl.ownerAccountId
          : args.ownerAccountId;

      return AtenaDeeplink(
        path: dl.path,
        perfilId: _normIdKey(_s(nextPerfil)).isEmpty
            ? null
            : _normIdKey(_s(nextPerfil)),
        ownerAccountId: _normIdKey(_s(nextOwner)).isEmpty
            ? null
            : _normIdKey(_s(nextOwner)),
        dateKey: _s(dl.dateKey).isNotEmpty ? dl.dateKey : args.dateKey,
        itemId: _s(dl.itemId).isNotEmpty ? dl.itemId : args.itemId,
        documentoId: _s(dl.documentoId).isNotEmpty
            ? dl.documentoId
            : args.documentoId,
        solicitudId: _s(dl.solicitudId).isNotEmpty
            ? dl.solicitudId
            : args.solicitudId,
        qp: dl.qp,
        qpAll: dl.qpAll,
      );
    }

    if (args is Map) {
      final map = args.cast<dynamic, dynamic>();

      final owner = _pickArgString(map, const <String>[
        'ownerAccountId',
        'ownerId',
        'cuentaId',
        'accountId',
      ]);
      final perfil = _pickArgString(map, const <String>[
        'perfilId',
        'perfil',
        'pid',
      ]);

      final date = _s(
        _pickArgString(map, const <String>['date', 'fecha', 'dateKey']) ?? '',
      );
      final item = _pickArgString(map, const <String>[
        'itemId',
        'item',
        'eventId',
        'id',
      ]);

      final solicitud = _pickArgString(map, const <String>[
        'solicitudId',
        'solicitud',
        'requestId',
      ]);
      final documento = _pickArgString(map, const <String>[
        'documentoId',
        'documento',
        'docId',
      ]);

      final nextPerfil = _s(dl.perfilId).isNotEmpty ? dl.perfilId : perfil;
      final nextOwner = _s(dl.ownerAccountId).isNotEmpty
          ? dl.ownerAccountId
          : owner;

      return AtenaDeeplink(
        path: dl.path,
        perfilId: _normIdKey(_s(nextPerfil)).isEmpty
            ? null
            : _normIdKey(_s(nextPerfil)),
        ownerAccountId: _normIdKey(_s(nextOwner)).isEmpty
            ? null
            : _normIdKey(_s(nextOwner)),
        dateKey: _s(dl.dateKey).isNotEmpty
            ? dl.dateKey
            : (date.isEmpty ? null : date),
        itemId: _s(dl.itemId).isNotEmpty ? dl.itemId : item,
        documentoId: _s(dl.documentoId).isNotEmpty ? dl.documentoId : documento,
        solicitudId: _s(dl.solicitudId).isNotEmpty ? dl.solicitudId : solicitud,
        qp: dl.qp,
        qpAll: dl.qpAll,
      );
    }

    return dl;
  }

  /// Para evitar loops: solo reenviamos initialDeeplink al gateway cuando
  /// la ruta es un deeplink "canónico" (calendario/documentos) o una ruta con query.
  static bool _shouldForwardInitialDeeplinkToGateway(String raw) {
    final safeRaw = _s(raw);
    if (safeRaw.isEmpty || safeRaw == '/') return false;

    // ✅ NO forwardear URLs absolutas como deeplink al gateway.
    if (safeRaw.contains('://')) return false;

    // Si tiene query, típicamente es deeplink.
    if (safeRaw.contains('?')) return true;

    final path = _normalizeToPath(safeRaw);

    // Deeplinks canónicos que CuentaHome puede resolver.
    if (path == '/calendario' || path == '/documentos') return true;

    // Rutas nombradas (auth / institucion/plan / institucion/perfil) NO deben reenviarse como deeplink.
    return false;
  }

  // =========================
  // Router
  // =========================

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    try {
      final nameForParse = _canonicalizeSettingsName(settings);

      // ✅ Rutas AUTH (no deeplink) – manejar antes del parser canónico
      final authRoute = _maybeBuildAuthRoute(settings, nameForParse);
      if (authRoute != null) return authRoute;

      // ✅ Rutas Institución (no deeplink)
      final instRoute = _maybeBuildInstitucionRoute(settings, nameForParse);
      if (instRoute != null) return instRoute;

      // ✅ ÚNICA fuente de parsing (deeplinks / rutas canónicas)
      var dl = AtenaDeeplink.parse(nameForParse);

      // ✅ Enriquecer con argumentos SOLO para completar faltantes
      dl = _enrichFromArguments(dl, settings.arguments);

      // ✅ Canonizar qp reservados si caller proveyó owner/perfil (ya normalizados)
      dl = dl.ensureCanonico(
        ownerAccountId: dl.ownerAccountId,
        perfilId: dl.perfilId,
      );

      if (dl.isCalendario) {
        if (!_hasCanonOwnerPerfil(dl)) {
          return _fallbackGateway(settings, nameForParse);
        }
        return _buildCalendarioRoute(settings: settings, deeplink: dl);
      }

      if (dl.isDocumentos) {
        if (!_hasCanonOwnerPerfil(dl)) {
          return _fallbackGateway(settings, nameForParse);
        }
        return _buildDocumentosRoute(settings: settings, deeplink: dl);
      }

      return _fallbackGateway(settings, nameForParse);
    } catch (e) {
      return _errorRoute(
        message: e.toString().replaceFirst('Exception: ', ''),
        settings: settings,
      );
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    final safe = _canonicalizeSettingsName(settings);

    final authRoute = _maybeBuildAuthRoute(settings, safe);
    if (authRoute != null) return authRoute;

    final instRoute = _maybeBuildInstitucionRoute(settings, safe);
    if (instRoute != null) return instRoute;

    return _fallbackGateway(settings, safe);
  }

  // =========================
  // AUTH routes (forgot + registro alumno)
  // =========================

  static Route<dynamic>? _maybeBuildAuthRoute(
    RouteSettings settings,
    String routeName,
  ) {
    final n = _normalizeToPath(routeName);

    // Permitir recibir argumentos como String (email) o Map {initialEmail: ...}
    String? extractInitialEmail(Object? args) {
      if (args == null) return null;
      if (args is String) {
        final s = args.trim();
        return s.isEmpty ? null : s;
      }
      if (args is Map) {
        final map = args.cast<dynamic, dynamic>();
        final v = map['initialEmail'];
        final s = (v ?? '').toString().trim();
        return s.isEmpty ? null : s;
      }
      return null;
    }

    // ✅ Registro alumno NO recibe initialEmail (por ahora).
    // Acepta deeplink opcional para continuar flujo (si caller lo manda).
    String? extractDeeplink(Object? args) {
      if (args == null) return null;
      if (args is String) {
        final s = args.trim();
        return s.isEmpty ? null : s;
      }
      if (args is Map) {
        final map = args.cast<dynamic, dynamic>();
        final v =
            map['deeplink'] ??
            map['initialDeeplink'] ??
            map['route'] ??
            map['name'];
        final s = (v ?? '').toString().trim();
        return s.isEmpty ? null : s;
      }
      return null;
    }

    if (n == '/alumno_forgot_password') {
      final seed = extractInitialEmail(settings.arguments);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AlumnoForgotPasswordPage(initialEmail: seed),
      );
    }

    if (n == '/institucion_forgot_password') {
      final seed = extractInitialEmail(settings.arguments);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => InstitucionForgotPasswordPage(initialEmail: seed),
      );
    }

    // ✅ Registro alumno por ruta nombrada
    if (n == '/alumno_registro') {
      final dl = extractDeeplink(settings.arguments);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AlumnoRegistroPage(deeplink: dl),
      );
    }

    return null;
  }

  // =========================
  // INSTITUCIÓN routes (plan + perfil)
  // =========================

  static Route<dynamic>? _maybeBuildInstitucionRoute(
    RouteSettings settings,
    String routeName,
  ) {
    final n = _normalizeToPath(routeName);

    if (n == '/institucion/plan') {
      String? owner;
      String? perfil;
      String? nombre;

      final args = settings.arguments;

      if (args is Map) {
        final map = args.cast<dynamic, dynamic>();

        owner = _pickArgString(map, const <String>[
          'ownerAccountId',
          'ownerId',
          'cuentaId',
          'accountId',
        ]);

        perfil = _pickArgString(map, const <String>[
          // ✅ prioridad: perfilId institución (canónico)
          'institucionPerfilId',
          // ✅ alias tolerantes
          'perfilId',
          'institucionId',
          'pid',
          'id',
        ]);

        // Nombre NO necesita normIdKey (puede tener espacios).
        for (final entry in map.entries) {
          final kk = _s(entry.key);
          if (kk.isEmpty) continue;
          if (_lowerEq(kk, 'institucionNombre') ||
              _lowerEq(kk, 'nombre') ||
              _lowerEq(kk, 'name')) {
            final vv = _s(entry.value);
            if (vv.isNotEmpty) {
              nombre = vv;
              break;
            }
          }
        }

        // ✅ Importante: NO consumimos/quitamos planStatus del map.
      }

      final o = _normIdKey(_s(owner));
      final p = _normIdKey(_s(perfil));

      if (o.isEmpty || p.isEmpty) {
        // Sin datos suficientes: delegar al fallback (que respeta rol institución).
        return _fallbackGateway(settings, routeName);
      }

      final nInst = _s(nombre);

      return MaterialPageRoute(
        settings: settings, // ✅ preserva arguments completos (incl. planStatus)
        builder: (_) => InstitucionPlanPage.manage(
          ownerAccountId: o,
          institucionPerfilId: p,
          institucionNombre: nInst.isEmpty ? null : nInst,
        ),
      );
    }

    if (n == '/institucion/perfil') {
      String? owner;
      String? perfil;
      Institucion? instInicial;

      final args = settings.arguments;

      if (args is Map) {
        final map = args.cast<dynamic, dynamic>();

        owner = _pickArgString(map, const <String>[
          'ownerAccountId',
          'ownerId',
          'cuentaId',
          'accountId',
        ]);

        perfil = _pickArgString(map, const <String>[
          // ✅ prioridad: perfilId institución (canónico)
          'institucionPerfilId',
          // ✅ alias tolerantes
          'perfilId',
          'institucionId',
          'pid',
          'id',
        ]);

        // ✅ Institucion inicial (opcional) para evitar fetch
        final seed =
            map['institucionInicial'] ?? map['institucion'] ?? map['inst'];
        if (seed is Institucion) instInicial = seed;
      }

      final o = _normIdKey(_s(owner));
      final p = _normIdKey(_s(perfil));

      if (o.isEmpty || p.isEmpty) {
        return _fallbackGateway(settings, routeName);
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => InstitucionPerfilPage(
          ownerAccountId: o,
          institucionPerfilId: p,
          institucionInicial: instInicial,
        ),
      );
    }

    return null;
  }

  // =========================
  // Fallback / Gateway (respeta rol)
  // =========================

  static Future<_FallbackDecision> _resolveFallbackDecision() async {
    // 0) Intentar session v2 primero (rol real)
    SessionData? session;
    try {
      session = await SessionService.getSession();
    } catch (_) {
      session = null;
    }

    // 1) Siempre intentar leer sesion_cuenta (owner) – puede existir también en institución
    String ownerAccountId = '';
    try {
      ownerAccountId = _s(await CuentaService.getSesionCuentaId());
    } catch (_) {
      ownerAccountId = '';
    }

    if (session != null && session.role == SessionRole.institucion) {
      final instPerfilId = _s(session.userId);

      // Si owner falta en institución, usamos instOwner best-effort
      if (ownerAccountId.isEmpty) {
        try {
          ownerAccountId = _s(
            await SessionService.getInstitucionOwnerAccountIdLogueado(),
          );
        } catch (_) {
          ownerAccountId = '';
        }
      }

      return _FallbackDecision(
        role: SessionRole.institucion,
        ownerAccountId: _normIdKey(ownerAccountId),
        institucionPerfilId: _normIdKey(instPerfilId),
      );
    }

    // CUENTA (o sin rol)
    return _FallbackDecision(
      role: session?.role,
      ownerAccountId: _normIdKey(ownerAccountId),
      institucionPerfilId: '',
    );
  }

  static Route<dynamic> _fallbackGateway(RouteSettings settings, String raw) {
    final rr = _s(raw).isEmpty ? '/' : _s(raw);

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => FutureBuilder<_FallbackDecision>(
        future: _resolveFallbackDecision(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final d = snap.data;

          // ✅ INSTITUCIÓN: nunca caer a CuentaHomePage
          if (d != null && d.role == SessionRole.institucion) {
            final o = _normIdKey(_s(d.ownerAccountId));
            final p = _normIdKey(_s(d.institucionPerfilId));

            if (o.isNotEmpty && p.isNotEmpty) {
              return InstitucionMenuPage(
                ownerAccountId: o,
                institucionPerfilId: p,
                institucionNombre: null,
              );
            }

            // Sin inventar textos/key ARB: mostramos solo el raw route.
            return Scaffold(
              appBar: AppBar(),
              body: Padding(padding: const EdgeInsets.all(16), child: Text(rr)),
            );
          }

          // ✅ CUENTA: gateway canónico
          final owner = _normIdKey(_s(d?.ownerAccountId));

          if (owner.isNotEmpty) {
            final forward = _shouldForwardInitialDeeplinkToGateway(rr);
            return CuentaHomePage(
              cuentaId: owner,
              initialDeeplink: forward ? rr : null,
            );
          }

          return Scaffold(
            appBar: AppBar(),
            body: Padding(padding: const EdgeInsets.all(16), child: Text(rr)),
          );
        },
      ),
    );
  }

  // =========================
  // Rutas específicas
  // =========================

  static Route<dynamic> _buildCalendarioRoute({
    required RouteSettings settings,
    required AtenaDeeplink deeplink,
  }) {
    final owner = _normIdKey(_s(deeplink.ownerAccountId));
    final perfil = _normIdKey(_s(deeplink.perfilId));

    if (owner.isEmpty || perfil.isEmpty) {
      return _fallbackGateway(settings, deeplink.toRouteString());
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AlumnoCalendarioPage(
        ownerAccountId: owner,
        perfilId: perfil,
        initialDateKey: deeplink.dateKey,
        initialItemId: deeplink.itemId,
      ),
    );
  }

  static Route<dynamic> _buildDocumentosRoute({
    required RouteSettings settings,
    required AtenaDeeplink deeplink,
  }) {
    final owner = _normIdKey(_s(deeplink.ownerAccountId));
    final perfil = _normIdKey(_s(deeplink.perfilId));

    if (owner.isEmpty || perfil.isEmpty) {
      return _fallbackGateway(settings, deeplink.toRouteString());
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AlumnoDocumentosPage(
        ownerAccountId: owner,
        perfilId: perfil,
        initialDocumentoId: deeplink.documentoId,
        initialSolicitudId: deeplink.solicitudId,
      ),
    );
  }

  // =========================
  // Error
  // =========================

  static Route<dynamic> _errorRoute({
    required String message,
    required RouteSettings settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(),
        body: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
      ),
    );
  }
}

// =============================================================================
// Fallback decision DTO
// =============================================================================

class _FallbackDecision {
  final SessionRole? role;
  final String ownerAccountId;
  final String institucionPerfilId;

  const _FallbackDecision({
    required this.role,
    required this.ownerAccountId,
    required this.institucionPerfilId,
  });
}
