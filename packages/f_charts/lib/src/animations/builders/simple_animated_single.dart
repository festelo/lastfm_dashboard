import 'package:f_charts/animations.dart';
import 'package:f_charts/data_models.dart';
import 'package:f_charts/utils.dart';
import 'package:flutter/animation.dart';
import '../animated_series.dart';

class SimpleAnimatedSeriesBuilderSingle implements AnimatedSeriesBuilderSingle {
  final RelativeOffset initialOffset;
  final AnimatableBuilder animatableBuilder;

  const SimpleAnimatedSeriesBuilderSingle(
    this.animatableBuilder,
    RelativeOffset initialOffset,
  ) : initialOffset = initialOffset ?? const RelativeOffset(0, 0);

  SimpleAnimatedSeriesBuilderSingle.direct({
    Curve curve = Curves.easeInOut,
    RelativeOffset initialOffset,
  }): this((a, b) => Tween(begin: a, end: b).chain(CurveTween(curve: curve)), initialOffset);

  @override
  SeriesTween build(SeriesAnimationBuilderDataSingle data) {
    final series = data.series;
    final bounds = data.bounds;
    final mapper = data.mapper;

    final offsets = series.entities
        .map((e) => e.toRelativeOffset(mapper, bounds))
        .toList();

    final values = offsets.map((e) => animatableBuilder(e + initialOffset, e)).toList();

    return SeriesTween(
      from: series,
      to: series,
      offsetAnimatables: values,
      showPoints: true,
    );
  }
}