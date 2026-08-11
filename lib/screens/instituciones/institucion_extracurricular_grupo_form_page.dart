// lib/screens/instituciones/institucion_extracurricular_grupo_form_page.dart
//
// ATENA – INSTITUCIÓN – EXTRACURRICULARES – FORM (GRUPO)
// CANÓNICO:
// - institucionId = perfilId (perfil institución)
// - bloque = fuente de verdad (módulo)
// - moduleKey esperado = bloque.key (snake_case estable) (informativo en UI)
//
// Objetivo:
// - Crear / editar GrupoExtracurricular (prototipo SharedPreferences)
// - Validaciones mínimas y seguras
// - Guardado vía ExtracurricularesService.upsertGrupo
//
// Compat fuerte (enero 2026):
// - NO requiere copyWith()
// - NO requiere newGrupoId() en el modelo
// - Para edición, reconstruye el objeto por toMap/fromMap (conservador)
// - Genera id desde ExtracurricularesService.instance.newGrupoId()
//
// Fix analyzer (enero 2026):
// - Elimina use_build_context_synchronously:
//   * Captura messenger y navigator ANTES de awaits.
//   * Tras await: usa mounted y referencias capturadas (no re-lee context).
// - Mantiene llaves explícitas.
//
// Hardening adicional (estructura):
// - Normaliza moduleKey y muestra advertencia si no coincide con bloque.key.
// - Valida que moduleKey pertenezca al set canónico (solo advertencia; el bloqueo real
//   ya ocurre en ModuloBase).
// - Sanitiza números (solo dígitos / clamp) de forma predecible.
//
// ✅ FIX (cierre):
// - Alinea normalización de institucionId con ExtracurricularesService (_normKey: trim + colapsa whitespace).
// - Usa institucionId canónica tanto al persistir como al guardar dentro del objeto.
// - Evita recalcular strings normalizados repetidamente en _save().
//
// ✅ UX (fase 2):
// - Muestra descripcionCorta + ejemplos del bloque (guía de carga).
// - Incluye campo Aula/Espacio (modelo ya lo soporta).
//
// ✅ i18n + dark mode (enero 2026):
// - Textos vía AppLocalizations (ARB-ready).
// - Colores vía Theme/ColorScheme.

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/extracurriculares/grupo_extracurricular.dart';
import '../../services/extracurriculares_service.dart';

class InstitucionExtracurricularGrupoFormPage extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;

  final BloqueExtracurricular bloque;
  final String moduleKey;

  /// Si viene, es edición. Si no, es alta.
  final GrupoExtracurricular? initial;

  const InstitucionExtracurricularGrupoFormPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.bloque,
    required this.moduleKey,
    this.initial,
  });

  @override
  State<InstitucionExtracurricularGrupoFormPage> createState() =>
      _InstitucionExtracurricularGrupoFormPageState();
}

