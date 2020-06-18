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

  Pair<DateTime> get bounds => boundsMap[boundsPeriod];
  Pair<DateTime> _nextBounds;
  Pair<DateTime> _previousBounds;
  Pair<DateTime> get nextBounds => _nextBounds;
  Pair<DateTime> get previousBounds => _previousBounds;

  DatePeriod _boundsPeriod = DatePeriod.year;
  DatePeriod get boundsPeriod => _boundsPeriod;
  set boundsPeriod(DatePeriod value) {
    _boundsPeriod = value;
    notify(this);
  }

  DatePeriod get pointsPeriod => nextPeriod;

  DatePeriod get nextPeriod {
    final nextIndex = DatePeriod.values.indexOf(boundsPeriod) + 1;
    if (nextIndex == DatePeriod.values.length) return null;
    return DatePeriod.values[nextIndex];
  }

  Pair<DateTime> getBoundsForRange(DateTime time, DatePeriod range,
      [int offset = 0]) {
    return Pair(
      range.addOffset(range.normalize(time), offset),
      range.addOffset(range.normalize(time), offset + 1),
    );
  }

  void updateRange(DateTime time, DatePeriod newRange, [int offset = 0]) {
    boundsPeriod = newRange;
    _previousBounds = getBoundsForRange(time, boundsPeriod, offset - 1);
    boundsMap[newRange] = getBoundsForRange(time, boundsPeriod, offset);
    _nextBounds = getBoundsForRange(time, boundsPeriod, offset + 1);
    notify(this);
  }

  void moveBounds({bool forward = true}) {
    updateRange(bounds.a, boundsPeriod, forward ? -1 : 1);
  }
}
