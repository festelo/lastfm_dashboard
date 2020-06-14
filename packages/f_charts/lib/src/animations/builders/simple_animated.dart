import 'package:f_charts/animations.dart';
import 'package:f_charts/data_models.dart';
import 'package:f_charts/utils.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import '../animated_series.dart';

class SimpleAnimatedSeriesBuilder implements AnimatedSeriesBuilder {
  final RelativeOffset initialOffset;
  final AnimatableBuilder animatableBuilder;

  const SimpleAnimatedSeriesBuilder(
    this.animatableBuilder,
    RelativeOffset initialOffset,
  ) : initialOffset = initialOffset ?? const RelativeOffset(0, 0);

  factory SimpleAnimatedSeriesBuilder.direct(AxisDirection direction, {
    Curve curve = Curves.easeInOut,
    RelativeOffset initialOffset,
  }) {
    RelativeOffset deltaOffset;
    if (direction == AxisDirection.right) {
      deltaOffset = RelativeOffset(1, 0);
    } else if (direction == AxisDirection.left) {
      deltaOffset = RelativeOffset(-1, 0);
    } else if (direction == AxisDirection.down) {
      deltaOffset = RelativeOffset(0, 1);
    } else if (direction == AxisDirection.up) {
      deltaOffset = RelativeOffset(0, -1);
    }
    return SimpleAnimatedSeriesBuilder(
      (a, b) => TweenSequence([
        TweenSequenceItem(
          weight: 50,
          tween: a != null
              ? Tween(begin: a, end: a + deltaOffset)
                  .chain(CurveTween(curve: curve))
              : ConstantTween(null),
        ),
        TweenSequenceItem(
          weight: 50,
          tween: b != null
              ? Tween(begin: b - deltaOffset, end: b)
                  .chain(CurveTween(curve: curve))
              : ConstantTween(null),
        )
      ]),
      initialOffset,
    );
  }

  factory SimpleAnimatedSeriesBuilder.leftCornerInOut({
    Curve curve = Curves.easeInOut,
    RelativeOffset initialOffset,
  }) {
    return SimpleAnimatedSeriesBuilder(
      (a, b) => TweenSequence([
        if (a != null)
          TweenSequenceItem(
            weight: 50,
            tween: Tween(begin: a, end: RelativeOffset(0, 0)).chain(
              CurveTween(curve: curve),
            ),
          ),
        if (b != null)
          TweenSequenceItem(
            weight: 50,
            tween: Tween(begin: RelativeOffset(0, 0), end: b).chain(
              CurveTween(curve: curve),
            ),
          ),
      ]),
      initialOffset,
    );
  }

  @override
  SeriesTween build(SeriesAnimationBuilderData data) {
    final seriesFrom = data.seriesFrom;
    final seriesTo = data.seriesTo;
    final boundsFrom = data.boundsFrom;
    final boundsTo = data.boundsTo;
    final mapper = data.mapper;

    final fromOffsets = seriesFrom.entities
        .map((e) => e.toRelativeOffset(mapper, boundsFrom) + initialOffset)
        .toList();
    final toOffsets = seriesTo?.entities
            ?.map((e) => e.toRelativeOffset(mapper, boundsTo))
            ?.toList() ??
        [];

    var fromValues = fromOffsets.map((e) => animatableBuilder(e, null));
    var toValues = toOffsets.map((e) => animatableBuilder(null, e));

    return SeriesTween(
      from: seriesFrom,
      to: seriesTo,
      offsetAnimatables: [...fromValues, ...toValues],
      showPoints: true,
    );
  }
}
