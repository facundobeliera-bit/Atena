import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Only Auth secrets migrate here. Business records and local accounts are untouched.
/// Operations are serialized because Supabase dispatches persistence asynchronously.
class SecureAuthStore {
  final FlutterSecureStorage vault;
  final SharedPreferences preferences;
  Future<void> _tail = Future.value();
  SecureAuthStore(
    this.preferences, {
    this.vault = const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: false),
    ),
  });

  Future<T> _ordered<T>(Future<T> Function() operation) {
    final result = _tail.then((_) async {
      try {
        return await operation();
      } catch (_) {
        // Platform errors can contain values/paths. Never propagate their text.
        throw StateError(
          'No se pudo acceder al almacenamiento seguro de sesión.',
        );
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _removeLegacy(String key) async {
    if (!await preferences.remove(key)) throw StateError('Storage unavailable');
  }

  Future<void> _verifiedWrite(String key, String value) async {
    await vault.write(key: key, value: value);
    if (await vault.read(key: key) != value) {
      throw StateError('Storage unavailable');
    }
  }

  Future<String?> read(String key) => _ordered(() async {
    final secured = await vault.read(key: key);
    if (secured != null) {
      await _removeLegacy(key);
      return secured.isEmpty ? null : secured;
    }
    final legacy = preferences.getString(key);
    if (legacy == null) return null;
    await _verifiedWrite(key, legacy);
    await _removeLegacy(key);
    return legacy.isEmpty ? null : legacy;
  });

  Future<void> write(String key, String value) => _ordered(() async {
    await _verifiedWrite(key, value);
    await _removeLegacy(key);
  });

  Future<void> remove(String key) => _ordered(() async {
    // A non-secret tombstone prevents resurrection if the process stops before
    // removal of the old cleartext record. Keep it until a subsequent sign-in.
    await _verifiedWrite(key, '');
    await _removeLegacy(key);
  });
}

class SecureAuthLocalStorage extends LocalStorage {
  static const pkceKey = 'supabase.auth.token-code-verifier';
  final SecureAuthStore store;
  final String key;
  const SecureAuthLocalStorage(this.store, this.key);
  @override
  Future<void> initialize() async {
    await store.read(key);
    await store.read(pkceKey);
  }

  @override
  Future<String?> accessToken() => store.read(key);
  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;
  @override
  Future<void> persistSession(String persistSessionString) =>
      store.write(key, persistSessionString);
  @override
  Future<void> removePersistedSession() async {
    await store.remove(key);
    await store.remove(pkceKey);
  }
}

class SecureAuthPkceStorage extends GotrueAsyncStorage {
  final SecureAuthStore store;
  SecureAuthPkceStorage(this.store);
  @override
  Future<String?> getItem({required String key}) => store.read(key);
  @override
  Future<void> setItem({required String key, required String value}) =>
      store.write(key, value);
  @override
  Future<void> removeItem({required String key}) => store.remove(key);
}
