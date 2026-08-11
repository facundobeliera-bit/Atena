// lib/screens/alumno/alumno_dashboard_page.dart
//
// ATENA – ALUMNO / DASHBOARD (CANÓNICO owner → perfiles)
//
// ✅ CIERRE FASE 2:
// - “Buscar instituciones” habilitado (no puede quedar disabled).
// - Navega a placeholder compilable para depurar flujo en Chrome.
// - “Mis solicitudes” sigue placeholder hasta pegar screen real.
// - ✅ i18n REAL (sin fallbacks): AppLocalizations.of(context).<key>
// - ✅ Theme/ColorScheme real (sin hardcode / sin withOpacity).
// - ✅ Simplificación: helpers mínimos, menos ruido, misma funcionalidad.

import 'package:flutter/material.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';

class AlumnoDashboardPage extends StatelessWidget {
  final String alumnoDocumento;

  /// ✅ owner-only
  final String ownerAccountId;

  /// ✅ perfil actual (dentro de la cuenta)
  final String perfilId;

  const AlumnoDashboardPage({
    super.key,
    required this.alumnoDocumento,
    required this.ownerAccountId,
    required this.perfilId,
  });

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = cs.surface.withValues(alpha: isDark ? 0.86 : 1.0);
    final dividerColor = cs.outlineVariant.withValues(
      alpha: isDark ? 0.55 : 0.35,
    );

    Widget card(Widget child) => Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alumnoDashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          card(
            ListTile(
              leading: const Icon(Icons.badge),
              title: Text(l10n.alumnoDashboardMiDni),
              subtitle: Text(
                alumnoDocumento,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ✅ “MIS SOLICITUDES” (owner-only)
          card(
            ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(l10n.alumnoDashboardMisSolicitudes),
              subtitle: Text(l10n.alumnoDashboardMisSolicitudesSub),
              onTap: () => _push(
                context,
                _AlumnoMisSolicitudesPlaceholderPage(
                  alumnoDocumento: alumnoDocumento,
                  ownerAccountId: ownerAccountId,
                  perfilId: perfilId,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: dividerColor),
          ),

          // ✅ “BUSCAR INSTITUCIONES”
          card(
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(l10n.alumnoDashboardBuscarInstituciones),
              subtitle: Text(l10n.alumnoDashboardBuscarInstitucionesSub),
              onTap: () => _push(
                context,
                _AlumnoBuscarInstitucionesPlaceholderPage(
                  ownerAccountId: ownerAccountId,
                  perfilId: perfilId,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          card(
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.commonLogout),
              subtitle: Text(l10n.alumnoDashboardCerrarSesionSub),
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================================================
/// PLACEHOLDER – Mis Solicitudes
/// =====================================================
class _AlumnoMisSolicitudesPlaceholderPage extends StatelessWidget {
  final String alumnoDocumento;
  final String ownerAccountId;
  final String perfilId;

  const _AlumnoMisSolicitudesPlaceholderPage({
    required this.alumnoDocumento,
    required this.ownerAccountId,
    required this.perfilId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = cs.surface.withValues(alpha: isDark ? 0.90 : 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alumnoMisSolicitudesTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.commonPendingConnect,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text('DNI: $alumnoDocumento'),
                Text('ownerAccountId: $ownerAccountId'),
                Text('perfilId: $perfilId'),
                const SizedBox(height: 10),
                Text(l10n.commonPasteRealScreenHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================================================
/// PLACEHOLDER – Buscar Instituciones
/// =====================================================
class _AlumnoBuscarInstitucionesPlaceholderPage extends StatefulWidget {
  final String ownerAccountId;
  final String perfilId;

  const _AlumnoBuscarInstitucionesPlaceholderPage({
    required this.ownerAccountId,
    required this.perfilId,
  });

  @override
  State<_AlumnoBuscarInstitucionesPlaceholderPage> createState() =>
      _AlumnoBuscarInstitucionesPlaceholderPageState();
}

class _AlumnoBuscarInstitucionesPlaceholderPageState
    extends State<_AlumnoBuscarInstitucionesPlaceholderPage> {
  final TextEditingController _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _q.text.trim();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = cs.surface.withValues(alpha: isDark ? 0.90 : 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alumnoBuscarInstitucionesTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.alumnoBuscarPlaceholderTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('ownerAccountId: ${widget.ownerAccountId}'),
                    Text('perfilId: ${widget.perfilId}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _q,
                      decoration: InputDecoration(
                        labelText: l10n.commonSearch,
                        hintText: l10n.commonSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      query.isEmpty
                          ? l10n.alumnoBuscarPlaceholderEmpty
                          : l10n.alumnoBuscarPlaceholderQuery(query),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
