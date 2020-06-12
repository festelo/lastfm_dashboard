class DatePeriod {
  static const DatePeriod month = DatePeriod(iterateMonths, 'month');
  static const DatePeriod week = DatePeriod(iterateWeeks, 'week');
  static const DatePeriod day = DatePeriod(iterateDays, 'day');
  static const DatePeriod hour = DatePeriod(iterateHours, 'hour');

  static List<DatePeriod> get values => [month, week, day, hour];

  final String name;
  final Iterable<DateTime> Function(DateTime from, DateTime to) _iterator;

  const DatePeriod(this._iterator, this.name);

  Iterable<DateTime> iterateBounds(DateTime from, DateTime to) =>
      _iterator(from, to);

  static Iterable<DateTime> iterateMonths(DateTime start, DateTime to) sync* {
    for (var i = 0;; i++) {
      final val = DateTime(start.year, start.month + i);
      if (!val.isBefore(to)) return;
      yield val;
    }
  }

  static Iterable<DateTime> iterateWeeks(DateTime start, DateTime to) sync* {
    final rstart =
        DateTime(start.year, start.month, start.day - start.weekday + 1);
    for (var i = 0;; i += 7) {
      final val =
          DateTime(rstart.year, rstart.month, rstart.day + i);
      if (!val.isBefore(to)) return;
      yield val;
    }
  }

  static Iterable<DateTime> iterateDays(DateTime start, DateTime to) sync* {
    for (var i = 0;; i++) {
      final val = DateTime(start.year, start.month, start.day + i);
      if (!val.isBefore(to)) return;
      yield val;
    }
  }

  static Iterable<DateTime> iterateHours(DateTime start, DateTime to) sync* {
    for (var i = 0;; i++) {
      final val = DateTime(start.year, start.month, start.day, start.hour + i);
      if (!val.isBefore(to)) return;
      yield val;
    }
  }
}
