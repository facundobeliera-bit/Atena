import '../screens/alumnos/alumno_documentos_page.dart';
import '../screens/instituciones/institucion_documentos_page.dart';
import '../screens/instituciones/institucion_trayectoria_page.dart';
import '../screens/alumnos/trayectoria_educativa_page.dart';
import '../screens/alumnos/alumno_calendario_page.dart';
import '../screens/alumnos/alumno_notificaciones_page.dart';
import '../screens/instituciones/institucion_gestion_vacantes_page.dart';
import '../screens/instituciones/institucion_respuestas_calendario_page.dart';
import 'package:flutter/material.dart';

import '../models/catalogo/ficha_publica.dart';
import '../routes/solicitud_publica_intent.dart';
import '../screens/auth/alumno_login_page.dart';
import '../screens/alumnos/alumno_buscar_instituciones_page.dart';
import '../screens/alumnos/alumno_mis_solicitudes_page.dart';
import '../screens/alumnos/alumno_solicitar_vacante_page.dart';
import '../screens/instituciones/institucion_catalogo_page.dart';
import '../screens/instituciones/institucion_mis_solicitudes_page.dart';
import '../services/remote/multiuser_session.dart';
import 'atena_workspace.dart';

const remoteSourceLabel = 'Supabase compartido · Piloto de evaluación';

String remoteError(Object error) => error is StateError
    ? error.message.toString()
    : 'No se pudo confirmar la operación con el servidor. Actualizá o reintentá. No se guardó como operación local.';

Widget _frame(
  BuildContext context,
  String title,
  List<Widget> children, {
  VoidCallback? refresh,
  List<Widget> actions = const [],
}) => Scaffold(
  appBar: AppBar(
    title: Text(title),
    actions: [
      if (refresh != null)
        IconButton(
          tooltip: 'Actualizar',
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
      ...actions,
    ],
  ),
  body: AtenaWorkspace(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(remoteSourceLabel),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  ),
);

class RemoteAccountPanel extends StatefulWidget {
  final SolicitudPublicaIntent? intent;
  const RemoteAccountPanel({super.key, this.intent});
  @override
  State<RemoteAccountPanel> createState() => _RemoteAccountPanelState();
}

class _RemoteAccountPanelState extends State<RemoteAccountPanel> {
  RemoteIdentityContext? _identity;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _identity = null;
      _error = null;
    });
    try {
      final value = await MultiuserSession.current.context();
      if (mounted) setState(() => _identity = value);
    } catch (e) {
      if (mounted) setState(() => _error = remoteError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _profile(String id) async {
    try {
      final intent = widget.intent;
      final offer = intent == null
          ? null
          : await MultiuserSession.current.offer(
              intent.institucionId,
              intent.grupoId,
            );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => offer == null
              ? AlumnoMisSolicitudesPage(
                  ownerAccountId: MultiuserSession.current.userId,
                  perfilId: id,
                )
              : AlumnoSolicitarVacantePage(
                  alumnoDocumento: '',
                  institucionId: offer.institucionId,
                  institucionNombre: offer.nombre,
                  actividadNombre: offer.nombre,
                  esCurricular: offer.categoria == CategoriaPublica.formal,
                  ownerAccountId: MultiuserSession.current.userId,
                  perfilId: id,
                  grupoCurricularId: offer.id,
                  ofertaRemota: offer,
                ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = remoteError(e));
    }
  }

  Future<void> _logout() async {
    try {
      await MultiuserSession.current.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } catch (e) {
      if (mounted) setState(() => _error = remoteError(e));
    }
  }

  @override
  Widget build(BuildContext context) => _frame(
    context,
    'Cuenta / perfiles autorizados',
    [
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Text(_error!),
      if (!MultiuserSession.current.signedIn)
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AlumnoLoginPage(solicitudPublica: widget.intent),
            ),
          ),
          child: const Text('Ingresar'),
        ),
      if (widget.intent != null)
        const Text(
          'Elegí el perfil con el que querés solicitar la oferta seleccionada.',
        ),
      OutlinedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AlumnoBuscarInstitucionesPage.publica(),
          ),
        ),
        child: const Text('Explorar instituciones'),
      ),
      for (final profile in _identity?.profiles ?? <String>[])
        Card(
          child: ListTile(
            title: Text(profile),
            subtitle: const Text('Perfil solicitante verificado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _profile(profile),
          ),
        ),
      for (final profile in _identity?.profiles ?? <String>[]) ...[
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlumnoCalendarioPage(
                ownerAccountId: MultiuserSession.current.userId,
                perfilId: profile,
              ),
            ),
          ),
          child: Text('Calendario · $profile'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlumnoNotificacionesPage(
                alumnoDocumento: '',
                perfilIdFiltro: profile,
              ),
            ),
          ),
          child: Text('Notificaciones · $profile'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlumnoDocumentosPage(
                ownerAccountId: MultiuserSession.current.userId,
                perfilId: profile,
              ),
            ),
          ),
          child: Text('Documentos · $profile'),
        ),
      ],
      for (final profile in _identity?.profiles ?? <String>[])
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TrayectoriaEducativaPage.alumno(
                ownerAccountId: MultiuserSession.current.userId,
                perfilId: profile,
              ),
            ),
          ),
          child: Text('Trayectoria educativa · $profile'),
        ),
      for (final scope
          in _identity?.institutions ?? <RemoteInstitutionContext>[])
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${scope.name} · ${scope.areaName}'),
                if (scope.capabilities.contains('catalog.publish'))
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InstitucionCatalogoPage(
                          institucionId: scope.institutionId,
                          areaId: scope.areaId,
                        ),
                      ),
                    ),
                    child: const Text('Catálogo y disponibilidad'),
                  ),
                if (scope.capabilities.contains('calendar.write') ||
                    scope.capabilities.contains('communications.write'))
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InstitucionGestionVacantesPage(
                          institucionId: scope.institutionId,
                          institucionNombre: scope.name,
                          remoteAreaId: scope.areaId,
                        ),
                      ),
                    ),
                    child: const Text('Notificar / Emitir'),
                  ),
                if (scope.capabilities.contains('responses.read'))
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InstitucionRespuestasCalendarioPage(
                          ownerAccountId: MultiuserSession.current.userId,
                          institucionId: scope.institutionId,
                          areaId: scope.areaId,
                          areaNombre: scope.areaName,
                        ),
                      ),
                    ),
                    child: const Text('Respuestas de calendario'),
                  ),
                if (scope.capabilities.contains('documents.read'))
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InstitucionDocumentosPage(
                          institucionId: scope.institutionId,
                          institucionNombre: scope.name,
                          remoteAreaId: scope.areaId,
                        ),
                      ),
                    ),
                    child: const Text('Documentación del área'),
                  ),
                if (scope.capabilities.contains('education.read'))
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InstitucionTrayectoriaPage(
                          institucionId: scope.institutionId,
                          areaId: scope.areaId,
                        ),
                      ),
                    ),
                    child: const Text('Trayectoria del alumnado'),
                  ),
                if (scope.capabilities.contains('requests.read'))
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InstitucionMisSolicitudesPage(
                          institucionId: scope.institutionId,
                          institucionNombre: scope.name,
                          areaId: scope.areaId,
                        ),
                      ),
                    ),
                    child: const Text('Gestionar solicitudes'),
                  ),
              ],
            ),
          ),
        ),
      if (_identity != null &&
          _identity!.profiles.isEmpty &&
          _identity!.institutions.isEmpty)
        const Text('Tu cuenta todavía no tiene perfiles ni áreas autorizadas.'),
    ],
    refresh: _busy ? null : _load,
    actions: [
      IconButton(
        tooltip: 'Cerrar sesión',
        onPressed: _busy ? null : _logout,
        icon: const Icon(Icons.logout),
      ),
    ],
  );
}

