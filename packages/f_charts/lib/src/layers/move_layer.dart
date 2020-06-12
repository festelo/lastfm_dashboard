import 'dart:ui';

import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:f_charts/animations.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'layer.dart';

class MoveAnimation {
  final List<AnimatedSeries> series;
  final ChartBounds boundsFrom;
  final ChartBounds boundsTo;

  MoveAnimation(
    this.series, {
    @required this.boundsFrom,
    @required this.boundsTo,
  });

  factory MoveAnimation.single(
    ChartData data,
    ChartMapper mapper, {
    AnimatedSeriesBuilderSingle animatedSeriesBuilder,
  }) {
    animatedSeriesBuilder ??= SimpleAnimatedSeriesBuilderSingle.direct();

    final bounds = ChartBoundsDoubled.fromData(data, mapper);
    final mapped = Map.fromEntries(data.series.map((c) => MapEntry(c.name, c)));
    final series = <AnimatedSeries>[];
    for (final key in mapped.keys) {
      var data = SeriesAnimationBuilderDataSingle(bounds, mapped[key], mapper);
      series.add(animatedSeriesBuilder.build(data));
    }
    return MoveAnimation(
      series,
      boundsFrom: bounds,
      boundsTo: bounds,
    );
  }

  factory MoveAnimation.between(
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
    final series = <AnimatedSeries>[];
    for (final key in mappedFrom.keys) {
      var data = SeriesAnimationBuilderData(boundsFromDoubled, boundsToDoubled,
          mappedFrom[key], mappedTo[key], mapper);
      series.add(animatedSeriesBuilder.build(data));
    }
    ;
    return MoveAnimation(
      series,
      boundsFrom: boundsFrom,
      boundsTo: boundsTo,
    );
  }
}

class ChartMoveLayer extends Layer {
  final Animation<double> parent;
  final MoveAnimation animation;

  final ChartTheme theme;
  ChartMoveLayer({this.animation, this.theme, this.parent})
      : assert(theme != null);

  @override
  bool themeChangeAffected(ChartTheme theme) {
    return false;
  }

  @override
  void draw(Canvas canvas, Size size) {
    for (final s in animation.series) {
      final points = s.points(parent);
      if (points.isEmpty) continue;
      Offset b;
      for (var i = 1; i < points.length; i++) {
        var a = points[i - 1].toAbsolute(size);
        b = points[i].toAbsolute(size);
        drawLine(canvas, a, b, s.from.color);
        if (s.showPoints) drawPoint(canvas, a, s.from.color);
      }
      if (b != null) drawPoint(canvas, b, s.from.color);
    }
  }

  void drawPoint(Canvas canvas, Offset offset, Color color) {
    canvas.drawCircle(
      offset,
      theme.point.radius,
      Paint()..color = color,
    );
  }

  void drawLine(Canvas canvas, Offset a, Offset b, Color color) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = theme.line.width,
    );
  }
}
