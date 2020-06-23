import 'dart:math';

import 'package:f_charts/animations.dart';
import 'package:f_charts/utils.dart';
import 'package:f_charts/data_models.dart';
import 'package:flutter/animation.dart';
import '../animated_series.dart';
import 'package:shared/models.dart';

Map<RelativeOffset, RelativeOffset> _findPointsIntersactionWay(
  List<RelativeOffset> from,
  List<RelativeOffset> to,
) {
  if (from.isEmpty || to.isEmpty) return {};
  Map<RelativeOffset, RelativeOffset> pointsMap = {};

  for (var pointFromI = 0; pointFromI < from.length; pointFromI++) {
    final xPosition = from[pointFromI].dx;

    for (var pointToI = 1; pointToI < to.length; pointToI++) {
      var toLine = Pair(to[pointToI - 1], to[pointToI]);
      if (!(toLine.a.dx <= xPosition && toLine.b.dx >= xPosition)) continue;

      final xLine = Pair(
        Point(xPosition, RelativeOffset.min),
        Point(xPosition, RelativeOffset.max),
      );

      final targetLine = Pair(
        Point(toLine.a.dx, toLine.a.dy),
        Point(toLine.b.dx, toLine.b.dy),
      );

      final cross = intersection(targetLine, xLine);
      if (cross != null)
        pointsMap[from[pointFromI]] =
            RelativeOffset(cross.x.toDouble(), cross.y.toDouble());
    }
  }

  return pointsMap;
}

class IntersactionAnimatedSeriesBuilder implements AnimatedSeriesBuilder {
  final AnimatableBuilder animatableBuilder;
  IntersactionAnimatedSeriesBuilder(this.animatableBuilder);

  IntersactionAnimatedSeriesBuilder.tween() : this((a, b) => Tween(begin: a, end: b));

  IntersactionAnimatedSeriesBuilder.curve({
    Curve curve = Curves.easeInOut,
  }) : this((a, b) => Tween(begin: a, end: b).chain(CurveTween(curve: curve)));

  @override
  SeriesTween build(SeriesAnimationBuilderData data) {
    final seriesFrom = data.seriesFrom;
    final seriesTo = data.seriesTo;
    final boundsFrom = data.boundsFrom;
    final boundsTo = data.boundsTo;
    final mapper = data.mapper;

    final fromOffsets = seriesFrom.entities
        .map((e) => e.toRelativeOffset(mapper, boundsFrom))
        .toList();
    final toOffsets = seriesTo?.entities
            ?.map((e) => e.toRelativeOffset(mapper, boundsTo))
            ?.toList() ??
        [];
    final directIntersactions =
        _findPointsIntersactionWay(fromOffsets, toOffsets);
    final reverseIntersactions =
        _findPointsIntersactionWay(toOffsets, fromOffsets).reverse();

    final allIntersactions = {...directIntersactions, ...reverseIntersactions};

    final allIntersactionsReversed = allIntersactions.reverse();

    if (allIntersactions.isNotEmpty)
      for (var key in fromOffsets) {
        if (allIntersactions[key] != null) continue;
        allIntersactions[key] = allIntersactions.values.reduce(
          (a, b) => (key.dx - a.dx).abs() < (key.dx - b.dx).abs() ? a : b,
        );
      }

    final pairs =
        allIntersactions.entries.map((e) => Pair(e.key, e.value)).toList();

    if (allIntersactionsReversed.isNotEmpty)
      for (var key in toOffsets) {
        if (allIntersactionsReversed[key] != null) continue;
        var nKey = allIntersactions.keys.reduce(
          (a, b) => (key.dx - a.dx).abs() < (key.dx - b.dx).abs() ? a : b,
        );
        pairs.add(Pair(nKey, key));
      }

    pairs.sort((a, b) {
      var compared = a.a.dx.compareTo(b.a.dx);
      if (compared == 0) return a.b.dx.compareTo(b.b.dx);
      return compared;
    });

    var values = pairs.map((e) => animatableBuilder(e.a, e.b)).toList();

    return SeriesTween(
      from: seriesFrom,
      to: seriesTo,
      offsetAnimatables: values,
    );
  }
}
