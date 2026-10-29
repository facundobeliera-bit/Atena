import 'dart:async';
import 'package:atena_app/services/remote/secure_auth_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const key = 'sb-fictional-auth-token';
  const fixture = 'fictional-session-not-a-credential';
  final encrypted = <String, String>{};
  late SharedPreferences prefs;
  late SecureAuthStore store;
  late SecureAuthLocalStorage storage;
  bool failWrite = false, corruptRead = false;
  Completer<void>? writeGate;
  setUp(() async {
    encrypted.clear();
    failWrite = false;
    corruptRead = false;
    writeGate = null;
    SharedPreferences.setMockInitialValues({
      key: fixture,
      'historical': 'preserve',
    });
    prefs = await SharedPreferences.getInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final k = args['key'] as String;
          if (call.method == 'write') {
            await writeGate?.future;
            if (failWrite) {
              throw PlatformException(code: 'failure', message: fixture);
            }
            encrypted[k] = args['value'] as String;
            return null;
          }
          if (call.method == 'read') {
            return corruptRead ? 'corrupt' : encrypted[k];
          }
          throw StateError('Unexpected platform method');
        });
    store = SecureAuthStore(prefs);
    storage = SecureAuthLocalStorage(store, key);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test(
    'migration verifies secure copy and removes only legacy Auth record',
    () async {
      await storage.initialize();
      expect(await storage.accessToken(), fixture);
      expect(prefs.containsKey(key), false);
      expect(prefs.getString('historical'), 'preserve');
      final restarted = SecureAuthLocalStorage(SecureAuthStore(prefs), key);
      await restarted.initialize();
      expect(await restarted.accessToken(), fixture);
    },
  );
  test(
    'failed encrypted write keeps original, never exposes platform error',
    () async {
      failWrite = true;
      await expectLater(
        storage.initialize(),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString().contains(fixture),
            'sanitized',
            false,
          ),
        ),
      );
      expect(prefs.getString(key), fixture);
      failWrite = false;
      await storage.initialize();
      expect(prefs.containsKey(key), false);
    },
  );
  test('wrong write readback does not remove the only legacy copy', () async {
    // Corrupt only the read after write, not the initial lookup.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'write') {
            corruptRead = true;
            return null;
          }
          return corruptRead ? 'corrupt' : null;
        });
    await expectLater(storage.initialize(), throwsStateError);
    expect(prefs.getString(key), fixture);
  });
  test(
    'secure newer identity wins over interrupted migration residue',
    () async {
      encrypted[key] = 'new-session';
      await storage.initialize();
      expect(await storage.accessToken(), 'new-session');
      expect(prefs.containsKey(key), false);
    },
  );
  test(
    'logout tombstone prevents resurrection after interrupted cleanup',
    () async {
      encrypted[key] = '';
      await storage.initialize();
      expect(await storage.hasAccessToken(), false);
      expect(prefs.containsKey(key), false);
    },
  );
  test('logout queues after pending write; restart has no session', () async {
    await storage.initialize();
    writeGate = Completer<void>();
    final save = storage.persistSession('rotated-session');
    final logout = storage.removePersistedSession();
    writeGate!.complete();
    await Future.wait([save, logout]);
    final restarted = SecureAuthLocalStorage(SecureAuthStore(prefs), key);
    expect(await restarted.hasAccessToken(), false);
    expect(encrypted[key], isEmpty);
  });
  test('PKCE migrates and deletes without a plaintext fallback', () async {
    const pkceKey = 'supabase.auth.token-code-verifier';
    await prefs.setString(pkceKey, 'fictitious-verifier');
    final pkce = SecureAuthPkceStorage(store);
    expect(await pkce.getItem(key: pkceKey), 'fictitious-verifier');
    expect(prefs.containsKey(pkceKey), false);
    await pkce.removeItem(key: pkceKey);
    expect(await pkce.getItem(key: pkceKey), isNull);
    expect(prefs.getString('historical'), 'preserve');
  });
  test('new session never writes cleartext preferences', () async {
    await storage.removePersistedSession();
    await storage.persistSession('another-fictional-session');
    expect(prefs.getKeys(), {'historical'});
    expect(await storage.hasAccessToken(), true);
  });
}
