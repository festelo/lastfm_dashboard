import 'package:epic/epic.dart';
import 'package:shared/models.dart';
import 'epic_view_model.dart';

class ChartViewModel extends EpicViewModel {
  ChartViewModel(EpicManager manager) : super(manager) {
    final time = DateTime.now();
    _bounds[DatePeriod.month] =
        Pair(DateTime(time.year), DateTime(time.year + 1));
  }

  Pair<DateTime> _allTimeBounds;
  Pair<DateTime> get allTimeBounds => _allTimeBounds;
  set allTimeBounds(Pair<DateTime> value) {
    _allTimeBounds = value;
    notify(this);
  }

  Map<DatePeriod, Pair<DateTime>> _bounds = {
    DatePeriod.month: Pair(DateTime.now(), null)
  };
  Map<DatePeriod, Pair<DateTime>> get boundsMap => _bounds;
  set boundsMap(value) {
    _bounds = value;
    notify(this);
  }
  Pair<DateTime> get bounds => boundsMap[period];
  Pair<DateTime> _nextBounds;
  Pair<DateTime> _previousBounds;
  Pair<DateTime> get nextBounds => _nextBounds;
  Pair<DateTime> get previousBounds => _previousBounds;

  DatePeriod _period = DatePeriod.month;
  DatePeriod get period => _period;
  set period(DatePeriod value) {
    _period = value;
    notify(this);
  }

  DatePeriod get nextPeriod {
    final nextIndex = DatePeriod.values.indexOf(period) + 1;
    if (nextIndex == DatePeriod.values.length) return null;
    return DatePeriod.values[nextIndex];
  }

  Pair<DateTime> getBoundsForRange(DateTime time, DatePeriod range,
      [int offset = 0]) {
    if (range == DatePeriod.month) {
      return Pair(
        DateTime(time.year + offset),
        DateTime(time.year + 1 + offset),
      );
    }
    if (range == DatePeriod.week) {
      return Pair(
        DateTime(time.year, time.month + offset),
        DateTime(time.year, time.month + 1 + offset),
      );
    }
    if (range == DatePeriod.day) {
      return Pair(
        DateTime(
          time.year,
          time.month,
          time.day - time.weekday + 1 + offset * 7,
        ),
        DateTime(
          time.year,
          time.month,
          time.day - time.weekday + 1 + (1 + offset) * 7,
        ),
      );
    }
    if (range == DatePeriod.hour) {
      return Pair(
        DateTime(time.year, time.month, time.day + offset),
        DateTime(time.year, time.month, time.day + 1 + offset),
      );
    }
    throw ArgumentError.value(range, 'Unknown DatePeriod');
  }

  void updateRange(DateTime time, DatePeriod newRange, [int offset = 0]) {
    period = newRange;
    _previousBounds = getBoundsForRange(time, newRange, offset - 1);
    boundsMap[newRange] = getBoundsForRange(time, newRange, offset);
    _nextBounds = getBoundsForRange(time, newRange, offset + 1);
    notify(this);
  }

  void moveBounds({bool forward = true}) {
    updateRange(bounds.a, period, forward ? -1 : 1);
  }
}
