import 'package:intl/intl.dart';

/// Formateo de fechas y montos según los formatos que espera la API.
///
/// Las instancias de [DateFormat] y [NumberFormat] son costosas de construir,
/// por eso se crean una sola vez a nivel de clase.
abstract final class Fmt {
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('dd MMM yyyy', 'es');
  static final DateFormat _displayDateTime = DateFormat('dd MMM yyyy · HH:mm', 'es');
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es',
    symbol: r'$',
    decimalDigits: 0,
  );
  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'es',
    symbol: r'$',
    decimalDigits: 1,
  );

  /// Fecha en el formato `YYYY-MM-DD` que usan los campos solo-fecha de la API
  /// (`expense_date`, `delivery_date`, `payment_date`…).
  static String apiDate(DateTime date) => _apiDate.format(date);

  /// Marca de tiempo RFC 3339 en UTC (`start_date`, `end_date`, `report_date`).
  static String apiDateTime(DateTime date) =>
      date.toUtc().toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), 'Z');

  /// Fecha legible para la interfaz.
  static String date(DateTime? date) =>
      date == null ? '—' : _displayDate.format(date.toLocal());

  /// Fecha y hora legibles para la interfaz.
  static String dateTime(DateTime? date) =>
      date == null ? '—' : _displayDateTime.format(date.toLocal());

  /// Monto en moneda, sin decimales.
  static String money(num? amount) =>
      amount == null ? '—' : _currency.format(amount);

  /// Monto abreviado (`$2,5 M`) para tarjetas de métricas.
  static String moneyCompact(num? amount) =>
      amount == null ? '—' : _compact.format(amount);

  /// Porcentaje con un decimal como máximo.
  static String percent(num? value) =>
      value == null ? '—' : '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';

  /// Parsea una fecha de la API tolerando `null`, `YYYY-MM-DD` y RFC 3339.
  static DateTime? parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Parsea un número de la API tolerando enteros, dobles y cadenas.
  static double? parseNum(Object? raw) => switch (raw) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s.replaceAll(',', '.')),
    _ => null,
  };
}
