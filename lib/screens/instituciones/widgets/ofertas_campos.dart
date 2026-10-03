// lib/screens/instituciones/widgets/ofertas_campos.dart
//
// ATENA – Piezas compartidas de las vacantes: niveles y categorías que habilita
// el plan, selector de opciones en tarjetas, campo numérico con botones,
// selector de días y armado del texto de horario y días.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/extracurriculares/bloque_extracurricular.dart';
import '../../../models/instituciones/instituciones_integrado.dart';
import '../../../ui/atena_ui.dart';

// -----------------------------------------------------------------------------
// Plan de la institución
// -----------------------------------------------------------------------------

/// Niveles curriculares que el plan de la institución tiene habilitados.
List<NivelCurricular> ofertasNivelesHabilitados(Institucion inst) {
  if (!inst.curricular) return const <NivelCurricular>[];
  final plan = inst.planSafe;
  return [
    for (final n in NivelCurricular.values)
      if (plan.niveles.any((x) => x.nivel == n && x.habilitado)) n,
  ];
}

/// Categorías (bloques) extracurriculares que el plan tiene habilitadas.
List<BloqueExtracurricular> ofertasBloquesHabilitados(Institucion inst) {
  if (!inst.extracurricular) return const <BloqueExtracurricular>[];
  final plan = inst.planSafe;
  return [
    for (final b in BloqueExtracurricularX.ordered())
      if (plan.modulos.any((x) => x.bloque == b && x.habilitado)) b,
  ];
}

/// true si el plan permite publicar vacantes de este tipo.
bool ofertasTipoHabilitado(Institucion inst, TipoOferta tipo) => switch (tipo) {
  TipoOferta.curricular => ofertasNivelesHabilitados(inst).isNotEmpty,
  TipoOferta.extracurricular => ofertasBloquesHabilitados(inst).isNotEmpty,
};

/// true si el plan permite crear vacantes en el nivel o categoría de [o].
bool ofertasCategoriaHabilitada(Institucion inst, Oferta o) {
  if (o.esCurricular) {
    return o.nivel != null && ofertasNivelesHabilitados(inst).contains(o.nivel);
  }
  return o.bloque != null && ofertasBloquesHabilitados(inst).contains(o.bloque);
}

// -----------------------------------------------------------------------------
// Íconos y textos de ayuda
// -----------------------------------------------------------------------------

IconData ofertasIconoTipo(TipoOferta tipo) => switch (tipo) {
  TipoOferta.curricular => Icons.school_rounded,
  TipoOferta.extracurricular => Icons.interests_rounded,
};

IconData ofertasIconoTurno(Turno turno) => switch (turno) {
  Turno.manana => Icons.wb_sunny_rounded,
  Turno.tarde => Icons.wb_twilight_rounded,
  Turno.noche => Icons.bedtime_rounded,
  Turno.completo => Icons.schedule_rounded,
};

/// Ejemplos de actividades para la categoría elegida.
String ofertasEjemplos(AppLocalizations t, BloqueExtracurricular? b) =>
    switch (b) {
      null => t.ofertasEjemplosGeneral,
      BloqueExtracurricular.deporteYMovimiento => t.ofertasEjemplosDeporte,
      BloqueExtracurricular.arteYExpresion => t.ofertasEjemplosArte,
      BloqueExtracurricular.idiomasYComunicacion => t.ofertasEjemplosIdiomas,
      BloqueExtracurricular.cienciaTecnologiaYRobotica =>
        t.ofertasEjemplosCiencia,
      BloqueExtracurricular.apoyoAcademico => t.ofertasEjemplosApoyo,
      BloqueExtracurricular.desarrolloPersonalYBienestar =>
        t.ofertasEjemplosBienestar,
      BloqueExtracurricular.otros => t.ofertasEjemplosOtros,
    };

/// Títulos sugeridos para una vacante curricular del nivel indicado.
List<String> ofertasSugerencias(AppLocalizations t, NivelCurricular nivel) =>
    switch (nivel) {
      NivelCurricular.jardin => [
        for (var n = 2; n <= 5; n++) t.ofertasSugSala(n),
      ],
      NivelCurricular.primaria => [
        for (var n = 1; n <= 7; n++) t.ofertasSugGrado(n),
      ],
      NivelCurricular.secundaria || NivelCurricular.tecnica => [
        for (var n = 1; n <= 6; n++) t.ofertasSugAnio(n),
      ],
      NivelCurricular.terciario => [
        for (var n = 1; n <= 4; n++) t.ofertasSugAnio(n),
      ],
    };

// -----------------------------------------------------------------------------
// Días y horario
// -----------------------------------------------------------------------------

