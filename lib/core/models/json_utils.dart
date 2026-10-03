// lib/core/models/json_utils.dart
//
// Lectura tolerante de JSON para los modelos del núcleo.

export '../store/atena_store.dart' show JsonDoc;

String jStr(dynamic v) => (v ?? '').toString().trim();

int jInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(jStr(v)) ?? fallback;
}

int? jIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(jStr(v));
}

bool jBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = jStr(v).toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}

DateTime jDate(dynamic v, {DateTime? fallback}) {
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  final p = DateTime.tryParse(jStr(v));
  return p ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? jDateOrNull(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(jStr(v));
}

List<String> jStrList(dynamic v) {
  if (v is! List) return <String>[];
  return v.map(jStr).where((s) => s.isNotEmpty).toList();
}

Map<String, String> jStrMap(dynamic v) {
  if (v is! Map) return <String, String>{};
  return {for (final e in v.entries) jStr(e.key): jStr(e.value)};
}

T enumByName<T extends Enum>(List<T> values, dynamic raw, T fallback) {
  final s = jStr(raw).toLowerCase();
  if (s.isEmpty) return fallback;
  for (final v in values) {
    if (v.name.toLowerCase() == s) return v;
  }
  return fallback;
}

/// Edad en años cumplidos a una fecha.
int edadEnAnios(DateTime nacimiento, [DateTime? hoy]) {
  final h = hoy ?? DateTime.now();
  var edad = h.year - nacimiento.year;
  if (h.month < nacimiento.month ||
      (h.month == nacimiento.month && h.day < nacimiento.day)) {
    edad--;
  }
  return edad < 0 ? 0 : edad;
}
