import 'package:flutter/material.dart';
import '../services/remote/multiuser_session.dart';

/// Edits the existing allowlisted catalog projection. It never persists locally
/// or nominates an owner/operator; the containing catalog page saves via RPC.
class CatalogOfferEditor extends StatefulWidget {
  final Map<String, dynamic> document;
  final int? groupIndex;
  const CatalogOfferEditor({
    super.key,
    required this.document,
    this.groupIndex,
  });
  @override
  State<CatalogOfferEditor> createState() => _CatalogOfferEditorState();
}

class _CatalogOfferEditorState extends State<CatalogOfferEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late String _kind, _formal, _status, _id;
  late Map<String, dynamic> _old;
  String? _error;
  @override
  void initState() {
    super.initState();
    _old = widget.groupIndex == null
        ? {}
        : Map<String, dynamic>.from(
            widget.document['groups'][widget.groupIndex],
          );
    _id =
        _old['id'] as String? ??
        'atena_${MultiuserSession.operationId(catalog: true)}';
    _kind = widget.document['area']['kind'] as String;
    _formal = _old['formal_type'] as String? ?? 'escolar';
    _status =
        _old['status'] as String? ??
        (_kind == 'curricular' ? 'disponible' : 'activo');
    for (final key in [
      'name',
      'activity_label',
      'schedule',
      'ages',
      'requirements',
      'description',
      'price',
    ]) {
      _fields[key] = TextEditingController(text: _old[key] as String? ?? '');
    }
    _fields['capacity'] = TextEditingController(
      text: (_old['capacity'] ?? 0).toString(),
    );
    for (final key in ['country', 'province', 'city']) {
      _fields[key] = TextEditingController(
        text: widget.document['institution'][key] as String? ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _time() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (!mounted || start == null) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: start.hour < 23 ? start.hour + 1 : 23,
        minute: start.minute,
      ),
    );
    if (!mounted || end == null) return;
    if (end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
      setState(() => _error = 'El final debe ser posterior al inicio.');
      return;
    }
    String clock(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    _fields['schedule']!.text = '${clock(start)}-${clock(end)}';
    setState(() => _error = null);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final cap = int.parse(_fields['capacity']!.text.trim());
    final occupied = _old['occupied'] as int? ?? 0;
    final group = <String, dynamic>{
      'id': _id,
      'kind': _kind,
      'formal_type': _formal,
      'status': _status,
      for (final key in [
        'name',
        'activity_label',
        'schedule',
        'ages',
        'requirements',
        'description',
        'price',
      ])
        key: _fields[key]!.text.trim(),
      'capacity': cap,
      'occupied': occupied,
      'available': cap - occupied,
      'availability': _status == 'suspendido'
          ? 'suspended'
          : cap == occupied || _status == 'completo'
          ? 'full'
          : 'available',
    };
    final doc = widget.document;
    doc['schema_version'] = 3;
    doc['area']['kind'] = _kind;
    for (final key in ['country', 'province', 'city']) {
      doc['institution'][key] = _fields[key]!.text.trim();
    }
    final groups = doc['groups'] as List;
    if (_kind == 'extracurricular') {
      final activities = doc['activities'] as List;
      final index = activities.indexWhere(
        (a) => a['name'] == _old['activity_label'],
      );
      final activity = {
        'id': index < 0
            ? 'atena_${MultiuserSession.operationId(catalog: true)}'
            : activities[index]['id'],
        'name': group['activity_label'],
        'active': index < 0 ? true : activities[index]['active'],
        for (final k in ['schedule', 'description', 'ages', 'price'])
          k: group[k],
      };
      if (index < 0) {
        activities.add(activity);
      } else {
        activities[index] = activity;
        for (final g in groups) {
          if (g['activity_label'] == _old['activity_label']) {
            g['activity_label'] = activity['name'];
          }
        }
      }
    }
    if (widget.groupIndex == null) {
      groups.add(group);
    } else {
      groups[widget.groupIndex!] = group;
    }
    Navigator.of(context).pop(doc);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.groupIndex == null ? 'Crear oferta' : 'Editar oferta'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Área: ${widget.document['area']['name']}'),
          const Text(
            'Se guardará como borrador privado. La publicación requiere una acción posterior.',
          ),
          if (_error != null) Text(_error!),
          if ((widget.document['groups'] as List).isEmpty)
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Tipo de oferta'),
              items: const [
                DropdownMenuItem(
                  value: 'curricular',
                  child: Text('Educación formal'),
                ),
                DropdownMenuItem(
                  value: 'extracurricular',
                  child: Text('Actividad extracurricular'),
                ),
              ],
              onChanged: (v) => setState(() {
                _kind = v!;
                _status = v == 'curricular' ? 'disponible' : 'activo';
              }),
            ),
          if (_kind == 'curricular')
            DropdownButtonFormField<String>(
              initialValue: _formal,
              decoration: const InputDecoration(
                labelText: 'Presentación de educación formal',
              ),
              items: const [
                DropdownMenuItem(value: 'escolar', child: Text('Escolar')),
                DropdownMenuItem(
                  value: 'superior',
                  child: Text('Superior / institutos'),
                ),
                DropdownMenuItem(
                  value: 'universidad',
                  child: Text('Universidad'),
                ),
              ],
              onChanged: (v) => setState(() => _formal = v!),
            ),
          for (final field in const <String, String>{
            'activity_label': 'Actividad / programa',
            'name': 'Grupo / turno',
            'schedule': 'Días y horario',
            'capacity': 'Cupo total',
            'ages': 'Edades',
            'requirements': 'Condiciones de inscripción',
            'description': 'Descripción',
            'price': 'Costo informado al alumno',
            'country': 'País',
            'province': 'Provincia',
            'city': 'Localidad',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextFormField(
                controller: _fields[field.key],
                keyboardType: field.key == 'capacity'
                    ? TextInputType.number
                    : TextInputType.text,
                decoration: InputDecoration(
                  labelText: field.value,
                  suffixIcon: field.key == 'schedule'
                      ? IconButton(
                          tooltip: 'Elegir horario',
                          onPressed: _time,
                          icon: const Icon(Icons.schedule),
                        )
                      : null,
                ),
                validator: (raw) {
                  final value = (raw ?? '').trim();
                  if (field.key == 'capacity') {
                    final n = int.tryParse(value);
                    return n == null ||
                            n < (_old['occupied'] as int? ?? 0) ||
                            n > 9999999
                        ? 'Cupo inválido o menor a la ocupación.'
                        : null;
                  }
                  if (value.length > 512) return 'Máximo 512 caracteres.';
                  if ([
                        'activity_label',
                        'name',
                        'schedule',
                        'country',
                        'province',
                        'city',
                      ].contains(field.key) &&
                      value.isEmpty) {
                    return 'Completá este dato.';
                  }
                  return null;
                },
              ),
            ),
          DropdownButtonFormField<String>(
            key: ValueKey(_kind),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Estado del grupo'),
            items: [
              DropdownMenuItem(
                value: _kind == 'curricular' ? 'disponible' : 'activo',
                child: const Text('Activo'),
              ),
              if (_kind == 'curricular')
                const DropdownMenuItem(
                  value: 'completo',
                  child: Text('Completo'),
                ),
              const DropdownMenuItem(
                value: 'suspendido',
                child: Text('Suspendido'),
              ),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Guardar borrador')),
        ],
      ),
    ),
  );
}
