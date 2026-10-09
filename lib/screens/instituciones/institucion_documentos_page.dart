import '../../services/remote/multiuser_session.dart';
import 'package:flutter/material.dart';
import '../../models/solicitudes/solicitud_alumno.dart';
import '../../services/documentacion_operativa_service.dart';
import '../../services/documentos_temporales_service.dart';
import '../../services/cuenta_service.dart';
import '../../ui/documento_local_actions.dart';

class InstitucionDocumentosPage extends StatefulWidget {
  final String institucionId, institucionNombre;
  final String? remoteAreaId;
  final String? initialOwnerAccountId,
      initialPerfilId,
      institucionOwnerAccountId;
  const InstitucionDocumentosPage({
    super.key,
    this.remoteAreaId,
    required this.institucionId,
    required this.institucionNombre,
    this.initialOwnerAccountId,
    this.initialPerfilId,
    this.institucionOwnerAccountId,
  });
  @override
  State<InstitucionDocumentosPage> createState() =>
      _InstitucionDocumentosPageState();
}

class _InstitucionDocumentosPageState extends State<InstitucionDocumentosPage> {
  final _message = TextEditingController();
  List<SolicitudAlumno> _students = [];
  final Map<String, String> _names = {};
  List<SolicitudDocumento> _requests = [];
  List<DocumentoTemporal> _documents = [];
  String? _selected, _error;
  String? _requestOperation, _requestIntent;
  TipoDocumento _type = TipoDocumento.values.first;
  bool _busy = true, _write = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final students = await DocumentacionOperativaService.destinatarios(
        widget.institucionId,
        remoteAreaId: widget.remoteAreaId,
      );
      final requests =
          await DocumentacionOperativaService.solicitudesInstitucion(
            widget.institucionId,
            remoteAreaId: widget.remoteAreaId,
          );
      final docs = await DocumentacionOperativaService.documentosInstitucion(
        widget.institucionId,
        remoteAreaId: widget.remoteAreaId,
      );
      for (final s in students) {
        _names[s.perfilId!] = MultiuserSession.enabled
            ? s.perfilId!
            : (await CuentaService.getPerfilAlumnoById(
                s.perfilId!,
              ))!.displayName;
      }
      var write = false;
      try {
        if (MultiuserSession.enabled) {
          await MultiuserSession.current.institution(
            widget.institucionId,
            widget.remoteAreaId ?? '',
            'documents.write',
          );
        } else {
          await DocumentacionOperativaService.contexto(
            widget.institucionId,
            escribir: true,
          );
        }
        write = true;
      } on StateError {
        /* Sólo lectura. */
      }
      if (!mounted) return;
      setState(() {
        _students = students;
        _requests = requests;
        _documents = docs;
        _write = write;
        if (!students.any((s) => s.id == _selected)) _selected = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _students = [];
          _requests = [];
          _documents = [];
          _write = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Documentación del área'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.institucionNombre,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                MultiuserSession.enabled
                    ? 'Documentos privados compartidos. PDF, PNG o JPEG de hasta 2 MB, disponibles durante cinco días. Una copia descargada fuera de Atena no puede revocarse.'
                    : 'Documentos locales de alumnos con inscripción confirmada en el área activa. Los archivos permanecen en este dispositivo.',
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_students.isEmpty && _error == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay inscripciones confirmadas verificables en esta área.',
                  ),
                ),
              if (_write && _students.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selected,
                  decoration: const InputDecoration(
                    labelText: 'Alumno e inscripción',
                  ),
                  items: _students
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            '${_names[s.perfilId]} · ${s.actividadNombre} · ${s.aula}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selected = v;
                  }),
                ),
                DropdownButtonFormField<TipoDocumento>(
                  isExpanded: true,
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Documento requerido',
                  ),
                  items: TipoDocumento.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _type = v;
                      });
                    }
                  },
                ),
                TextField(
                  controller: _message,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Indicaciones para la familia',
                  ),
                ),
                FilledButton.icon(
                  onPressed: _selected == null
                      ? null
                      : () => _mutate(() async {
                          final intent =
                              '$_selected|${_type.name}|${_message.text.trim()}';
                          if (_requestIntent != intent) {
                            _requestIntent = intent;
                            _requestOperation = MultiuserSession.operationId();
                          }
                          await DocumentacionOperativaService.solicitar(
                            widget.institucionId,
                            _selected!,
                            _type,
                            _message.text,
                            remoteAreaId: widget.remoteAreaId,
                            operationId: _requestOperation,
                          );
                          _requestIntent = null;
                          _requestOperation = null;
                        }),
                  icon: const Icon(Icons.assignment),
                  label: const Text('Solicitar documento'),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Solicitudes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_requests.isEmpty)
                const Text('Sin solicitudes de documentación.'),
              for (final s in _requests)
                Card(
                  child: ListTile(
                    title: Text(
                      '${s.tipo.label} · ${_names[s.perfilId] ?? "Alumno"}',
                    ),
                    subtitle: Text('${s.estado.name}\n${s.mensaje ?? ""}'),
                    trailing:
                        _write && s.estado == EstadoSolicitudDocumento.pendiente
                        ? IconButton(
                            tooltip: 'Cancelar solicitud',
                            icon: const Icon(Icons.cancel_outlined),
                            onPressed: () => _mutate(
                              () => DocumentacionOperativaService.cancelar(
                                widget.institucionId,
                                s.id,
                                remoteAreaId: widget.remoteAreaId,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Archivos recibidos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_documents.isEmpty) const Text('No hay archivos recibidos.'),
              for (final d in _documents)
                Card(
                  child: ListTile(
                    title: Text(
                      '${d.tipo.label} · ${_names[d.perfilId] ?? "Alumno"}',
                    ),
                    subtitle: Text(
                      d.expirado
                          ? 'Vencido'
                          : 'Disponible hasta ${d.expiresAt.toLocal().toString().split(" ").first}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Abrir documento',
                      icon: const Icon(Icons.open_in_new),
                      onPressed: d.expirado
                          ? null
                          : () => abrirDocumentoLocal(context, d),
                    ),
                  ),
                ),
            ],
          ),
  );
}
