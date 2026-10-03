// lib/screens/instituciones/widgets/perf_inst_form_datos.dart
//
// Pestaña "Datos" del perfil: identificación, ubicación y contacto
// administrativo de la institución.

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../models/instituciones/instituciones_integrado.dart';
import '../../../ui/atena_labels.dart';
import '../../../ui/atena_ui.dart';
import '../../auth/widgets/auth_shell.dart';
import 'perf_inst_campos.dart';

class PerfInstFormDatos extends StatelessWidget {
  final PerfInstCampos campos;
  final bool habilitado;
  final TipoInstitucion tipo;
  final ModalidadCursado modalidad;
  final ValueChanged<TipoInstitucion> onTipo;
  final ValueChanged<ModalidadCursado> onModalidad;

  const PerfInstFormDatos({
    super.key,
    required this.campos,
    required this.habilitado,
    required this.tipo,
    required this.modalidad,
    required this.onTipo,
    required this.onModalidad,
  });

  static const int _maxLinea = 120;
  static const int _maxLugar = 60;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const gap = SizedBox(height: 14);
    const seccion = SizedBox(height: AtenaSpace.md);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PerfInstSeccion(
          titulo: t.perfInstSecIdentidad,
          ayuda: t.perfInstSecIdentidadAyuda,
          children: [
            PerfInstCampo(
              controller: campos.nombre,
              label: t.perfInstNombre,
              icon: Icons.account_balance_outlined,
              habilitado: habilitado,
              mayusculas: TextCapitalization.words,
              largoMaximo: _maxLinea,
              autofill: const [AutofillHints.organizationName],
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return t.commonRequiredField;
                return s.length < 3 ? t.perfInstNombreCorto : null;
              },
            ),
            gap,
            PerfInstCampo(
              controller: campos.cuit,
              label: t.perfInstCuit,
              helper: t.perfInstCuitAyuda,
              icon: Icons.badge_outlined,
              habilitado: habilitado,
              teclado: TextInputType.number,
              formato: [digitsOnly],
              largoMaximo: 11,
              validator: (v) => AuthValidators.cuit(t, v),
            ),
            gap,
            DropdownButtonFormField<TipoInstitucion>(
              initialValue: tipo,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.perfInstTipo,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: [
                for (final x in TipoInstitucion.values)
                  DropdownMenuItem(
                    value: x,
                    child: Text(
                      t.tipoInstitucion(x),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: habilitado
                  ? (x) {
                      if (x != null) onTipo(x);
                    }
                  : null,
            ),
            gap,
            _SelectorModalidad(
              valor: modalidad,
              onChanged: habilitado ? onModalidad : null,
            ),
          ],
        ),
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecUbicacion,
          children: [
            PerfInstCampo(
              controller: campos.direccion,
              label: t.perfInstDireccion,
              icon: Icons.place_outlined,
              habilitado: habilitado,
              mayusculas: TextCapitalization.words,
              largoMaximo: _maxLinea,
              autofill: const [AutofillHints.streetAddressLine1],
              validator: (v) => AuthValidators.required(t, v),
            ),
            gap,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PerfInstCampo(
                    controller: campos.ciudad,
                    label: t.perfInstCiudad,
                    habilitado: habilitado,
                    mayusculas: TextCapitalization.words,
                    largoMaximo: _maxLugar,
                    autofill: const [AutofillHints.addressCity],
                    validator: (v) => AuthValidators.required(t, v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PerfInstCampo(
                    controller: campos.provincia,
                    label: t.perfInstProvincia,
                    habilitado: habilitado,
                    mayusculas: TextCapitalization.words,
                    largoMaximo: _maxLugar,
                    autofill: const [AutofillHints.addressState],
                    validator: (v) => AuthValidators.required(t, v),
                  ),
                ),
              ],
            ),
            gap,
            PerfInstCampo(
              controller: campos.pais,
              label: t.perfInstPais,
              icon: Icons.public_rounded,
              habilitado: habilitado,
              mayusculas: TextCapitalization.words,
              largoMaximo: _maxLugar,
              autofill: const [AutofillHints.countryName],
              validator: (v) => AuthValidators.required(t, v),
            ),
          ],
        ),
        seccion,
        PerfInstSeccion(
          titulo: t.perfInstSecAdmin,
          ayuda: t.perfInstSecAdminAyuda,
          children: [
            PerfInstCampo(
              controller: campos.email,
              label: t.perfInstEmailAdmin,
              icon: Icons.alternate_email_rounded,
              habilitado: habilitado,
              teclado: TextInputType.emailAddress,
              largoMaximo: _maxLinea,
              autofill: const [AutofillHints.email],
              validator: (v) => AuthValidators.email(t, v),
            ),
            gap,
            PerfInstCampo(
              controller: campos.telefono,
              label: t.commonPhone,
              icon: Icons.phone_outlined,
              habilitado: habilitado,
              teclado: TextInputType.phone,
              formato: [PerfInstFormato.teclasTelefono],
              largoMaximo: 24,
              autofill: const [AutofillHints.telephoneNumber],
              validator: (v) => PerfInstFormato.telefono(t, v, requerido: true),
            ),
          ],
        ),
      ],
    );
  }
}

/// Modalidad de cursado: segmentado en fila o, si no hay ancho, en columna.
class _SelectorModalidad extends StatelessWidget {
  final ModalidadCursado valor;

  /// null = deshabilitado.
  final ValueChanged<ModalidadCursado>? onChanged;

  const _SelectorModalidad({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cambiar = onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.perfInstModalidad, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final enColumna = c.maxWidth < 400;
            return SegmentedButton<ModalidadCursado>(
              direction: enColumna ? Axis.vertical : Axis.horizontal,
              // En fila reparte el ancho entre las opciones; en columna ya
              // ocupa todo el ancho que recibe.
              expandedInsets: enColumna ? null : EdgeInsets.zero,
              segments: [
                for (final m in ModalidadCursado.values)
                  ButtonSegment(value: m, label: Text(t.modalidad(m))),
              ],
              selected: {valor},
              onSelectionChanged: cambiar == null
                  ? null
                  : (seleccion) => cambiar(seleccion.first),
            );
          },
        ),
      ],
    );
  }
}
