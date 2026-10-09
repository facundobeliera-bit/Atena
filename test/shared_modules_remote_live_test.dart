import 'dart:typed_data';
import 'package:atena_app/screens/alumnos/alumno_documentos_page.dart';
import 'package:atena_app/screens/instituciones/institucion_documentos_page.dart';
import 'package:atena_app/services/documentacion_operativa_service.dart';
import 'package:atena_app/services/documentos_temporales_service.dart';
// Opt-in real JWT widget test. Credentials arrive only in process memory.
// No Auth administration, provisioning, schema change or local data migration.
import 'dart:convert';
import 'dart:io';
import 'package:atena_app/l10n/gen/app_localizations.dart';
import 'package:atena_app/models/alumnos/modulo_educativo.dart';
import 'package:atena_app/screens/alumnos/alumno_calendario_page.dart';
import 'package:atena_app/screens/alumnos/alumno_notificaciones_page.dart';
import 'package:atena_app/screens/alumnos/trayectoria_educativa_page.dart';
import 'package:atena_app/screens/instituciones/institucion_gestion_vacantes_page.dart';
import 'package:atena_app/screens/instituciones/institucion_respuestas_calendario_page.dart';
import 'package:atena_app/services/remote/multiuser_session.dart';
import 'package:atena_app/services/remote/emisiones_supabase_repository.dart';
import 'package:atena_app/services/trayectoria_educativa_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  final env = Platform.environment;
  if (env['ATENA_MODULES_LIVE'] != '1') return;
  _Binding();
  final fixture = jsonDecode(env['ATENA_MODULES_FIXTURE']!) as Map;
  final inst = fixture['institution'] as String,
      area = fixture['area'] as String,
      profile = fixture['profile'] as String,
      enrollment = fixture['request_id'] as String;
  final clients = List.generate(
    2,
    (_) => SupabaseClient(
      'https://eaegvxxxkvhdukbkydvy.supabase.co',
      env['ATENA_MODULES_PUBLIC_KEY']!,
    ),
  );
  final sessions = clients.map(MultiuserSession.new).toList();
  testWidgets(
    'real JWT existing screens: emission, inbox, calendar response and six educational modules',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'protected_local_marker': 'unchanged',
      });
      tester.view.physicalSize = const Size(1300, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
        for (var i = 0; !done && i < 600; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        if (!done) fail('Remote operation timeout');
        if (error != null) Error.throwWithStackTrace(error!, stack!);
      }

      Future<void> denied(Future<dynamic> action) async {
        try {
          await action;
        } on PostgrestException {
          return;
        }
        fail('Expected server authorization rejection');
      }

      Future<void> waitFor(Finder f) async {
        for (var i = 0; i < 400; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
          if (f.evaluate().isNotEmpty) return;
        }
        fail('Expected widget did not appear: $f');
      }

      Future<void> show(int who, Widget page) async {
        MultiuserSession.testSession = sessions[who];
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

      try {
        await network(() async {
          for (var i = 0; i < 2; i++) {
            await sessions[i].signIn(
              env['ATENA_MODULES_EMAIL_$i']!,
              env['ATENA_MODULES_PASSWORD_$i']!,
            );
          }
        });
        final tag = 'Flutter TEST ${DateTime.now().microsecondsSinceEpoch}';
        await show(
          0,
          InstitucionGestionVacantesPage(
            institucionId: inst,
            institucionNombre: 'Institución TEST',
            remoteAreaId: area,
          ),
        );
        await waitFor(find.text(profile));
        await tester.tap(find.byTooltip('Notificar / Emitir'));
        await tester.pumpAndSettle();
        final title = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Título',
        );
        final body = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Mensaje',
        );
        await tester.enterText(title, tag);
        await tester.enterText(body, 'Mensaje ficticio entre sesiones');
        final send = find.byIcon(Icons.send);
        await tester.ensureVisible(send);
        await tester.tap(send);
        await waitFor(find.textContaining('Envío confirmado por Supabase:'));
        debugPrint('PASS existing institutional emission form');
        await show(
          1,
          AlumnoNotificacionesPage(
            alumnoDocumento: '',
            perfilIdFiltro: profile,
          ),
        );
        await waitFor(find.text(tag));
        debugPrint('PASS existing student inbox from another real session');
        final emission = MultiuserSession.operationId();
        final now = DateTime.now();
        await network(() async {
          await EmisionesSupabaseRepository(sessions[0]).save(
            institution: inst,
            area: area,
            id: emission,
            operation: MultiuserSession.operationId(),
            kind: 'calendar',
            title: '$tag calendario',
            body: 'Ficticio',
            requests: [enrollment],
            start: DateTime(now.year, now.month, now.day, 10, 30),
            rsvp: 'optional',
          );
        });
        await show(
          1,
          AlumnoCalendarioPage(
            ownerAccountId: sessions[1].userId,
            perfilId: profile,
            initialItemId: emission,
          ),
        );
        await waitFor(find.textContaining('$tag calendario'));
        debugPrint('PASS existing student calendar');
        await tester.tap(find.textContaining('$tag calendario').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmar').last);
        await network(() async {
          for (var i = 0; i < 30; i++) {
            final rows = await EmisionesSupabaseRepository(
              sessions[1],
            ).student(profile);
            if (rows.singleWhere((r) => r['id'] == emission)['rsvpStatus'] ==
                'yes') {
              return;
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          fail('RSVP was not confirmed by server');
        });
        await show(
          0,
          InstitucionRespuestasCalendarioPage(
            ownerAccountId: sessions[0].userId,
            institucionId: inst,
            areaId: area,
          ),
        );
        await waitFor(find.textContaining('$tag calendario'));
        debugPrint('PASS existing institutional responses');
        final data = <ModuloEducativo, Map<String, dynamic>>{
          ModuloEducativo.progreso: {'porcentaje': 40},
          ModuloEducativo.boletines: {
            'anio': 2026,
            'periodo': 'TEST sprint',
            'calificaciones': {'Materia TEST': 8},
            'observaciones': 'Publicable',
          },
          ModuloEducativo.titulos: {
            'titulo': 'Certificado TEST',
            'entidadEmisora': 'Ficticia',
            'fechaEmision': '2026-10-08',
          },
          ModuloEducativo.becas: {
            'nombre': 'Beca TEST',
            'descripcion': 'Ficticia',
            'fechaInicio': '2026-10-08',
            'fechaFin': '',
            'activa': true,
          },
          ModuloEducativo.sanciones: {
            'motivo': 'TEST',
            'tipo': 'Advertencia',
            'detalle': 'Ficticio',
            'fecha': '2026-10-08',
            'hasta': '',
            'activa': true,
          },
          ModuloEducativo.equivalencias: {
            'institucionOrigenId': 'Ficticia',
            'materiaOrigen': 'TEST A',
            'materiaDestino': 'TEST B',
            'observacion': 'Decisión ficticia',
            'fecha': '2026-10-08',
            'aprobada': true,
          },
        };
        for (final entry in data.entries) {
          final module = entry.key;
          MultiuserSession.testSession = sessions[0];
          await network(() async {
            final old = await TrayectoriaEducativaService.instance
                .leerInstitucion(
                  institucionId: inst,
                  areaId: area,
                  solicitudId: enrollment,
                  modulo: module,
                );
            final own = old
                .where((r) => r['id'] == 'sprint-20261008-${module.name}')
                .firstOrNull;
            await TrayectoriaEducativaService.instance.guardar(
              institucionId: inst,
              areaId: area,
              solicitudId: enrollment,
              modulo: module,
              id: 'sprint-20261008-${module.name}',
              datos: entry.value,
              visibleAlumno: true,
              revisionEsperada: own?['revision'] as int?,
            );
          });
          MultiuserSession.testSession = sessions[1];
          await network(() async {
            final rows = await TrayectoriaEducativaService.instance.leerAlumno(
              ownerAccountId: sessions[1].userId,
              perfilId: profile,
              modulo: module,
            );
            expectSync(
              rows.any((r) => r['id'] == 'sprint-20261008-${module.name}'),
              true,
            );
            expectSync(rows.any((r) => r.containsKey('historial')), false);
          });
          await show(
            1,
            TrayectoriaEducativaPage.alumno(
              ownerAccountId: sessions[1].userId,
              perfilId: profile,
            ).pagina(module),
          );
          await waitFor(find.textContaining('Registrado por'));
          debugPrint('PASS real JWT existing education screen: ${module.name}');
        }
        await show(
          0,
          TrayectoriaEducativaPage.institucion(
            institucionId: inst,
            areaId: area,
            solicitudId: enrollment,
          ).pagina(ModuloEducativo.progreso),
        );
        await waitFor(find.text('Actualizar registro'));
        await tester.tap(find.text('Actualizar registro'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('edu_porcentaje')),
          '55',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar registro'));
        await waitFor(find.text('Información confirmada por Supabase.'));
        await show(
          1,
          TrayectoriaEducativaPage.alumno(
            ownerAccountId: sessions[1].userId,
            perfilId: profile,
          ).pagina(ModuloEducativo.progreso),
        );
        await waitFor(find.text('Avance (%): 55.0'));
        debugPrint('PASS existing editor updates another session');
        await show(
          0,
          InstitucionDocumentosPage(
            institucionId: inst,
            institucionNombre: 'TEST',
            remoteAreaId: area,
          ),
        );
        await waitFor(find.text('Solicitar documento'));
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining(profile).last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), tag);
        await tester.ensureVisible(find.text('Solicitar documento'));
        await tester.tap(find.text('Solicitar documento'));
        await waitFor(find.textContaining('pendiente'));
        late SolicitudDocumento documentRequest;
        await network(() async {
          documentRequest =
              (await DocumentacionOperativaService.solicitudesInstitucion(
                inst,
                remoteAreaId: area,
              )).singleWhere((r) => r.mensaje == tag);
        });
        debugPrint('PASS existing institutional document request form');
        await show(
          1,
          AlumnoDocumentosPage(
            ownerAccountId: sessions[1].userId,
            perfilId: profile,
          ),
        );
        await waitFor(find.textContaining(tag));
        final png = Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5e8AAAAASUVORK5CYII=',
          ),
        );
        await network(() async {
          await DocumentacionOperativaService.adjuntar(
            sessions[1].userId,
            profile,
            documentRequest.id,
            png,
          );
          await DocumentacionOperativaService.adjuntar(
            sessions[1].userId,
            profile,
            documentRequest.id,
            png,
          );
          final requests =
              await DocumentacionOperativaService.solicitudesAlumno(
                sessions[1].userId,
                profile,
              );
          expectSync(
            requests.singleWhere((r) => r.id == documentRequest.id).estado,
            EstadoSolicitudDocumento.cumplida,
          );
        });
        await show(
          0,
          InstitucionDocumentosPage(
            institucionId: inst,
            institucionNombre: 'TEST',
            remoteAreaId: area,
          ),
        );
        await waitFor(find.textContaining('cumplida'));
        await network(() async {
          final docs =
              await DocumentacionOperativaService.documentosInstitucion(
                inst,
                remoteAreaId: area,
              );
          final file = await DocumentacionOperativaService.abrir(
            docs.singleWhere((d) => d.id == documentRequest.id),
          );
          expectSync(Uri.parse(file.ref).data!.contentAsBytes(), png);
          await denied(
            clients[0].rpc(
              'atena_documents_read',
              params: {'p_profile': profile},
            ),
          );
          await denied(
            clients[1].rpc(
              'atena_documents_read',
              params: {'p_institution': inst, 'p_area': area},
            ),
          );
          await denied(
            clients[1].rpc(
              'atena_document_cancel',
              params: {'p_id': documentRequest.id},
            ),
          );
        });
        debugPrint(
          'PASS private document persists between real JWT sessions and forged contexts denied',
        );
        MultiuserSession.testSession = sessions[1];
        await network(() async {
          await DocumentacionOperativaService.eliminar(
            sessions[1].userId,
            profile,
            documentRequest.id,
          );
          await denied(
            clients[0].rpc(
              'atena_document_open',
              params: {'p_id': documentRequest.id},
            ),
          );
        });
        debugPrint(
          'PASS document removal denies subsequent access in institutional session',
        );

        expectSync(
          (await SharedPreferences.getInstance()).getString(
            'protected_local_marker',
          ),
          'unchanged',
        );
        expectSync(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        MultiuserSession.testSession = null;
        await network(() async {
          for (final client in clients) {
            await client.dispose();
          }
        });
        await tester.pump(const Duration(seconds: 16));
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
