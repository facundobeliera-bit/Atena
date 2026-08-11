// lib/routes/atena_deeplink.dart
//
// ATENA – Deeplink parser (CANÓNICO)
// Soporta (mínimo real):
// - /calendario?perfilId=...&date=YYYY-MM-DD&itemId=...
// - /documentos?perfilId=...(&documentoId=...)
// - /documentos?perfilId=...(&solicitudId=...) ✅
//
// Objetivo:
// - Parseo robusto (acepta Uri completo o path+query)
// - Normaliza dateKey a YYYY-MM-DD cuando sea posible
// - NO depende de Flutter widgets (solo dart:core)
//
// Hardening (enero 2026):
// - Keys case-insensitive.
// - Tolerante a hash routes (#/ruta?...).
// - Si input es absoluto y trae fragment con ruta, usa fragment.
// - Si hay keys duplicadas y la primera viene vacía, prefiere la no vacía.
// - Preserva query params extras (qp / qpAll).
//
// ✅ FIX/MEJORA (enero 2026):
// - ensureCanonico(...): ahora fuerza owner/perfil también cuando YA existe pero difiere
//   (si caller lo provee explícitamente, esa es la fuente de verdad).
// - ensureCanonicoString(...): preserva el path original, pero garantiza reserved keys
//   coherentes con toRouteString.
// - parse(...): tolera inputs tipo "/#/ruta?x=1" y "ruta?x=1" (web hash).
// - toRouteString(...): no duplica reservadas y mantiene extras.
//
// ✅ FIX (feb 2026):
// - Normaliza ids (trim + sin whitespace interno) para compat con services.
// - ensureCanonico(): si el objeto tenía campos perfilId/ownerAccountId pero qp traía
//   otro valor, el caller manda; además actualiza también los campos del objeto.
// - toRouteString(): no elimina extras accidentales con mismo casing que reservadas;
//   las elimina case-insensitive (como antes), pero vuelve a setear reservadas al final.
// - parse(): tolera inputs tipo "https://x/#/ruta?..." o "x/#/ruta?..."
// - parse(): robustez extra para query con ';' (algunas integraciones web).
//
// ✅ HARDENING EXTRA (feb 2026 · canónico E2E):
// - ensureCanonico(): si caller pasa owner/perfil, SIEMPRE repara qp/qpAll aunque
//   this.perfilId/this.ownerAccountId ya coincidan (evita objeto inconsistente).
//
// Nota: este archivo NO debe depender de Flutter.
//

class AtenaDeeplink {
  final String path;
  final String? perfilId;
  final String? ownerAccountId;

  final String? dateKey;
  final String? itemId;

  final String? documentoId;
  final String? solicitudId;

  /// Query params "best value" (key casing preservado por primer key visto).
  final Map<String, String> qp;

  /// Query params "all values" (key casing preservado por primer key visto).
  final Map<String, List<String>> qpAll;

  const AtenaDeeplink({
    required this.path,
    this.perfilId,
    this.ownerAccountId,
    this.dateKey,
    this.itemId,
    this.documentoId,
    this.solicitudId,
    this.qp = const <String, String>{},
    this.qpAll = const <String, List<String>>{},
  });

  bool get isCalendario => _canonPath(path) == '/calendario';
  bool get isDocumentos => _canonPath(path) == '/documentos';

  // =====================================================
  // Normalización básica
  // =====================================================

