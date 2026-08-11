// lib/screens/alumnos/alumno_calendario_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

import '../../routes/atena_deeplink.dart';
import '../../services/alumno_service.dart';
import '../../services/alumno_calendario_interacciones_service.dart';

class AlumnoCalendarioPage extends StatefulWidget {
  final String ownerAccountId;
  final String perfilId;

  /// ✅ Deeplink support (canónico):
  /// /calendario?perfilId=...&date=YYYY-MM-DD&itemId=...
  final String? initialDateKey; // "YYYY-MM-DD"
  final String? initialItemId; // id del evento o de agenda personal

  const AlumnoCalendarioPage({
    super.key,
    required this.ownerAccountId,
    required this.perfilId,
    this.initialDateKey,
    this.initialItemId,
  });

  @override
  State<AlumnoCalendarioPage> createState() => _AlumnoCalendarioPageState();
}

class _AlumnoCalendarioPageState extends State<AlumnoCalendarioPage> {
  bool _cargando = true;
  String? _error;

  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _diaSeleccionado = DateTime.now();

  // RAW
  // ✅ Calendario curricular/extracurricular: AlumnoCalendarioInteraccionesService (canónico)
  // ✅ Agenda personal: AlumnoService (canónico)
  List<Map<String, dynamic>> _eventosCalendario = [];
  List<Map<String, dynamic>> _agendaPersonal = [];

  // Filtros UI
  bool _showCurricular = true;
  bool _showExtracurricular = true;
  bool _showPersonal = true;

  // ✅ Focus deeplink
  String? _focusItemId;
  bool _focusDateResolved = false;
  bool _focusScrollDone = false;
  bool _focusScrollScheduled = false;

  // ✅ Keys por ítem (para scroll determinista) — se limpia por día (y se poda)
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  AppLocalizations get _l10n => AppLocalizations.of(context);

  // ✅ Normalización canónica de IDs (misma idea que router/services): trim + sin whitespace interno
  String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  GlobalKey _keyForItem(String id) {
    final safeId = id.trim();
    if (safeId.isEmpty) {
      return GlobalKey(
        debugLabel: 'cal_item_empty_${DateTime.now().microsecondsSinceEpoch}',
      );
    }
    final k = _itemKeys[safeId];
    if (k != null) return k;
    final nk = GlobalKey(debugLabel: 'cal_item_$safeId');
    _itemKeys[safeId] = nk;
    return nk;
  }

  void _pruneItemKeys(Set<String> keepIds) {
    if (_itemKeys.isEmpty) return;
    final remove = <String>[];
    _itemKeys.forEach((k, value) {
      if (!keepIds.contains(k)) remove.add(k);
    });
    for (final id in remove) {
      _itemKeys.remove(id);
    }
  }

  void _onSelectDay(DateTime day) {
    setState(() {
      _diaSeleccionado = day;
      _itemKeys.clear();

      _focusItemId = null;
      _focusScrollDone = true;
      _focusScrollScheduled = false;
      _focusDateResolved = true;
    });
  }

  @override
  void initState() {
    super.initState();

    final dk = (widget.initialDateKey ?? '').trim();
    final iid = (widget.initialItemId ?? '').trim();

    if (dk.isNotEmpty) {
      final d = _parseDateKey(dk);
      _diaSeleccionado = d;
      _mesActual = DateTime(d.year, d.month, 1);
      _focusDateResolved = true;
    }

    _focusItemId = iid.isNotEmpty ? iid : null;

    unawaited(_cargar());
  }

  // =====================================================
  // DATE HELPERS (backend-ready)
  // =====================================================

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _parseDateKey(String s) {
    final t = s.trim();
    final p = t.split('-');
    if (p.length == 3) {
      final y = int.tryParse(p[0]) ?? 1970;
      final m = int.tryParse(p[1]) ?? 1;
      final d = int.tryParse(p[2]) ?? 1;
      return DateTime(y, m, d);
    }
    final dt = DateTime.tryParse(t);
    return dt ?? DateTime(1970, 1, 1);
  }

  String _eventDateKey(Map<String, dynamic> e) {
    final v = e['date'] ?? e['fecha'] ?? e['dia'] ?? e['fechaIso'];
    if (v == null) return '';

    if (v is DateTime) return _dateKey(v);
    if (v is int) {
      try {
        return _dateKey(DateTime.fromMillisecondsSinceEpoch(v));
      } catch (_) {
        return '';
      }
    }

    final s = v.toString().trim();
    if (s.isEmpty) return '';

    final dt = DateTime.tryParse(s);
    if (dt != null) return _dateKey(dt);

    if (s.length >= 10 && s[4] == '-' && s[7] == '-') return s.substring(0, 10);

    return _dateKey(_parseDateKey(s));
  }

  // =====================================================
  // Flags institución / lock / rsvp (backend-ready)
  // =====================================================

  String _normStr(dynamic v) => (v ?? '').toString().trim();

