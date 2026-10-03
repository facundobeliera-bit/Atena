// lib/ui/atena_format.dart
//
// Formato de fechas y horas según el idioma activo.

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

class AtenaFormat {
  const AtenaFormat._();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "Recién", "Hace 5 min", "Hace 3 h", "Ayer" o la fecha.
  static String haceTiempo(BuildContext context, DateTime fecha) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inMinutes < 1) return t.uiJustNow;
    if (diff.inMinutes < 60) return t.uiMinutesAgo(diff.inMinutes);
    if (_day(fecha) == _day(now)) return t.uiHoursAgo(diff.inHours);
    if (_day(fecha) == _day(now.subtract(const Duration(days: 1)))) {
      return t.uiYesterday;
    }
    return fechaCorta(context, fecha);
  }

  /// "Hoy", "Mañana" o "vie., 3 abr.".
  static String diaRelativo(BuildContext context, DateTime fecha) {
    final t = AppLocalizations.of(context);
    final today = _day(DateTime.now());
    final d = _day(fecha);
    if (d == today) return t.uiToday;
    if (d == today.add(const Duration(days: 1))) return t.uiTomorrow;
    return fechaCorta(context, fecha);
  }

  /// "vie., 3 abr." (sin año si es el año actual).
  static String fechaCorta(BuildContext context, DateTime fecha) {
    final loc = MaterialLocalizations.of(context);
    if (fecha.year == DateTime.now().year) return loc.formatMediumDate(fecha);
    return loc.formatCompactDate(fecha);
  }

  /// "viernes, 3 de abril de 2026".
  static String fechaLarga(BuildContext context, DateTime fecha) =>
      MaterialLocalizations.of(context).formatFullDate(fecha);

  /// "03/04/2026".
  static String fechaNumerica(BuildContext context, DateTime fecha) =>
      MaterialLocalizations.of(context).formatCompactDate(fecha);

  /// "abril de 2026".
  static String mesAnio(BuildContext context, DateTime fecha) =>
      MaterialLocalizations.of(context).formatMonthYear(fecha);

  /// "ABR": las tres primeras letras del mes, para bloques de fecha.
  static String mesCorto(BuildContext context, DateTime fecha) {
    final mes = mesAnio(context, fecha).trim();
    return (mes.length <= 3 ? mes : mes.substring(0, 3)).toUpperCase();
  }

  /// "14:30" o "2:30 PM" según la configuración del dispositivo.
  static String hora(BuildContext context, DateTime fecha) {
    final loc = MaterialLocalizations.of(context);
    final h24 = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    return loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(fecha),
      alwaysUse24HourFormat: h24,
    );
  }
}
