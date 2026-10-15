import 'package:flutter/material.dart';
import '../services/remote/password_recovery.dart';

class PasswordRecoveryPage extends StatefulWidget {
  final String? initialEmail;
  final PasswordRecovery? recovery;
  const PasswordRecoveryPage({super.key, this.initialEmail, this.recovery});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  late final api = widget.recovery ?? PasswordRecovery.fromEnvironment();
  late final email = TextEditingController(text: widget.initialEmail ?? '');
  final form = GlobalKey<FormState>();
  bool busy = false, requested = false;

  @override
  void dispose() {
    email.dispose();
    if (widget.recovery == null) api?.dispose();
    super.dispose();
  }

  void back() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  Future<void> request() async {
    if (busy || requested || api == null || !form.currentState!.validate()) {
      return;
    }
    setState(() => busy = true);
    await api!.request(email.text);
    if (!mounted) return;
    email.clear();
    setState(() {
      busy = false;
      requested = true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Recuperar contraseña'),
      leading: IconButton(
        tooltip: 'Volver',
        onPressed: back,
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (api == null)
                  const Text(
                    'La recuperación remota está pendiente de habilitación en '
                    'el piloto. No se ha solicitado ningún cambio de contraseña.',
                  )
                else if (requested)
                  const Text(PasswordRecovery.neutralMessage)
                else ...[
                  const Text(
                    'Usá el correo de tu cuenta remota. Supabase enviará un '
                    'enlace para establecer una nueva contraseña en el navegador.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) =>
                        RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Ingresá un correo válido.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : request,
                    child: Text(busy ? 'Enviando…' : 'Solicitar enlace'),
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: back,
                  child: const Text('Volver al ingreso'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
