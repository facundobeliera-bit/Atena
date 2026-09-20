import 'dart:io';

import 'package:atena_app/services/remote/pilot_remote_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final env = Platform.environment;
  final key = env['ATENA_PILOT_PUBLIC_KEY'];
  final run = env['ATENA_PILOT_RUN'];
  final passwordA = env['ATENA_PILOT_PASSWORD_A'];
  final passwordB = env['ATENA_PILOT_PASSWORD_B'];
  if (key == null || run == null || passwordA == null || passwordB == null) {
    return; // Live checks run only through the local smoke launcher.
  }

  test(
    'Flutter client authenticates, persists, isolates and signs out',
    () async {
      SupabaseClient client() =>
          SupabaseClient('https://eaegvxxxkvhdukbkydvy.supabase.co', key);
      final a = client();
      final b = client();
      final aSecondSession = client();
      final gatewayA = SupabasePilotRemoteGateway(a);
      final gatewayB = SupabasePilotRemoteGateway(b);
      final gatewayASecond = SupabasePilotRemoteGateway(aSecondSession);
      final institutionA = 'atena-pilot-a-$run';
      final institutionB = 'atena-pilot-b-$run';
      final areaA = 'area-a-$run';
      final areaB = 'area-b-$run';
      try {
        await gatewayA.signIn('atena-pilot-a-$run@example.invalid', passwordA);
        await gatewayB.signIn('atena-pilot-b-$run@example.invalid', passwordB);
        expect(gatewayA.isSignedIn, isTrue);
        expect(gatewayB.isSignedIn, isTrue);
        final assignmentA = (await gatewayA.assignments()).single;
        final assignmentB = (await gatewayB.assignments()).single;
        expect(assignmentA.institutionId, institutionA);
        expect(assignmentA.areaId, areaA);
        expect(assignmentA.operatorId, 'operator-a-$run');
        expect(assignmentA.canWrite, isTrue);
        expect(assignmentB.institutionId, institutionB);
        expect(assignmentB.operatorId, 'operator-b-$run');

        final visibleA = await gatewayA.institutions();
        final visibleB = await gatewayB.institutions();
        expect(visibleA.map((i) => i.id), contains(institutionA));
        expect(visibleA.map((i) => i.id), isNot(contains(institutionB)));
        expect(visibleB.map((i) => i.id), contains(institutionB));
        expect(visibleB.map((i) => i.id), isNot(contains(institutionA)));
        expect(
          (await gatewayA.areas(institutionA)).map((a) => a.id),
          contains(areaA),
        );
        expect(await gatewayA.areas(institutionB), isEmpty);
        expect(
          (await gatewayB.areas(institutionB)).map((a) => a.id),
          contains(areaB),
        );

        final resource =
            'flutter-live-${DateTime.now().microsecondsSinceEpoch}';
        final noteId = await gatewayA.recordNote(
          institutionId: institutionA,
          areaId: areaA,
          operatorId: assignmentA.operatorId,
          resourceId: resource,
          note: 'Nota ficticia desde Flutter',
        );
        expect(noteId, isNotEmpty);
        expect((await gatewayB.notes(institutionA, areaA)), isEmpty);
        await gatewayASecond.signIn(
          'atena-pilot-a-$run@example.invalid',
          passwordA,
        );
        expect(
          (await gatewayASecond.notes(
            institutionA,
            areaA,
          )).map((n) => n.resourceId),
          contains(resource),
        );

        await gatewayA.signOut();
        expect(gatewayA.isSignedIn, isFalse);
        await expectLater(gatewayA.institutions(), throwsStateError);
      } finally {
        await a.dispose();
        await b.dispose();
        await aSecondSession.dispose();
      }
    },
  );
}
