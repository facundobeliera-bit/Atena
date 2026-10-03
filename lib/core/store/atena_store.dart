// lib/core/store/atena_store.dart
//
// Almacenamiento local de ATENA: colecciones de documentos JSON.
//
// - Cada colección se guarda como una lista JSON bajo la clave "atena4.<nombre>".
// - Las escrituras de una misma colección se serializan (sin pérdidas por
//   escrituras simultáneas dentro de la app).
// - Los archivos (fotos, documentos) van aparte como "blobs" en base64.
//
// Toda la persistencia de la app pasa por acá: reemplazar esta clase por un
// cliente de backend es el camino para sincronizar entre dispositivos.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../services/storage_service.dart';

typedef JsonDoc = Map<String, dynamic>;

class AtenaStore {
  AtenaStore._(this._storage);

  static final AtenaStore instance = AtenaStore._(StorageService.instance);

  static const String _prefix = 'atena4.';
  static const String _blobPrefix = 'atena4.blob.';

  final StorageService _storage;
  final Map<String, List<JsonDoc>> _cache = <String, List<JsonDoc>>{};
  final Map<String, Future<void>> _tails = <String, Future<void>>{};

  /// Se incrementa con cada escritura; las pantallas lo escuchan para refrescar.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static JsonDoc _copy(JsonDoc d) =>
      jsonDecode(jsonEncode(d)) as Map<String, dynamic>;

  Future<T> _serialized<T>(String key, Future<T> Function() action) {
    final previous = _tails[key] ?? Future<void>.value();
    final completer = Completer<void>();
    _tails[key] = completer.future;
    return previous.then((_) => action()).whenComplete(() {
      completer.complete();
      if (identical(_tails[key], completer.future)) _tails.remove(key);
    });
  }

  Future<List<JsonDoc>> _load(String collection) async {
    final cached = _cache[collection];
    if (cached != null) return cached;
    final list = await _storage.getJsonList('$_prefix$collection');
    _cache[collection] = list;
    return list;
  }

  /// Lee una colección completa (copias independientes).
  Future<List<JsonDoc>> read(String collection) async {
    final list = await _load(collection);
    return list.map(_copy).toList();
  }

  /// Lee un documento por id.
  Future<JsonDoc?> get(String collection, String id) async {
    final list = await _load(collection);
    for (final d in list) {
      if (d['id'] == id) return _copy(d);
    }
    return null;
  }

  /// Modifica la colección de forma atómica (dentro de la app).
  Future<T> update<T>(
    String collection,
    FutureOr<T> Function(List<JsonDoc> docs) change,
  ) {
    return _serialized(collection, () async {
      final docs = (await _load(collection)).map(_copy).toList();
      final result = await change(docs);
      _cache[collection] = docs;
      await _storage.setJsonList('$_prefix$collection', docs);
      revision.value++;
      return result;
    });
  }

  /// Inserta o reemplaza un documento por id.
  Future<void> put(String collection, JsonDoc doc) {
    final id = doc['id'];
    if (id is! String || id.isEmpty) {
      throw ArgumentError('AtenaStore.put: el documento necesita un id');
    }
    return update<void>(collection, (docs) {
      final i = docs.indexWhere((d) => d['id'] == id);
      if (i >= 0) {
        docs[i] = _copy(doc);
      } else {
        docs.add(_copy(doc));
      }
    });
  }

  Future<bool> delete(String collection, String id) {
    return update<bool>(collection, (docs) {
      final before = docs.length;
      docs.removeWhere((d) => d['id'] == id);
      return docs.length != before;
    });
  }

  /// Elimina una colección completa.
  Future<void> drop(String collection) {
    return _serialized(collection, () async {
      _cache.remove(collection);
      await _storage.remove('$_prefix$collection');
      revision.value++;
    });
  }

  /// Nombres de las colecciones guardadas que empiezan con [prefix].
  Future<List<String>> collections(String prefix) async {
    final keys = await _storage.getKeys();
    final start = '$_prefix$prefix';
    return [
      for (final k in keys)
        if (k.startsWith(start) && !k.startsWith(_blobPrefix))
          k.substring(_prefix.length),
    ];
  }

  // ---------------------------------------------------------------------------
  // Documentos sueltos y blobs
  // ---------------------------------------------------------------------------

  Future<JsonDoc?> readSingle(String key) => _storage.getJson('$_prefix$key');

  Future<void> writeSingle(String key, JsonDoc doc) async {
    await _serialized(key, () => _storage.setJson('$_prefix$key', doc));
    revision.value++;
  }

  Future<void> deleteSingle(String key) async {
    await _serialized(key, () => _storage.remove('$_prefix$key'));
    revision.value++;
  }

  Future<String?> readBlob(String key) =>
      _storage.getString('$_blobPrefix$key');

  /// Devuelve false si el dispositivo no pudo guardar el archivo (sin espacio).
  Future<bool> writeBlob(String key, String base64Data) async {
    final ok = await _storage.setStringStrict('$_blobPrefix$key', base64Data);
    if (ok) revision.value++;
    return ok;
  }

  Future<void> deleteBlob(String key) async {
    await _storage.remove('$_blobPrefix$key');
    revision.value++;
  }

  /// Claves crudas del almacenamiento (para migraciones).
  Future<Set<String>> rawKeys() => _storage.getKeys();

  /// Valor crudo de una clave (texto, número, booleano o lista).
  Future<Object?> rawValue(String key) => _storage.getRaw(key);

  /// Elimina claves crudas (datos de versiones anteriores) y descarta la caché.
  Future<void> removeRaw(Iterable<String> keys) async {
    for (final k in keys) {
      await _storage.remove(k);
    }
    _cache.clear();
    revision.value++;
  }

  /// Borra TODOS los datos guardados en este dispositivo.
  Future<void> borrarTodo() async {
    _cache.clear();
    _tails.clear();
    await _storage.clearAll();
    revision.value++;
  }

  /// Solo para pruebas.
  @visibleForTesting
  void resetCache() {
    _cache.clear();
    _tails.clear();
  }
}

/// Generador de ids legibles y únicos por dispositivo.
class AtenaIds {
  const AtenaIds._();

  static int _seq = 0;

  static String next(String prefix) {
    _seq = (_seq + 1) % 1000000;
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final seq = _seq.toRadixString(36).padLeft(3, '0');
    return '${prefix}_$ts$seq';
  }
}
