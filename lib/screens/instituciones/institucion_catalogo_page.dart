import '../../services/remote/multiuser_session.dart';
import '../../ui/multiuser_panels.dart';
import 'package:flutter/material.dart';
import '../../services/catalogo_publicable_service.dart';
import '../../ui/atena_workspace.dart';

class InstitucionCatalogoPage extends StatefulWidget {
  final String institucionId, areaId;
  const InstitucionCatalogoPage({
    super.key,
    required this.institucionId,
    required this.areaId,
  });
  @override
  State<InstitucionCatalogoPage> createState() =>
      _InstitucionCatalogoPageState();
}

class _InstitucionCatalogoPageState extends State<InstitucionCatalogoPage> {
  final _service = CatalogoPublicableService();
  EstadoCatalogoPublicable? _value;
  String? _error;
  bool _busy = false;
  bool _published = false;

  Future<void> _publish() async {
    final value = _value;
    if (_busy || value == null) return;
    final controllers = <String, TextEditingController>{};
    setState(() => _busy = true);
    try {
      final old = await _service.publicacionLocal(
        widget.institucionId,
        widget.areaId,
      );
      var type = old?.ofertas.firstOrNull?.tipoFormal ?? 'escolar';
      final formal = value.catalogo.datos['area']['kind'] == 'curricular';
      for (final g in value.catalogo.grupos) {
        var price = '';
        for (final o in old?.ofertas ?? []) {
          if (await CatalogoPublicableService.identificador(
                formal ? 'curricular-group' : 'extra-group',
                widget.institucionId,
                o.id,
              ) ==
              g['id']) {
            price = o.precio;
          }
        }
        controllers[g['id']] = TextEditingController(text: price);
      }
      if (!mounted) return;
      setState(() => _busy = false);
      final approved = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => AlertDialog(
            title: const Text('Publicar en este dispositivo'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'La institución, ubicación, contacto público y ofertas de esta área podrán consultarse sin iniciar sesión. Revisá que no contengan datos personales. No se publican en Internet ni en otros dispositivos.',
                    ),
                    const SizedBox(height: 16),
                    if (formal) ...[
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Presentación de educación formal',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'escolar',
                            child: Text('Escolar'),
                          ),
                          DropdownMenuItem(
                            value: 'superior',
                            child: Text('Superior / institutos'),
                          ),
                          DropdownMenuItem(
                            value: 'universidad',
                            child: Text('Universidad'),
                          ),
                        ],
                        onChanged: (v) => update(() => type = v!),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Indicá el costo para el alumno por oferta. Escribí Gratuito, un importe o dejá vacío para Consultar. No corresponde al plan de Atena.',
                      ),
                      for (final g in value.catalogo.grupos)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextField(
                            controller: controllers[g['id']],
                            decoration: InputDecoration(
                              labelText:
                                  '${g['activity_label']} · ${g['name']}',
                              helperText: 'Costo público',
                            ),
                          ),
                        ),
                    ] else
                      const Text(
                        'El costo, edades y descripción se toman de las actividades existentes. Un precio vacío se muestra como Consultar.',
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Publicar'),
              ),
            ],
          ),
        ),
      );
      if (approved != true) return;
      if (!mounted) return;
      setState(() => _busy = true);
      await _service.publicarLocal(
        widget.institucionId,
        widget.areaId,
        tipoFormal: type,
        precios: controllers.map((k, v) => MapEntry(k, v.text.trim())),
      );
      if (mounted) setState(() => _published = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo publicar. Revisá los datos y los permisos del área.',
            ),
          ),
        );
      }
    } finally {
      // Dialog route may still be animating while controllers are attached.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (final c in controllers.values) {
        c.dispose();
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.retirarLocal(widget.institucionId, widget.areaId);
      if (mounted) setState(() => _published = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo retirar la publicación.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (MultiuserSession.enabled) return;
    _load();
  }

  Future<void> _load({bool prepare = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _value = null;
      _error = null;
    });
    try {
      if (prepare) await _service.preparar(widget.institucionId, widget.areaId);
      final value = await _service.consultar(
        widget.institucionId,
        widget.areaId,
      );
      final published = await _service.publicacionLocal(
        widget.institucionId,
        widget.areaId,
      );
      if (mounted) {
        setState(() {
          _value = value;
          _published = published != null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : e is StateError
              ? e.message.toString()
              : 'No se pudo preparar el catálogo. Volvé a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _label(EstadoCatalogo state) => switch (state) {
    EstadoCatalogo.local => 'Sólo local',
    EstadoCatalogo.pendiente => 'Preparado · sincronización pendiente',
    EstadoCatalogo.confirmado => 'Versión confirmada por el servidor',
    EstadoCatalogo.cambiosLocales => 'Cambios locales sin preparar',
    EstadoCatalogo.errorConexion => 'Envío sin confirmar · error de conexión',
    EstadoCatalogo.conflicto => 'Conflicto de versiones · requiere revisión',
  };

  @override
  Widget build(BuildContext context) {
    if (MultiuserSession.enabled) {
      return RemoteCatalogPanel(
        institutionId: widget.institucionId,
        areaId: widget.areaId,
      );
    }
    final value = _value;
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo del área')),
      body: AtenaWorkspace(
        maxWidth: 860,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const AtenaSectionHeader(
                eyebrow: 'Preparación local',
                title: 'Revisá tu propuesta',
                subtitle:
                    'Esta vista utiliza las actividades y grupos existentes. Preparar guarda una versión local; todavía no la publica en otros dispositivos.',
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _load(),
                  child: const Text('Reintentar'),
                ),
              ],
              if (value != null) ...[
                Text(
                  _label(value.estado),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (value.preparadoEn != null)
                  Text(
                    'Última preparación local: ${value.preparadoEn!.toLocal()}',
                  ),
                Text(
                  '${value.catalogo.actividades.length} actividades · ${value.catalogo.grupos.length} grupos',
                ),
                const SizedBox(height: 12),
                if (value.catalogo.vacio)
                  const Text(
                    'El catálogo de esta área está vacío. Una lista vacía también se conserva como una versión válida.',
                  ),
                for (final a in value.catalogo.actividades)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(a['name'] as String),
                      subtitle: Text(a['schedule'] as String),
                    ),
                  ),
                for (final g in value.catalogo.grupos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['name'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(g['activity_label'] as String),
                            if ((g['schedule'] as String).isNotEmpty)
                              Text(g['schedule'] as String),
                            Text(
                              g['available'] == null
                                  ? 'Cupo no gestionado · disponibilidad no confirmada'
                                  : g['availability'] != 'available'
                                  ? 'Disponibilidad no habilitada'
                                  : '${g['available']} vacantes informadas',
                            ),
                            Text('Estado: ${g['status']}'),
                            if (g['availability'] == 'full')
                              const Text('Sin vacantes disponibles'),
                            if (g['availability'] == 'suspended')
                              const Text('Inscripciones suspendidas'),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Revisá que los nombres publicados no contengan información personal. Los cupos son informativos: preparar no reserva ni confirma inscripciones.',
                ),
                const SizedBox(height: 16),
                Text(
                  _published
                      ? 'Visible en el buscador de este dispositivo'
                      : 'No publicado en el buscador',
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _publish,
                  icon: const Icon(Icons.public),
                  label: Text(
                    _published
                        ? 'Actualizar publicación local'
                        : 'Publicar en el buscador local',
                  ),
                ),
                if (_published)
                  TextButton(
                    onPressed: _busy ? null : _withdraw,
                    child: const Text('Retirar del buscador'),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _load(prepare: true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Preparar versión local'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _load(),
                  child: const Text('Volver a leer los grupos'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
