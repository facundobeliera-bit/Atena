import 'dart:convert';
import 'dart:io';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

// SDK/HTTP contract regression, not a simulation claimed as real JWT validation.
void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  late MultiuserSession session;
  final paths = <String>[];
  bool available = true, failure = false, switchIdentity = false;
  String? contextError;
  Future<void> restore(String id) => client.auth.recoverSession(
    jsonEncode({
      'access_token': 'offline-fixture-not-valid-jwt',
      'token_type': 'bearer',
      'user': {
        'id': id,
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({'local-data': 'preserve'});
    paths.clear();
    available = true;
    failure = false;
    switchIdentity = false;
    contextError = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    session = MultiuserSession(client);
    server.listen((r) async {
      await r.drain<void>();
      r.response.persistentConnection = false;
      paths.add(r.uri.toString());
      Object? reply = {};
      if (r.uri.path.endsWith('atena_authenticated_context')) {
        reply = {
          'auth_user_id': session.userId,
          'applicant_profiles': [],
          'institutional_contexts': [],
          if (available) 'session_guard_version': 1,
        };
        if (contextError != null) {
          r.response.statusCode = 403;
          reply = {'code': '42501', 'message': contextError};
        }
      }
      if (r.uri.path.endsWith('atena_revoke_my_sessions')) {
        reply = null;
        if (failure) {
          r.response.statusCode = 503;
          reply = {'code': '503', 'message': 'offline'};
        }
        if (switchIdentity) await restore('account-b');
      }
      r.response.headers.contentType = ContentType.json;
      r.response.write(jsonEncode(reply));
      await r.response.close();
    });
    await restore('account-a');
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'global logout performs server cutoff then Auth global logout',
    () async {
      await session.signOutEverywhere();
      expect(paths, [
        '/rest/v1/rpc/atena_authenticated_context',
        '/rest/v1/rpc/atena_revoke_my_sessions',
        '/auth/v1/logout?scope=global',
      ]);
      expect(session.signedIn, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('local-data'),
        'preserve',
      );
    },
  );
  test('older server does not simulate global revocation', () async {
    available = false;
    await expectLater(session.signOutEverywhere(), throwsStateError);
    expect(paths, hasLength(1));
    expect(session.signedIn, isTrue);
  });
  test('cutoff failure propagates and permits a real retry', () async {
    failure = true;
    await expectLater(
      session.signOutEverywhere(),
      throwsA(isA<PostgrestException>()),
    );
    expect(session.signedIn, isTrue);
    expect(paths.where((p) => p.contains('/logout')), isEmpty);
    failure = false;
    await session.signOutEverywhere();
    expect(session.signedIn, isFalse);
  });
  test(
    'identity change during cutoff cannot sign out a different account',
    () async {
      switchIdentity = true;
      await expectLater(session.signOutEverywhere(), throwsStateError);
      expect(session.userId, 'account-b');
      expect(paths.where((p) => p.contains('/logout')), isEmpty);
    },
  );
  test('explicit revoked session clears SDK Auth state', () async {
    contextError = 'Session revoked or expired';
    await expectLater(session.context(), throwsA(isA<PostgrestException>()));
    expect(session.signedIn, isFalse);
    expect(paths.last, '/auth/v1/logout?scope=local');
  });
  test(
    'permission denial never signs out an otherwise authenticated user',
    () async {
      contextError = 'Not authorized';
      await expectLater(session.context(), throwsA(isA<PostgrestException>()));
      expect(session.signedIn, isTrue);
      expect(paths, hasLength(1));
    },
  );
}
