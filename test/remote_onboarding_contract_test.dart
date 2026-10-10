import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/screens/auth/alumno_login_page.dart';
import 'package:atena_app/screens/auth/institucion_login_page.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({'existing-local': 'preserve'});
    client = SupabaseClient(
      'https://fixture.invalid',
      'fictional-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    MultiuserSession.testSession = MultiuserSession(client);
  });
  tearDown(() async {
    MultiuserSession.testSession = null;
    await client.dispose();
  });
  for (final entry in <({String name, Widget page})>[
    (name: 'institution', page: const InstitucionLoginPage()),
    (name: 'student', page: const AlumnoLoginPage()),
  ]) {
    testWidgets(
      '${entry.name}: remote onboarding cannot create a local account',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: entry.page,
          ),
        );
        await tester.pumpAndSettle();
        final labels = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        );
        final register = find.widgetWithText(
          OutlinedButton,
          labels.commonRegister,
        );
        expect(register, findsOneWidget);
        expect(tester.widget<OutlinedButton>(register).onPressed, isNull);
        expect(
          find.textContaining('Sólo cuentas piloto habilitadas'),
          findsOneWidget,
        );
        expect(
          (await SharedPreferences.getInstance()).getString('existing-local'),
          'preserve',
        );
        expect(client.auth.currentUser, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
