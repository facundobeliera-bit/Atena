import 'package:atena_app/main.dart';
import 'package:atena_app/screens/landing/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Sin sesión, Atena abre la portada', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      const AtenaApp(
        initialLocale: Locale('es'),
        initialThemeMode: ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
