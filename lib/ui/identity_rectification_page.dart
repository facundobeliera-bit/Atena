import 'dart:async';
import 'package:flutter/material.dart';
import '../services/remote/identity_rectification.dart';
import '../services/remote/institution_onboarding.dart';
import '../services/remote/multiuser_session.dart';

class IdentityRectificationPage extends StatefulWidget {
  const IdentityRectificationPage({super.key});
  @override
  State<IdentityRectificationPage> createState() =>
      _IdentityRectificationPageState();
}

class _IdentityRectificationPageState extends State<IdentityRectificationPage> {
  late final api = IdentityRectification(MultiuserSession.current);
  Map<String, dynamic>? data;
  bool busy = false;
  String? error;
  StreamSubscription<dynamic>? auth;
  @override
  void initState() {
    super.initState();
    final openedAs = api.session.userId;
    auth = api.session.client.auth.onAuthStateChange.listen((_) {
      if (mounted && openedAs != api.session.userId) {
        setState(() {
          data = null;
          error = 'La sesión cambió. Volvé a ingresar.';
        });
      }
    });
    _load();
  }

  @override
  void dispose() {
    auth?.cancel();
    super.dispose();
  }

  Future<void> _load() => _run(() async => data = await api.state());
  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      data = null;
      error = InstitutionOnboarding.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _send(
    String action,
    Map<String, dynamic> body,
    String actor,
  ) async {
    if (actor != api.session.userId) {
      setState(() {
        data = null;
        error = 'La sesión cambió. Volvé a ingresar.';
      });
      return;
    }
    await _run(() async {
      await api.command(action, body);
      data = await api.state();
    });
  }

  Future<void> _apply(Map target) async {
    final actor = api.session.userId;
    var name = target['name'] as String,
        birth = target['birth_date'] as String? ?? '',
        reason = '';
    final form = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar rectificación'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No cambia la identidad hasta la aprobación de un revisor independiente. No incluyas documentos ni datos sensibles en el motivo.',
                ),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre propuesto',
                  ),
                  maxLength: 160,
                  onChanged: (v) => name = v,
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 3 ? 'Ingresá el nombre' : null,
                ),
                if (target['scope'] == 'family')
                  TextFormField(
                    initialValue: birth,
                    decoration: const InputDecoration(
                      labelText: 'Nacimiento (AAAA-MM-DD)',
                    ),
                    onChanged: (v) => birth = v,
                    validator: (v) =>
                        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v ?? '')
                        ? null
                        : 'Usá AAAA-MM-DD',
                  ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Motivo de rectificación',
                  ),
                  maxLength: 300,
                  onChanged: (v) => reason = v,
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 8 ? 'Indicá el motivo' : null,
                ),
                const Text(
                  'Esta vía no cambia cuentas, vínculos ni la condición de menor/mayor de edad.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Enviar a revisión'),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    await _send('apply', {
      'scope': target['scope'],
      'target_id': target['id'],
      'name': name.trim(),
      if (target['scope'] == 'family') 'birth_date': birth.trim(),
      'reason': reason.trim(),
      'operation_id': MultiuserSession.operationId(),
    }, actor);
  }

  Future<void> _review(Map row, bool approve) async {
    final actor = api.session.userId;
    var evidence = '', checked = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            approve ? 'Aprobar rectificación' : 'Rechazar rectificación',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Anterior: ${row['previous_name']} · ${row['previous_birth_date'] ?? ''}\n'
                  'Propuesto: ${row['proposed_name']} · ${row['proposed_birth_date'] ?? ''}\nMotivo: ${row['reason']}',
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Referencia de revisión',
                  ),
                  maxLength: 160,
                  onChanged: (v) => update(() => evidence = v),
                ),
                if (approve)
                  CheckboxListTile(
                    value: checked,
                    onChanged: (v) => update(() => checked = v == true),
                    title: const Text(
                      'Verifiqué identidad, titularidad y evidencia de la rectificación.',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: evidence.trim().length >= 8 && (!approve || checked)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Confirmar revisión'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accepted != true) return;
    await _send(approve ? 'approve' : 'reject', {
      'application_id': row['id'],
      'review_reference': evidence.trim(),
      'identity_checked': checked,
    }, actor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Rectificación de identidad'),
      actions: [
        IconButton(
          onPressed: busy ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Las modificaciones sensibles requieren revisión. Los datos públicos de la oferta se gestionan en su catálogo; el correo de acceso y los vínculos no se cambian aquí.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null) Text(error!),
        for (final Map target in data?['targets'] as List? ?? [])
          ListTile(
            title: Text(target['name']),
            subtitle: Text(
              target['scope'] == 'family' ? 'Perfil verificado' : 'Institución',
            ),
            trailing: TextButton(
              onPressed: busy ? null : () => _apply(target),
              child: const Text('Solicitar rectificación'),
            ),
          ),
        for (final Map row in data?['applications'] as List? ?? [])
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row['previous_name']} → ${row['proposed_name']} · ${row['status']}',
                  ),
                  Text(
                    'Nacimiento: ${row['previous_birth_date'] ?? 'No corresponde'} → ${row['proposed_birth_date'] ?? 'No corresponde'}',
                  ),
                  if (row['review_reference'] != null)
                    Text(
                      'Revisión: ${row['review_reference']} · ${row['decided_at']}',
                    ),
                  if (row['status'] == 'pending' &&
                      row['applicant'] != api.session.userId &&
                      data?['${row['scope']}_reviewer'] == true)
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: busy ? null : () => _review(row, true),
                          child: const Text('Revisar y aprobar'),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => _review(row, false),
                          child: const Text('Rechazar'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
