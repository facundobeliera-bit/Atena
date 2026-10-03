// lib/screens/instituciones/widgets/pln_promo_card.dart
//
// Tarjeta del código promocional: campo para ingresarlo y estado aplicado.
// El código nunca se muestra ni se sugiere: lo escribe quien lo tiene.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';
import 'pln_precios.dart';

class PlnPromoCard extends StatelessWidget {
  final TextEditingController controller;

  /// El código ya está aplicado a la selección actual.
  final bool aplicado;

  /// El código ya quedó guardado en el plan: no se puede quitar.
  final bool fijo;

  final bool comprobando;
  final bool habilitado;
  final String? error;
  final VoidCallback onAplicar;
  final VoidCallback onQuitar;

  const PlnPromoCard({
    super.key,
    required this.controller,
    required this.aplicado,
    required this.fijo,
    required this.comprobando,
    required this.habilitado,
    required this.error,
    required this.onAplicar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activo = habilitado && !comprobando;

    return AtenaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AtenaIconBadge(
                icon: Icons.local_offer_rounded,
                color: AtenaColors.goldDeep,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.plnPromoTitulo,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (aplicado)
            _Aplicado(
              texto: fijo
                  ? t.plnPromoActivo(PlnPromo.porcentaje)
                  : t.plnPromoValido(PlnPromo.porcentaje),
              onQuitar: fijo || !habilitado ? null : onQuitar,
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: activo,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(32)],
                    onSubmitted: (_) => onAplicar(),
                    decoration: InputDecoration(
                      labelText: t.plnPromoCampo,
                      hintText: t.plnPromoHint,
                      errorText: error,
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton.tonal(
                    onPressed: activo ? onAplicar : null,
                    child: comprobando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(t.plnPromoAplicar),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Aplicado extends StatelessWidget {
  final String texto;
  final VoidCallback? onQuitar;

  const _Aplicado({required this.texto, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = AtenaBrand.of(context).success;
    final tone = AtenaTone.of(context, base);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(AtenaRadius.md)),
        border: Border.all(color: base.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: tone.foreground, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                texto,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tone.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (onQuitar != null)
            IconButton(
              tooltip: t.plnPromoQuitar,
              onPressed: onQuitar,
              icon: Icon(Icons.close_rounded, color: tone.foreground),
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    );
  }
}
