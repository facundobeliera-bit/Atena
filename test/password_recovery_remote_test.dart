import 'dart:convert';
import 'dart:io';
import 'package:atena_app/main.dart' show AtenaApp;
import 'package:atena_app/screens/auth/alumno_forgot_password_page.dart';
import 'package:atena_app/screens/auth/institucion_forgot_password_page.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/services/remote/password_recovery.dart';
import 'package:atena_app/ui/password_recovery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

class _ObservedRecovery extends PasswordRecovery {
  _ObservedRecovery(super.auth);
  Future<void>? pending;
  @override
  Future<void> request(String email) => pending = super.request(email);
}

void main() {
  _Binding();
  late HttpServer server;
  late GoTrueClient auth;
  late _ObservedRecovery recovery;
  late SupabaseClient normal;
  late SupabaseClient guest;
  final requests =
      <({String method, Uri url, String body, String? authorization})>[];
  int response = 200;
  bool offline = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'protected-local': 'unchanged'});
    requests.clear();
    response = 200;
    offline = false;
    normal = SupabaseClient(
      'https://fixture.invalid',
      'fictional-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    guest = SupabaseClient(
      'https://fixture.invalid',
      'fictional-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await normal.auth.recoverSession(
      jsonEncode({
        'access_token': 'offline-fixture-not-valid-jwt',
        'token_type': 'bearer',
        'user': {
          'id': 'other-account',
          'app_metadata': {},
          'user_metadata': {},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      requests.add((
        method: r.method,
        url: r.uri,
        body: await utf8.decoder.bind(r).join(),
        authorization: r.headers.value('authorization'),
      ));
      r.response.headers.contentType = ContentType.json;
      r.response.persistentConnection = false;
      r.response.statusCode = response;
      r.response.write(
        offline
            ? 'INVALID JSON UNTRUSTED'
            : response == 200
            ? '{}'
            : '{"msg":"UNTRUSTED account status","error_code":"email_not_found"}',
      );
      await r.response.close();
    });
    auth = GoTrueClient(
      url: 'http://127.0.0.1:${server.port}/auth/v1',
      headers: {'apikey': 'fictional-public'},
      autoRefreshToken: false,
      flowType: AuthFlowType.implicit,
    );
    recovery = _ObservedRecovery(auth);
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    recovery.dispose();
    await normal.dispose();
    await guest.dispose();
    await server.close(force: true);
  });

  test(
    'SDK requests official recovery without PKCE storage or session mutation',
    () async {
      await recovery.request('  fictional@example.invalid  ');
      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/auth/v1/recover');
      expect(r.url.queryParameters, {
        'redirect_to': PasswordRecovery.returnUrl,
      });
      final body = jsonDecode(r.body) as Map;
      expect(body['email'], 'fictional@example.invalid');
      expect(body['code_challenge'], isNull);
      expect(r.authorization, isNull);
      expect(auth.currentSession, isNull);
      expect(normal.auth.currentUser!.id, 'other-account');
      expect((await SharedPreferences.getInstance()).getKeys(), {
        'protected-local',
      });
    },
  );

  for (final status in [200, 400, 422, 429, 500]) {
    testWidgets(
      'neutral UI for provider status $status; no account enumeration',
      (tester) async {
        response = status;
        await tester.pumpWidget(
          MaterialApp(home: PasswordRecoveryPage(recovery: recovery)),
        );
        await tester.enterText(
          find.byType(TextFormField),
          'fictional@example.invalid',
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('Solicitar enlace'));
          await recovery.pending;
        });
        await tester.pumpAndSettle();
        expect(find.text(PasswordRecovery.neutralMessage), findsOneWidget);
        expect(find.textContaining('UNTRUSTED'), findsNothing);
        expect(find.text('Solicitar enlace'), findsNothing);
        expect(requests, hasLength(1));
        expect(auth.currentSession, isNull);
        expect(normal.auth.currentUser!.id, 'other-account');
        await tester.tap(find.text('Volver al ingreso'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('transport errors never reveal provider output', () async {
    offline = true;
    await recovery.request('fictional@example.invalid');
    expect(auth.currentSession, isNull);
    expect(normal.auth.currentUser!.id, 'other-account');
  });
  testWidgets('invalid email does not send; duplicate submits are ignored', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: PasswordRecoveryPage(recovery: recovery)),
    );
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.tap(find.text('Solicitar enlace'));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    await tester.enterText(
      find.byType(TextFormField),
      'fictional@example.invalid',
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Solicitar enlace'));
      await tester.tap(find.text('Solicitar enlace'));
      await recovery.pending;
    });
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
  });
  testWidgets(
    'both roles use remote recovery, disabled until configuration approval',
    (tester) async {
      MultiuserSession.testSession = MultiuserSession(normal);
      for (final page in [
        const AlumnoForgotPasswordPage(),
        const InstitucionForgotPasswordPage(),
      ]) {
        await tester.pumpWidget(MaterialApp(home: page));
        await tester.pumpAndSettle();
        expect(find.byType(PasswordRecoveryPage), findsOneWidget);
        expect(
          find.textContaining('pendiente de habilitación'),
          findsOneWidget,
        );
        expect(find.text('Solicitar enlace'), findsNothing);
        expect(requests, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
  testWidgets(
    'real remote router opens recovery for both roles and can return',
    (tester) async {
      MultiuserSession.testSession = MultiuserSession(guest);
      await tester.pumpWidget(
        const AtenaApp(
          initialLocale: Locale('es'),
          initialThemeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();
      for (final route in [
        '/alumno_forgot_password',
        '/institucion_forgot_password',
      ]) {
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .pushNamed(route);
        await tester.pumpAndSettle();
        expect(find.byType(PasswordRecoveryPage), findsOneWidget);
        await tester.tap(find.text('Volver al ingreso'));
        await tester.pumpAndSettle();
        expect(find.byType(PasswordRecoveryPage), findsNothing);
      }
      expect(normal.auth.currentUser!.id, 'other-account');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
