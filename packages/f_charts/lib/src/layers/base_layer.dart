import 'dart:ui';

import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:f_charts/utils.dart';
import 'package:flutter/material.dart';

import 'layer.dart';

class ChartDrawBaseLayer extends Layer {
  final List<ChartPoint> points;
  final List<ChartLine> lines;
  final ChartState state;

  final ChartTheme theme;

  ChartDrawBaseLayer({
    List<ChartPoint> points,
    List<ChartLine> lines,
    @required this.theme,
    @required this.state,
  })  : assert(theme != null),
        points = points ?? [],
        lines = lines ?? [];

  factory ChartDrawBaseLayer.calculate(
    ChartData data,
    ChartTheme theme,
    ChartState state,
    ChartMapper mapper, [
    ChartBounds bounds,
  ]) {
    final boundsDoubled = ChartBoundsDoubled.fromDataOr(data, mapper, bounds);
    final layer = ChartDrawBaseLayer(theme: theme, state: state);

    for (final s in data.series) {
      layer._placeSeries(s, boundsDoubled, mapper);
    }
    return layer;
  }

  void _placeSeries(
    ChartSeries series,
    ChartBoundsDoubled bounds,
    ChartMapper mapper,
  ) {
    if (series.entities.isEmpty) return;
    RelativeOffset bo;

    for (var i = 1; i < series.entities.length; i++) {
      var a = series.entities[i - 1];
      var b = series.entities[i];
      final ao = a.toRelativeOffset(mapper, bounds);
      bo = b.toRelativeOffset(mapper, bounds);
      placeLine(ao, bo, series.color);
      placePoint(ao, series.color);
    }
    placePoint(bo ?? series.entities[0].toRelativeOffset(mapper, bounds),
        series.color);
  }

  void placePoint(RelativeOffset o, Color color) {
    if (theme.point == null) return;
    points.add(ChartPoint(
      o,
      color: color ?? theme.point.color,
      radius: theme.point.radius,
    ));
  }

  void placeLine(RelativeOffset a, RelativeOffset b, Color color) {
    if (theme.line == null) return;
    lines.add(ChartLine(a, b,
        color: color ?? theme.line.color, width: theme.line.width));
  }

  @override
  bool themeChangeAffected(ChartTheme theme) {
    return theme.line != this.theme.line || theme.point != this.theme.point;
  }

  @override
  bool shouldDraw() => !state.isSwitching;

  @override
  void draw(Canvas canvas, Size size) {
    for (final l in lines) {
      canvas.drawLine(
        l.a.toAbsolute(size) + state.draggingOffset,
        l.b.toAbsolute(size) + state.draggingOffset,
        Paint()
          ..color = l.color
          ..strokeWidth = l.width,
      );
    }

    for (final p in points) {
      canvas.drawCircle(
        p.offset.toAbsolute(size) + state.draggingOffset,
        theme.point.radius,
        Paint()..color = p.color,
      );
    }
  }
}
