import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/remote/multiuser_session.dart';

/// No cached private bytes remain rendered after leaving this foreground session.
/// Reopening goes through the document RPC and its current authorization again.
class PrivateDocumentView extends StatefulWidget {
  final MultiuserSession session;
  final Widget child;
  const PrivateDocumentView({
    super.key,
    required this.session,
    required this.child,
  });
  @override
  State<PrivateDocumentView> createState() => _PrivateDocumentViewState();
}

class _PrivateDocumentViewState extends State<PrivateDocumentView>
    with WidgetsBindingObserver {
  late final String _actor;
  late final String? _token;
  StreamSubscription<AuthState>? _subscription;
  bool _closed = false;
  @override
  void initState() {
    super.initState();
    _actor = widget.session.userId;
    _token = widget.session.client.auth.currentSession?.accessToken;
    _closed = _actor.isEmpty || _token == null;
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.session.client.auth.onAuthStateChange.listen((_) {
      if (widget.session.userId != _actor ||
          widget.session.client.auth.currentSession?.accessToken != _token) {
        _close();
      }
    }, onError: (Object _) => _close());
  }

  void _close() {
    if (mounted && !_closed) setState(() => _closed = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _close();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _closed
      ? Scaffold(
          appBar: AppBar(title: const Text('Documento privado')),
          body: const Center(
            child: Text(
              'Vista privada cerrada. Volvé a abrir el documento para verificar tu acceso.',
            ),
          ),
        )
      : widget.child;
}
