import 'dart:ui';

import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:flutter/cupertino.dart';

import 'layer.dart';

class ChartDecorationLayer extends Layer {
  final List<ChartLine> axisMarkers;
  final List<ChartText> axisTextMarkers;
  ChartLine _xAxisLine;
  ChartLine _yAxisLine;

  final ChartTheme theme;

  ChartDecorationLayer({
    List<ChartLine> axisMarkers,
    List<ChartText> axisTextMarkers,
    @required this.theme,
  })  : assert(theme != null),
        axisMarkers = axisMarkers ?? [],
        axisTextMarkers = axisTextMarkers ?? [];

  factory ChartDecorationLayer.calculate({
    @required ChartData data,
    @required ChartTheme theme,
    @required ChartMarkersPointer markersPointer,
    @required ChartMapper mapper,
    ChartBounds bounds,
  }) {
    bounds = mapper.getBounds(data, or: bounds);
    final layer = ChartDecorationLayer(theme: theme);
    layer.placeXAxisLine();
    layer.placeYAxisLine();
    layer.placeYMarkers(bounds, mapper, markersPointer);
    layer.placeXMarkers(bounds, mapper, markersPointer);
    return layer;
  }

  void placeXAxisLine() {
    if (theme.xAxis == null) {
      _xAxisLine = null;
    } else {
      _xAxisLine = ChartLine(
        RelativeOffset(0, 1),
        RelativeOffset(1, 1),
        color: theme.xAxis.color,
        width: theme.xAxis.width,
      );
    }
  }

  void placeYAxisLine() {
    if (theme.yAxis == null) {
      _yAxisLine = null;
    } else {
      _yAxisLine = ChartLine(
        RelativeOffset(0, 0),
        RelativeOffset(0, 1),
        color: theme.yAxis.color,
        width: theme.yAxis.width,
      );
    }
  }

  void placeYMarkers(
    ChartBounds bounds,
    ChartMapper mapper,
    ChartMarkersPointer markersPointer,
  ) {
    if (theme.yMarkers == null) {
      return;
    }
    final points = markersPointer.ordinate
        .getPoints(bounds.minOrdinate, bounds.maxOrdinate);
    final min = mapper.ordinateMapper.toDouble(bounds.minOrdinate);
    final max = mapper.ordinateMapper.toDouble(bounds.maxOrdinate);
    for (final p in points) {
      final i = 1 - (mapper.ordinateMapper.toDouble(p) - min) / max;
      if (theme.yMarkers.line != null)
        axisMarkers.add(ChartLine(
          RelativeOffset(0, i),
          RelativeOffset(1, i),
          color: theme.yMarkers.line.color,
          width: theme.yMarkers.line.width,
        ));
      if (theme.yMarkers.text != null) {
        var painter = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            style: theme.yMarkers.text,
            text: mapper.ordinateMapper.getString(p),
          ),
        )..layout();
        axisTextMarkers.add(
          ChartText(
            CombinedOffset()
              ..absoluteX = -painter.width - 5
              ..relativeY = i
              ..absoluteY = -painter.height / 2,
            painter,
          ),
        );
      }
    }
  }

  void placeXMarkers(
    ChartBounds bounds,
    ChartMapper mapper,
    ChartMarkersPointer markersPointer,
  ) {
    if (theme.xMarkers == null) {
      return;
    }
    final points = markersPointer.abscissa
        .getPoints(bounds.minAbscissa, bounds.maxAbscissa);
    final min = mapper.abscissaMapper.toDouble(bounds.minAbscissa);
    final max = mapper.abscissaMapper.toDouble(bounds.maxAbscissa);
    for (final p in points) {
      final i = (mapper.abscissaMapper.toDouble(p) - min) / (max - min);
      if (theme.xMarkers.line != null)
        axisMarkers.add(ChartLine(
          RelativeOffset(i, 0),
          RelativeOffset(i, 1),
          color: theme.xMarkers.line.color,
          width: theme.xMarkers.line.width,
        ));
      if (theme.xMarkers.text != null) {
        var painter = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            style: theme.xMarkers.text,
            text: mapper.abscissaMapper.getString(p),
          ),
        )..layout();
        axisTextMarkers.add(
          ChartText(
            CombinedOffset()
              ..relativeY = 1
              ..relativeX = i
              ..absoluteX = -painter.width / 2,
            painter,
          ),
        );
      }
    }
  }

  @override
  bool themeChangeAffected(ChartTheme theme) {
    return theme.xMarkers != this.theme.xMarkers ||
        theme.yMarkers != this.theme.yMarkers ||
        theme.xAxis != this.theme.xAxis ||
        theme.yAxis != this.theme.yAxis;
  }

  @override
  void draw(Canvas canvas, Size size) {
    for (final l in axisMarkers) {
      canvas.drawLine(
        l.a.toAbsolute(size),
        l.b.toAbsolute(size),
        Paint()
          ..color = l.color
          ..strokeWidth = l.width,
      );
    }

    for (final t in axisTextMarkers) {
      t.painter.paint(canvas, t.offset.toAbsolute(size));
    }

    if (_xAxisLine != null) {
      canvas.drawLine(
        _xAxisLine.a.toAbsolute(size),
        _xAxisLine.b.toAbsolute(size),
        Paint()
          ..strokeWidth = _xAxisLine.width
          ..color = _xAxisLine.color,
      );
    }

    if (_yAxisLine != null) {
      canvas.drawLine(
        _yAxisLine.a.toAbsolute(size),
        _yAxisLine.b.toAbsolute(size),
        Paint()
          ..strokeWidth = _yAxisLine.width
          ..color = _yAxisLine.color,
      );
    }
  }
}
