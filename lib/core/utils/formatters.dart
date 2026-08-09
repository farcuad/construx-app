import 'package:intl/intl.dart';

/// Formateo de fechas y montos según los formatos que espera la API.
///
/// Las instancias de [DateFormat] y [NumberFormat] son costosas de construir,
/// por eso se crean una sola vez a nivel de clase.
abstract final class Fmt {
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// Idioma en que se muestran fechas y montos.
  ///
  /// Es estado global mutable a propósito: los formateadores son caros y se
  /// consultan desde cualquier `build`, así que se comparten. Solo lo escribe
  /// `LocaleController` al cambiar de idioma.
  static String _locale = 'es';

  static DateFormat _displayDate = _dateFormat();
  static DateFormat _displayDateTime = _dateTimeFormat();
  static NumberFormat _currency = _currencyFormat();
  static NumberFormat _compact = _compactFormat();

  static DateFormat _dateFormat() => DateFormat('dd MMM yyyy', _locale);
  static DateFormat _dateTimeFormat() =>
      DateFormat('dd MMM yyyy · HH:mm', _locale);
  static NumberFormat _currencyFormat() =>
      NumberFormat.currency(locale: _locale, symbol: r'$', decimalDigits: 0);
  static NumberFormat _compactFormat() => NumberFormat.compactCurrency(
    locale: _locale,
    symbol: r'$',
    decimalDigits: 1,
  );

  /// Cambia el idioma y rehace los formateadores.
  ///
  /// Los símbolos de fecha del idioma deben estar cargados (`main` llama a
  /// `initializeDateFormatting` para los tres que ofrece la app).
  static set locale(String code) {
    if (code == _locale) return;
    _locale = code;
    _displayDate = _dateFormat();
    _displayDateTime = _dateTimeFormat();
    _currency = _currencyFormat();
    _compact = _compactFormat();
  }

  static String get locale => _locale;

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