/// Nombres cortos de los días, de lunes (0) a domingo (6).
List<String> ofertasNombresDias(AppLocalizations t) => [
  t.ofertasDiaLun,
  t.ofertasDiaMar,
  t.ofertasDiaMie,
  t.ofertasDiaJue,
  t.ofertasDiaVie,
  t.ofertasDiaSab,
  t.ofertasDiaDom,
];

/// Texto legible de los días elegidos: "Lun a Vie", "Lun, Mié y Vie"…
String ofertasTextoDias(AppLocalizations t, Set<int> dias) {
  if (dias.isEmpty) return '';
  final orden = dias.toList()..sort();
  final nombres = ofertasNombresDias(t);
  if (orden.length == 7) return t.ofertasDiasTodos;
  if (orden.length == 1) return nombres[orden.first];
  final seguidos = orden.last - orden.first == orden.length - 1;
  if (seguidos && orden.length >= 3) {
    return t.ofertasDiasRango(nombres[orden.first], nombres[orden.last]);
  }
  final partes = [for (final d in orden) nombres[d]];
  return t.ofertasDiasLista(
    partes.sublist(0, partes.length - 1).join(', '),
    partes.last,
  );
}

/// Días a partir del texto guardado, o null si no se reconoce el formato.
/// El texto pudo guardarse con la app en otro idioma: se prueban todos.
Set<int>? ofertasLeerDias(AppLocalizations t, String texto) {
  final buscado = normalizarBusqueda(texto);
  if (buscado.isEmpty) return <int>{};
  final idiomas = [
    t,
    for (final l in AppLocalizations.supportedLocales)
      if (l.languageCode != t.localeName) lookupAppLocalizations(l),
  ];
  for (final idioma in idiomas) {
    for (var mascara = 1; mascara < 128; mascara++) {
      final dias = {
        for (var d = 0; d < 7; d++)
          if (mascara & (1 << d) != 0) d,
      };
      if (normalizarBusqueda(ofertasTextoDias(idioma, dias)) == buscado) {
        return dias;
      }
    }
  }
  return null;
}

/// Hora en formato 24 h con dos dígitos ("08:05").
String ofertasHora(TimeOfDay h) =>
    '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

int ofertasMinutos(TimeOfDay h) => h.hour * 60 + h.minute;

final RegExp _horarioSimple = RegExp(
  r'^\s*(\d{1,2})[:.](\d{2})\s*\S{1,4}\s*(\d{1,2})[:.](\d{2})\s*$',
);

/// Lee un horario guardado del tipo "08:00 a 12:00" (null si no coincide).
(TimeOfDay, TimeOfDay)? ofertasLeerHorario(String texto) {
  final m = _horarioSimple.firstMatch(texto);
  if (m == null) return null;
  final v = [for (var i = 1; i <= 4; i++) int.parse(m.group(i)!)];
  if (v[0] > 23 || v[2] > 23 || v[1] > 59 || v[3] > 59) return null;
  return (
    TimeOfDay(hour: v[0], minute: v[1]),
    TimeOfDay(hour: v[2], minute: v[3]),
  );
}

// -----------------------------------------------------------------------------
// Selector de opciones en tarjetas
// -----------------------------------------------------------------------------

class OfertasOpcion<T> {
  final T valor;
  final IconData icono;
  final String titulo;
  final String? detalle;

  const OfertasOpcion({
    required this.valor,
    required this.icono,
    required this.titulo,
    this.detalle,
  });
}

/// Elige una opción entre varias. Las tarjetas se acomodan en columnas según
/// el ancho disponible (todas de la misma altura en cada fila).
class OfertasSelector<T> extends StatelessWidget {
  final List<OfertasOpcion<T>> opciones;
  final T? seleccion;
  final ValueChanged<T>? onChanged;

  /// Ancho mínimo de cada tarjeta.
  final double anchoMinimo;

  const OfertasSelector({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.onChanged,
    this.anchoMinimo = 150,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, c) {
        final n = opciones.length;
        var cols = math.max(
          1,
          math.min(n, ((c.maxWidth + gap) / (anchoMinimo + gap)).floor()),
        );
        if (n == 4 && cols == 3) cols = 2;

        final filas = <Widget>[];
        for (var i = 0; i < n; i += cols) {
          final fila = opciones.sublist(i, math.min(i + cols, n));
          filas.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < cols; j++) ...[
                    if (j > 0) const SizedBox(width: gap),
                    Expanded(
                      child: j < fila.length
                          ? _OpcionTile<T>(
                              opcion: fila[j],
                              seleccionada: fila[j].valor == seleccion,
                              onTap: onChanged == null
                                  ? null
                                  : () => onChanged!(fila[j].valor),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < filas.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              filas[i],
            ],
          ],
        );
      },
    );
  }
}

