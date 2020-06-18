import 'dart:ui';

import 'package:f_charts/animations.dart';
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

class SeriesTween extends Animatable<SeriesAnimationData> {
  final List<Animatable<RelativeOffset>> offsetAnimatables;
  final ChartSeries to;
  final ChartSeries from;
  final bool showPoints;

  SeriesTween({
    @required this.to,
    @required this.from,
    @required this.offsetAnimatables,
    this.showPoints = false,
  });

  @override
  SeriesAnimationData transform(double t) {
    final points = offsetAnimatables
        .map((e) => e.transform(t))
        .where((e) => e != null)
        .toList();
    return SeriesAnimationData(
      points: points,
      showPoints: showPoints,
      color: from.color,
    );
  }
}

class SeriesAnimationData {
  final List<RelativeOffset> points;
  final bool showPoints;
  final Color color;
  SeriesAnimationData({
    this.points,
    this.showPoints = false,
    this.color,
  });
}

class ChartTween extends Animatable<List<SeriesAnimationData>> {
  final List<Animatable<SeriesAnimationData>> animatables;

  ChartTween(this.animatables);

  factory ChartTween.single(
    ChartData data,
    ChartMapper mapper, {
    AnimatedSeriesBuilderSingle animatedSeriesBuilder,
  }) {
    animatedSeriesBuilder ??= SimpleAnimatedSeriesBuilderSingle.direct();

    final bounds = ChartBoundsDoubled.fromData(data, mapper);
    final mapped = Map.fromEntries(data.series.map((c) => MapEntry(c.name, c)));
    final series = <SeriesTween>[];
    for (final key in mapped.keys) {
      var data = SeriesAnimationBuilderDataSingle(bounds, mapped[key], mapper);
      series.add(animatedSeriesBuilder.build(data));
    }
    return ChartTween(series);
  }

  factory ChartTween.between(
    ChartData from,
    ChartData to,
    ChartMapper mapper, {
    AnimatedSeriesBuilder animatedSeriesBuilder,
    ChartBounds boundsFrom,
    ChartBounds boundsTo,
  }) {
    animatedSeriesBuilder ??= IntersactionAnimatedSeriesBuilder.curve();

    final boundsFromDoubled = ChartBoundsDoubled.fromDataOr(from, mapper, boundsFrom);
    final boundsToDoubled = ChartBoundsDoubled.fromDataOr(to, mapper, boundsTo);

    final mappedFrom =
        Map.fromEntries(from.series.map((c) => MapEntry(c.name, c)));
    final mappedTo = Map.fromEntries(to.series.map((c) => MapEntry(c.name, c)));
    final series = <SeriesTween>[];
    for (final key in mappedFrom.keys) {
      var data = SeriesAnimationBuilderData(boundsFromDoubled, boundsToDoubled,
          mappedFrom[key], mappedTo[key], mapper);
      series.add(animatedSeriesBuilder.build(data));
    }
    return ChartTween(series);
  }

  @override
  List<SeriesAnimationData> transform(double t) {
    return animatables.map((e) => e.transform(t)).toList();
  }
}

abstract class AnimatedSeriesBuilder {
  SeriesTween build(SeriesAnimationBuilderData data);
}

abstract class AnimatedSeriesBuilderSingle {
  SeriesTween build(SeriesAnimationBuilderDataSingle data);
}