  static String _canonPath(String rawPath) {
    var p = _norm(rawPath).toLowerCase();
    if (p.isEmpty) return '/';
    if (!p.startsWith('/')) p = '/$p';
    while (p.contains('//')) {
      p = p.replaceAll('//', '/');
    }
    while (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  static String _norm(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? '' : s;
  }

  static String _normKeyLower(String k) => _norm(k).toLowerCase();

  static bool _lowerEq(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  static String _safeDecode(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    try {
      return Uri.decodeQueryComponent(t);
    } catch (_) {
      return t;
    }
  }

  static String _safeEncode(String s) {
    try {
      return Uri.encodeQueryComponent(s);
    } catch (_) {
      return s;
    }
  }

  /// IDs: trim + elimina whitespace interno (key/lookup estable) – consistente con services.
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  // =====================================================
  // API principal (sin cambios de contrato)
  // =====================================================

  AtenaDeeplink ensureCanonico({String? ownerAccountId, String? perfilId}) {
    if (!isCalendario && !isDocumentos) return this;

    final oid = _normIdKey(_norm(ownerAccountId));
    final pid = _normIdKey(_norm(perfilId));

    final nextQp = Map<String, String>.from(qp);
    final nextQpAll = <String, List<String>>{};
    qpAll.forEach((k, list) {
      nextQpAll[k] = List<String>.from(list);
    });

    void forceSet(String key, String value) {
      final v = _normIdKey(_norm(value));
      if (v.isEmpty) return;

      // Remover duplicados por casing
      nextQp.removeWhere((k, _) => _lowerEq(k, key));
      nextQpAll.removeWhere((k, _) => _lowerEq(k, key));

      // Set canónico (casing estable del key reservado)
      nextQp[key] = v;
      nextQpAll[key] = <String>[v];
    }

    // ✅ HARDENING E2E:
    // Si caller pasa owner/perfil, SIEMPRE forzamos qp/qpAll (aunque ya coincida).
    if (pid.isNotEmpty) {
      forceSet('perfilId', pid);
    }
    if (oid.isNotEmpty) {
      forceSet('ownerAccountId', oid);
    }

    final perfilFinal = pid.isNotEmpty
        ? pid
        : (_normIdKey(_norm(this.perfilId)).isEmpty
              ? null
              : _normIdKey(_norm(this.perfilId)));

    final ownerFinal = oid.isNotEmpty
        ? oid
        : (_normIdKey(_norm(this.ownerAccountId)).isEmpty
              ? null
              : _normIdKey(_norm(this.ownerAccountId)));

    // Exclusión: si hay solicitudId, documentoId no aplica
    final sid = _normIdKey(_norm(solicitudId));
    final docFinal = sid.isNotEmpty ? null : documentoId;

    return AtenaDeeplink(
      path: path,
      perfilId: perfilFinal,
      ownerAccountId: ownerFinal,
      dateKey: dateKey,
      itemId: itemId,
      documentoId: docFinal,
      solicitudId: solicitudId,
      qp: nextQp,
      qpAll: nextQpAll,
    );
  }

  String toRouteString({String? forcePath}) {
    final pCanon = _canonPath(forcePath ?? path);

    // 1) Partimos de extras
    final params = <String, String>{};
    params.addAll(qp);

    // 2) Evitar duplicados por casing para claves reservadas
    void removeReserved(String key) {
      params.removeWhere((k, _) => _lowerEq(k, key));
    }

    removeReserved('perfilId');
    removeReserved('ownerAccountId');
    removeReserved('date');
    removeReserved('itemId');
    removeReserved('solicitudId');
    removeReserved('documentoId');

    // 3) Set canónico de claves reservadas (casing estable)
    final pid = _normIdKey(_norm(perfilId));
    if (pid.isNotEmpty) params['perfilId'] = pid;

    final oid = _normIdKey(_norm(ownerAccountId));
    if (oid.isNotEmpty) params['ownerAccountId'] = oid;

    if (pCanon == '/calendario') {
      final d = _norm(dateKey);
      final it = _normIdKey(_norm(itemId));
      if (d.isNotEmpty) params['date'] = d;
      if (it.isNotEmpty) params['itemId'] = it;
    }

    if (pCanon == '/documentos') {
      final sid = _normIdKey(_norm(solicitudId));
      final did = _normIdKey(_norm(documentoId));

      if (sid.isNotEmpty) {
        params['solicitudId'] = sid;
      } else if (did.isNotEmpty) {
        params['documentoId'] = did;
      }
    }

    if (params.isEmpty) return pCanon;

    final q = params.entries
        .map((e) => '${_safeEncode(e.key)}=${_safeEncode(e.value)}')
        .join('&');

    return '$pCanon?$q';
  }

  static String ensureCanonicoString(
    String raw, {
    String? ownerAccountId,
    String? perfilId,
  }) {
    final d = AtenaDeeplink.parse(
      raw,
    ).ensureCanonico(ownerAccountId: ownerAccountId, perfilId: perfilId);
    return d.toRouteString();
  }

  // =====================================================
  // PARSE (robusto, canónico)
  // =====================================================

  static AtenaDeeplink parse(String input) {
    final raw = _norm(input);
    if (raw.isEmpty) {
      return const AtenaDeeplink(path: '/');
    }

    // 1) Normalizar hash-routes (#/ruta?... o #ruta?...):
    var candidate = raw;

    // Tolerar casos tipo "https://x/#/ruta?..." o "x/#/ruta?..."
    try {
      final idxHash = candidate.indexOf('#');
      if (idxHash >= 0 && idxHash < candidate.length - 1) {
        final frag = candidate.substring(idxHash + 1).trim();
        if (frag.isNotEmpty) {
          if (frag.startsWith('/') ||
              frag.contains('?') ||
              frag.contains('/')) {
            candidate = frag;
          }
        }
      }
    } catch (_) {}

    // ✅ HARDENING: tolera "/#/ruta?x=1" y "/#ruta?x=1"
    if (candidate.startsWith('/#/')) {
      candidate = candidate.substring(2); // "/#"
    } else if (candidate.startsWith('/#')) {
      candidate = candidate.substring(2); // "/#"
      if (!candidate.startsWith('/')) candidate = '/$candidate';
    }

    // 2) Intentar parsear como Uri (absoluto o relativo)
    Uri? uri;
    try {
      uri = Uri.tryParse(candidate);
    } catch (_) {
      uri = null;
    }

    // Si es absoluto y trae fragment con ruta, usar fragment.
    if (uri != null && uri.hasScheme) {
      final frag = _norm(uri.fragment);
      if (frag.isNotEmpty && (frag.startsWith('/') || frag.contains('?'))) {
        candidate = frag;
        try {
          uri = Uri.tryParse(candidate);
        } catch (_) {
          uri = null;
        }
      }
    }

    // Fallback manual si Uri no pudo parsear bien.
    final String pathRaw;
    final String queryRaw;
    if (uri == null) {
      final parts = candidate.split('?');
      pathRaw = parts.isNotEmpty ? parts.first : '/';
      queryRaw = parts.length > 1 ? parts.sublist(1).join('?') : '';
    } else {
      pathRaw = uri.path.isNotEmpty ? uri.path : (candidate.split('?').first);
      queryRaw = uri.hasQuery
          ? uri.query
          : (candidate.contains('?')
                ? candidate.split('?').sublist(1).join('?')
                : '');
    }

    final pCanon = _canonPath(pathRaw);

    // 3) Parse query manual (case-insensitive + duplicates prefer non-empty)
    final parsed = _parseQueryManual(queryRaw);

    // 4) Resolver claves canónicas (case-insensitive)
    String pickOne(List<String> keysLower) {
      for (final k in keysLower) {
        final v = parsed.byLower[k];
        if (v != null && _norm(v).isNotEmpty) return v;
      }
      return '';
    }

    final perfil = _normIdKey(
      _norm(pickOne(const <String>['perfilid', 'perfil', 'pid'])),
    );

    final owner = _normIdKey(
      _norm(
        pickOne(const <String>[
          'owneraccountid',
          'ownerid',
          'cuentaid',
          'accountid',
        ]),
      ),
    );

    String normalizeDateKey(String v) {
      final t = _norm(v);
      if (t.isEmpty) return '';
      // Si viene ISO con hora, extraer YYYY-MM-DD.
      if (t.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t)) {
        return t.substring(0, 10);
      }
      // Intentar parsear y formatear a YYYY-MM-DD
      try {
        final dt = DateTime.tryParse(t);
        if (dt != null) {
          final y = dt.year.toString().padLeft(4, '0');
          final m = dt.month.toString().padLeft(2, '0');
          final d = dt.day.toString().padLeft(2, '0');
          return '$y-$m-$d';
        }
      } catch (_) {}
      return t;
    }

    final date = normalizeDateKey(
      pickOne(const <String>['date', 'fecha', 'datekey']),
    );

    final item = _normIdKey(
      _norm(pickOne(const <String>['itemid', 'item', 'eventid', 'id'])),
    );

    final solicitud = _normIdKey(
      _norm(pickOne(const <String>['solicitudid', 'solicitud', 'requestid'])),
    );

    final documento = _normIdKey(
      _norm(pickOne(const <String>['documentoid', 'documento', 'docid'])),
    );

    // Regla: si hay solicitudId, documentoId se ignora (mutuamente excluyentes en /documentos).
    final docFinal = solicitud.isNotEmpty
        ? null
        : (documento.isEmpty ? null : documento);

    // 5) Construir qp / qpAll preservando casing “primer key visto”
    final qp = parsed.qp;
    final qpAll = parsed.qpAll;

    // 6) Preparar campos por path (sin bloquear extras)
    String? dateKeyFinal;
    String? itemIdFinal;
    String? solicitudIdFinal;
    String? documentoIdFinal;

    if (pCanon == '/calendario') {
      dateKeyFinal = date.isEmpty ? null : date;
      itemIdFinal = item.isEmpty ? null : item;
    } else if (pCanon == '/documentos') {
      solicitudIdFinal = solicitud.isEmpty ? null : solicitud;
      documentoIdFinal = docFinal;
    }

    return AtenaDeeplink(
      path: pCanon,
      perfilId: perfil.isEmpty ? null : perfil,
      ownerAccountId: owner.isEmpty ? null : owner,
      dateKey: dateKeyFinal,
      itemId: itemIdFinal,
      documentoId: documentoIdFinal,
      solicitudId: solicitudIdFinal,
      qp: qp,
      qpAll: qpAll,
    );
  }

  // =====================================================
  // Query parse manual (case-insensitive + dedup prefer non-empty)
  // =====================================================

  static _ParsedQuery _parseQueryManual(String queryRaw) {
    final q0 = _norm(queryRaw);
    if (q0.isEmpty) {
      return const _ParsedQuery(
        qp: <String, String>{},
        qpAll: <String, List<String>>{},
        byLower: <String, String>{},
      );
    }

    // ✅ Algunos entornos (web/interop) traen ';' como separador.
    final q = q0.replaceAll(';', '&');

    // Internos por lowerKey
    final originalKeyByLower = <String, String>{};
    final allByLower = <String, List<String>>{};
    final bestByLower = <String, String>{};

    void addKV(String kRaw, String vRaw) {
      final k = _safeDecode(kRaw);
      final v = _safeDecode(vRaw);

      final kTrim = _norm(k);
      if (kTrim.isEmpty) return;

      final lower = _normKeyLower(kTrim);
      final originalKey = originalKeyByLower.putIfAbsent(lower, () => kTrim);

      final list = allByLower.putIfAbsent(lower, () => <String>[]);
      list.add(v);

      // Best-effort: si el actual es vacío y el nuevo es no vacío, reemplazar.
      final prev = bestByLower[lower];
      final prevNorm = _norm(prev);
      final nextNorm = _norm(v);

      if (prev == null) {
        bestByLower[lower] = v;
      } else if (prevNorm.isEmpty && nextNorm.isNotEmpty) {
        bestByLower[lower] = v;
      }
      // Si ambos no vacíos, nos quedamos con el primero (estabilidad).
      // Si ambos vacíos, no importa.
      // Nota: mantenemos casing del primer key visto, aunque luego venga con casing distinto.
      originalKeyByLower[lower] = originalKey;
    }

    final parts = q.split('&');
    for (final part in parts) {
      final p = part.trim();
      if (p.isEmpty) continue;

      final eq = p.indexOf('=');
      if (eq < 0) {
        addKV(p, '');
      } else {
        final k = p.substring(0, eq);
        final v = p.substring(eq + 1);
        addKV(k, v);
      }
    }

    // Materializar con casing del primer key visto
    final qp = <String, String>{};
    final qpAll = <String, List<String>>{};
    final byLower = <String, String>{};

    originalKeyByLower.forEach((lower, origKey) {
      final best = bestByLower[lower] ?? '';
      qp[origKey] = best;
      qpAll[origKey] = List<String>.from(allByLower[lower] ?? const <String>[]);
      byLower[lower] = best;
    });

    return _ParsedQuery(qp: qp, qpAll: qpAll, byLower: byLower);
  }
}

class _ParsedQuery {
  final Map<String, String> qp;
  final Map<String, List<String>> qpAll;

  /// Lookup case-insensitive (lowerKey -> bestValue)
  final Map<String, String> byLower;

  const _ParsedQuery({
    required this.qp,
    required this.qpAll,
    required this.byLower,
  });
}
