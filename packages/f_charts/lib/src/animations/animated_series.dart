import 'package:f_charts/data_models.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

typedef AnimatableBuilder = Animatable<RelativeOffset> Function(
    RelativeOffset from, RelativeOffset to);

class SeriesAnimationBuilderDataSingle<T1, T2> {
  final ChartBoundsDoubled bounds;
  final ChartSeries<T1, T2> series;
  final ChartMapper<T1, T2> mapper;

  SeriesAnimationBuilderDataSingle(this.bounds, this.series, this.mapper);
}

class SeriesAnimationBuilderData<T1, T2> {
  final ChartBoundsDoubled boundsFrom;
  final ChartBoundsDoubled boundsTo;
  final ChartSeries<T1, T2> seriesFrom;
  final ChartSeries<T1, T2> seriesTo;
  final ChartMapper<T1, T2> mapper;

  SeriesAnimationBuilderData(this.boundsFrom, this.boundsTo, this.seriesFrom,
      this.seriesTo, this.mapper);
}

class AnimatedSeries {
  final List<Animatable<RelativeOffset>> offsetAnimatables;
  final ChartSeries to;
  final ChartSeries from;
  final bool showPoints;

  AnimatedSeries({
    @required this.to,
    @required this.from,
    @required this.offsetAnimatables,
    this.showPoints = false,
  });

  List<RelativeOffset> points(Animation<double> animation) {
    return offsetAnimatables
        .map((e) => e.evaluate(animation))
        .where((e) => e != null)
        .toList();
  }
}

abstract class AnimatedSeriesBuilder {
  AnimatedSeries build(SeriesAnimationBuilderData data);
}

abstract class AnimatedSeriesBuilderSingle {
  AnimatedSeries build(SeriesAnimationBuilderDataSingle data);
}
