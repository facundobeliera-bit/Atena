// lib/screens/instituciones/institucion_extracurricular_modulo_base.dart
//
// ATENA – INSTITUCIÓN – EXTRACURRICULARES – BASE (UI GENÉRICA)
//
// HARDENING (fase 2):
// - Alinea 100% normalizaciones con ExtracurricularesService:
//   * institucionId storageKey = trim + remove whitespace interno.
//   * moduleKey = trim + lower (sin “arreglos mágicos”).
// - Valida key una sola vez (struct con detalle) y reutiliza en toda la UI.
// - Evita recalcular validaciones múltiples por build (cachea _KeyValidation).
// - Future estable: RefreshIndicator espera el mismo future y recarga correctamente.
// - Manejo de errores con UI clara + botón reintentar.
// - Asegura persistencia usando SIEMPRE institucionId CANÓNICA (sin whitespace).
// - Corrige mensaje/ramas de error para que coincidan con la causa real.
// - Protege acciones: CRUD / solicitudes / cupos / borrar quedan bloqueadas si key o id inválidos.
//
// EXTENSIÓN (feb 2026 · solicitado):
// - Emisión de “Fichas Extracurriculares” desde la institución:
//   * Emitir => Notificación (owner alumno) + Evento de Calendario (alumno).
//   * El alumno ve la ficha al entrar al ítem del calendario (deeplink canónico).
//   * Este módulo NO vuelve a pedir selección de bloque: ya viene definido por el selector.
//
// Importante (backend-ready):
// - Este módulo NO inventa fuentes de alumnos.
// - Intenta obtener destinatarios por un método opcional del service (dynamic):
//     listarDestinatariosConfirmadosPorModulo(institucionId, moduleKey)
//   Si no existe todavía, permite ingreso manual “owner|perfil” (sin romper compilación).
// - La emisión real también se delega a un método opcional del service (dynamic):
//     emitirFichaExtracurricular(payload)
//   Si no existe aún, deja el flujo UI armado y muestra toast informativo.
//
// ✅ i18n + dark mode (enero 2026):
// - Textos vía AppLocalizations (ARB-ready).
// - Colores vía Theme/ColorScheme.
// - Evita copyWith en modelo (compat fuerte): edición por toMap/fromMap.
//
// ✅ UI (feb 2026 · fondo institucional fullscreen):
// - Stack(fit: StackFit.expand) + fondo Positioned.fill + contenido SafeArea.
// - Scaffold transparente + extendBodyBehindAppBar para coherencia visual.
//

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/extracurriculares/grupo_extracurricular.dart';
import '../../services/extracurriculares_service.dart';
import '../../ui/atena_assets.dart';

import 'institucion_extracurricular_grupo_form_page.dart';
import 'institucion_mis_solicitudes_page.dart';

class InstitucionExtracurricularModuloBase extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  final BloqueExtracurricular bloque;
  final String moduleKey;

  const InstitucionExtracurricularModuloBase({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.bloque,
    required this.moduleKey,
  });

  @override
  State<InstitucionExtracurricularModuloBase> createState() =>
      _InstitucionExtracurricularModuloBaseState();
}

class _KeyValidation {
  final String instIdCanon; // storage key (sin whitespace interno)
  final String normalizedKey;
  final String expectedKey;

  final bool instIdOk;

  final bool keyIsSnake;
  final bool keyMatchesBloque;
  final bool keyIsCanonical;

  final bool isValid;

  const _KeyValidation({
    required this.instIdCanon,
    required this.normalizedKey,
    required this.expectedKey,
    required this.instIdOk,
    required this.keyIsSnake,
    required this.keyMatchesBloque,
    required this.keyIsCanonical,
    required this.isValid,
  });

