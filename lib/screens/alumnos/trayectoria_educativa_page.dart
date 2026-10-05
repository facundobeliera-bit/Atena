import '../../ui/atena_workspace.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/alumnos/modulo_educativo.dart';
import '../../services/trayectoria_educativa_service.dart';
import '../../services/pdf/pdf_trayectoria.dart';

class TrayectoriaEducativaPage extends StatelessWidget {
  final String? institucionId, areaId, solicitudId, ownerAccountId, perfilId;
  const TrayectoriaEducativaPage.institucion({
    super.key,
    required this.institucionId,
    required this.areaId,
    required this.solicitudId,
  }) : ownerAccountId = null,
       perfilId = null;
  const TrayectoriaEducativaPage.alumno({
    super.key,
    required this.ownerAccountId,
    required this.perfilId,
  }) : institucionId = null,
       areaId = null,
       solicitudId = null;
  bool get institucional => institucionId != null;
  Widget pagina(ModuloEducativo modulo) =>
      _RegistrosPage(scope: this, module: modulo);

  Future<List<Map<String, dynamic>>> leer(ModuloEducativo module) =>
      institucional
      ? TrayectoriaEducativaService.instance.leerInstitucion(
          institucionId: institucionId!,
          areaId: areaId!,
          solicitudId: solicitudId!,
          modulo: module,
        )
      : TrayectoriaEducativaService.instance.leerAlumno(
          ownerAccountId: ownerAccountId!,
          perfilId: perfilId!,
          modulo: module,
        );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trayectoria educativa')),
    body: AtenaWorkspace(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AtenaSectionHeader(
            eyebrow: 'Tu recorrido',
            title: institucional
                ? 'Información de esta inscripción'
                : 'Tu información educativa',
            subtitle: institucional
                ? 'Registros y documentos asociados a esta inscripción.'
                : 'Información compartida por tus instituciones',
          ),
          const AtenaLocalNotice(),
          AtenaResponsiveGrid(
            children: [
              for (final module in ModuloEducativo.values)
                AtenaActionCard(
                  icon: Icons.auto_stories_outlined,
                  title: module.label,
                  subtitle: module.aviso,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _RegistrosPage(scope: this, module: module),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RegistrosPage extends StatefulWidget {
  final TrayectoriaEducativaPage scope;
  final ModuloEducativo module;
  const _RegistrosPage({required this.scope, required this.module});
  @override
  State<_RegistrosPage> createState() => _RegistrosPageState();
}

class _RegistrosPageState extends State<_RegistrosPage> {
  late Future<List<Map<String, dynamic>>> _future;
  bool _editable = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _read();
  }

  Future<List<Map<String, dynamic>>> _read() async {
    final data = await widget.scope.leer(widget.module);
    _editable =
        widget.scope.institucional &&
        await TrayectoriaEducativaService.instance.puedeEditar(
          widget.scope.institucionId!,
          widget.scope.areaId!,
        );
    return data;
  }

  Future<void> _edit([Map<String, dynamic>? record]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _Editor(scope: widget.scope, module: widget.module, record: record),
      ),
    );
    if (mounted && saved == true) setState(_reload);
  }

  Future<void> _export(Map<String, dynamic> record) async {
    try {
      final current = (await widget.scope.leer(
        widget.module,
      )).firstWhere((r) => r['id'] == record['id']);
      final bytes = await PdfTrayectoria.build(widget.module, current).save();
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Atena_${widget.module.name}_${current['revision']}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el documento: $e')),
        );
      }
    }
  }

  String _value(dynamic value) {
    if (value == null || value == '') return 'Sin información';
    if (value is Map) {
      return value.isEmpty
          ? 'Sin calificaciones — incompleto'
          : value.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    }
    return value.toString();
  }

