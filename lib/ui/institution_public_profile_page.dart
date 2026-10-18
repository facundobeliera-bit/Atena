import 'package:flutter/material.dart';
import '../services/remote/institution_onboarding.dart';
import '../services/remote/institution_public_profile.dart';
import '../services/remote/multiuser_session.dart';

class InstitutionPublicProfilePage extends StatefulWidget {
  final String institutionId;
  const InstitutionPublicProfilePage({super.key, required this.institutionId});
  @override
  State<InstitutionPublicProfilePage> createState() => _ProfileState();
}

class _ProfileState extends State<InstitutionPublicProfilePage> {
  late final api = InstitutionPublicProfile(
    InstitutionOnboarding(MultiuserSession.current),
  );
  final form = GlobalKey<FormState>();
  final fields = {
    for (final k in InstitutionPublicProfile.fields.keys)
      k: TextEditingController(),
  };
  bool busy = true, loaded = false;
  int revision = 0;
  String? message, operation;
  Map<String, String>? pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final result = await api.read(widget.institutionId);
      if (!mounted) return;
      revision = result['revision'];
      for (final k in fields.keys) {
        fields[k]!.text = result['document'][k];
      }
      loaded = true;
      pending = null;
      operation = null;
    } catch (e) {
      if (mounted) message = InstitutionOnboarding.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    // Retain the exact request after uncertain network outcomes. Editing is
    // enabled again only after server confirmation or an explicit reload.
    pending ??= {for (final k in fields.keys) k: fields[k]!.text.trim()};
    operation ??= MultiuserSession.operationId();
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final result = await api.save(
        widget.institutionId,
        operation!,
        revision,
        pending!,
      );
      if (!mounted) return;
      revision = result['revision'];
      pending = null;
      operation = null;
      message = 'Perfil público confirmado por el servidor.';
    } catch (e) {
      if (mounted) {
        message =
            '${InstitutionOnboarding.error(e)} Reintentá el mismo envío o actualizá para consultar el estado guardado.';
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Perfil público institucional'),
      actions: [
        IconButton(
          onPressed: busy ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Consultar estado guardado',
        ),
      ],
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Estos datos serán públicos mientras exista una oferta publicada. No incluyas datos de alumnos ni información privada. El correo de contacto no cambia el acceso a tu cuenta.',
          ),
          const Text(
            'La identidad legal y la titularidad requieren revisión independiente.',
          ),
          const Text(
            'País, provincia o localidad vacíos conservan la ubicación de cada oferta. Los demás campos vacíos quitan ese dato del perfil público.',
          ),
          if (busy) const LinearProgressIndicator(),
          if (message != null) Text(message!),
          if (loaded) ...[
            for (final field in InstitutionPublicProfile.fields.entries)
              TextFormField(
                controller: fields[field.key],
                enabled: !busy && pending == null,
                decoration: InputDecoration(labelText: field.value),
                maxLength: field.key == 'description'
                    ? 2000
                    : field.key == 'opening_hours'
                    ? 600
                    : field.key == 'address'
                    ? 300
                    : 160,
                maxLines:
                    field.key == 'description' || field.key == 'opening_hours'
                    ? 3
                    : 1,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (field.key == 'public_name' && value.isEmpty) {
                    return 'Ingresá el nombre público.';
                  }
                  if (field.key == 'email' &&
                      value.isNotEmpty &&
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                    return 'Revisá el correo de contacto.';
                  }
                  return null;
                },
              ),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(
                pending == null ? 'Guardar datos públicos' : 'Reintentar envío',
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
