import 'package:shared/models.dart';

class ChartMarkersPointer<TAbscissa, TOrdinate> {
  final MarkersPointer<TAbscissa> abscissa;
  final MarkersPointer<TOrdinate> ordinate;
  ChartMarkersPointer(this.abscissa, this.ordinate);
}

abstract class MarkersPointer<T> {
  List<T> getPoints(T min, T max);
}

class IntMarkersPointer implements MarkersPointer<int> {
  final int step;
  IntMarkersPointer(this.step);

  @override
  List<int> getPoints(min, max) {
    final ret = <int>[];
    final start = (min / step).ceil() * step;
    for (var i = start; i <= max; i += step) {
      ret.add(i);
    }
    return ret;
  }
}

class DateTimeMarkersPointer implements MarkersPointer<DateTime> {
  final Duration step;
  DateTimeMarkersPointer(this.step);

  @override
  List<DateTime> getPoints(min, max) {
    final ret = <DateTime>[];
    final startInt = (min.millisecondsSinceEpoch / step.inMilliseconds).ceil() *
        step.inMilliseconds;
    final start = DateTime.fromMillisecondsSinceEpoch(startInt);
    for (var i = start;
        i.millisecondsSinceEpoch <= max.millisecondsSinceEpoch;
        i = i.add(step)) {
      ret.add(i);
    }
    return ret;
  }
}

class DatePeriodMarkersPointer implements MarkersPointer<DateTime> {
  final DatePeriod period;
  DatePeriodMarkersPointer(this.period);

  @override
  List<DateTime> getPoints(min, max) {
    final ret = <DateTime>[];
    for (final p in period.iterateBounds(min, max)) {
      ret.add(p);
    }
    return ret;
  }
}