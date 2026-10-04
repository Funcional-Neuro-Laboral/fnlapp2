/// Fechas en español sin depender de los datos de idioma de intl.
class DateFormatEs {
  DateFormatEs._();

  static const _shortMonths = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  static const _longMonths = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// 3 oct
  static String short(DateTime date) => '${date.day} ${_shortMonths[date.month - 1]}';

  /// 3 oct 2026
  static String shortWithYear(DateTime date) => '${short(date)} ${date.year}';

  /// 3 de octubre de 2026
  static String long(DateTime date) => '${date.day} de ${_longMonths[date.month - 1]} de ${date.year}';

  /// "hoy", "ayer" o la fecha corta.
  static String relative(DateTime date, {DateTime? now}) {
    final today = _dayOnly(now ?? DateTime.now());
    final day = _dayOnly(date);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'hoy';
    if (diff == 1) return 'ayer';
    if (diff == -1) return 'mañana';
    return 'el ${short(date)}';
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