  String errorMessage(AppLocalizations l10n) {
    if (isValid) return '';

    if (!instIdOk) {
      return l10n.institucionExtracBaseErrInvalidInstId;
    }

    if (!keyIsSnake) {
      return l10n.institucionExtracBaseErrInvalidModuleKeySnake;
    }

    if (!keyMatchesBloque) {
      return l10n.institucionExtracBaseErrModuleKeyMismatch(expectedKey);
    }

    return l10n.institucionExtracBaseErrModuleKeyNotCanonical(normalizedKey);
  }
}

/// Destinatario canónico (owner + perfil).
class _DestinatarioCanonico {
  final String ownerAccountId;
  final String perfilId;
  final String displayName;

  const _DestinatarioCanonico({
    required this.ownerAccountId,
    required this.perfilId,
    required this.displayName,
  });

  String get key => '${ownerAccountId.trim()}|${perfilId.trim()}';
}

class _InstitucionExtracurricularModuloBaseState
    extends State<InstitucionExtracurricularModuloBase> {
  Future<List<GrupoExtracurricular>>? _futureGrupos;

  // Cache: evita recalcular validaciones en cada build.
  late _KeyValidation _k;

  static String _n(String? v) => (v ?? '').trim();

  // Alineado a ExtracurricularesService:
  // - institucionId storageKey = trim + remove whitespace interno (RegExp \s+)
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  // moduleKey = trim + lower
  static String _normKey(String v) => v.trim().toLowerCase();

  static bool _isValidSnakeCase(String key) {
    final k = _normKey(key);
    if (k.isEmpty) return false;
    final re = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
    return re.hasMatch(k);
  }

  static bool _isValidCanonicalKey(String key) {
    final k = _normKey(key);
    return BloqueExtracurricularX.isValidKey(k);
  }

  _KeyValidation _validateKeys() {
    final instIdCanon = _normIdKey(widget.institucionId);
    final instIdOk = instIdCanon.isNotEmpty;

    final normalizedKey = _normKey(widget.moduleKey);
    final expectedKey = _normKey(widget.bloque.key);

    final keyIsSnake = _isValidSnakeCase(normalizedKey);
    final keyMatchesBloque = normalizedKey == expectedKey;
    final keyIsCanonical = _isValidCanonicalKey(normalizedKey);

    final isValid =
        instIdOk && keyIsSnake && keyMatchesBloque && keyIsCanonical;

    return _KeyValidation(
      instIdCanon: instIdCanon,
      normalizedKey: normalizedKey,
      expectedKey: expectedKey,
      instIdOk: instIdOk,
      keyIsSnake: keyIsSnake,
      keyMatchesBloque: keyMatchesBloque,
      keyIsCanonical: keyIsCanonical,
      isValid: isValid,
    );
  }

  void _toast(ScaffoldMessengerState? messenger, String msg) {
    if (messenger == null) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      // NO-OP
    }
  }

  void _goSolicitudesModulo({required _KeyValidation k}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InstitucionMisSolicitudesPage(
          institucionId: k.instIdCanon,
          institucionNombre: widget.institucionNombre,
          moduleKey: k.normalizedKey,
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, {IconData? icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _cuposLabelFromGrupo(AppLocalizations l10n, GrupoExtracurricular g) {
    final cupoMax = g.cupoMaximo;
    final cupoOcupado = g.cupoOcupado;

    if (cupoMax <= 0) return l10n.institucionExtracBaseCuposNotManaged;

    final disp = cupoMax - cupoOcupado;
    return l10n.institucionExtracBaseCuposManaged(disp < 0 ? 0 : disp, cupoMax);
  }

  Future<List<GrupoExtracurricular>> _loadGrupos({
    required _KeyValidation k,
  }) async {
    final id = k.instIdCanon;
    final mk = k.normalizedKey;

    if (id.isEmpty || mk.isEmpty) return <GrupoExtracurricular>[];
    if (!k.isValid) return <GrupoExtracurricular>[];

    return ExtracurricularesService.instance.cargarGruposPorModulo(
      institucionId: id,
      moduleKey: mk,
    );
  }

  void _reloadFuture({required _KeyValidation k}) {
    if (!mounted) return;

    setState(() {
      _k = k;
      _futureGrupos = k.isValid
          ? _loadGrupos(k: k)
          : Future.value(<GrupoExtracurricular>[]);
    });
  }

  Future<void> _abrirFormCrearEditar({
    required _KeyValidation k,
    GrupoExtracurricular? initial,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (!k.isValid) {
      _toast(
        messenger,
        k.errorMessage(l10n).isEmpty
            ? l10n.institucionExtracBaseInvalidDataGeneric
            : k.errorMessage(l10n),
      );
      return;
    }

    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InstitucionExtracurricularGrupoFormPage(
          institucionId: k.instIdCanon,
          institucionNombre: widget.institucionNombre,
          bloque: widget.bloque,
          moduleKey: k.normalizedKey,
          initial: initial,
        ),
      ),
    );

    if (!mounted) return;
    if (res == true) _reloadFuture(k: _k);
  }

  int _clamp(int v, int min, int max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  GrupoExtracurricular _rebuildFromMap(GrupoExtracurricular base, Map m) {
    try {
      return GrupoExtracurricular.fromMap(Map<String, dynamic>.from(m));
    } catch (_) {
      return base; // fallback conservador
    }
  }

  Future<void> _gestionarCuposMvp({
    required _KeyValidation k,
    required GrupoExtracurricular g,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (!k.isValid) {
      _toast(
        messenger,
        k.errorMessage(l10n).isEmpty
            ? l10n.institucionExtracBaseInvalidDataForCupos
            : k.errorMessage(l10n),
      );
      return;
    }

    final cupoMax = g.cupoMaximo;
    if (cupoMax <= 0) {
      _toast(messenger, l10n.institucionExtracBaseCuposRequireMax);
      return;
    }

    int ocupado = _clamp(g.cupoOcupado, 0, cupoMax);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(l10n.institucionExtracBaseCuposDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.institucionExtracBaseCuposDialogActividad(
                    _n(g.actividadNombre).isEmpty
                        ? l10n.labelNotProvided
                        : _n(g.actividadNombre),
                  ),
                ),
                Text(
                  l10n.institucionExtracBaseCuposDialogGrupo(
                    _n(g.nombreGrupo).isEmpty
                        ? l10n.labelNotProvided
                        : _n(g.nombreGrupo),
                  ),
                ),
                const SizedBox(height: 10),
                Text(l10n.institucionExtracBaseCuposDialogMax(cupoMax)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setLocal(() {
                        ocupado = _clamp(ocupado - 1, 0, cupoMax);
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: l10n.actionDecrease,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.institucionExtracBaseCuposDialogOcupado(ocupado),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setLocal(() {
                        ocupado = _clamp(ocupado + 1, 0, cupoMax);
                      }),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: l10n.actionIncrease,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.institucionExtracBaseCuposDialogDisponibles(
                    cupoMax - ocupado,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(l10n.actionCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      // ✅ Compat fuerte: NO copyWith. Actualiza por toMap/fromMap.
      final m = g.toMap();
      m['cupoOcupado'] = ocupado;
      m['updatedAt'] = DateTime.now().toIso8601String();
      final updated = _rebuildFromMap(g, m);

      await ExtracurricularesService.instance.upsertGrupo(
        k.instIdCanon,
        updated,
      );

      if (!mounted) return;

      _reloadFuture(k: _k);
      _toast(messenger, l10n.institucionExtracBaseCuposUpdated);
    } catch (e) {
      _toast(
        messenger,
        l10n.institucionExtracBaseCuposSaveFailed(e.toString()),
      );
    }
  }

  Future<void> _borrarGrupoConConfirmacion({
    required _KeyValidation k,
    required GrupoExtracurricular g,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (!k.isValid) {
      _toast(
        messenger,
        k.errorMessage(l10n).isEmpty
            ? l10n.institucionExtracBaseInvalidDataForDelete
            : k.errorMessage(l10n),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.institucionExtracBaseDeleteDialogTitle),
        content: Text(
          l10n.institucionExtracBaseDeleteDialogBody(
            _n(g.actividadNombre).isEmpty
                ? l10n.labelNotProvided
                : _n(g.actividadNombre),
            _n(g.nombreGrupo).isEmpty
                ? l10n.labelNotProvided
                : _n(g.nombreGrupo),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      await ExtracurricularesService.instance.borrarGrupo(k.instIdCanon, g.id);

      if (!mounted) return;

      _reloadFuture(k: _k);
      _toast(messenger, l10n.institucionExtracBaseDeletedOk);
    } catch (e) {
      _toast(messenger, l10n.institucionExtracBaseDeleteFailed(e.toString()));
    }
  }

  // =====================================================
  // ✅ EMISIÓN DE FICHAS (NOTI + CALENDARIO) — UI + CONTRATO
  // =====================================================

  Future<List<_DestinatarioCanonico>> _tryLoadDestinatariosConfirmados({
    required _KeyValidation k,
  }) async {
    if (!k.isValid) return const <_DestinatarioCanonico>[];

    try {
      final svc = ExtracurricularesService.instance as dynamic;

      final raw = await svc.listarDestinatariosConfirmadosPorModulo(
        institucionId: k.instIdCanon,
        moduleKey: k.normalizedKey,
      );

      if (raw is! List) return const <_DestinatarioCanonico>[];

      final out = <_DestinatarioCanonico>[];
      for (final it in raw) {
        if (it is! Map) continue;

        final owner = (it['ownerAccountId'] ?? '').toString().trim();
        final perfil = (it['perfilId'] ?? '').toString().trim();
        if (owner.isEmpty || perfil.isEmpty) continue;

        final nombre = (it['nombre'] ?? it['displayName'] ?? '')
            .toString()
            .trim();
        out.add(
          _DestinatarioCanonico(
            ownerAccountId: owner,
            perfilId: perfil,
            displayName: nombre.isEmpty ? perfil : nombre,
          ),
        );
      }

      final seen = <String>{};
      return out.where((d) => seen.add(d.key)).toList();
    } on NoSuchMethodError {
      return const <_DestinatarioCanonico>[];
    } catch (_) {
      return const <_DestinatarioCanonico>[];
    }
  }

  Future<void> _emitirFichaFlow({required _KeyValidation k}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (!k.isValid) {
      _toast(
        messenger,
        k.errorMessage(l10n).isEmpty
            ? l10n.institucionExtracBaseInvalidDataGeneric
            : k.errorMessage(l10n),
      );
      return;
    }

    final destinos = await _tryLoadDestinatariosConfirmados(k: k);
    final gruposForDialog = await _loadGrupos(k: k);

    if (!mounted) return;

    final now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);
    TimeOfDay time = TimeOfDay.fromDateTime(now);
    GrupoExtracurricular? grupo = gruposForDialog.isNotEmpty
        ? gruposForDialog.first
        : null;

    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final manualCtrl = TextEditingController();

    final selected = <String, bool>{for (final d in destinos) d.key: true};

    bool addToCalendar = true;
    bool requireRsvp = false;

    String dateKeyLabel(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String timeHHmmLabel(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(l10n.institucionExtracBaseEmitirFichaTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.institucionExtracBaseEmitirFichaSubtitle(
                      widget.bloque.label,
                    ),
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date,
                              firstDate: DateTime(now.year - 1, 1, 1),
                              lastDate: DateTime(now.year + 2, 12, 31),
                            );
                            if (picked != null) setLocal(() => date = picked);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(dateKeyLabel(date)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: time,
                            );
                            if (picked != null) setLocal(() => time = picked);
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(timeHHmmLabel(time)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (gruposForDialog.isNotEmpty) ...[
                    DropdownButtonFormField<GrupoExtracurricular>(
                      key: ValueKey<String>('grupo_${grupo?.id ?? 'none'}'),
                      initialValue: grupo,
                      items: gruposForDialog
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                '${_n(g.actividadNombre).isEmpty ? l10n.labelNotProvided : _n(g.actividadNombre)} · ${_n(g.nombreGrupo).isEmpty ? l10n.labelNotProvided : _n(g.nombreGrupo)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => grupo = v),
                      decoration: InputDecoration(
                        labelText:
                            l10n.institucionExtracBaseEmitirFichaGrupoLabel,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText:
                          l10n.institucionExtracBaseEmitirFichaTituloLabel,
                      hintText: l10n.institucionExtracBaseEmitirFichaTituloHint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyCtrl,
                    minLines: 3,
                    maxLines: 7,
                    decoration: InputDecoration(
                      labelText:
                          l10n.institucionExtracBaseEmitirFichaContenidoLabel,
                      hintText:
                          l10n.institucionExtracBaseEmitirFichaContenidoHint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: addToCalendar,
                    onChanged: (v) => setLocal(() => addToCalendar = v),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.institucionExtracBaseEmitirFichaAddToCalendar,
                    ),
                    subtitle: Text(
                      l10n.institucionExtracBaseEmitirFichaAddToCalendarHelp,
                    ),
                  ),
                  SwitchListTile(
                    value: requireRsvp,
                    onChanged: (v) => setLocal(() => requireRsvp = v),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.institucionExtracBaseEmitirFichaRequireRsvp,
                    ),
                    subtitle: Text(
                      l10n.institucionExtracBaseEmitirFichaRequireRsvpHelp,
                    ),
                  ),
                  const Divider(height: 18),
                  Text(
                    l10n.institucionExtracBaseEmitirFichaDestinatariosTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (destinos.isEmpty) ...[
                    Text(
                      l10n.institucionExtracBaseEmitirFichaDestinatariosEmptyHelp,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: manualCtrl,
                      minLines: 2,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText:
                            l10n.institucionExtracBaseEmitirFichaManualLabel,
                        hintText:
                            l10n.institucionExtracBaseEmitirFichaManualHint,
                      ),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => setLocal(() {
                            for (final d in destinos) {
                              selected[d.key] = true;
                            }
                          }),
                          child: Text(l10n.actionSelectAll),
                        ),
                        OutlinedButton(
                          onPressed: () => setLocal(() {
                            for (final d in destinos) {
                              selected[d.key] = false;
                            }
                          }),
                          child: Text(l10n.actionSelectNone),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final d in destinos)
                      CheckboxListTile(
                        value: selected[d.key] ?? false,
                        onChanged: (v) =>
                            setLocal(() => selected[d.key] = (v == true)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(d.displayName),
                        subtitle: Text(d.key),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(l10n.actionCancel),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                icon: const Icon(Icons.send),
                label: Text(l10n.actionEmit),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (ok != true) return;

    final title = titleCtrl.text.trim().isEmpty
        ? l10n.institucionExtracBaseEmitirFichaDefaultTitle(widget.bloque.label)
        : titleCtrl.text.trim();

    final content = bodyCtrl.text.trim().isEmpty
        ? l10n.institucionExtracBaseEmitirFichaDefaultBody
        : bodyCtrl.text.trim();

    final dateKey = dateKeyLabel(date);
    final timeHHmm = timeHHmmLabel(time);

    final recipients = <Map<String, dynamic>>[];

    if (destinos.isNotEmpty) {
      for (final d in destinos) {
        if (selected[d.key] == true) {
          recipients.add({
            'ownerAccountId': d.ownerAccountId,
            'perfilId': d.perfilId,
            'displayName': d.displayName,
          });
        }
      }
    } else {
      final lines = manualCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final line in lines) {
        final p = line.split('|');
        if (p.length != 2) continue;
        final owner = p[0].trim();
        final perfil = p[1].trim();
        if (owner.isEmpty || perfil.isEmpty) continue;
        recipients.add({
          'ownerAccountId': owner,
          'perfilId': perfil,
          'displayName': perfil,
        });
      }
    }

    if (recipients.isEmpty) {
      _toast(messenger, l10n.institucionExtracBaseEmitirFichaNoRecipients);
      return;
    }

    final payload = <String, dynamic>{
      'version': 1,
      'institucionId': k.instIdCanon,
      'moduleKey': k.normalizedKey,
      'bloqueKey': _normKey(widget.bloque.key),
      'bloqueLabel': widget.bloque.label,
      'date': dateKey,
      'time': timeHHmm,
      'title': title,
      'content': content,
      'addToCalendar': addToCalendar,
      'requiresRsvp': requireRsvp,
      'rsvpPolicy': requireRsvp ? 'optional' : 'optional',
      'grupo': grupo == null
          ? null
          : <String, dynamic>{
              'grupoId': grupo!.id,
              'actividadNombre': _n(grupo!.actividadNombre),
              'nombreGrupo': _n(grupo!.nombreGrupo),
              'turno': _n(grupo!.turno),
              'aula': _n(grupo!.aula),
            },
      'recipients': recipients,
      'createdAtIso': DateTime.now().toIso8601String(),
    };

    try {
      final svc = ExtracurricularesService.instance as dynamic;
      await svc.emitirFichaExtracurricular(payload);

      if (!mounted) return;
      _toast(messenger, l10n.institucionExtracBaseEmitirFichaOk);
    } on NoSuchMethodError {
      _toast(messenger, l10n.institucionExtracBaseEmitirFichaServiceMissing);
    } catch (e) {
      _toast(
        messenger,
        l10n.institucionExtracBaseEmitirFichaFailed(e.toString()),
      );
    }
  }

  // =====================================================
  // UI – FONDO INSTITUCIONAL FULLSCREEN
  // =====================================================

  Widget _buildBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ Por ahora reusamos el asset canónico del selector institucional.
    // Si luego querés un asset específico para Extracurriculares, se cambia acá.
    final path = AtenaAssets.ensureCanonical(AtenaAssets.bgInstitucionSelector);

    return Positioned.fill(
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: cs.surface);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _k = _validateKeys();
    _futureGrupos = _k.isValid
        ? _loadGrupos(k: _k)
        : Future.value(<GrupoExtracurricular>[]);
  }

  @override
  void didUpdateWidget(
    covariant InstitucionExtracurricularModuloBase oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final changed =
        oldWidget.institucionId != widget.institucionId ||
        oldWidget.moduleKey != widget.moduleKey ||
        oldWidget.bloque != widget.bloque;

    if (changed) {
      final next = _validateKeys();
      _reloadFuture(k: next);
    }
  }

  Future<void> _handleRefresh({required _KeyValidation k}) async {
    _reloadFuture(k: k);

    final f = _futureGrupos;
    if (f != null) {
      try {
        await f;
      } catch (_) {
        // no-op: el builder ya contempla error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cs = theme.colorScheme;

    final onSurfaceVariant = cs.onSurfaceVariant;
    final messenger = ScaffoldMessenger.maybeOf(context);

    final instName = widget.institucionNombre.trim().isEmpty
        ? l10n.institucionGeneric
        : widget.institucionNombre.trim();

    final k = _k;

    final leyenda = widget.bloque.ejemplos;
    final hasLeyenda = leyenda.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.institucionExtracBaseAppBarTitle(widget.bloque.label)),
        actions: [
          IconButton(
            tooltip: l10n.actionEmit,
            onPressed: k.isValid ? () => _emitirFichaFlow(k: k) : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(context),
          Positioned.fill(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => _handleRefresh(k: k),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      color: cs.surface.withValues(alpha: 0.92),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instName,
                              style:
                                  (theme.textTheme.titleMedium ??
                                          const TextStyle(fontSize: 16))
                                      .copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _chip(
                                  context,
                                  widget.bloque.label,
                                  icon: Icons.grid_view,
                                ),
                                _chip(
                                  context,
                                  l10n.institucionExtracBaseChipModuleKey(
                                    k.normalizedKey,
                                  ),
                                  icon: Icons.key,
                                ),
                                if (k.instIdOk)
                                  _chip(
                                    context,
                                    l10n.institucionExtracBaseChipInstId(
                                      k.instIdCanon,
                                    ),
                                    icon: Icons.apartment,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.institucionExtracBaseHeaderNote,
                              style: TextStyle(color: onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.75,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.institucionExtracBaseEmitirFichaBanner,
                                      style: TextStyle(color: onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!k.isValid) ...[
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: cs.error,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      k.errorMessage(l10n),
                                      style:
                                          (theme.textTheme.bodySmall ??
                                                  const TextStyle(fontSize: 12))
                                              .copyWith(color: cs.error),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      color: cs.surface.withValues(alpha: 0.92),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.bloque.descripcionCorta,
                                style: TextStyle(color: onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Card(
                      elevation: 0,
                      color: cs.surface.withValues(alpha: 0.92),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.institucionExtracBaseEmitirFichaCardTitle,
                              style:
                                  (theme.textTheme.titleSmall ??
                                          const TextStyle(fontSize: 14))
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface,
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.institucionExtracBaseEmitirFichaCardSubtitle,
                              style: TextStyle(color: onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: k.isValid
                                        ? () => _emitirFichaFlow(k: k)
                                        : null,
                                    icon: const Icon(Icons.send),
                                    label: Text(l10n.actionEmit),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: k.isValid
                                        ? () => _goSolicitudesModulo(k: k)
                                        : null,
                                    icon: const Icon(Icons.inbox),
                                    label: Text(
                                      l10n.institucionExtracBaseOpenInboxCta,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.institucionExtracBaseEmitirFichaCardFootnote,
                              style:
                                  (theme.textTheme.bodySmall ??
                                          const TextStyle(fontSize: 12))
                                      .copyWith(color: onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      color: cs.surface.withValues(alpha: 0.92),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.institucionExtracBaseQuickGuideTitle,
                              style:
                                  (theme.textTheme.titleSmall ??
                                          const TextStyle(fontSize: 14))
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface,
                                      ),
                            ),
                            const SizedBox(height: 10),
                            if (!hasLeyenda)
                              Text(
                                l10n.institucionExtracBaseQuickGuideEmpty,
                                style: TextStyle(color: onSurfaceVariant),
                              )
                            else
                              for (final item in leyenda) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: TextStyle(color: onSurfaceVariant),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                            const SizedBox(height: 4),
                            Text(
                              l10n.institucionExtracBaseQuickGuideFootnote,
                              style:
                                  (theme.textTheme.bodySmall ??
                                          const TextStyle(fontSize: 12))
                                      .copyWith(color: onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      color: cs.surface.withValues(alpha: 0.92),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.institucionExtracBaseGroupsTitle,
                              style:
                                  (theme.textTheme.titleSmall ??
                                          const TextStyle(fontSize: 14))
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface,
                                      ),
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<List<GrupoExtracurricular>>(
                              future: _futureGrupos,
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (!k.isValid) {
                                  return Text(
                                    k.errorMessage(l10n).isEmpty
                                        ? l10n.institucionExtracBaseInvalidDataToList
                                        : k.errorMessage(l10n),
                                    style: TextStyle(color: cs.error),
                                  );
                                }

                                if (snap.hasError) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.institucionExtracBaseLoadFailed,
                                        style: TextStyle(color: cs.error),
                                      ),
                                      const SizedBox(height: 10),
                                      FilledButton.icon(
                                        onPressed: () => _handleRefresh(k: k),
                                        icon: const Icon(Icons.refresh),
                                        label: Text(l10n.actionRetry),
                                      ),
                                    ],
                                  );
                                }

                                final list =
                                    (snap.data ?? <GrupoExtracurricular>[])
                                        .toList(growable: false);

                                if (list.isEmpty) {
                                  return Text(
                                    l10n.institucionExtracBaseNoGroupsYet,
                                    style: TextStyle(color: onSurfaceVariant),
                                  );
                                }

                                return Column(
                                  children: [
                                    for (final g in list) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.surface.withValues(
                                            alpha: 0.72,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: cs.outlineVariant.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _n(
                                                          g.actividadNombre,
                                                        ).isEmpty
                                                        ? l10n.labelNotProvided
                                                        : _n(g.actividadNombre),
                                                    style:
                                                        (theme
                                                                    .textTheme
                                                                    .titleSmall ??
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ))
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _chip(
                                                  context,
                                                  g.tieneCupos
                                                      ? l10n.institucionExtracBaseWithCupos
                                                      : l10n.institucionExtracBaseNoCupos,
                                                  icon: g.tieneCupos
                                                      ? Icons
                                                            .confirmation_number_outlined
                                                      : Icons
                                                            .remove_circle_outline,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              l10n.institucionExtracBaseGroupLine(
                                                _n(g.nombreGrupo).isEmpty
                                                    ? l10n.labelNotProvided
                                                    : _n(g.nombreGrupo),
                                              ),
                                              style: TextStyle(
                                                color: onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (_n(g.turno).isNotEmpty)
                                              Text(
                                                l10n.institucionExtracBaseTurnoLine(
                                                  _n(g.turno),
                                                ),
                                                style: TextStyle(
                                                  color: onSurfaceVariant,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            if (_n(g.aula).isNotEmpty)
                                              Text(
                                                l10n.institucionExtracBaseAulaLine(
                                                  _n(g.aula),
                                                ),
                                                style: TextStyle(
                                                  color: onSurfaceVariant,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _cuposLabelFromGrupo(l10n, g),
                                              style: TextStyle(
                                                color: onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _abrirFormCrearEditar(
                                                        k: k,
                                                        initial: g,
                                                      ),
                                                  icon: const Icon(Icons.edit),
                                                  label: Text(l10n.actionEdit),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _gestionarCuposMvp(
                                                        k: k,
                                                        g: g,
                                                      ),
                                                  icon: const Icon(Icons.tune),
                                                  label: Text(
                                                    l10n.institucionExtracBaseActionCupos,
                                                  ),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _borrarGrupoConConfirmacion(
                                                        k: k,
                                                        g: g,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  label: Text(
                                                    l10n.actionDelete,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: Text(l10n.institucionExtracBaseCreateGroupTitle),
                      subtitle: Text(
                        l10n.institucionExtracBaseCreateGroupSubtitle,
                      ),
                      enabled: k.isValid,
                      onTap: () => _abrirFormCrearEditar(k: k, initial: null),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.rule),
                      title: Text(l10n.institucionExtracBaseRulesTitle),
                      subtitle: Text(l10n.institucionExtracBaseRulesSubtitle),
                      onTap: () => _toast(
                        messenger,
                        l10n.institucionExtracBaseRulesPendingToast(
                          widget.bloque.label,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.inbox),
                      title: Text(l10n.institucionExtracBaseSolicitudesTitle),
                      subtitle: Text(
                        l10n.institucionExtracBaseSolicitudesSubtitle(
                          k.normalizedKey,
                        ),
                      ),
                      enabled: k.isValid,
                      onTap: k.isValid
                          ? () => _goSolicitudesModulo(k: k)
                          : () => _toast(
                              messenger,
                              k.errorMessage(l10n).isEmpty
                                  ? l10n.institucionExtracBaseInvalidDataGeneric
                                  : k.errorMessage(l10n),
                            ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
