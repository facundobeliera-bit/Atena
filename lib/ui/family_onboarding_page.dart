import 'dart:async';
import 'package:flutter/material.dart';
import '../services/remote/family_onboarding.dart';
import '../services/remote/institution_onboarding.dart';
import '../services/remote/multiuser_session.dart';

class FamilyOnboardingPage extends StatefulWidget {
  const FamilyOnboardingPage({super.key});
  @override
  State<FamilyOnboardingPage> createState() => _FamilyOnboardingPageState();
}

class _FamilyOnboardingPageState extends State<FamilyOnboardingPage> {
  late final api = FamilyOnboarding(MultiuserSession.current);
  final email = TextEditingController(), password = TextEditingController();
  final name = TextEditingController(), birth = TextEditingController();
  final target = TextEditingController();
  Map<String, dynamic>? data;
  String? message;
  String kind = 'adult', operation = MultiuserSession.operationId();
  bool busy = false;
  StreamSubscription<dynamic>? authChanges;
  @override
  void initState() {
    super.initState();
    final openedAs = api.session.userId;
    authChanges = api.session.client.auth.onAuthStateChange.listen((_) {
      if (mounted && api.session.userId != openedAs) {
        setState(() {
          data = null;
          kind = 'adult';
          message = 'La sesión cambió. Volvé al acceso para continuar.';
        });
      }
    });
    if (api.session.signedIn) _refresh();
  }