class RemoteRequestPanel extends StatefulWidget {
  final String profile;
  final OfertaPublica offer;
  const RemoteRequestPanel({
    super.key,
    required this.profile,
    required this.offer,
  });
  @override
  State<RemoteRequestPanel> createState() => _RemoteRequestPanelState();
}

class _RemoteRequestPanelState extends State<RemoteRequestPanel> {
  final _operation = MultiuserSession.operationId();
  bool _busy = false;
  String? _error;
  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MultiuserSession.current.create(
        widget.profile,
        widget.offer,
        _operation,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AlumnoMisSolicitudesPage(
            ownerAccountId: MultiuserSession.current.userId,
            perfilId: widget.profile,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = remoteError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _frame(context, 'Solicitar vacante', [
    Text(widget.offer.nombre, style: Theme.of(context).textTheme.titleLarge),
    Text('${widget.offer.grupo} · ${widget.offer.horario}'),
    Text('Perfil: ${widget.profile}'),
    const Text(
      'La institución confirmará la inscripción según disponibilidad. Enviar una solicitud no reserva el cupo.',
    ),
    if (_error != null) Text(_error!),
    FilledButton(
      onPressed: _busy ? null : _submit,
      child: Text(_busy ? 'Enviando…' : 'Enviar solicitud'),
    ),
  ]);
}

class RemoteRequestsPanel extends StatefulWidget {
  final String? profile, institutionId, areaId;
  const RemoteRequestsPanel({
    super.key,
    this.profile,
    this.institutionId,
    this.areaId,
  });
  @override
  State<RemoteRequestsPanel> createState() => _RemoteRequestsPanelState();
}

class _RemoteRequestsPanelState extends State<RemoteRequestsPanel> {
  List<Map<String, dynamic>> _rows = [];
  Map<String, OfertaPublica> _offers = {};
  bool _busy = false, _canDecide = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _rows = [];
      _error = null;
    });
    try {
      final service = MultiuserSession.current;
      final rows = await service.requests(
        profile: widget.profile,
        institutionId: widget.institutionId,
        areaId: widget.areaId,
      );
      final offers = {
        for (final i in await service.catalog())
          for (final o in i.ofertas) o.id: o,
      };
      final canDecide =
          widget.profile == null &&
          (await service.institution(
            widget.institutionId!,
            widget.areaId!,
            'requests.read',
          )).capabilities.contains('requests.decide');
      if (mounted) {
        setState(() {
          _rows = rows;
          _offers = offers;
          _canDecide = canDecide;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = remoteError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(String id, String state) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MultiuserSession.current.decide(
        widget.institutionId!,
        widget.areaId!,
        id,
        state,
      );
    } catch (e) {
      if (mounted) setState(() => _error = remoteError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && _error == null) await _load();
  }

  @override
  Widget build(BuildContext context) => _frame(
    context,
    widget.profile == null ? 'Solicitudes institucionales' : 'Mis solicitudes',
    [
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Text(_error!),
      if (!_busy && _error == null && _rows.isEmpty)
        const Text('No hay solicitudes en este contexto.'),
      for (final row in _rows)
        Card(
          key: ValueKey<String>(row['id'] as String),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_offers[row['group_id']]?.nombre ?? 'Oferta no publicada'),
                Text('Perfil: ${row['applicant_profile_id']}'),
                Text(switch (row['state']) {
                  'confirmed' => 'Confirmada',
                  'rejected' => 'Rechazada',
                  'pending' => 'Pendiente',
                  _ => 'Cancelada',
                }),
                if (_offers[row['group_id']] case final offer?)
                  Text(
                    'Vacantes disponibles: ${offer.disponibles ?? 'Consultar'}',
                  ),
                if (_canDecide && row['state'] == 'pending')
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _decide(row['id'], 'confirmed'),
                        child: const Text('Confirmar'),
                      ),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _decide(row['id'], 'rejected'),
                        child: const Text('Rechazar'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
    ],
    refresh: _busy ? null : _load,
  );
}

class RemoteCatalogPanel extends StatefulWidget {
  final String institutionId, areaId;
  const RemoteCatalogPanel({
    super.key,
    required this.institutionId,
    required this.areaId,
  });
  @override
  State<RemoteCatalogPanel> createState() => _RemoteCatalogPanelState();
}

class _RemoteCatalogPanelState extends State<RemoteCatalogPanel> {
  Map<String, dynamic>? _record;
  List<OfertaPublica> _offers = [];
  String? _error, _success;
  String _operation = MultiuserSession.operationId(catalog: true);
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = MultiuserSession.current;
      final scope = await s.institution(
        widget.institutionId,
        widget.areaId,
        'catalog.publish',
      );
      final record = await s.publication(widget.institutionId, widget.areaId);
      final offers = (await s.catalog())
          .expand((i) => i.ofertas)
          .where((o) => o.areaId == scope.publicAreaId)
          .toList();
      if (mounted) {
        setState(() {
          _record = record;
          _offers = offers;
          _operation = MultiuserSession.operationId(catalog: true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _record = null;
          _offers = [];
          _error = remoteError(e);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    final record = _record;
    if (_busy || record == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await MultiuserSession.current.publish(
        widget.institutionId,
        widget.areaId,
        Map<String, dynamic>.from(record['document']),
        record['version'] as int,
        _operation,
      );
      if (mounted) {
        setState(() => _success = 'Publicación confirmada por Supabase.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = remoteError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && _error == null) await _load();
  }

  @override
  Widget build(
    BuildContext context,
  ) => _frame(context, 'Catálogo y disponibilidad', [
    if (_busy) const LinearProgressIndicator(),
    if (_error != null) Text(_error!),
    if (_success != null) Text(_success!),
    if (_record != null) Text('Versión remota: ${_record!['version']}'),
    for (final offer in _offers)
      Card(
        child: ListTile(
          title: Text(offer.nombre),
          subtitle: Text(
            '${offer.grupo} · ${offer.horario}\nVacantes disponibles: ${offer.disponibles ?? 'Consultar'}',
          ),
        ),
      ),
    const Text(
      'Sólo se muestran ofertas habilitadas en el piloto compartido. Los grupos locales no se importan automáticamente.',
    ),
    FilledButton(
      onPressed: _busy || _record == null ? null : _publish,
      child: const Text('Publicar catálogo compartido'),
    ),
  ], refresh: _busy ? null : _load);
}
