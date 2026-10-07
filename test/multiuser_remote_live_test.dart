// Opt-in: the secure launcher injects fictional credentials into process memory.
// Nothing in this file provisions Auth users, passwords, permissions or schema.
import 'dart:convert';
import 'dart:io';

import 'package:atena_app/main.dart';
import 'package:atena_app/screens/alumnos/alumno_buscar_instituciones_page.dart';
import 'package:atena_app/screens/alumnos/alumno_mis_solicitudes_page.dart';
import 'package:atena_app/screens/auth/alumno_login_page.dart';
import 'package:atena_app/screens/auth/institucion_login_page.dart';
import 'package:atena_app/screens/cuentas/cuenta_home_page.dart';
import 'package:atena_app/screens/instituciones/institucion_catalogo_page.dart';
import 'package:atena_app/screens/instituciones/institucion_mis_solicitudes_page.dart';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _LiveBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  final env = Platform.environment;
  if (!env.containsKey('ATENA_LIVE_PASSWORD_C')) return;
  _LiveBinding();
  final manifest = jsonDecode(env['ATENA_LIVE_MANIFEST']!) as Map;
  final institution = manifest['institution_a'] as Map;
  final profile = manifest['applicants'][0]['profile_id'] as String;
  final otherProfile = manifest['applicants'][1]['profile_id'] as String;
  final group = manifest['resource']['group_id'] as String;
  final clients = List.generate(
    3,
    (_) => SupabaseClient(
      'https://eaegvxxxkvhdukbkydvy.supabase.co',
      env['ATENA_LIVE_PUBLIC_KEY']!,
    ),
  );
  final sessions = clients.map(MultiuserSession.new).toList();

  testWidgets(
    'real Auth + ordinary Flutter screens: publish, request, confirm, capacity and isolation',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'preserve_local_marker': 'untouched',
      });
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> waitFor(Finder finder) async {
        debugPrint('Await UI: $finder');
        for (var attempt = 0; attempt < 300; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 70)),
          );
          await tester.pump(const Duration(milliseconds: 70));
          if (finder.evaluate().isNotEmpty) return;
        }
        fail('Expected screen did not appear: $finder');
      }

      // HTTP clients reused by widgets deliver callbacks in the widget zone.
      // Keep pumping that zone while awaiting real I/O, instead of freezing it
      // inside runAsync for the whole operation.
      Future<void> network(Future<void> Function() action) async {
        var done = false;
        Object? error;
        StackTrace? stack;
        action().then<void>(
          (_) {
            done = true;
          },
          onError: (Object e, StackTrace s) {
            error = e;
            stack = s;
            done = true;
          },
        );
        for (var attempt = 0; !done && attempt < 600; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        if (!done) fail('Live HTTP operation did not finish');
        if (error != null) Error.throwWithStackTrace(error!, stack!);
      }

      Future<void> denied(Future<dynamic> operation, Matcher matcher) async {
        Object? rejected;
        try {
          await operation;
        } catch (e) {
          rejected = e;
        }
        expectSync(rejected, matcher);
      }

      Future<void> show(int account, Widget page) async {
        debugPrint('Open UI: ${page.runtimeType}, session $account');
        MultiuserSession.testSession = sessions[account];
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: page,
          ),
        );
      }

      Future<void> login(String label) async {
        debugPrint('Login UI: $label');
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), env['ATENA_LIVE_EMAIL_$label']!);
        await tester.enterText(
          fields.at(1),
          env['ATENA_LIVE_PASSWORD_$label']!,
        );
        final submit = find.byWidgetPredicate((w) => w is ElevatedButton).first;
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        debugPrint('Login submitted: $label');
        await waitFor(find.text('Cuenta / perfiles autorizados'));
      }

      try {
        // Institution enters through its EXISTING login, not a privileged test RPC.
        await show(0, const InstitucionLoginPage());
        await login('A');
        await waitFor(find.text('Catálogo y disponibilidad'));
        await tester.tap(find.text('Catálogo y disponibilidad'));
        await waitFor(find.textContaining('Versión remota:'));
        expectSync(find.byType(InstitucionCatalogoPage), findsOneWidget);
        await tester.tap(find.text('Publicar catálogo compartido'));
        await waitFor(find.text('Publicación confirmada por Supabase.'));

        // Retire only the old PENDING request from this exact fictional campaign.
        // The previous confirmed request and historical pilot records are retained.
        await network(() async {
          final rows = await sessions[0].requests(
            institutionId: institution['institution_id'],
            areaId: institution['area_id'],
          );
          for (final r in rows.where(
            (r) =>
                r['group_id'] == group &&
                r['applicant_profile_id'] == profile &&
                r['state'] == 'pending',
          )) {
            await sessions[0].decide(
              institution['institution_id'],
              institution['area_id'],
              r['id'],
              'rejected',
            );
          }
        });

        // Independent anonymous client -> existing public catalog/profile -> login.
        await show(1, const AlumnoBuscarInstitucionesPage.publica());
        await waitFor(find.text('Ver institución y ofertas'));
        await tester.tap(find.text('Ver institución y ofertas').first);
        await waitFor(find.text('Solicitar inscripción'));
        await tester.ensureVisible(find.text('Solicitar inscripción').first);
        await tester.tap(find.text('Solicitar inscripción').first);
        await waitFor(find.byType(AlumnoLoginPage));
        await login('B');
        await waitFor(find.text(profile));
        expectSync(find.text(otherProfile), findsNothing);
        await tester.tap(find.text(profile));
        await waitFor(find.text('Enviar solicitud'));
        await tester.tap(find.text('Enviar solicitud'));
        await waitFor(find.text('Pendiente'));
        expectSync(find.byType(AlumnoMisSolicitudesPage), findsOneWidget);
        String requestId = '';
        debugPrint('Read newly created request');
        await network(() async {
          final rows = await sessions[1]
              .requests(profile: profile)
              .timeout(const Duration(seconds: 15));
          final created = rows.singleWhere(
            (r) => r['group_id'] == group && r['state'] == 'pending',
          );
          requestId = created['id'];
          debugPrint('Created request found; checking third identity');
          expectSync(
            created['applicant_auth_user_id'],
            clients[1].auth.currentUser!.id,
          );
          await sessions[2]
              .signIn(env['ATENA_LIVE_EMAIL_C']!, env['ATENA_LIVE_PASSWORD_C']!)
              .timeout(const Duration(seconds: 15));
          debugPrint('Third identity authenticated');
          expectSync((await sessions[2].context()).institutions, isEmpty);
          await denied(
            clients[1].rpc(
              'atena_request_create',
              params: {
                'p_profile_id': otherProfile,
                'p_group_id': group,
                'p_operation_id': MultiuserSession.operationId(),
              },
            ),
            isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
          );
          final publication = await sessions[0].publication(
            institution['institution_id'],
            institution['area_id'],
          );
          await denied(
            clients[1].rpc(
              'atena_publish_catalog',
              params: {
                'p_institution_id': institution['institution_id'],
                'p_area_id': institution['area_id'],
                'p_operation_id': MultiuserSession.operationId(catalog: true),
                'p_expected_version': publication['version'],
                'p_payload': jsonEncode(publication['document']),
                'p_fingerprint': '0' * 64,
                'p_state': 'published',
              },
            ),
            isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
          );
          expectSync(
            await clients[2]
                .from('atena_requests')
                .select()
                .eq('id', requestId),
            isEmpty,
          );
          await denied(
            clients[2].rpc(
              'atena_request_decide',
              params: {'p_request_id': requestId, 'p_state': 'confirmed'},
            ),
            isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
          );
          await denied(
            sessions[1].create(
              otherProfile,
              (await sessions[1].catalog())
                  .expand((i) => i.ofertas)
                  .firstWhere((o) => o.id == group),
              MultiuserSession.operationId(),
            ),
            isA<StateError>(),
          );
        });

        await show(0, CuentaHomePage(cuentaId: sessions[0].userId));
        await waitFor(find.text('Gestionar solicitudes'));
        await tester.tap(find.text('Gestionar solicitudes'));
        await waitFor(find.text('Confirmar'));
        expectSync(find.byType(InstitucionMisSolicitudesPage), findsOneWidget);
        await tester.ensureVisible(find.text('Confirmar'));
        await tester.tap(find.text('Confirmar'));
        await waitFor(
          find.descendant(
            of: find.byKey(ValueKey(requestId)),
            matching: find.text('Confirmada'),
          ),
        );
        await network(() async {
          final rows = await sessions[0].requests(
            institutionId: institution['institution_id'],
            areaId: institution['area_id'],
          );
          expectSync(
            rows.singleWhere((r) => r['id'] == requestId)['state'],
            'confirmed',
          );
          await sessions[0].decide(
            institution['institution_id'],
            institution['area_id'],
            requestId,
            'confirmed',
          );
          final a = (await sessions[0].catalog())
              .expand((i) => i.ofertas)
              .singleWhere((o) => o.id == group);
          final b = (await sessions[1].catalog())
              .expand((i) => i.ofertas)
              .singleWhere((o) => o.id == group);
          expectSync(a.disponibles, 0);
          expectSync(b.disponibles, a.disponibles);
        });
        await show(
          1,
          AlumnoMisSolicitudesPage(
            ownerAccountId: sessions[1].userId,
            perfilId: profile,
          ),
        );
        await waitFor(find.text('Confirmada'));
        expectSync(find.text('Vacantes disponibles: 0'), findsWidgets);

        // Remote logout must not leave a local session capable of restoring a role.
        await show(1, CuentaHomePage(cuentaId: sessions[1].userId));
        await waitFor(find.text(profile));
        await tester.tap(find.byTooltip('Cerrar sesión'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        expectSync(sessions[1].signedIn, isFalse);
        await network(() async {
          await denied(sessions[1].context(), isA<StateError>());
          final prefs = await SharedPreferences.getInstance();
          expectSync(prefs.getKeys(), {'preserve_local_marker'});
        });
        await tester.pumpWidget(
          const AtenaApp(
            initialLocale: Locale('es'),
            initialThemeMode: ThemeMode.light,
          ),
        );
        await waitFor(find.text('Alumnos'));
        expectSync(find.text(profile), findsNothing);
      } finally {
        debugPrint('Dispose live test clients');
        await tester.pumpWidget(const SizedBox.shrink());
        MultiuserSession.testSession = null;
        await network(() async {
          for (final client in clients) {
            await client.dispose().timeout(const Duration(seconds: 5));
          }
        });
        // dart:io keeps idle HTTP connections for 15 seconds. Expire those real
        // client's idle timers before the widget binding checks its invariants.
        await tester.pump(const Duration(seconds: 16));
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
