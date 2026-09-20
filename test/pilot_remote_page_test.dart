import 'package:atena_app/repositories/pilot_operation_repository.dart';
import 'package:atena_app/screens/pilot/pilot_remote_page.dart';
import 'package:atena_app/services/remote/pilot_remote_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements PilotRemoteGateway {
  bool signedIn = false;
  bool invalidSession = false;
  final saved = <PilotOperation>[];

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> signIn(String email, String password) async {
    if (email != 'pilot@example.invalid' || password != 'test-password') {
      throw StateError('Invalid test login');
    }
    signedIn = true;
  }

  @override
  Future<void> signOut() async => signedIn = false;

  @override
  Future<List<PilotInstitution>> institutions() async => signedIn
      ? [const PilotInstitution('institution-a', 'Institución A')]
      : [];

  @override
  Future<List<PilotArea>> areas(String institutionId) async =>
      institutionId == 'institution-a'
      ? [const PilotArea('area-a', 'Área A')]
      : [];

  @override
  Future<List<PilotAssignment>> assignments() async {
    if (invalidSession) throw StateError('Expired pilot session');
    return signedIn
        ? [
            const PilotAssignment(
              institutionId: 'institution-a',
              areaId: 'area-a',
              operatorId: 'operator-a',
              capabilities: ['pilot.read', 'pilot.write'],
            ),
          ]
        : [];
  }

  @override
  Future<String> recordNote({
    required String institutionId,
    required String areaId,
    required String operatorId,
    required String resourceId,
    required String note,
  }) async {
    if (!signedIn ||
        institutionId != 'institution-a' ||
        areaId != 'area-a' ||
        operatorId != 'operator-a') {
      throw StateError('Invalid pilot identity');
    }
    saved.add(
      PilotOperation(
        id: 'note-1',
        institutionId: institutionId,
        areaId: areaId,
        operatorId: operatorId,
        resourceId: resourceId,
        note: note,
      ),
    );
    return 'note-1';
  }

  @override
  Future<List<PilotOperation>> notes(
    String institutionId,
    String areaId,
  ) async => signedIn && institutionId == 'institution-a' && areaId == 'area-a'
      ? List.of(saved)
      : [];
}

void main() {
  testWidgets('piloto aislado ingresa, guarda y cierra sesión remota', (
    tester,
  ) async {
    final gateway = _FakeGateway();
    await tester.pumpWidget(
      MaterialApp(home: PilotRemotePage(gateway: gateway)),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Correo de prueba'),
      'pilot@example.invalid',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Contraseña de prueba'),
      'test-password',
    );
    await tester.tap(find.text('Ingresar al piloto'));
    await tester.pumpAndSettle();
    expect(gateway.isSignedIn, isTrue);

    await tester.tap(find.byKey(const ValueKey('pilot-institution')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Institución A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pilot-area-institution-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Área A').last);
    await tester.pumpAndSettle();

    expect(find.text('ID de operador asignado'), findsNothing);
    expect(find.text('Operador asignado: operator-a'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nota ficticia'),
      'Nota de interfaz',
    );
    await tester.tap(find.text('Guardar nota remota'));
    await tester.pumpAndSettle();
    expect(gateway.saved.single.note, 'Nota de interfaz');
    await tester.scrollUntilVisible(
      find.text('Nota de interfaz'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nota de interfaz'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión remota'));
    await tester.pumpAndSettle();
    expect(gateway.isSignedIn, isFalse);
    expect(find.text('Ingresar al piloto'), findsOneWidget);
    expect(find.text('Nota de interfaz'), findsNothing);
  });

  testWidgets('sesión remota inválida no muestra datos ni permite escribir', (
    tester,
  ) async {
    final gateway = _FakeGateway()
      ..signedIn = true
      ..invalidSession = true;
    await tester.pumpWidget(
      MaterialApp(home: PilotRemotePage(gateway: gateway)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo completar la operación remota.'),
      findsOneWidget,
    );
    expect(find.text('Institución A'), findsNothing);
    expect(find.text('Guardar nota remota'), findsNothing);
    expect(gateway.saved, isEmpty);
  });
}