  Widget _details(Map<String, dynamic> r, {bool history = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${r['institucion'] ?? r['institucionId']} · ${r['actividad'] ?? ''}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text('Grupo: ${r['aula'] ?? ''} · ${r['turno'] ?? ''}'),
      for (final field in widget.module.campos.entries)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('${field.value}: ${_value(r[field.key])}'),
        ),
      if (widget.module.booleano != null)
        Text(
          '${widget.module.booleano == 'aprobada' ? 'Decisión' : 'Estado'}: ${r[widget.module.booleano] == true ? (widget.module.booleano == 'aprobada' ? 'Aprobada' : 'Activa') : (widget.module.booleano == 'aprobada' ? 'No aprobada' : 'Inactiva')}',
        ),
      if (widget.module == ModuloEducativo.boletines)
        Text(
          r['completo'] == true
              ? 'Con calificaciones registradas; verificar alcance del período.'
              : 'INCOMPLETO: faltan calificaciones.',
        ),
      if (widget.module == ModuloEducativo.titulos) Text(widget.module.aviso),
      const SizedBox(height: 8),
      Text(
        'Registrado por ${r['operadorNombre'] ?? 'Sin autor verificado'} · Revisión ${r['revision'] ?? 'histórica'}',
      ),
      if (widget.scope.institucional)
        Text(
          r['visibleAlumno'] == true
              ? 'Compartido con el alumno/familia'
              : 'Interno de la institución',
        ),
      if (!history &&
          widget.scope.institucional &&
          r['historial'] is List &&
          (r['historial'] as List).isNotEmpty)
        ExpansionTile(
          title: const Text('Historial de correcciones'),
          children: [
            for (final past in r['historial'] as List)
              Padding(
                padding: const EdgeInsets.all(12),
                child: _details(
                  Map<String, dynamic>.from(past as Map),
                  history: true,
                ),
              ),
          ],
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.module.label)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('No se pudo abrir la información: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final records = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(widget.module.aviso),
                if (_editable) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar información'),
                  ),
                ],
                if (records.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Todavía no hay información disponible en esta sección.',
                    ),
                  ),
                for (final record in records)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _details(record),
                          if (widget.module == ModuloEducativo.boletines ||
                              widget.module == ModuloEducativo.titulos)
                            TextButton.icon(
                              onPressed: () => _export(record),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Ver / exportar PDF'),
                            ),
                          if (_editable)
                            TextButton.icon(
                              onPressed: () => _edit(record),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Actualizar registro'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Editor extends StatefulWidget {
  final TrayectoriaEducativaPage scope;
  final ModuloEducativo module;
  final Map<String, dynamic>? record;
  const _Editor({required this.scope, required this.module, this.record});
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final _controllers = <String, TextEditingController>{};
  late final String _id;
  bool _visible = false, _state = false, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _id =
        widget.record?['id']?.toString() ??
        'edu_${UniqueKey()}_${DateTime.now().microsecondsSinceEpoch}';
    _visible = widget.record?['visibleAlumno'] == true;
    _state = widget.record?[widget.module.booleano] == true;
    for (final key in widget.module.campos.keys) {
      final value = widget.record?[key];
      var text = value?.toString() ?? '';
      if (value is Map) {
        text = value.entries.map((e) => '${e.key} = ${e.value}').join('\n');
      }
      if (widget.module.esFecha(key) && text.length >= 10) {
        text = text.substring(0, 10);
      }
      _controllers[key] = TextEditingController(text: text);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        for (final entry in _controllers.entries) entry.key: entry.value.text,
      };
      if (widget.module == ModuloEducativo.boletines) {
        final grades = <String, double>{};
        for (final line in _controllers['calificaciones']!.text.split('\n')) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('=');
          final grade = parts.length == 2
              ? double.tryParse(parts[1].trim().replaceAll(',', '.'))
              : null;
          if (grade == null ||
              parts.first.trim().isEmpty ||
              grades.containsKey(parts.first.trim())) {
            throw ArgumentError(
              'Usá una materia por línea: Materia = nota, sin repetir materias.',
            );
          }
          grades[parts.first.trim()] = grade;
        }
        data['calificaciones'] = grades;
      }
      if (widget.module.booleano != null) {
        data[widget.module.booleano!] = _state;
      }
      await TrayectoriaEducativaService.instance.guardar(
        institucionId: widget.scope.institucionId!,
        areaId: widget.scope.areaId!,
        solicitudId: widget.scope.solicitudId!,
        modulo: widget.module,
        id: _id,
        datos: data,
        visibleAlumno: _visible,
        revisionEsperada: widget.record?['revision'] as int?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información guardada en este dispositivo.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${widget.record == null ? 'Registrar' : 'Actualizar'} · ${widget.module.label}',
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.module.aviso),
            const SizedBox(height: 16),
            for (final field in widget.module.campos.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: TextField(
                  key: ValueKey('edu_${field.key}'),
                  controller: _controllers[field.key],
                  enabled: !_saving,
                  minLines: 1,
                  maxLines: widget.module.esFecha(field.key) ? 1 : 4,
                  decoration: InputDecoration(
                    labelText: field.value,
                    helperText: widget.module.esFecha(field.key)
                        ? 'AAAA-MM-DD'
                        : null,
                    border: const OutlineInputBorder(),
                    suffixIcon: widget.module.esFecha(field.key)
                        ? IconButton(
                            tooltip: 'Elegir fecha',
                            onPressed: _saving
                                ? null
                                : () async {
                                    final entered = DateTime.tryParse(
                                      _controllers[field.key]!.text,
                                    );
                                    final date = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime(2200),
                                      initialDate:
                                          entered != null &&
                                              !entered.isBefore(
                                                DateTime(1900),
                                              ) &&
                                              !entered.isAfter(DateTime(2200))
                                          ? entered
                                          : DateTime.now(),
                                    );
                                    if (date != null && mounted) {
                                      _controllers[field.key]!.text = date
                                          .toIso8601String()
                                          .substring(0, 10);
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today),
                          )
                        : null,
                  ),
                ),
              ),
            if (widget.module.booleano != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  widget.module.booleano == 'aprobada'
                      ? 'Decisión institucional: aprobada'
                      : 'Activa',
                ),
                value: _state,
                onChanged: _saving ? null : (v) => setState(() => _state = v),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compartir con el alumno/familia'),
              subtitle: const Text(
                'Comparte los campos de este registro. Desactivado: sólo consulta institucional autorizada.',
              ),
              value: _visible,
              onChanged: _saving ? null : (v) => setState(() => _visible = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Guardando…' : 'Guardar registro'),
            ),
          ],
        ),
      ),
    ),
  );
}
