import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:atena_app/services/remote/documentos_supabase_repository.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/ui/private_document_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  _Binding();
  late SupabaseClient client;
  late HttpServer server;
  late MultiuserSession session;
  Completer<void>? gate;
  late Completer<void> received;
  Future<void> login(String token, {String actor = 'fictitious-user'}) async {
    // Local SDK state only, not a verified JWT or remote authentication.
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': token,
        'refresh_token': 'fixture-refresh',
        'expires_in': 3600,
        'token_type': 'bearer',
        'user': {
          'id': actor,
          'aud': 'authenticated',
          'email': 'test@example.invalid',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-10-27T00:00:00Z',
        },
      }),
    );
  }

  setUp(() async {
    gate = null;
    received = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    session = MultiuserSession(client);
    await login('fixture-session-a');
    server.listen((r) async {
      await utf8.decoder.bind(r).join();
      if (!received.isCompleted) received.complete();
      await gate?.future;
      r.response.headers.contentType = ContentType.json;
      r.response.write('{}');
      await r.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'old private response rejected even when same user logs in again',
    () async {
      gate = Completer<void>();
      final opening = DocumentosSupabaseRepository(
        session,
      ).open('document-test');
      final rejected = expectLater(opening, throwsStateError);
      await received.future;
      await login('fixture-session-b');
      gate!.complete();
      await rejected;
    },
  );
  testWidgets('visible document disappears after account changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrivateDocumentView(
          session: session,
          child: const Text('PRIVATE-FIXTURE'),
        ),
      ),
    );
    expect(find.text('PRIVATE-FIXTURE'), findsOneWidget);
    await login('fixture-session-b', actor: 'other-fixture');
    await tester.pump();
    expect(find.text('PRIVATE-FIXTURE'), findsNothing);
    expect(find.textContaining('Vista privada cerrada'), findsOneWidget);
  });
  testWidgets(
    'background closes cached bytes and resuming cannot restore them',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PrivateDocumentView(
            session: session,
            child: const Text('PRIVATE-FIXTURE'),
          ),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('PRIVATE-FIXTURE'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('PRIVATE-FIXTURE'), findsNothing);
    },
  );
}