class _OpcionTile<T> extends StatelessWidget {
  final OfertasOpcion<T> opcion;
  final bool seleccionada;
  final VoidCallback? onTap;

  const _OpcionTile({
    required this.opcion,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = seleccionada ? cs.onPrimaryContainer : cs.onSurface;
    final detalle = (opcion.detalle ?? '').trim();

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: seleccionada,
      child: Material(
        color: seleccionada ? cs.primaryContainer : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AtenaRadius.field,
          side: BorderSide(
            color: seleccionada ? cs.primary : cs.outlineVariant,
            width: seleccionada ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    opcion.icono,
                    size: 22,
                    color: seleccionada
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          opcion.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: fg,
                          ),
                        ),
                        if (detalle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            detalle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: seleccionada
                                  ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (seleccionada) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: cs.onPrimaryContainer,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Campos que se validan juntos
// -----------------------------------------------------------------------------

/// Marca un campo en rojo sin repetir el mensaje (lo muestra el grupo).
Widget? ofertasMarcaError(bool hayError) =>
    hayError ? const SizedBox.shrink() : null;

/// Uno o más campos que se validan en conjunto. El error (o la ayuda) se
/// muestra debajo, a todo el ancho, en lugar de apretarse dentro de un campo
/// angosto.
class OfertasGrupoValidado extends StatelessWidget {
  final String? Function() validar;
  final String? ayuda;

  /// Arma los campos: [hayError] indica si hay que marcarlos y [alCambiar] se
  /// llama cada vez que el usuario modifica un valor.
  final Widget Function(
    BuildContext context,
    bool hayError,
    VoidCallback alCambiar,
  )
  builder;

  const OfertasGrupoValidado({
    super.key,
    required this.validar,
    required this.builder,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: 0,
      validator: (_) => validar(),
      builder: (campo) {
        final theme = Theme.of(campo.context);
        final error = campo.errorText;
        final texto = (error ?? ayuda ?? '').trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            builder(
              campo.context,
              error != null,
              () => campo.didChange((campo.value ?? 0) + 1),
            ),
            if (texto.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Semantics(
                  liveRegion: error != null,
                  child: Text(
                    texto,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: error == null ? null : theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Campo numérico con botones − / +
// -----------------------------------------------------------------------------

class OfertasNumeroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final int minimo;
  final int maximo;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  const OfertasNumeroField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.minimo = 1,
    this.maximo = 999,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return OfertasGrupoValidado(
      validar: () => validator?.call(controller.text),
      ayuda: helperText,
      builder: (context, hayError, alCambiar) {
        final valor = int.tryParse(controller.text.trim());

        void fijar(int nuevo) {
          final texto = '${nuevo.clamp(minimo, maximo)}';
          controller.value = TextEditingValue(
            text: texto,
            selection: TextSelection.collapsed(offset: texto.length),
          );
          alCambiar();
        }

        return Row(
          children: [
            _BotonPaso(
              icono: Icons.remove_rounded,
              tooltip: t.ofertasRestarUno,
              onPressed: enabled && valor != null && valor > minimo
                  ? () => fijar(valor - 1)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter('$maximo'.length),
                ],
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  labelText: label,
                  error: ofertasMarcaError(hayError),
                ),
                onChanged: (_) => alCambiar(),
              ),
            ),
            const SizedBox(width: 10),
            _BotonPaso(
              icono: Icons.add_rounded,
              tooltip: t.ofertasSumarUno,
              onPressed: enabled && (valor ?? 0) < maximo
                  ? () => fijar((valor ?? 0) + 1)
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _BotonPaso extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback? onPressed;

  const _BotonPaso({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 56,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AtenaRadius.field),
        ),
        icon: Icon(icono),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Selector de días
// -----------------------------------------------------------------------------

class OfertasDiasSelector extends StatelessWidget {
  /// Días elegidos: 0 = lunes … 6 = domingo.
  final Set<int> seleccion;
  final ValueChanged<Set<int>>? onChanged;

  const OfertasDiasSelector({
    super.key,
    required this.seleccion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nombres = ofertasNombresDias(AppLocalizations.of(context));
    // Sin separación extra entre renglones: cada chip ya reserva su área táctil.
    return Wrap(
      spacing: 8,
      children: [
        for (var d = 0; d < 7; d++)
          FilterChip(
            label: Text(nombres[d]),
            selected: seleccion.contains(d),
            onSelected: onChanged == null
                ? null
                : (elegido) {
                    final nuevos = {...seleccion};
                    if (elegido) {
                      nuevos.add(d);
                    } else {
                      nuevos.remove(d);
                    }
                    onChanged!(nuevos);
                  },
          ),
      ],
    );
  }
}
