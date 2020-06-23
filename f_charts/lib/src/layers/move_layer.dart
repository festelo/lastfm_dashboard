import 'dart:ui';

import 'package:f_charts/widget_models.dart';
import 'package:f_charts/animations.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'layer.dart';

class ChartMoveLayer extends Layer {
  final Animation<List<SeriesAnimationData>> animation;
  final ChartState state;

  final ChartTheme theme;
  ChartMoveLayer({this.theme, this.state, this.animation})
      : assert(theme != null);

  @override
  bool themeChangeAffected(ChartTheme theme) {
    return false;
  }

  @override
  void draw(Canvas canvas, Size size) {
    final values = animation.value;
    for (final series in values) {
      final points = series.points;
      if (points.isEmpty) continue;
      Offset b;
      for (var i = 1; i < points.length; i++) {
        var a = points[i - 1].toAbsolute(size);
        b = points[i].toAbsolute(size);
        drawLine(canvas, a, b, series.color);
        if (series.showPoints) drawPoint(canvas, a, series.color);
      }
      if (b != null) drawPoint(canvas, b, series.color);
    }
  }

  @override
  bool shouldRepaint() {
    return state.isSwitching;
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
