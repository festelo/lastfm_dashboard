class DatePeriod {
  static const DatePeriod month = DatePeriod(iterateMonths, 'month');
  static const DatePeriod week = DatePeriod(iterateWeeks, 'week');
  static const DatePeriod day = DatePeriod(iterateDays, 'day');
  static const DatePeriod hour = DatePeriod(iterateHours, 'hour');

  static List<DatePeriod> get values => [month, week, day, hour];

  final String name;
  final Iterable<DateTime> Function(
    DateTime from,
    DateTime to, {
    bool includingTo,
  }) _iterator;

  const DatePeriod(this._iterator, this.name);

  Iterable<DateTime> iterateBounds(
    DateTime from,
    DateTime to, {
    bool includingTo = false,
  }) =>
      _iterator(from, to, includingTo: includingTo);

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
}
