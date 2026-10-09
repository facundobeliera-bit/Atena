import 'dart:convert';
import 'dart:io';
import 'package:atena_app/main.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

// Offline navigation regression: actual SDK Auth events, not JWT verification.
// Real authentication/isolation is tested by the opt-in remote suites.
class _Session extends MultiuserSession {
  _Session(super.client);
  @override
  Future<RemoteIdentityContext> context() async => RemoteIdentityContext({
    'auth_user_id': userId,
    'applicant_profiles': <dynamic>[],
    'institutional_contexts': <dynamic>[],
  });
}

void main() {
  _Binding();
  late HttpServer server;
  late SupabaseClient client;
  Future<void> restore(String id) => client.auth.recoverSession(
    jsonEncode({
      'access_token': 'offline-fixture-not-a-valid-jwt',
      'token_type': 'bearer',
      'user': {
        'id': id,
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({'protected-local': 'unchanged'});
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 200;
      request.response.write('{}');
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'fictional-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    MultiuserSession.testSession = _Session(client);
    await restore('account-a');
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    await client.dispose();
    await server.close(force: true);
  });
  Future<void> openPrivate(WidgetTester tester) async {
    await tester.pumpWidget(
      const AtenaApp(
        initialLocale: Locale('es'),
        initialThemeMode: ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('PRIVATE ACCOUNT A')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE ACCOUNT A'), findsOneWidget);
  }

  testWidgets(
    'remote logout removes private routes and Back cannot restore them',
    (tester) async {
      await openPrivate(tester);
      await tester.runAsync(
        () => client.auth.signOut(scope: SignOutScope.local),
      );
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE ACCOUNT A'), findsNothing);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(nav.canPop(), isFalse);
      expect(client.auth.currentUser, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('protected-local'),
        'unchanged',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'different remote identity discards previous account navigation',
    (tester) async {
      await openPrivate(tester);
      await restore('account-b');
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE ACCOUNT A'), findsNothing);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
        isFalse,
      );
      expect(client.auth.currentUser!.id, 'account-b');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('same identity session refresh preserves ongoing navigation', (
    tester,
  ) async {
    await openPrivate(tester);
    await client.auth.setInitialSession(
      jsonEncode(client.auth.currentSession!.toJson()),
    );
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE ACCOUNT A'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('expired unrecoverable session removes private content', (
    tester,
  ) async {
    await openPrivate(tester);
    final expired = client.auth.currentSession!.toJson();
    // Synthetic expired token, accepted only by the offline SDK fixture.
    expired['access_token'] = 'e30.eyJleHAiOjB9.offline';
    await tester.runAsync(() async {
      await expectLater(
        client.auth.recoverSession(jsonEncode(expired)),
        throwsA(isA<AuthException>()),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE ACCOUNT A'), findsNothing);
    expect(client.auth.currentUser, isNull);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'first login preserves the route handling a pending public offer',
    (tester) async {
      await tester.runAsync(
        () => client.auth.signOut(scope: SignOutScope.local),
      );
      await tester.pumpWidget(
        const AtenaApp(
          initialLocale: Locale('es'),
          initialThemeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: Text('PUBLIC LOGIN WITH PENDING OFFER')),
            ),
          );
      await tester.pumpAndSettle();
      await restore('account-a');
      await tester.pumpAndSettle();
      expect(find.text('PUBLIC LOGIN WITH PENDING OFFER'), findsOneWidget);
      expect(client.auth.currentUser!.id, 'account-a');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
