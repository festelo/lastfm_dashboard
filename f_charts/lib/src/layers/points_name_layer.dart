import 'dart:ui';

import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:f_charts/utils.dart';
import 'package:flutter/material.dart';

import 'layer.dart';

class PointsNameLayer extends Layer {
  final List<ChartText> pointTexts;

  final ChartTheme theme;
  final ChartState state;

  PointsNameLayer({
    List<ChartText> pointTexts,
    List<ChartLine> lines,
    @required this.theme,
    @required this.state,
  })  : assert(theme != null),
        pointTexts = pointTexts ?? [];

  factory PointsNameLayer.calculate(
    ChartData data,
    ChartTheme theme,
    ChartState state,
    ChartMapper mapper, [
    ChartBounds bounds,
  ]) {
    bounds ??= mapper.getBounds(data, or: bounds);
    final boundsDoubled = ChartBoundsDoubled.fromBounds(bounds, mapper);
    final layer = PointsNameLayer(theme: theme, state: state);

    for (final s in data.series) {
      layer._placeTexts(s, boundsDoubled, mapper);
    }
    return layer;
  }

  void _placeTexts(
    ChartSeries series,
    ChartBoundsDoubled bounds,
    ChartMapper mapper,
  ) {
    for (final e in series.entities) {
      final offset = e.toRelativeOffset(mapper, bounds);
      placeText(offset, offset.toString(), Colors.red);
    }
  }

  void placeText(RelativeOffset a, String text, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: Colors.red, fontSize: 13),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    pointTexts.add(ChartText(a, textPainter));
  }

  @override
  bool shouldDraw() => !state.isSwitching;

  @override
  bool themeChangeAffected(ChartTheme theme) {
    return false;
  }

  @override
  void draw(Canvas canvas, Size size) {
    for (final t in pointTexts) {
      t.painter.paint(canvas, t.offset.toAbsolute(size));
    }
  }
}
