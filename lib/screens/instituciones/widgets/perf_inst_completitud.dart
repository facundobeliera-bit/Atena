// lib/screens/instituciones/widgets/perf_inst_completitud.dart
//
// Qué tan completo está el perfil público de la institución y qué conviene
// sumar para completarlo.

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';

/// Datos del perfil público que suman a la completitud, de mayor a menor peso.
enum PerfInstPaso {
  descripcion,
  fotos,
  logo,
  telefono,
  horarioAtencion,
  servicios,
  horarioClases,
  emailOWeb,
  redes,
}

class PerfInstCompletitud {
  static const int descripcionMinima = 80;
  static const int fotosRecomendadas = 3;

  /// De 0 a 100.
  final int porcentaje;

  /// Lo que falta, ordenado por importancia.
  final List<PerfInstPaso> pendientes;

  final int fotosFaltantes;

  const PerfInstCompletitud._(
    this.porcentaje,
    this.pendientes,
    this.fotosFaltantes,
  );

  bool get completo => pendientes.isEmpty;

  factory PerfInstCompletitud.calcular({
    required int largoDescripcion,
    required int fotos,
    required bool logo,
    required bool telefono,
    required bool horarioAtencion,
    required bool servicios,
    required bool horarioClases,
    required bool emailOWeb,
    required bool redes,
  }) {
    var puntos = 0;
    final pendientes = <PerfInstPaso>[];

    void paso(PerfInstPaso p, int peso, bool cumplido) {
      if (cumplido) {
        puntos += peso;
      } else {
        pendientes.add(p);
      }
    }

    // Una descripción corta suma la mitad; las fotos suman de a una.
    paso(PerfInstPaso.descripcion, 20, largoDescripcion >= descripcionMinima);
    if (largoDescripcion > 0 && largoDescripcion < descripcionMinima) {
      puntos += 10;
    }
    final conFotos = fotos.clamp(0, fotosRecomendadas);
    paso(PerfInstPaso.fotos, 20, conFotos == fotosRecomendadas);
    if (conFotos < fotosRecomendadas) {
      puntos += 20 * conFotos ~/ fotosRecomendadas;
    }
    paso(PerfInstPaso.logo, 15, logo);
    paso(PerfInstPaso.telefono, 10, telefono);
    paso(PerfInstPaso.horarioAtencion, 10, horarioAtencion);
    paso(PerfInstPaso.servicios, 10, servicios);
    paso(PerfInstPaso.horarioClases, 5, horarioClases);
    paso(PerfInstPaso.emailOWeb, 5, emailOWeb);
    paso(PerfInstPaso.redes, 5, redes);

    return PerfInstCompletitud._(
      puntos,
      pendientes,
      fotosRecomendadas - conFotos,
    );
  }

  /// Consejo para completar un dato que falta.
  String consejo(AppLocalizations t, PerfInstPaso paso) => switch (paso) {
    PerfInstPaso.descripcion => t.perfInstConsejoDescripcion(descripcionMinima),
    PerfInstPaso.fotos =>
      fotosFaltantes == fotosRecomendadas
          ? t.perfInstConsejoFotosPrimeras(fotosRecomendadas)
          : t.perfInstConsejoFotos(fotosFaltantes),
    PerfInstPaso.logo => t.perfInstConsejoLogo,
    PerfInstPaso.telefono => t.perfInstConsejoTelefono,
    PerfInstPaso.horarioAtencion => t.perfInstConsejoAtencion,
    PerfInstPaso.servicios => t.perfInstConsejoServicios,
    PerfInstPaso.horarioClases => t.perfInstConsejoClases,
    PerfInstPaso.emailOWeb => t.perfInstConsejoEmailWeb,
    PerfInstPaso.redes => t.perfInstConsejoRedes,
  };
}

/// Tarjeta "Tu perfil está completo al 70%" con los próximos pasos.
class PerfInstCompletitudCard extends StatelessWidget {
  final PerfInstCompletitud completitud;

  const PerfInstCompletitudCard({super.key, required this.completitud});

  static const int _maxConsejos = 3;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = completitud;

    return AtenaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: c.porcentaje / 100,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: cs.primaryContainer,
                        color: c.completo
                            ? AtenaBrand.of(context).success
                            : cs.primary,
                      ),
                      Center(
                        child: Text(
                          t.perfInstPorcentaje(c.porcentaje),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.completo
                          ? t.perfInstCompletoListo
                          : t.perfInstCompleto(c.porcentaje),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.completo
                          ? t.perfInstCompletoListoAyuda
                          : t.perfInstCompletoAyuda,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!c.completo) ...[
            const SizedBox(height: 12),
            for (final paso in c.pendientes.take(_maxConsejos))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.consejo(t, paso),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