  @override
  void dispose() {
    authChanges?.cancel();
    for (final c in [email, password, name, birth, target]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() {
          data = null;
          message = InstitutionOnboarding.error(
            e,
          ).replaceAll('alta institucional', 'alta de alumnos y familias');
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _refresh() => _run(() async {
    final value = await api.state();
    if (mounted) {
      setState(() {
        data = value;
        if (value['adult'] != true) kind = 'adult';
      });
    }
  });
  Future<void> _command(String action, Map<String, dynamic> body) =>
      _run(() async {
        await api.command(action, body);
        if (action == 'apply') operation = MultiuserSession.operationId();
        final value = await api.state();
        if (mounted) {
          setState(() {
            data = value;
            if (value['adult'] != true) kind = 'adult';
            message = 'Operación confirmada por el servidor.';
          });
        }
      });
  Future<void> _review(String action, Map row) async {
    var evidence = '';
    var checked = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            action == 'revoke'
                ? 'Revocar autorización'
                : 'Revisión administrativa',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'La revisión debe comprobar identidad, edad y, para menores, responsabilidad autorizada. Atena no verifica automáticamente la representación legal. No escribas documentos ni datos sensibles aquí.',
                ),
                TextField(
                  onChanged: (v) => update(() => evidence = v.trim()),
                  decoration: const InputDecoration(
                    labelText: 'Referencia de revisión',
                  ),
                ),
                if (action == 'approve')
                  CheckboxListTile(
                    value: checked,
                    onChanged: (v) => update(() => checked = v == true),
                    title: const Text(
                      'Verifiqué identidad, edad y autorización correspondiente',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed:
                  evidence.length >= 8 && (action != 'approve' || checked)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Confirmar revisión'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _command(action, {
      if (action == 'revoke') ...{
        'profile_id': row['id'],
        'user_id': row['user_id'],
      } else
        'application_id': row['id'],
      'review_reference': evidence,
      'identity_checked': checked,
      'responsibility_checked': checked,
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Alumnos y familias'),
      actions: [
        if (api.session.signedIn)
          IconButton(
            onPressed: busy ? null : _refresh,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Supabase compartido · Piloto de evaluación'),
        const Text(
          'Crear una cuenta no aprueba perfiles ni vínculos. Confirmá tu correo y solicitá una revisión. Los menores se gestionan mediante adultos autorizados.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (message != null) Text(message!),
        if (!api.session.signedIn) ...[
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
          ),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña (mínimo 12 caracteres)',
            ),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () => _run(() async {
                    await api.register(email.text, password.text);
                    password.clear();
                    if (mounted) {
                      setState(
                        () => message =
                            'Revisá tu correo y confirmá el enlace. Después volvé al acceso e ingresá.',
                      );
                    }
                  }),
            child: const Text('Crear cuenta remota'),
          ),
        ],
        if (data != null && api.session.signedIn) ...[
          DropdownButtonFormField<String>(
            key: ValueKey('${data!['adult']}:$kind'),
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Solicitud'),
            items: [
              const DropdownMenuItem(
                value: 'adult',
                child: Text('Mi perfil · mayor de 18 años'),
              ),
              const DropdownMenuItem(
                value: 'self_link',
                child: Text('Mi perfil existente · ya cumplí 18 años'),
              ),
              if (data!['adult'] == true) ...[
                const DropdownMenuItem(
                  value: 'minor',
                  child: Text('Nuevo perfil de menor'),
                ),
                const DropdownMenuItem(
                  value: 'link',
                  child: Text('Vincular menor existente'),
                ),
              ],
            ],
            onChanged: busy
                ? null
                : (v) => setState(() {
                    kind = v!;
                    operation = MultiuserSession.operationId();
                  }),
          ),
          if (kind == 'adult' || kind == 'minor') ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre del perfil'),
            ),
            TextField(
              controller: birth,
              decoration: const InputDecoration(
                labelText: 'Nacimiento (AAAA-MM-DD)',
              ),
            ),
          ] else ...[
            const Text(
              'El código identifica la solicitud, no concede acceso. Un revisor debe comprobar la responsabilidad antes de vincularla.',
            ),
            TextField(
              controller: target,
              decoration: const InputDecoration(
                labelText: 'Código de perfil para revisión',
              ),
            ),
          ],
          FilledButton(
            onPressed: busy
                ? null
                : () => _command('apply', {
                    'operation_id': operation,
                    'kind': kind,
                    'name': kind == 'adult' || kind == 'minor'
                        ? name.text.trim()
                        : '',
                    if (kind == 'adult' || kind == 'minor')
                      'birth_date': birth.text.trim(),
                    if (kind == 'link' || kind == 'self_link')
                      'target_profile': target.text.trim(),
                  }),
            child: const Text('Solicitar revisión'),
          ),
          for (final Map a in data!['applications'] as List? ?? [])
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a['name'] == '' ? 'Vinculación familiar' : a['name']} · ${a['status']}',
                    ),
                    if (data!['reviewer'] == true)
                      Text(
                        'Cuenta: ${a['applicant']}\nNacimiento: ${a['birth_date'] ?? 'No corresponde'}\nPerfil solicitado: ${a['target_profile'] ?? 'Nuevo'}',
                      ),
                    if (data!['reviewer'] == true &&
                        a['status'] == 'pending' &&
                        a['applicant'] != api.session.userId)
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => _review('approve', a),
                            child: const Text('Revisar y aprobar'),
                          ),
                          TextButton(
                            onPressed: busy ? null : () => _review('reject', a),
                            child: const Text('Rechazar'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          for (final Map p in data!['profiles'] as List? ?? [])
            Card(
              child: ListTile(
                title: Text('${p['name']}'),
                subtitle: SelectableText(
                  'Código: ${p['id']}\n${p['active'] == true ? 'Autorización vigente' : 'Revocada'}${data!['reviewer'] == true ? '\nCuenta: ${p['user_id']}' : ''}',
                ),
                trailing:
                    data!['reviewer'] == true &&
                        p['active'] == true &&
                        p['user_id'] != api.session.userId
                    ? TextButton(
                        onPressed: busy ? null : () => _review('revoke', p),
                        child: const Text('Revocar'),
                      )
                    : null,
              ),
            ),
          const Text(
            'Después de la aprobación, volvé a Cuenta y actualizá para elegir el perfil y consultar ofertas e inscripciones.',
          ),
        ],
      ],
    ),
  );
}
