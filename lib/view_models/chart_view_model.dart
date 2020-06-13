import 'package:epic/epic.dart';
import 'package:shared/models.dart';
import 'epic_view_model.dart';

class ChartViewModel extends EpicViewModel {
  ChartViewModel(EpicManager manager): super(manager) {
    final time = DateTime.now();
    _bounds[DatePeriod.month] = Pair(
      DateTime(time.year),
      DateTime(time.year + 1)
    );
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
  Map<DatePeriod, Pair<DateTime>> get bounds => _bounds;
  set bounds(value) {
    _bounds = value;
    notify(this);
  }

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

  
  Future<void> updateRange(DateTime time, DatePeriod newRange,
      [int offset = 0]) async {
    if (newRange == DatePeriod.month) {
      bounds[newRange] = Pair(
        DateTime(time.year + offset),
        DateTime(time.year + 1 + offset),
      );
    }
    if (newRange == DatePeriod.week) {
      bounds[newRange] = Pair(
        DateTime(time.year, time.month + offset),
        DateTime(time.year, time.month + 1 + offset),
      );
    }
    if (newRange == DatePeriod.day) {
      bounds[newRange] = Pair(
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
    if (newRange == DatePeriod.hour) {
      bounds[newRange] = Pair(
        DateTime(time.year, time.month, time.day + offset),
        DateTime(time.year, time.month, time.day + 1 + offset),
      );
    }
    period = newRange;
    notify(this);
  }

  Future<void> moveBounds({bool forward = true}) async {
    await updateRange(bounds[period].a, period, forward ? -1 : 1);
  }
}