// lib/screens/alumnos/widgets/cal_al_evento_sheet.dart
//
// ATENA – Calendario del alumno: detalle de un evento y confirmación de
// asistencia (cuando la institución la pide).

import 'package:flutter/material.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import 'cal_al_items.dart';

/// Muestra el detalle del evento. Si el alumno responde la asistencia, la
/// respuesta se guarda y se devuelve al cerrar.
Future<Asistencia?> mostrarCalAlEvento(
  BuildContext context, {
  required Evento evento,
  required String perfilId,
  required String alumnoNombre,
  Asistencia? respuesta,
}) {
  return showModalBottomSheet<Asistencia>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AtenaRoleTheme(
      role: AtenaRole.alumno,
      child: _EventoSheet(
        evento: evento,
        perfilId: perfilId,
        alumnoNombre: alumnoNombre,
        respuesta: respuesta,
      ),
    ),
  );
}

class _EventoSheet extends StatefulWidget {
  final Evento evento;
  final String perfilId;
  final String alumnoNombre;
  final Asistencia? respuesta;

  const _EventoSheet({
    required this.evento,
    required this.perfilId,
    required this.alumnoNombre,
    required this.respuesta,
  });

  @override
  State<_EventoSheet> createState() => _EventoSheetState();
}

class _EventoSheetState extends State<_EventoSheet> {
  /// Respuesta que se está enviando (bloquea las opciones).
  Asistencia? _enviando;
  String? _error;

  /// false si la institución eliminó el evento con la hoja abierta.
  bool _disponible = true;

  bool get _pasado => DateUtils.dateOnly(
    widget.evento.finEfectivo,
  ).isBefore(DateUtils.dateOnly(DateTime.now()));

  Future<void> _responder(Asistencia a) async {
    if (_enviando != null || a == widget.respuesta) return;
    final t = AppLocalizations.of(context);
    setState(() {
      _enviando = a;
      _error = null;
    });
    try {
      final repo = CalendarioRepo.instance;
      final vigente = await repo.evento(
        widget.evento.institucionId,
        widget.evento.id,
      );
      if (vigente == null) {
        if (!mounted) return;
        setState(() {
          _enviando = null;
          _disponible = false;
          _error = t.calAlEventoNoDisponible;
        });
        return;
      }
      await repo.responder(
        evento: vigente,
        perfilId: widget.perfilId,
        alumnoNombre: widget.alumnoNombre,
        asistencia: a,
      );
      if (!mounted) return;
      Navigator.of(context).pop(a);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = null;
        _error = coreErrorText(t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = widget.evento;
    final lugar = e.lugar.trim();
    final descripcion = e.descripcion.trim();
    final elegida = _enviando ?? widget.respuesta;
    final error = _error;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AtenaStatusChip(
              label: t.tipoEvento(e.tipo),
              color: colorTipoEvento(e.tipo),
              icon: iconoTipoEvento(e.tipo),
            ),
            const SizedBox(height: 12),
            Text(e.titulo, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            AtenaInfoRow(
              icon: Icons.account_balance_rounded,
              label: t.commonInstitution,
              value: e.institucionNombre,
            ),
            AtenaInfoRow(
              icon: Icons.schedule_rounded,
              label: t.calAlCuando,
              value:
                  '${calAlFechasEvento(context, e)}\n'
                  '${calAlHorarioEvento(context, e)}',
            ),
            if (lugar.isNotEmpty)
              AtenaInfoRow(
                icon: Icons.place_rounded,
                label: t.calAlLugar,
                value: lugar,
              ),
            if (descripcion.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: AtenaRadius.field,
                ),
                child: Text(descripcion, style: theme.textTheme.bodyMedium),
              ),
            ],
            if (e.pideConfirmacion) ...[
              const SizedBox(height: 22),
              Text(t.calAlAsistenciaTitulo, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                _pasado ? t.calAlAsistenciaPasado : t.calAlAsistenciaAyuda,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in Asistencia.values) ...[
                    if (a != Asistencia.values.first) const SizedBox(width: 8),
                    Expanded(
                      child: _OpcionAsistencia(
                        asistencia: a,
                        seleccionada: elegida == a,
                        enviando: _enviando == a,
                        habilitada:
                            !_pasado && _disponible && _enviando == null,
                        atenuada: (_pasado || !_disponible) && elegida != a,
                        onTap: () => _responder(a),
                      ),
                    ),
                  ],
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                AtenaBanner(tone: AtenaBannerTone.error, message: error),
              ],
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.uiClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opción de asistencia (ícono + texto) con estado elegido y de envío.
class _OpcionAsistencia extends StatelessWidget {
  final Asistencia asistencia;
  final bool seleccionada;
  final bool enviando;
  final bool habilitada;
  final bool atenuada;
  final VoidCallback onTap;

  const _OpcionAsistencia({
    required this.asistencia,
    required this.seleccionada,
    required this.enviando,
    required this.habilitada,
    required this.atenuada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tone = AtenaTone.of(context, calAlColorAsistencia(asistencia));
    final color = seleccionada ? tone.foreground : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: seleccionada,
      enabled: habilitada,
      inMutuallyExclusiveGroup: true,
      child: Opacity(
        opacity: atenuada ? 0.5 : 1,
        child: Material(
          color: seleccionada ? tone.background : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AtenaRadius.field,
            side: BorderSide(
              color: seleccionada ? tone.color : cs.outlineVariant,
              width: seleccionada ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: habilitada ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: enviando
                        ? CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: tone.foreground,
                          )
                        : Icon(calAlIconoAsistencia(asistencia), color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.asistencia(asistencia),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: seleccionada ? tone.foreground : cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