class _InstitucionExtracurricularGrupoFormPageState
    extends State<InstitucionExtracurricularGrupoFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _actividadCtrl = TextEditingController();
  final _grupoCtrl = TextEditingController();
  final _turnoCtrl = TextEditingController();
  final _aulaCtrl = TextEditingController();

  final _cupoMaxCtrl = TextEditingController();
  final _cupoOcupadoCtrl = TextEditingController();

  bool _activo = true;
  bool _saving = false;

  static String _n(String? v) => (v ?? '').trim();
  static String _norm(String v) => v.trim().toLowerCase();

  /// ✅ Alineado con ExtracurricularesService._normKey:
  /// trim + colapsa whitespace interno (lo elimina).
  static String _normIdKey(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

  String _normalizeModuleKey(String k) => _norm(k);

  int _parseIntSafe(String s, {int fallback = 0}) {
    final t = s.trim();
    if (t.isEmpty) return fallback;

    final onlyDigits = t.replaceAll(RegExp(r'[^0-9\-]'), '');
    final parsed = int.tryParse(onlyDigits);
    return parsed ?? fallback;
  }

  int _clamp(int v, int min, int max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  @override
  void initState() {
    super.initState();

    final g = widget.initial;

    if (g != null) {
      _actividadCtrl.text = g.actividadNombre;
      _grupoCtrl.text = g.nombreGrupo;

      _turnoCtrl.text = g.turno;
      _aulaCtrl.text = g.aula;

      _cupoMaxCtrl.text = g.cupoMaximo.toString();
      _cupoOcupadoCtrl.text = g.cupoOcupado.toString();

      _activo = g.activo;
    } else {
      _cupoMaxCtrl.text = '0';
      _cupoOcupadoCtrl.text = '0';
      _activo = true;
    }
  }

  @override
  void dispose() {
    _actividadCtrl.dispose();
    _grupoCtrl.dispose();
    _turnoCtrl.dispose();
    _aulaCtrl.dispose();
    _cupoMaxCtrl.dispose();
    _cupoOcupadoCtrl.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (_) {
      // NO-OP
    }
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

  GrupoExtracurricular _rebuildFromMap(GrupoExtracurricular base, Map m) {
    try {
      return GrupoExtracurricular.fromMap(Map<String, dynamic>.from(m));
    } catch (_) {
      return base; // fallback conservador
    }
  }

  Widget _buildGuiaBloque(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final b = widget.bloque;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.institucionExtracGrupoGuiaBloqueTitle,
              style:
                  (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
                      .copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              b.descripcionCorta,
              style:
                  (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: b.ejemplos
                  .map(
                    (e) => Chip(
                      label: Text(
                        e,
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 12) ??
                            const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateMin2Required(
    AppLocalizations l10n,
    String? v, {
    required String emptyMsg,
    required String shortMsg,
  }) {
    final t = _n(v);
    if (t.isEmpty) return emptyMsg;
    if (t.length < 2) return shortMsg;
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;

    _dismissKeyboard();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // ✅ Capturas ANTES de cualquier await
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);

    final instIdCanon = _normIdKey(widget.institucionId);
    if (instIdCanon.isEmpty) {
      _toast(messenger, l10n.institucionExtracGrupoInvalidInstitutionId);
      return;
    }

    final normalizedModuleKey = _normalizeModuleKey(widget.moduleKey);
    final expectedModuleKey = _normalizeModuleKey(widget.bloque.key);
    final isCanonicalKey = BloqueExtracurricularX.isValidKey(
      normalizedModuleKey,
    );

    // Avisos best-effort (no bloquea).
    if (normalizedModuleKey != expectedModuleKey) {
      _toast(
        messenger,
        l10n.institucionExtracGrupoWarnModuleKeyMismatch(expectedModuleKey),
      );
    } else if (!isCanonicalKey) {
      _toast(
        messenger,
        l10n.institucionExtracGrupoWarnModuleKeyNotCanonical(
          normalizedModuleKey,
        ),
      );
    }

    final actividad = _n(_actividadCtrl.text);
    final grupo = _n(_grupoCtrl.text);
    final turno = _n(_turnoCtrl.text);
    final aula = _n(_aulaCtrl.text);

    int cupoMax = _parseIntSafe(_cupoMaxCtrl.text, fallback: 0);
    int cupoOcupado = _parseIntSafe(_cupoOcupadoCtrl.text, fallback: 0);

    if (cupoMax < 0) cupoMax = 0;
    if (cupoOcupado < 0) cupoOcupado = 0;

    if (cupoMax > 0) {
      cupoOcupado = _clamp(cupoOcupado, 0, cupoMax);
    } else {
      cupoOcupado = 0; // consistencia MVP
    }

    final now = DateTime.now();
    final bool isEdit = widget.initial != null;

    GrupoExtracurricular nuevo;

    if (!isEdit) {
      final newId = ExtracurricularesService.instance.newGrupoId();

      nuevo = GrupoExtracurricular(
        id: newId,
        institucionId: instIdCanon,
        bloque: widget.bloque,
        actividadNombre: actividad,
        nombreGrupo: grupo,
        turno: turno,
        aula: aula,
        cupoMaximo: cupoMax,
        cupoOcupado: cupoOcupado,
        activo: _activo,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      final base = widget.initial!;
      final m = base.toMap();

      m['institucionId'] = instIdCanon;
      m['bloque'] = widget.bloque.key;

      m['actividadNombre'] = actividad;
      m['nombreGrupo'] = grupo;
      m['turno'] = turno;
      m['aula'] = aula;

      m['cupoMaximo'] = cupoMax;
      m['cupoOcupado'] = cupoOcupado;
      m['activo'] = _activo;

      m['updatedAt'] = now.toIso8601String();

      nuevo = _rebuildFromMap(base, m);
    }

    if (!mounted) return;
    setState(() => _saving = true);

    try {
      await ExtracurricularesService.instance.upsertGrupo(instIdCanon, nuevo);

      if (!mounted) return;
      nav.pop(true);
    } catch (e) {
      if (!mounted) return;
      _toast(messenger, l10n.institucionExtracGrupoSaveFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final instName = widget.institucionNombre.trim().isEmpty
        ? l10n.institucionGeneric
        : widget.institucionNombre.trim();

    final isEdit = widget.initial != null;

    final normalizedKey = _normalizeModuleKey(widget.moduleKey);
    final expectedKey = _normalizeModuleKey(widget.bloque.key);
    final keyOk = normalizedKey == expectedKey;

    final keyIsCanonical = BloqueExtracurricularX.isValidKey(normalizedKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? l10n.institucionExtracGrupoEditTitle
              : l10n.institucionExtracGrupoCreateTitle,
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            tooltip: l10n.actionSave,
          ),
        ],
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _saving,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
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
                      const SizedBox(height: 8),
                      _TextLine(
                        text: l10n.institucionExtracGrupoHeaderBloqueLine(
                          widget.bloque.label,
                          normalizedKey,
                        ),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.institucionExtracGrupoHeaderNotePrototype,
                        style:
                            (theme.textTheme.bodySmall ??
                                    const TextStyle(fontSize: 12))
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                      ),
                      if (!keyOk || !keyIsCanonical) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                !keyOk
                                    ? l10n.institucionExtracGrupoWarnKeyMismatch(
                                        expectedKey,
                                      )
                                    : l10n.institucionExtracGrupoWarnKeyNotCanonical(
                                        normalizedKey,
                                      ),
                                style:
                                    (theme.textTheme.bodySmall ??
                                            const TextStyle(fontSize: 12))
                                        .copyWith(
                                          color: theme.colorScheme.error,
                                        ),
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

              // ✅ Guía del bloque (descripcion + ejemplos)
              _buildGuiaBloque(context),
              const SizedBox(height: 14),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _actividadCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText:
                            l10n.institucionExtracGrupoFieldActividadLabel,
                        hintText: l10n.institucionExtracGrupoFieldActividadHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => _validateMin2Required(
                        l10n,
                        v,
                        emptyMsg:
                            l10n.institucionExtracGrupoValActividadRequired,
                        shortMsg: l10n.validationTooShort,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _grupoCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.institucionExtracGrupoFieldGrupoLabel,
                        hintText: l10n.institucionExtracGrupoFieldGrupoHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => _validateMin2Required(
                        l10n,
                        v,
                        emptyMsg: l10n.institucionExtracGrupoValGrupoRequired,
                        shortMsg: l10n.validationTooShort,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _turnoCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText:
                            l10n.institucionExtracGrupoFieldTurnoOptionalLabel,
                        hintText:
                            l10n.institucionExtracGrupoFieldTurnoOptionalHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _aulaCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText:
                            l10n.institucionExtracGrupoFieldAulaOptionalLabel,
                        hintText:
                            l10n.institucionExtracGrupoFieldAulaOptionalHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cupoMaxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  l10n.institucionExtracGrupoFieldCupoMaxLabel,
                              hintText:
                                  l10n.institucionExtracGrupoFieldCupoMaxHint,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = _parseIntSafe(v ?? '', fallback: 0);
                              if (n < 0) return l10n.validationCannotBeNegative;
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cupoOcupadoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n
                                  .institucionExtracGrupoFieldCupoOcupadoLabel,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final occ = _parseIntSafe(v ?? '', fallback: 0);
                              if (occ < 0) {
                                return l10n.validationCannotBeNegative;
                              }

                              final max = _parseIntSafe(
                                _cupoMaxCtrl.text,
                                fallback: 0,
                              );
                              if (max > 0 && occ > max) {
                                return l10n
                                    .institucionExtracGrupoValOccExceedsMax;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _activo,
                      onChanged: (v) => setState(() => _activo = v),
                      title: Text(l10n.institucionExtracGrupoFieldActivoTitle),
                      subtitle: Text(
                        l10n.institucionExtracGrupoFieldActivoSubtitle,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _saving ? l10n.statusSaving : l10n.actionSave,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget mínimo para evitar repetir estilos y mantener legibilidad (sin dependencias).
class _TextLine extends StatelessWidget {
  final String text;
  final Color? color;

  const _TextLine({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: color));
  }
}
