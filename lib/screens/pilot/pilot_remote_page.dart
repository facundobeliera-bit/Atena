import 'package:flutter/material.dart';

import '../../repositories/pilot_operation_repository.dart';
import '../../services/remote/pilot_remote_gateway.dart';

/// Circuito de prueba separado de las cuentas y sesiones locales de Atena.
class PilotRemotePage extends StatefulWidget {
  final PilotRemoteGateway gateway;
  const PilotRemotePage({super.key, required this.gateway});

  @override
  State<PilotRemotePage> createState() => _PilotRemotePageState();
}

class _PilotRemotePageState extends State<PilotRemotePage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;
  List<PilotInstitution> _institutions = const [];
  List<PilotAssignment> _assignments = const [];
  List<PilotArea> _areas = const [];
  List<PilotOperation> _notes = const [];
  String? _institutionId;
  String? _areaId;

  @override
  void initState() {
    super.initState();
    if (widget.gateway.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInstitutions());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo completar la operación remota.';
          _notes = const [];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadInstitutions() => _run(() async {
    final assignments = await widget.gateway.assignments();
    final institutions = await widget.gateway.institutions();
    if (!mounted) return;
    setState(() {
      _assignments = assignments;
      _institutions = institutions
          .where((i) => assignments.any((a) => a.institutionId == i.id))
          .toList(growable: false);
      _institutionId = null;
      _areas = const [];
      _areaId = null;
      _notes = const [];
    });
  });

  Future<void> _signIn() => _run(() async {
    await widget.gateway.signIn(_email.text.trim(), _password.text);
    _password.clear();
    final assignments = await widget.gateway.assignments();
    final institutions = await widget.gateway.institutions();
    if (!mounted) return;
    setState(() {
      _assignments = assignments;
      _institutions = institutions
          .where((i) => assignments.any((a) => a.institutionId == i.id))
          .toList(growable: false);
      _institutionId = null;
      _areas = const [];
      _areaId = null;
      _notes = const [];
    });
  });

  Future<void> _selectInstitution(String? id) => _run(() async {
    final areas = id == null
        ? <PilotArea>[]
        : (await widget.gateway.areas(id))
              .where(
                (a) => _assignments.any(
                  (assignment) =>
                      assignment.institutionId == id &&
                      assignment.areaId == a.id,
                ),
              )
              .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _institutionId = id;
      _areas = areas;
      _areaId = null;
      _notes = const [];
    });
  });

  Future<void> _refreshNotes() => _run(() async {
    final institutionId = _institutionId;
    final areaId = _areaId;
    if (institutionId == null || areaId == null) return;
    final notes = await widget.gateway.notes(institutionId, areaId);
    if (mounted) setState(() => _notes = notes);
  });

  Future<void> _saveNote() => _run(() async {
    final institutionId = _institutionId;
    final areaId = _areaId;
    final assignment = _assignments
        .where((a) => a.institutionId == institutionId && a.areaId == areaId)
        .firstOrNull;
    final note = _note.text.trim();
    if (institutionId == null ||
        areaId == null ||
        assignment == null ||
        !assignment.canWrite ||
        note.isEmpty) {
      throw StateError('Faltan datos de prueba.');
    }
    await widget.gateway.recordNote(
      institutionId: institutionId,
      areaId: areaId,
      operatorId: assignment.operatorId,
      resourceId: 'flutter-${DateTime.now().microsecondsSinceEpoch}',
      note: note,
    );
    final notes = await widget.gateway.notes(institutionId, areaId);
    if (!mounted) return;
    _note.clear();
    setState(() => _notes = notes);
  });

  Future<void> _signOut() => _run(() async {
    await widget.gateway.signOut();
    if (!mounted) return;
    _password.clear();
    _note.clear();
    setState(() {
      _assignments = const [];
      _institutions = const [];
      _institutionId = null;
      _areas = const [];
      _areaId = null;
      _notes = const [];
    });
  });

  @override
  Widget build(BuildContext context) {
    final signedIn = widget.gateway.isSignedIn;
    final selectedAssignment = _assignments
        .where((a) => a.institutionId == _institutionId && a.areaId == _areaId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Piloto remoto de Atena')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Circuito de prueba. No utiliza las cuentas ni los datos habituales de Atena.',
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              if (!signedIn) ...[
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Correo de prueba',
                  ),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña de prueba',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _signIn,
                  child: const Text('Ingresar al piloto'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión remota'),
                ),
                TextButton(
                  onPressed: _busy ? null : _loadInstitutions,
                  child: const Text('Actualizar instituciones'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('pilot-institution'),
                  initialValue: _institutionId,
                  decoration: const InputDecoration(
                    labelText: 'Institución visible',
                  ),
                  items: _institutions
                      .map(
                        (i) =>
                            DropdownMenuItem(value: i.id, child: Text(i.name)),
                      )
                      .toList(),
                  onChanged: _busy ? null : _selectInstitution,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('pilot-area-$_institutionId'),
                  initialValue: _areaId,
                  decoration: const InputDecoration(labelText: 'Área visible'),
                  items: _areas
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (id) {
                          setState(() {
                            _areaId = id;
                            _notes = const [];
                          });
                          _refreshNotes();
                        },
                ),
                if (_areaId != null) ...[
                  const SizedBox(height: 16),
                  if (selectedAssignment != null)
                    Text('Operador asignado: ${selectedAssignment.operatorId}'),
                  TextField(
                    controller: _note,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Nota ficticia',
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy || selectedAssignment?.canWrite != true
                        ? null
                        : _saveNote,
                    child: const Text('Guardar nota remota'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _refreshNotes,
                    child: const Text('Actualizar notas'),
                  ),
                  for (final note in _notes)
                    ListTile(
                      title: Text(note.note),
                      subtitle: Text(note.resourceId),
                    ),
                ],
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