  bool _bool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is double) return v.toInt() != 0;
    final s = _normStr(v).toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  String _sourceEvento(Map<String, dynamic> e) =>
      _normStr(e['source'] ?? e['origen'] ?? e['createdBy']);

  bool _isInstitucionSource(Map<String, dynamic> e) {
    final s = _sourceEvento(e).toLowerCase();
    return s == 'institucion' || s == 'institution' || s == 'inst';
  }

  bool _isLockedEvento(Map<String, dynamic> e) {
    final locked = _bool(e['lock']) || _bool(e['locked']);
    final allowDelete = e.containsKey('allowStudentDelete')
        ? _bool(e['allowStudentDelete'])
        : true;
    final allowEdit = e.containsKey('allowStudentEdit')
        ? _bool(e['allowStudentEdit'])
        : true;

    if (_isInstitucionSource(e) &&
        !e.containsKey('allowStudentDelete') &&
        !e.containsKey('allowStudentEdit')) {
      return true;
    }

    if (locked) return true;
    if (!allowDelete && !allowEdit) return true;

    return false;
  }

  bool _allowStudentDelete(Map<String, dynamic> e) {
    if (e.containsKey('allowStudentDelete')) {
      return _bool(e['allowStudentDelete']);
    }
    return !_isInstitucionSource(e);
  }

  // =====================================================
  // ✅ FASE 2 – Evento Especial institucional (detectores tolerantes)
  // =====================================================

  bool _isEventoEspecial(Map<String, dynamic> e) {
    final tipo = _normStr(
      e['tipo'] ?? e['tipoEventoCalendario'] ?? e['eventType'],
    ).toLowerCase();
    if (tipo == 'eventoespecial' ||
        tipo == 'evento_especial' ||
        tipo == 'special') {
      return true;
    }

    final cat = _normStr(e['category'] ?? e['categoria']).toLowerCase();
    if (cat == 'especial' || cat == 'evento_especial' || cat == 'special') {
      return true;
    }

    if (_bool(e['isSpecial'], fallback: false)) return true;

    final tcal = _normStr(
      e['tipoCalendario'] ?? e['tipoEvento'] ?? '',
    ).toLowerCase();
    if (tcal == 'eventoespecial') return true;

    return false;
  }

  String _labelTipoEspecial(Map<String, dynamic> e) {
    final te = _normStr(
      e['tipoEspecial'] ?? e['specialType'] ?? e['eventoEspecialTipo'],
    ).toLowerCase();

    switch (te) {
      case 'inicioclases':
      case 'inicio_clases':
      case 'start_classes':
        return _l10n.alumnoCalendarioEspecialInicioClases;
      case 'finclases':
      case 'fin_clases':
      case 'end_classes':
        return _l10n.alumnoCalendarioEspecialFinClases;
      case 'receso':
      case 'vacaciones':
      case 'break':
      case 'recess':
        return _l10n.alumnoCalendarioEspecialReceso;
      case 'iniciociclo':
      case 'inicio_ciclo':
      case 'start_cycle':
        return _l10n.alumnoCalendarioEspecialInicioCiclo;
      case 'finciclo':
      case 'fin_ciclo':
      case 'end_cycle':
        return _l10n.alumnoCalendarioEspecialFinCiclo;
      default:
        return te.isEmpty ? '' : te;
    }
  }

  String _segmentoLabel(Map<String, dynamic> e) {
    final seg = e['segmentoEspecial'];
    if (seg is Map) {
      final m = Map<String, dynamic>.from(seg);
      final nivel = _normStr(m['nivel']);
      final turno = _normStr(m['turno']);
      final gLabel = _normStr(m['grupoLabel']);
      final gKey = _normStr(m['grupoKey']);

      final parts = <String>[];
      if (nivel.isNotEmpty) parts.add(nivel);
      if (turno.isNotEmpty) parts.add(turno);
      if (gLabel.isNotEmpty) {
        parts.add(gLabel);
      } else if (gKey.isNotEmpty) {
        parts.add(gKey);
      }
      return parts.join(' · ');
    }

    final nivel = _normStr(e['nivel']);
    final turno = _normStr(e['turno']);
    final grupo = _normStr(e['grupo'] ?? e['curso'] ?? e['sala']);

    final parts = <String>[];
    if (nivel.isNotEmpty) parts.add(nivel);
    if (turno.isNotEmpty) parts.add(turno);
    if (grupo.isNotEmpty) parts.add(grupo);

    return parts.join(' · ');
  }

  // =====================================================
  // Deeplink open (CANÓNICO)
  // =====================================================

  String _extractDeeplink(Map<String, dynamic> e) {
    final v =
        e['deeplink'] ??
        e['deepLink'] ??
        e['route'] ??
        e['ruta'] ??
        e['url'] ??
        e['link'];
    return (v ?? '').toString().trim();
  }

  AtenaDeeplink _withBestDateIfNeeded(
    AtenaDeeplink d, {
    String? fallbackDateKey,
  }) {
    if (!d.isCalendario) return d;

    final dk = (d.dateKey ?? '').trim();
    if (dk.isNotEmpty) return d;

    final fk = (fallbackDateKey ?? '').trim();
    if (fk.isEmpty) return d;

    return AtenaDeeplink(
      path: d.path,
      perfilId: d.perfilId,
      ownerAccountId: d.ownerAccountId,
      dateKey: fk,
      itemId: d.itemId,
      documentoId: d.documentoId,
      solicitudId: d.solicitudId,
      qp: d.qp,
      qpAll: d.qpAll,
    );
  }

  Future<bool> _openDeeplinkIfAny(
    Map<String, dynamic> e, {
    String? fallbackDateKey,
  }) async {
    final raw = _extractDeeplink(e);
    if (raw.isEmpty) return false;

    final ownerId = _normIdKey(widget.ownerAccountId);
    final perfilId = _normIdKey(widget.perfilId);

    try {
      var d = AtenaDeeplink.parse(
        raw,
      ).ensureCanonico(ownerAccountId: ownerId, perfilId: perfilId);

      // Si el deeplink es calendario y no trae date, lo completamos.
      d = _withBestDateIfNeeded(d, fallbackDateKey: fallbackDateKey);

      final route = d.toRouteString();
      if (!mounted) return true;

      await Navigator.of(context).pushNamed(route);
      return true;
    } catch (err) {
      // No inventamos strings nuevos: hard-fail silencioso y fallback al modal.
      // ignore: avoid_print
      print('AlumnoCalendarioPage: deeplink open error: $err');
      return false;
    }
  }

  // =====================================================
  // RSVP (CANÓNICO)
  // =====================================================

  bool _requiresRsvp(Map<String, dynamic> e) {
    if (_bool(e['requiresRsvp'])) return true;
    final p = _normStr(e['rsvpPolicy']).toLowerCase();
    return p.isNotEmpty;
  }

  String _rsvpPolicy(Map<String, dynamic> e) {
    final p = _normStr(e['rsvpPolicy']).toLowerCase();
    return p.isEmpty ? 'optional' : p;
  }

  String _rsvpValue(Map<String, dynamic> e) {
    final v = _normStr(e['rsvpStatus'] ?? e['rsvp']).toLowerCase();
    if (v == 'yes' || v == 'no' || v == 'maybe' || v == 'pending') return v;
    return '';
  }

  bool _rsvpAllowDecline(Map<String, dynamic> e) {
    final policy = _rsvpPolicy(e);
    if (policy == 'mandatory_attendance') return false;
    if (_isLockedEvento(e) && _isInstitucionSource(e)) return false;
    return true;
  }

  RsvpStatusAtena _toRsvpEnum(String v) {
    final s = v.trim().toLowerCase();
    if (s == 'yes') return RsvpStatusAtena.yes;
    if (s == 'no') return RsvpStatusAtena.no;
    if (s == 'maybe') return RsvpStatusAtena.maybe;
    return RsvpStatusAtena.pending;
  }

  // =====================================================
  // ColorHint (backend-ready)
  // =====================================================

  Color? _colorFromHint(dynamic hint) {
    if (hint == null) return null;

    if (hint is int) {
      try {
        return Color(hint);
      } catch (_) {
        return null;
      }
    }

    final s = hint.toString().trim();
    if (s.isEmpty) return null;

    String hex = s;
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.toLowerCase().startsWith('0x')) hex = hex.substring(2);

    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;

    final v = int.tryParse(hex, radix: 16);
    if (v == null) return null;

    try {
      return Color(v);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setRsvp(Map<String, dynamic> e, String value) async {
    final v = value.toLowerCase().trim();
    if (v != 'yes' && v != 'no' && v != 'maybe') return;

    if (!_requiresRsvp(e)) return;

    if (v == 'no' && !_rsvpAllowDecline(e)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.alumnoCalendarioSnackNoDeclinar)),
      );
      return;
    }

    final id = _normStr(e['id']);
    if (id.isEmpty) return;

    final ownerId = _normIdKey(widget.ownerAccountId);
    final perfilId = _normIdKey(widget.perfilId);

    try {
      final updated = await AlumnoCalendarioInteraccionesService.instance
          .setRsvp(
            ownerAccountId: ownerId,
            perfilId: perfilId,
            eventId: id,
            status: _toRsvpEnum(v),
            notificarOwner: true,
          );

      if (!mounted) return;

      if (updated != null) {
        bool applied = false;
        setState(() {
          final idx = _eventosCalendario.indexWhere(
            (x) => _normStr(x['id']) == id,
          );
          if (idx >= 0) {
            _eventosCalendario[idx] = Map<String, dynamic>.from(updated);
            applied = true;
          }
          _focusItemId = id;
          _focusScrollDone = false;
          _focusScrollScheduled = false;
          _focusDateResolved = true;
        });

        if (!applied) {
          await _cargar();
        }
      }

      if (!mounted) return;
      final msg = (v == 'yes')
          ? _l10n.alumnoCalendarioSnackAsistenciaConfirmada
          : (v == 'maybe'
                ? _l10n.alumnoCalendarioSnackAsistenciaQuizas
                : _l10n.alumnoCalendarioSnackAsistenciaDeclinada);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.alumnoCalendarioSnackNoGuardarRsvp(err.toString()),
          ),
        ),
      );
    }
  }

  // =====================================================
  // LOAD
  // =====================================================

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final ownerId = _normIdKey(widget.ownerAccountId);
      final perfilId = _normIdKey(widget.perfilId);

      if (ownerId.isEmpty) {
        throw Exception(_l10n.commonOwnerInvalid);
      }
      if (perfilId.isEmpty) {
        throw Exception(_l10n.commonPerfilInvalid);
      }

      final cal = await AlumnoCalendarioInteraccionesService.instance
          .listarEventos(ownerAccountId: ownerId, perfilId: perfilId);

      final agenda = await AlumnoService.instance.getAgendaPersonalRaw(
        ownerAccountId: ownerId,
        perfilId: perfilId,
      );

      if (!mounted) return;
      setState(() {
        _eventosCalendario = List<Map<String, dynamic>>.from(cal);
        _agendaPersonal = List<Map<String, dynamic>>.from(agenda);
      });

      final fid = (_focusItemId ?? '').trim();
      if (!_focusDateResolved && fid.isNotEmpty) {
        _tryResolveFocusDateFromItemId(fid);
      }

      Future.microtask(() async {
        try {
          await AlumnoService.instance.emitPreEventosDue(
            ownerAccountId: ownerId,
            perfilId: perfilId,
            duplicarEnPerfil: true,
          );
        } catch (_) {}
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _tryResolveFocusDateFromItemId(String itemId) {
    if (!mounted) return;

    final id = itemId.trim();
    if (id.isEmpty) {
      setState(() => _focusDateResolved = true);
      return;
    }

    String? dateKey;

    for (final e in _eventosCalendario) {
      final eid = (e['id'] ?? '').toString().trim();
      if (eid == id) {
        final dk = _eventDateKey(e).trim();
        if (dk.isNotEmpty) dateKey = dk;
        break;
      }
    }

    if (dateKey == null) {
      for (final e in _agendaPersonal) {
        final eid = (e['id'] ?? '').toString().trim();
        if (eid == id) {
          final dk = _eventDateKey(e).trim();
          if (dk.isNotEmpty) dateKey = dk;
          break;
        }
      }
    }

    if (dateKey != null && dateKey.trim().isNotEmpty) {
      final d = _parseDateKey(dateKey);
      setState(() {
        _diaSeleccionado = d;
        _mesActual = DateTime(d.year, d.month, 1);
        _showPersonal = true;
        _focusScrollDone = false;
        _focusScrollScheduled = false;
        _focusDateResolved = true;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _focusDateResolved = true;
    });
  }

  // =========================
  // Tipos + Colores UI
  // =========================

  String _tipoEvento(Map<String, dynamic> e) {
    final raw = (e['type'] ?? e['tipo'] ?? '').toString().trim().toLowerCase();
    if (raw.isEmpty) return 'personal';

    if (raw.contains('curr')) return 'curricular';
    if (raw.contains('extra')) return 'extracurricular';

    if (raw == 'curricular' || raw == 'extracurricular' || raw == 'personal') {
      return raw;
    }

    return 'personal';
  }

  bool _eventoVisible(Map<String, dynamic> e) {
    final t = _tipoEvento(e);
    if (t == 'curricular') return _showCurricular;
    if (t == 'extracurricular') return _showExtracurricular;
    return _showPersonal;
  }

  Color _colorPorTipo(String tipo, ColorScheme cs) {
    switch (tipo) {
      case 'curricular':
        return cs.primary;
      case 'extracurricular':
        return cs.tertiary;
      default:
        return cs.secondary;
    }
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'curricular':
        return Icons.school;
      case 'extracurricular':
        return Icons.sports_soccer;
      default:
        return Icons.edit_note;
    }
  }

  Color _colorEvento(Map<String, dynamic> e, ColorScheme cs) {
    final hint = e['colorHint'] ?? e['color'] ?? e['uiColor'];
    final fromHint = _colorFromHint(hint);

    if (fromHint == null && _isEventoEspecial(e)) {
      return cs.secondaryContainer;
    }

    return fromHint ?? _colorPorTipo(_tipoEvento(e), cs);
  }

  // =========================
  // Fuente unificada de eventos por día
  // =========================

  List<Map<String, dynamic>> _eventosDelDia(DateTime dia) {
    final key = _dateKey(dia);

    final cal = _eventosCalendario.where((e) {
      final k = _eventDateKey(e);
      return k == key && _eventoVisible(e);
    });

    final per = _agendaPersonal
        .where((e) {
          final k = _eventDateKey(e);
          return k == key && _showPersonal;
        })
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          m['type'] = 'personal';
          return m;
        });

    final out = <Map<String, dynamic>>[];
    out.addAll(cal.map((e) => Map<String, dynamic>.from(e)));
    out.addAll(per);

    int rank(String t) {
      if (t == 'curricular') return 0;
      if (t == 'extracurricular') return 1;
      return 2;
    }

    out.sort((a, b) {
      final ra = rank(_tipoEvento(a));
      final rb = rank(_tipoEvento(b));
      if (ra != rb) return ra.compareTo(rb);

      final ta = _normStr(a['title'] ?? a['titulo']).toLowerCase();
      final tb = _normStr(b['title'] ?? b['titulo']).toLowerCase();
      if (ta != tb) return ta.compareTo(tb);

      return _normStr(a['id']).compareTo(_normStr(b['id']));
    });

    return out;
  }

  int _countTipoEnDia(DateTime dia, String tipo) {
    final key = _dateKey(dia);

    if (tipo == 'personal') {
      if (!_showPersonal) return 0;
      return _agendaPersonal.where((e) => _eventDateKey(e) == key).length;
    }

    if (tipo == 'curricular' && !_showCurricular) return 0;
    if (tipo == 'extracurricular' && !_showExtracurricular) return 0;

    return _eventosCalendario
        .where(
          (e) =>
              _eventDateKey(e) == key &&
              _tipoEvento(e) == tipo &&
              _eventoVisible(e),
        )
        .length;
  }

  // =========================
  // UI: Mes / Grid
  // =========================

  void _prevMes() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month - 1, 1);
    });
  }

  void _nextMes() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + 1, 1);
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime?> _buildMonthCells(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final firstWeekday = first.weekday; // 1..7 (Mon..Sun)
    final leadingEmpty = firstWeekday - 1;

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[];

    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  // =========================
  // Agenda personal: CRUD (+ notificaciones canónicas)
  // =========================

  Future<void> _agregarNota() async {
    final messenger = ScaffoldMessenger.of(context);

    final res = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) =>
          _AgendaItemDialog(dateKey: _dateKey(_diaSeleccionado)),
    );

    if (!mounted) return;
    if (res == null) return;

    final ownerId = _normIdKey(widget.ownerAccountId);
    final perfilId = _normIdKey(widget.perfilId);

    try {
      final saved = await AlumnoService.instance.upsertAgendaPersonalItem(
        ownerAccountId: ownerId,
        perfilId: perfilId,
        item: res,
      );

      if (!mounted) return;
      setState(() {
        final id = saved['id'].toString();
        final idx = _agendaPersonal.indexWhere((e) => (e['id'] ?? '') == id);
        if (idx >= 0) {
          _agendaPersonal[idx] = saved;
        } else {
          _agendaPersonal.add(saved);
        }
        _focusItemId = id;
        _focusScrollDone = false;
        _focusScrollScheduled = false;
        _focusDateResolved = true;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_l10n.alumnoCalendarioSnackNoGuardarNota(e.toString())),
        ),
      );
    }
  }

  Future<void> _editarNota(Map<String, dynamic> item) async {
    final messenger = ScaffoldMessenger.of(context);

    final res = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) => _AgendaItemDialog(
        initial: item,
        dateKey: _eventDateKey(item).isNotEmpty
            ? _eventDateKey(item)
            : _dateKey(_diaSeleccionado),
      ),
    );

    if (!mounted) return;
    if (res == null) return;

    final ownerId = _normIdKey(widget.ownerAccountId);
    final perfilId = _normIdKey(widget.perfilId);

    try {
      final saved = await AlumnoService.instance.upsertAgendaPersonalItem(
        ownerAccountId: ownerId,
        perfilId: perfilId,
        item: res,
      );

      if (!mounted) return;
      setState(() {
        final id = saved['id'].toString();
        final idx = _agendaPersonal.indexWhere((e) => (e['id'] ?? '') == id);
        if (idx >= 0) _agendaPersonal[idx] = saved;
        _focusItemId = id;
        _focusScrollDone = false;
        _focusScrollScheduled = false;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _l10n.alumnoCalendarioSnackNoActualizarNota(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _borrarNota(Map<String, dynamic> item) async {
    final messenger = ScaffoldMessenger.of(context);

    final id = (item['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_l10n.commonDeleteTitle),
        content: Text(_l10n.alumnoCalendarioEliminarConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_l10n.commonDelete),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    final ownerId = _normIdKey(widget.ownerAccountId);
    final perfilId = _normIdKey(widget.perfilId);

    try {
      await AlumnoService.instance.deleteAgendaPersonalItem(
        ownerAccountId: ownerId,
        perfilId: perfilId,
        itemId: id,
      );

      if (!mounted) return;
      setState(() {
        _agendaPersonal.removeWhere((e) => (e['id'] ?? '') == id);
        if ((_focusItemId ?? '') == id) _focusItemId = null;
        _focusScrollDone = true;
        _focusScrollScheduled = false;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _l10n.alumnoCalendarioSnackNoEliminarNota(e.toString()),
          ),
        ),
      );
    }
  }

  // =====================================================
  // Focus scroll (determinista con GlobalKey + ensureVisible)
  // =====================================================

  void _applyScrollFocusIfNeeded(List<Map<String, dynamic>> eventosHoy) {
    final fid = (_focusItemId ?? '').trim();
    if (fid.isEmpty) return;
    if (_focusScrollDone) return;
    if (_focusScrollScheduled) return;

    final idx = eventosHoy.indexWhere(
      (e) => (e['id'] ?? '').toString().trim() == fid,
    );
    if (idx < 0) return;

    _focusScrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((frameTime) {
      if (!mounted) return;

      final key = _keyForItem(fid);
      final ctx = key.currentContext;
      if (ctx == null) {
        if (!mounted) return;
        setState(() {
          _focusScrollScheduled = false;
        });
        return;
      }

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        alignment: 0.2,
      );

      if (!mounted) return;
      setState(() {
        _focusScrollDone = true;
      });

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _focusItemId = null;
          _focusScrollScheduled = false;
        });
      });
    });
  }

  // =====================================================
  // Modal detalle (evento no-personal) — Fase 2: Evento Especial destacado
  // =====================================================

  Future<void> _openEventoDetalle(Map<String, dynamic> e) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final tipo = _tipoEvento(e);
    final color = _colorEvento(e, cs);

    final title = (e['title'] ?? e['titulo'] ?? _l10n.commonEvent)
        .toString()
        .trim();
    final note = (e['note'] ?? e['nota'] ?? '').toString().trim();

    final fromInst = _isInstitucionSource(e);
    final locked = _isLockedEvento(e);

    final isEspecial = _isEventoEspecial(e);
    final labelEspecial = _labelTipoEspecial(e);
    final seg = _segmentoLabel(e);

    final requiresRsvp = _requiresRsvp(e);
    final rsvp = _rsvpValue(e);
    final policy = _rsvpPolicy(e);

    final instId = (e['institucionId'] ?? '').toString().trim();
    final dateKey = _eventDateKey(e).trim().isNotEmpty
        ? _eventDateKey(e)
        : _dateKey(_diaSeleccionado);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.14),
                        child: Icon(
                          isEspecial ? Icons.flag : _iconoPorTipo(tipo),
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEspecial && labelEspecial.isNotEmpty
                              ? '$labelEspecial — $title'
                              : title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        label: tipo == 'curricular'
                            ? _l10n.commonCurricular
                            : (tipo == 'extracurricular'
                                  ? _l10n.commonExtracurricular
                                  : _l10n.commonPersonal),
                        icon: Icons.category,
                      ),
                      _Badge(
                        label: '${_l10n.commonDate}: $dateKey',
                        icon: Icons.event,
                      ),
                      if (isEspecial)
                        _Badge(
                          label: _l10n.commonSpecialEvent,
                          icon: Icons.flag,
                        ),
                      if (seg.isNotEmpty)
                        _Badge(label: seg, icon: Icons.filter_alt),
                      if (fromInst)
                        _Badge(
                          label: _l10n.commonInstitution,
                          icon: Icons.apartment,
                        ),
                      if (instId.isNotEmpty)
                        _Badge(
                          label: '${_l10n.commonId}: $instId',
                          icon: Icons.badge,
                        ),
                      if (locked)
                        _Badge(label: _l10n.commonMandatory, icon: Icons.lock),
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _l10n.commonDetail,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(note),
                  ],
                  const SizedBox(height: 12),
                  if (requiresRsvp) ...[
                    Text(
                      _l10n.commonAttendance,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (rsvp.isEmpty || rsvp == 'pending')
                          ? _l10n.commonAttendancePending
                          : (rsvp == 'yes'
                                ? _l10n.commonAttendanceYes
                                : (rsvp == 'maybe'
                                      ? _l10n.commonAttendanceMaybe
                                      : _l10n.commonAttendanceNo)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_l10n.commonPolicy}: ${policy.isEmpty ? 'optional' : policy}',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            await _setRsvp(e, 'yes');
                          },
                          icon: const Icon(Icons.check),
                          label: Text(_l10n.commonConfirm),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            await _setRsvp(e, 'maybe');
                          },
                          icon: const Icon(Icons.help_outline),
                          label: Text(_l10n.commonMaybe),
                        ),
                        if (_rsvpAllowDecline(e))
                          OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _setRsvp(e, 'no');
                            },
                            icon: const Icon(Icons.close),
                            label: Text(_l10n.commonDecline),
                          ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _l10n.alumnoCalendarioNoRequiereAsistencia,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(),
                  Text(
                    _l10n.alumnoCalendarioNotaCanonica,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ownerId = _normIdKey(widget.ownerAccountId);
    final perfilId = _normIdKey(widget.perfilId);

    if (ownerId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.alumnoCalendarioTitle)),
        body: Center(child: Text(_l10n.commonOwnerInvalid)),
      );
    }
    if (perfilId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.alumnoCalendarioTitle)),
        body: Center(child: Text(_l10n.commonPerfilInvalid)),
      );
    }

    final cells = _buildMonthCells(_mesActual);
    final rows = (cells.length / 7).ceil();
    final monthLabel =
        '${_mesActual.month.toString().padLeft(2, '0')}/${_mesActual.year}';

    final eventosHoy = _eventosDelDia(_diaSeleccionado);

    final keepIds = <String>{};
    for (final e in eventosHoy) {
      final id = (e['id'] ?? '').toString().trim();
      if (id.isNotEmpty) keepIds.add(id);
    }
    if (_itemKeys.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((frameTime) {
        if (!mounted) return;
        _pruneItemKeys(keepIds);
      });
    }

    _applyScrollFocusIfNeeded(eventosHoy);

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.alumnoCalendarioTitle),
        actions: [
          IconButton(
            tooltip: _l10n.commonRefresh,
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando ? null : _agregarNota,
        icon: const Icon(Icons.add),
        label: Text(_l10n.alumnoCalendarioFabNotaAlarma),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _prevMes,
                        icon: const Icon(Icons.chevron_left),
                        tooltip: _l10n.commonPrevMonth,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            monthLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMes,
                        icon: const Icon(Icons.chevron_right),
                        tooltip: _l10n.commonNextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: _showCurricular,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LegendDot(color: _colorPorTipo('curricular', cs)),
                            const SizedBox(width: 6),
                            Text(_l10n.commonCurricular),
                          ],
                        ),
                        onSelected: (v) => setState(() {
                          _showCurricular = v;
                          _itemKeys.clear();
                          _focusScrollDone = true;
                        }),
                      ),
                      FilterChip(
                        selected: _showExtracurricular,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LegendDot(
                              color: _colorPorTipo('extracurricular', cs),
                            ),
                            const SizedBox(width: 6),
                            Text(_l10n.commonExtracurricular),
                          ],
                        ),
                        onSelected: (v) => setState(() {
                          _showExtracurricular = v;
                          _itemKeys.clear();
                          _focusScrollDone = true;
                        }),
                      ),
                      FilterChip(
                        selected: _showPersonal,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LegendDot(color: _colorPorTipo('personal', cs)),
                            const SizedBox(width: 6),
                            Text(_l10n.commonPersonal),
                          ],
                        ),
                        onSelected: (v) => setState(() {
                          _showPersonal = v;
                          _itemKeys.clear();
                          _focusScrollDone = true;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(
                      7,
                      (i) =>
                          Expanded(child: Center(child: Text(_diasSemana(i)))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: List.generate(rows, (r) {
                        final start = r * 7;
                        final week = cells.sublist(start, start + 7);

                        return Expanded(
                          child: Row(
                            children: List.generate(7, (i) {
                              final day = week[i];
                              if (day == null) {
                                return const Expanded(child: SizedBox());
                              }

                              final isSelected = _sameDay(
                                day,
                                _diaSeleccionado,
                              );
                              final isToday = _sameDay(day, DateTime.now());

                              final cCur = _countTipoEnDia(day, 'curricular');
                              final cExt = _countTipoEnDia(
                                day,
                                'extracurricular',
                              );
                              final cPer = _countTipoEnDia(day, 'personal');

                              final borderColor = isSelected
                                  ? cs.primary
                                  : cs.outlineVariant.withValues(alpha: 0.6);

                              final bg = isToday
                                  ? cs.primary.withValues(alpha: 0.06)
                                  : null;

                              return Expanded(
                                child: InkWell(
                                  onTap: () => _onSelectDay(day),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: borderColor,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      color: bg,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${day.day}',
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        _DotsRow(
                                          curricularCount: cCur,
                                          extracurricularCount: cExt,
                                          personalCount: cPer,
                                          curricularColor: _colorPorTipo(
                                            'curricular',
                                            cs,
                                          ),
                                          extracurricularColor: _colorPorTipo(
                                            'extracurricular',
                                            cs,
                                          ),
                                          personalColor: _colorPorTipo(
                                            'personal',
                                            cs,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_l10n.commonEvents} – ${_dateKey(_diaSeleccionado)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: eventosHoy.isEmpty
                        ? Center(
                            child: Text(
                              _l10n.alumnoCalendarioNoEventosDia,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: eventosHoy.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final e = eventosHoy[idx];
                              final tipo = _tipoEvento(e);
                              final color = _colorEvento(e, cs);

                              final title =
                                  (e['title'] ??
                                          e['titulo'] ??
                                          _l10n.commonEvent)
                                      .toString()
                                      .trim();
                              final note = (e['note'] ?? e['nota'] ?? '')
                                  .toString()
                                  .trim();

                              final alarmEnabled = _bool(
                                e['alarmEnabled'],
                                fallback: false,
                              );
                              final alarmTime = (e['alarmTime'] ?? '')
                                  .toString();

                              final isPersonal = (tipo == 'personal');

                              final id = (e['id'] ?? '').toString().trim();
                              final canKey = id.isNotEmpty;
                              final isFocused =
                                  (_focusItemId ?? '').trim().isNotEmpty &&
                                  id.isNotEmpty &&
                                  id == (_focusItemId ?? '').trim();

                              final fromInst = _isInstitucionSource(e);
                              final locked = _isLockedEvento(e);
                              final requiresRsvp =
                                  !isPersonal && _requiresRsvp(e);
                              final rsvp = _rsvpValue(e);

                              final isEspecial =
                                  !isPersonal && _isEventoEspecial(e);
                              final labelEspecial = isEspecial
                                  ? _labelTipoEspecial(e)
                                  : '';
                              final seg = isEspecial ? _segmentoLabel(e) : '';

                              final lockBadge =
                                  (!isPersonal &&
                                      (locked || !_allowStudentDelete(e)))
                                  ? _Badge(
                                      label: _l10n.commonMandatory,
                                      icon: Icons.lock,
                                    )
                                  : null;

                              final instBadge = (!isPersonal && fromInst)
                                  ? _Badge(
                                      label: _l10n.commonInstitution,
                                      icon: Icons.apartment,
                                    )
                                  : null;

                              final especialBadge = isEspecial
                                  ? _Badge(
                                      label: labelEspecial.isNotEmpty
                                          ? labelEspecial
                                          : _l10n.commonSpecialEvent,
                                      icon: Icons.flag,
                                    )
                                  : null;

                              final segBadge = (seg.isNotEmpty)
                                  ? _Badge(label: seg, icon: Icons.filter_alt)
                                  : null;

                              final rsvpBadge = requiresRsvp
                                  ? _Badge(
                                      label: rsvp.isEmpty || rsvp == 'pending'
                                          ? _l10n.commonAttendancePending
                                          : (rsvp == 'yes'
                                                ? _l10n.commonAttendanceYes
                                                : (rsvp == 'maybe'
                                                      ? _l10n
                                                            .commonAttendanceMaybe
                                                      : _l10n
                                                            .commonAttendanceNo)),
                                      icon: Icons.how_to_reg,
                                    )
                                  : null;

                              return AnimatedContainer(
                                key: canKey ? _keyForItem(id) : null,
                                duration: const Duration(milliseconds: 220),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: isFocused
                                      ? Border.all(color: cs.primary, width: 2)
                                      : null,
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: cs.outlineVariant.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: isPersonal
                                        ? null
                                        : () async {
                                            final fallbackDk =
                                                _eventDateKey(
                                                  e,
                                                ).trim().isNotEmpty
                                                ? _eventDateKey(e)
                                                : _dateKey(_diaSeleccionado);

                                            final opened =
                                                await _openDeeplinkIfAny(
                                                  e,
                                                  fallbackDateKey: fallbackDk,
                                                );
                                            if (opened) return;

                                            await _openEventoDetalle(e);
                                          },
                                    leading: CircleAvatar(
                                      backgroundColor: color.withValues(
                                        alpha: 0.14,
                                      ),
                                      child: Icon(
                                        isEspecial
                                            ? Icons.flag
                                            : _iconoPorTipo(tipo),
                                        color: color,
                                      ),
                                    ),
                                    title: Text(
                                      isEspecial && labelEspecial.isNotEmpty
                                          ? '$labelEspecial — $title'
                                          : title,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tipo == 'curricular'
                                              ? _l10n.commonCurricular
                                              : (tipo == 'extracurricular'
                                                    ? _l10n
                                                          .commonExtracurricular
                                                    : _l10n.commonPersonal),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            if (especialBadge != null)
                                              especialBadge,
                                            if (segBadge != null) segBadge,
                                            if (instBadge != null) instBadge,
                                            if (lockBadge != null) lockBadge,
                                            if (rsvpBadge != null) rsvpBadge,
                                          ],
                                        ),
                                        if (note.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(note),
                                        ],
                                        if (isPersonal && alarmEnabled) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '${_l10n.commonAlarm}: ${alarmTime.isEmpty ? _l10n.commonNoTime : alarmTime}',
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: isPersonal
                                        ? PopupMenuButton<String>(
                                            onSelected: (v) {
                                              if (v == 'edit') {
                                                unawaited(_editarNota(e));
                                              }
                                              if (v == 'del') {
                                                unawaited(_borrarNota(e));
                                              }
                                            },
                                            itemBuilder: (menuContext) => [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text(_l10n.commonEdit),
                                              ),
                                              PopupMenuItem(
                                                value: 'del',
                                                child: Text(_l10n.commonDelete),
                                              ),
                                            ],
                                          )
                                        : (requiresRsvp
                                              ? PopupMenuButton<String>(
                                                  tooltip: _l10n
                                                      .alumnoCalendarioConfirmarAsistencia,
                                                  onSelected: (v) async {
                                                    if (v == 'yes') {
                                                      await _setRsvp(e, 'yes');
                                                    }
                                                    if (v == 'maybe') {
                                                      await _setRsvp(
                                                        e,
                                                        'maybe',
                                                      );
                                                    }
                                                    if (v == 'no') {
                                                      await _setRsvp(e, 'no');
                                                    }
                                                  },
                                                  itemBuilder: (menuContext) => [
                                                    PopupMenuItem(
                                                      value: 'yes',
                                                      child: Text(
                                                        _l10n.commonConfirm,
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'maybe',
                                                      child: Text(
                                                        _l10n.commonMaybe,
                                                      ),
                                                    ),
                                                    if (_rsvpAllowDecline(e))
                                                      PopupMenuItem(
                                                        value: 'no',
                                                        child: Text(
                                                          _l10n.commonDecline,
                                                        ),
                                                      ),
                                                  ],
                                                  icon: const Icon(
                                                    Icons.how_to_reg,
                                                  ),
                                                )
                                              : null),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _diasSemana(int i) {
    switch (i) {
      case 0:
        return _l10n.commonMon;
      case 1:
        return _l10n.commonTue;
      case 2:
        return _l10n.commonWed;
      case 3:
        return _l10n.commonThu;
      case 4:
        return _l10n.commonFri;
      case 5:
        return _l10n.commonSat;
      default:
        return _l10n.commonSun;
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DotsRow extends StatelessWidget {
  final int curricularCount;
  final int extracurricularCount;
  final int personalCount;

  final Color curricularColor;
  final Color extracurricularColor;
  final Color personalColor;

  const _DotsRow({
    required this.curricularCount,
    required this.extracurricularCount,
    required this.personalCount,
    required this.curricularColor,
    required this.extracurricularColor,
    required this.personalColor,
  });

  Widget _dot(Color c) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    final dots = <Widget>[];

    if (curricularCount > 0) dots.add(_dot(curricularColor));
    if (extracurricularCount > 0) {
      if (dots.isNotEmpty) dots.add(const SizedBox(width: 4));
      dots.add(_dot(extracurricularColor));
    }
    if (personalCount > 0) {
      if (dots.isNotEmpty) dots.add(const SizedBox(width: 4));
      dots.add(_dot(personalColor));
    }

    if (dots.isEmpty) {
      return const SizedBox(height: 7);
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: dots);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Badge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AgendaItemDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final String dateKey;

  const _AgendaItemDialog({required this.dateKey, this.initial});

  @override
  State<_AgendaItemDialog> createState() => _AgendaItemDialogState();
}

class _AgendaItemDialogState extends State<_AgendaItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;

  bool _alarmEnabled = false;
  TimeOfDay? _alarmTime;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  String _s(dynamic v) => (v ?? '').toString().trim();

  bool _bool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is double) return v.toInt() != 0;
    final s = _s(v).toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? const <String, dynamic>{};

    _titleCtrl = TextEditingController(text: (init['title'] ?? '').toString());
    _noteCtrl = TextEditingController(text: (init['note'] ?? '').toString());

    _alarmEnabled = _bool(init['alarmEnabled'], fallback: false);

    final alarmTime = (init['alarmTime'] ?? '').toString().trim();
    if (alarmTime.contains(':')) {
      final p = alarmTime.split(':');
      final h = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 0;
      _alarmTime = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    setState(() => _alarmTime = picked);
  }

  String _timeToStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _save() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final init = widget.initial ?? const <String, dynamic>{};
    final id = (init['id'] ?? '').toString().trim();

    final out = <String, dynamic>{
      if (id.isNotEmpty) 'id': id,
      'date': widget.dateKey,
      'title': _titleCtrl.text.trim(),
      'note': _noteCtrl.text.trim(),
      'alarmEnabled': _alarmEnabled,
      'alarmTime': (_alarmEnabled && _alarmTime != null)
          ? _timeToStr(_alarmTime!)
          : '',
    };

    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isNew = widget.initial == null;
    final dialogTitle = isNew
        ? '${_l10n.commonNew} ${_l10n.alumnoCalendarioDialogNotaAlarma}'
        : '${_l10n.commonEdit} ${_l10n.alumnoCalendarioDialogNotaAlarma}';

    return AlertDialog(
      title: Text(dialogTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_l10n.commonDate}: ${widget.dateKey}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: _l10n.commonTitle,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return _l10n.alumnoCalendarioDialogIngresarTitulo;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _l10n.commonNoteOptional,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_l10n.alumnoCalendarioDialogAlarmaLocal),
                  subtitle: Text(_l10n.alumnoCalendarioDialogAlarmaLocalDesc),
                  value: _alarmEnabled,
                  onChanged: (v) => setState(() => _alarmEnabled = v),
                ),
                if (_alarmEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_l10n.commonTime}: ${_alarmTime == null ? _l10n.commonNoTime : _timeToStr(_alarmTime!)}',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_l10n.commonChoose),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _l10n.alumnoCalendarioDialogAvisoNotificacion,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(_l10n.commonCancel),
        ),
        ElevatedButton(onPressed: _save, child: Text(_l10n.commonSave)),
      ],
    );
  }
}
