import 'package:flutter/material.dart';
import '../services/remote/institution_onboarding.dart';
import '../services/remote/multiuser_session.dart';

/// Registration and applications are distinct from authorized institutional access.
class InstitutionOnboardingPage extends StatefulWidget {
  const InstitutionOnboardingPage({super.key});
  @override
  State<InstitutionOnboardingPage> createState() =>
      _InstitutionOnboardingPageState();
}

class _InstitutionOnboardingPageState extends State<InstitutionOnboardingPage> {
  late final api = InstitutionOnboarding(MultiuserSession.current);
  final email = TextEditingController(), password = TextEditingController();
  final name = TextEditingController(), reference = TextEditingController();
  final applicationOperation = MultiuserSession.operationId();
  Map<String, dynamic>? state;
  String? message;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    if (api.session.signedIn) _refresh();
  }

  @override
  void dispose() {
    for (final c in [email, password, name, reference]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) {
        setState(() {
          state = null;
          message = InstitutionOnboarding.error(e);
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _refresh() => _run(() async {
    final result = await api.state();
    if (mounted) setState(() => state = result);
  });
  Future<void> _command(String action, Map<String, dynamic> data) =>
      _run(() async {
        await api.command(action, data);
        final result = await api.state();
        if (mounted) {
          setState(() {
            state = result;
            message = 'Operación confirmada por el servidor.';
          });
        }
      });
  Future<String?> _text(String title, String label) async {
    var entered = "";
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          onChanged: (value) => entered = value,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, entered.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _review(Map a, bool approve) async {
    final evidence = await _text(
      approve ? 'Aprobar representación' : 'Rechazar solicitud',
      'Referencia de revisión (sin datos sensibles)',
    );
    if (evidence == null || !mounted) return;
    if (approve) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verificación administrativa'),
          content: const Text(
            'Confirmo que revisé la identidad y la autorización para representar esta institución. Atena no realiza una verificación oficial automática.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar revisión'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    await _command(approve ? 'approve' : 'reject', {
      'application_id': a['id'],
      'review_reference': evidence,
      'representation_checked': approve,
    });
  }

  Future<void> _invite(Map institution, Map area) async {
    final recipient = await _text(
      'Invitar operador por 48 horas',
      'Correo del operador',
    );
    if (recipient == null || !mounted) return;
    final selected = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Permisos para esta área'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final cap in const {
                'catalog.publish': 'Publicar ofertas',
                'requests.read': 'Consultar solicitudes',
                'requests.decide': 'Resolver solicitudes',
              }.entries)
                CheckboxListTile(
                  title: Text(cap.value),
                  value: selected.contains(cap.key),
                  onChanged: (v) => update(() {
                    if (v == true) {
                      selected.add(cap.key);
                    } else {
                      selected.remove(cap.key);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Invitar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _command('invite', {
        'institution_id': institution['id'],
        'area_id': area['id'],
        'email': recipient,
        'capabilities': selected.toList(),
      });
    }
  }

  Widget _button(String text, VoidCallback action) =>
      OutlinedButton(onPressed: busy ? null : action, child: Text(text));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Incorporación institucional'),
      actions: [
        if (api.session.signedIn)
          IconButton(
            onPressed: busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Crear una cuenta no aprueba una institución. La representación requiere revisión administrativa explícita.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (message != null) Text(message!),
        if (!api.session.signedIn) ...[
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: password,
            decoration: const InputDecoration(
              labelText: 'Contraseña (12 caracteres o más)',
            ),
            obscureText: true,
          ),
          _button(
            'Crear cuenta remota',
            () => _run(() async {
              await api.register(email.text, password.text);
              password.clear();
              if (mounted) {
                setState(
                  () => message =
                      'Revisá tu correo y confirmá la cuenta. Después regresá a Ingresar. El registro no concede permisos institucionales.',
                );
              }
            }),
          ),
        ] else ...[
          if (state != null) ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nombre de la institución',
              ),
            ),
            TextField(
              controller: reference,
              decoration: const InputDecoration(
                labelText: 'Referencia institucional para revisión',
              ),
            ),
            _button(
              'Solicitar incorporación',
              () => _command('apply', {
                'name': name.text.trim(),
                'reference': reference.text.trim(),
                'operation_id': applicationOperation,
              }),
            ),
            for (final a in state!['applications'] as List)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${a['name']} · ${a['status']}'),
                      if (state!['reviewer'] == true &&
                          a['status'] == 'pending' &&
                          a['applicant'] != api.session.userId) ...[
                        Text('Solicitante: ${a['applicant']}'),
                        Text('Referencia: ${a['reference']}'),
                        _button('Revisar y aprobar', () => _review(a, true)),
                        _button('Rechazar', () => _review(a, false)),
                      ],
                    ],
                  ),
                ),
              ),
            for (final i in state!['institutions'] as List)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i['name'] as String),
                      _button('Crear área', () async {
                        final n = await _text('Nueva área', 'Nombre');
                        if (n != null) {
                          await _command('area_create', {
                            'institution_id': i['id'],
                            'name': n,
                            'operation_id': MultiuserSession.operationId(),
                          });
                        }
                      }),
                      for (final a in i['areas'] as List) ...[
                        Text(a['display_name'] as String),
                        _button('Renombrar área', () async {
                          final n = await _text('Área', 'Nombre');
                          if (n != null) {
                            await _command('area_rename', {
                              'institution_id': i['id'],
                              'area_id': a['id'],
                              'name': n,
                            });
                          }
                        }),
                        _button(
                          'Invitar operador · ${a['display_name']}',
                          () => _invite(i, a),
                        ),
                      ],
                      for (final o in i['operators'] as List)
                        if (o['is_owner'] != true && o['active'] == true)
                          _button('Revocar operador ${o['id']}', () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text(
                                  'Revocar acceso institucional',
                                ),
                                content: Text(
                                  'Se revocará el acceso de ${o['id']} a esta institución.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Revocar'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await _command('revoke_operator', {
                                'institution_id': i['id'],
                                'operator_id': o['id'],
                              });
                            }
                          }),
                    ],
                  ),
                ),
              ),
            for (final i in state!['invitations'] as List)
              _button(
                'Aceptar invitación · ${i['institution_id']} · ${i['area_id']}',
                () => _command('accept_invitation', {'invitation_id': i['id']}),
              ),
            const Text(
              'Tras la aprobación o invitación, volvé a Cuenta y actualizá para abrir las ofertas y solicitudes de tus áreas.',
            ),
          ],
        ],
      ],
    ),
  );
}
