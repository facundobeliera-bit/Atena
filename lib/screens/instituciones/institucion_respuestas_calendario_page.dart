import '../../services/remote/multiuser_session.dart';
import '../../services/remote/emisiones_supabase_repository.dart';
import 'package:flutter/material.dart';

import '../../services/alumno_calendario_interacciones_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/session_service.dart';

class InstitucionRespuestasCalendarioPage extends StatefulWidget {
  final String ownerAccountId;
  final String institucionId;
  final String? areaId;
  final String? areaNombre;

  const InstitucionRespuestasCalendarioPage({
    super.key,
    required this.ownerAccountId,
    required this.institucionId,
    this.areaId,
    this.areaNombre,
  });

  @override
  State<InstitucionRespuestasCalendarioPage> createState() =>
      _InstitucionRespuestasCalendarioPageState();
}

class _RespuestaUi {
  final RespuestaCalendarioInstitucion response;
  final String studentName;

  const _RespuestaUi({required this.response, required this.studentName});
}

class _InstitucionRespuestasCalendarioPageState
    extends State<InstitucionRespuestasCalendarioPage> {
  bool _loading = true;
  bool _accessDenied = false;
  String? _error;
  List<_RespuestaUi> _responses = const <_RespuestaUi>[];

  static String _id(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _hasValidInstitutionContext() async {
    if (MultiuserSession.enabled) {
      await MultiuserSession.current.institution(
        widget.institucionId,
        widget.areaId ?? '',
        'responses.read',
      );
      return true;
    }
    final expectedOwner = _id(widget.ownerAccountId);
    final expectedInstitution = _id(widget.institucionId);
    if (expectedOwner.isEmpty || expectedInstitution.isEmpty) return false;

    final session = await SessionService.getSession();
    if (session == null || session.role != SessionRole.institucion) {
      return false;
    }
    if (_id(session.userId) != expectedInstitution) return false;

    final sessionOwner =
        await SessionService.getInstitucionOwnerAccountIdLogueado();
    if (_id(sessionOwner ?? '') != expectedOwner) return false;

    final belongs = await CuentaService.ownerTienePerfil(
      ownerAccountId: expectedOwner,
      perfilId: expectedInstitution,
    );
    return belongs;
  }

  Future<String> _studentName(RespuestaCalendarioInstitucion response) async {
    if (MultiuserSession.enabled) return response.perfilId;
    final owner = await CuentaService.getOwnerAccountIdForPerfilAlumno(
      response.perfilId,
    );
    if (_id(owner ?? '') != _id(response.ownerAccountId)) {
      return response.perfilId;
    }
    final profile = await CuentaService.getPerfilAlumnoById(response.perfilId);
    final name = profile?.displayName.trim() ?? '';
    return name.isEmpty ? response.perfilId : name;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (!await _hasValidInstitutionContext()) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _accessDenied = true;
          _responses = const <_RespuestaUi>[];
        });
        return;
      }

      final area = _id(widget.areaId ?? '');
      final responses = MultiuserSession.enabled
          ? (await EmisionesSupabaseRepository(
                  MultiuserSession.current,
                ).responses(widget.institucionId, area))
                .where((r) => r['respondedAt'] != null)
                .map(
                  (r) => RespuestaCalendarioInstitucion(
                    id: r['id'],
                    institucionId: r['institucionId'],
                    ownerAccountId: '',
                    perfilId: r['perfilId'],
                    eventId: r['eventId'],
                    areaId: r['areaId'],
                    grupoId: r['grupoId'],
                    dateKey: r['eventDate'],
                    status: RsvpStatusAtena.values.byName(r['status']),
                    respondedAt: DateTime.parse(r['respondedAt']),
                    eventTitle: r['eventTitle'],
                  ),
                )
                .toList()
          : area.isEmpty
          ? await AlumnoCalendarioInteraccionesService.instance
                .listarRespuestasInstitucion(widget.institucionId)
          : await AlumnoCalendarioInteraccionesService.instance
                .listarRespuestasArea(
                  institucionId: widget.institucionId,
                  areaId: area,
                );
      final ui = <_RespuestaUi>[];
      for (final response in responses) {
        ui.add(
          _RespuestaUi(
            response: response,
            studentName: await _studentName(response),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _accessDenied = false;
        _responses = ui;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
        _responses = const <_RespuestaUi>[];
      });
    }
  }

  String _statusLabel(RsvpStatusAtena status) {
    switch (status) {
      case RsvpStatusAtena.yes:
        return 'Sí';
      case RsvpStatusAtena.no:
        return 'No';
      case RsvpStatusAtena.maybe:
        return 'Tal vez';
      case RsvpStatusAtena.pending:
        return 'Pendiente';
    }
  }

  String _dateLabel(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_accessDenied) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se pudo validar la sesión para esta institución.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No se pudieron cargar las respuestas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_responses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(Icons.event_available_outlined, size: 52),
            SizedBox(height: 16),
            Center(child: Text('Todavía no hay respuestas de alumnos.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _responses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _responses[index];
          final response = item.response;
          final eventTitle = response.eventTitle.trim().isEmpty
              ? 'Evento ${response.eventId}'
              : response.eventTitle;
          return Card(
            key: ValueKey('calendar-response-${response.eventId}'),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(eventTitle),
              subtitle: Text(
                '${item.studentName}\nFecha del evento: ${_dateLabel(response.dateKey)}',
              ),
              isThreeLine: true,
              trailing: Chip(label: Text(_statusLabel(response.status))),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.areaNombre ?? '').trim().isEmpty
              ? 'Respuestas de calendario'
              : '${widget.areaNombre!.trim()} — Respuestas de calendario',
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }
}
