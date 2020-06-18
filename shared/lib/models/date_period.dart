class DatePeriod {
  static const DatePeriod year =
      DatePeriod(iterateYears, normalizeYear, addYears, 'year');
  static const DatePeriod month =
      DatePeriod(iterateMonths, normalizeMonth, addMonths, 'month');
  static const DatePeriod week =
      DatePeriod(iterateWeeks, normalizeWeek, addWeeks, 'week');
  static const DatePeriod day =
      DatePeriod(iterateDays, normalizeDay, addDays, 'day');
  static const DatePeriod hour =
      DatePeriod(iterateHours, normalizeHour, addHours, 'hour');

  static List<DatePeriod> get values => [month, week, day, hour];

  final String name;
  final Iterable<DateTime> Function(
    DateTime from,
    DateTime to, {
    bool includingTo,
  }) _iterator;
  final DateTime Function(DateTime) normalize;
  final DateTime Function(DateTime date, int offset) addOffset;

  const DatePeriod(this._iterator, this.normalize, this.addOffset, this.name);

  Iterable<DateTime> iterateBounds(
    DateTime from,
    DateTime to, {
    bool includingTo = false,
  }) =>
      _iterator(from, to, includingTo: includingTo);

  static Iterable<DateTime> iterateYears(DateTime start, DateTime to,
      {bool includingTo = false}) sync* {
    for (var i = 0;; i++) {
      final val = DateTime(start.year + i);
      if (includingTo ? val.isAfter(to) : !val.isBefore(to)) return;
      yield val;
    }
  }

  static Iterable<DateTime> iterateMonths(DateTime start, DateTime to,
      {bool includingTo = false}) sync* {
    for (var i = 0;; i++) {
      final val = DateTime(start.year, start.month + i);
      if (includingTo ? val.isAfter(to) : !val.isBefore(to)) return;
      yield val;
    }
  }

  static Iterable<DateTime> iterateWeeks(DateTime start, DateTime to,
      {bool includingTo = false}) sync* {
    final rstart =
        DateTime(start.year, start.month, start.day - start.weekday + 1);
    for (var i = 0;; i += 7) {
      final val = DateTime(rstart.year, rstart.month, rstart.day + i);
      if (includingTo ? val.isAfter(to) : !val.isBefore(to)) return;
      yield val;
    }
  }

  static Iterable<DateTime> iterateDays(DateTime start, DateTime to,
      {bool includingTo = false}) sync* {
    for (var i = 0;; i++) {
      final val = DateTime(start.year, start.month, start.day + i);
      if (includingTo ? val.isAfter(to) : !val.isBefore(to)) return;
      yield val;
    }
  }

  static Iterable<DateTime> iterateHours(DateTime start, DateTime to,
      {bool includingTo = false}) sync* {
    for (var i = 0;; i++) {
      final val = DateTime(start.year, start.month, start.day, start.hour + i);
      if (includingTo ? val.isAfter(to) : !val.isBefore(to)) return;
      yield val;
    }
  }

  static DateTime normalizeYear(DateTime time) {
    return DateTime(time.year);
  }

  static DateTime normalizeMonth(DateTime time) {
    return DateTime(time.year, time.month);
  }

  static DateTime normalizeWeek(DateTime time) {
    return DateTime(time.year, time.month, time.day - time.weekday + 1);
  }

  static DateTime normalizeDay(DateTime time) {
    return DateTime(time.year, time.month, time.day);
  }

  static DateTime normalizeHour(DateTime time) {
    return DateTime(time.year, time.month, time.day, time.hour);
  }

  static DateTime addYears(DateTime time, int offset) {
    return DateTime(time.year + offset, time.month, time.day, time.hour,
        time.minute, time.second, time.millisecond, time.microsecond);
  }

  static DateTime addMonths(DateTime time, int offset) {
    return DateTime(time.year, time.month + offset, time.day, time.hour,
        time.minute, time.second, time.millisecond, time.microsecond);
  }

  static DateTime addWeeks(DateTime time, int offset) {
    return time.add(Duration(days: 7 * offset));
  }

  static DateTime addDays(DateTime time, int offset) {
    return time.add(Duration(days: 1 * offset));
  }

  static DateTime addHours(DateTime time, int offset) {
    return time.add(Duration(hours: 1 * offset));
  }
}
