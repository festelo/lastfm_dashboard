import 'dart:math';
import 'dart:ui';

import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:f_charts/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shared/models.dart';

import 'layer.dart';

class IntersactionInfo<T1, T2> {
  final Pair<Offset> line;
  final Offset offset;
  final Pair<ChartEntity<T1, T2>> entities;
  final ChartEntity<T1, T2> nearestEntity;
  final double deltaToNearest;
  IntersactionInfo({
    @required this.line,
    @required this.offset,
    @required this.entities,
    @required this.nearestEntity,
    @required this.deltaToNearest,
  });
}

class ChartInteractionLayer<T1, T2> extends Layer {
  double xPositionAbs;
  final ChartTheme theme;
  final Map<ChartSeries<T1, T2>, List<ChartLine>> seriesLines;
  final Map<ChartEntity<T1, T2>, ChartPoint> entityPoints;
  final ChartState state;
  final ChartMapper<T1, T2> mapper;
  final ChartBoundsDoubled bounds;

  final PointPressedCallback<T1, T2> pointPressed;

  Size cachedSize;

  Map<ChartEntity<T1, T2>, Offset> cachedEntityPointsAbs;

  void recalculateCache(Size size) {
    if (size == cachedSize) return;
    cachedEntityPointsAbs = entityPoints.map(
      (key, value) => MapEntry(
        key,
        value.offset.toAbsolute(size),
      ),
    );
    cachedSize = size;
  }

  Pair<Offset> retrieveAbsoluteLine(ChartEntity a, ChartEntity b) {
    return Pair(cachedEntityPointsAbs[a], cachedEntityPointsAbs[b]);
  }

  Offset retrieveAbsolutePoint(ChartEntity entity) {
    return cachedEntityPointsAbs[entity];
  }

  ChartInteractionLayer({
    @required this.theme,
    @required this.state,
    @required this.mapper,
    @required this.bounds,
    this.pointPressed,
    Map<ChartSeries<T1, T2>, List<ChartLine>> seriesLines,
    Map<ChartEntity<T1, T2>, ChartPoint> entityPoints,
  })  : assert(theme != null),
        seriesLines = seriesLines ?? {},
        entityPoints = entityPoints ?? {};

  factory ChartInteractionLayer.calculate(
    ChartData<T1, T2> data,
    ChartTheme theme,
    ChartState state,
    ChartMapper<T1, T2> mapper, {
    PointPressedCallback<T1, T2> pointPressed,
    ChartBounds bounds,
  }) {
    final boundsDoubled = ChartBoundsDoubled.fromDataOr(data, mapper, bounds);
    final layer = ChartInteractionLayer<T1, T2>(
      theme: theme,
      pointPressed: pointPressed,
      mapper: mapper,
      bounds: boundsDoubled,
      state: state,
    );

    for (final s in data.series) {
      layer._placeSeries(s, boundsDoubled, mapper);
    }
    return layer;
  }

  void _placeSeries(
    ChartSeries<T1, T2> series,
    ChartBoundsDoubled bounds,
    ChartMapper<T1, T2> mapper,
  ) {
    if (series.entities.isEmpty) return;
    RelativeOffset bo;
    ChartEntity<T1, T2> b;

    for (var i = 1; i < series.entities.length; i++) {
      var a = series.entities[i - 1];
      b = series.entities[i];
      final ao = a.toRelativeOffset(mapper, bounds);
      bo = b.toRelativeOffset(mapper, bounds);
      placeLine(series, ao, bo);
      placePoint(a, ao, series.color);
    }
    if (b == null) b = series.entities[0];
    if (bo == null) bo = b.toRelativeOffset(mapper, bounds);
    placePoint(b, bo, series.color);
  }

  void placeLine(ChartSeries<T1, T2> s, RelativeOffset a, RelativeOffset b) {
    if (seriesLines[s] == null) seriesLines[s] = [];
    seriesLines[s].add(ChartLine(a, b));
  }

  void placePoint(ChartEntity<T1, T2> e, RelativeOffset o, Color color) {
    entityPoints[e] = ChartPoint(o, radius: theme.point?.radius, color: color);
  }

  @override
  bool hitTest(Offset position) {
    if (pointPressed == null ||
        cachedEntityPointsAbs == null ||
        cachedEntityPointsAbs.isEmpty ||
        state.isSwitching) return super.hitTest(position);

    for (final e in cachedEntityPointsAbs.entries) {
      final diff = e.value - position;
      if (diff.dx < 20 && diff.dy < 20 && diff.dx > -20 && diff.dy > -20) {
        pointPressed(e.key);
        return true;
      }
    }

    return false;
  }

  @override
  bool themeChangeAffected(ChartTheme theme) {
    return false;
  }

  @override
  bool shouldDraw() => !state.isSwitching && !state.isDragging;

  @override
  void draw(Canvas canvas, Size size) {
    recalculateCache(size);
    if (xPositionAbs == null || xPositionAbs < 0 || xPositionAbs > size.width)
      return;
    for (final series in seriesLines.keys) {
      final intersaction = getIntersactionWithSeries(
        series,
        size,
        xPositionAbs,
      );
      if (intersaction != null) {
        drawInterscationHighlight(canvas, size, series, intersaction);
        drawYPointerMarkers(canvas, size, series, intersaction);
      }
    }
    drawXPointerMarker(canvas, size);
    if (theme.xPointer != null) _drawXPointerLine(canvas, size);
    if (theme.point != null)
      for (final p in entityPoints.values) {
        canvas.drawCircle(
          p.offset.toAbsolute(size),
          theme.point.radius,
          Paint()..color = p.color,
        );
      }
  }

  void _drawXPointerLine(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(xPositionAbs, 0),
      Offset(xPositionAbs, size.height),
      Paint()
        ..strokeWidth = theme.xPointer.width
        ..color = theme.xPointer.color,
    );
  }

  IntersactionInfo getIntersactionWithSeries(
    ChartSeries<T1, T2> series,
    Size size,
    double xPosition,
  ) {
    for (var i = 1; i < series.entities.length; i++) {
      final a = series.entities[i - 1];
      final b = series.entities[i];
      final line = retrieveAbsoluteLine(a, b);
      final xHighlightLine = Pair(
        Point(xPosition, 0),
        Point(xPosition, RelativeOffset.max),
      );

      if (line.a.dx < xPosition && line.b.dx > xPosition) {
        final linePair = Pair(line.a, line.b);
        final cross = intersection(linePair.toPointPair(), xHighlightLine);
        if (cross == null) continue;
        var deltaA = (xPosition - line.a.dx).abs();
        var deltaB = (xPosition - line.b.dx).abs();
        var nearestDelta = min(deltaA, deltaB);
        return IntersactionInfo(
          line: line,
          offset: Offset(cross.x.toDouble(), cross.y.toDouble()),
          entities: Pair(series.entities[i - 1], series.entities[i]),
          nearestEntity: nearestDelta == deltaA ? a : b,
          deltaToNearest: nearestDelta,
        );
      }
    }

    var first = series.entities[0];
    var firstPoint = retrieveAbsolutePoint(first);
    var deltaFirst = (xPosition - firstPoint.dx).abs();
    if (deltaFirst < 10) {
      return IntersactionInfo(
          line: retrieveAbsoluteLine(first, series.entities[1]),
          offset: firstPoint,
          entities: Pair(first, series.entities[1]),
          deltaToNearest: deltaFirst,
          nearestEntity: first);
    }

    var last = series.entities[series.entities.length - 1];
    var lastPoint = retrieveAbsolutePoint(last);
    var deltaLast = (xPosition - lastPoint.dx).abs();
    if (deltaLast < 10) {
      return IntersactionInfo(
          line: retrieveAbsoluteLine(
              series.entities[series.entities.length - 2], last),
          offset: lastPoint,
          entities: Pair(series.entities[series.entities.length - 2], last),
          deltaToNearest: deltaLast,
          nearestEntity: last);
    }
    return null;
  }

  void _drawYMarker(
      Canvas canvas, Size size, Offset cross, Color color, String text,
      {bool inactive = false}) {
    final textStyle =
        TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold);
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    var height = textPainter.height + theme.yHighlightMarker.mainAxisMargin * 2;

    var backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          theme.background.withOpacity(0),
          theme.background,
          theme.background,
          theme.background.withOpacity(0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset(
              cross.dx, cross.dy - height / 2) &
          Size(theme.outerSpace.left, height));

    var linePaint = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0),
          color,
          color,
          color.withOpacity(0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset(cross.dx, cross.dy - 10) & Size(1, 20));
    canvas.drawRect(
      Rect.fromLTRB(
          -theme.outerSpace.left,
          cross.dy - height / 2,
          -2,
          cross.dy + height / 2),
      backgroundPaint,
    );
    canvas.drawLine(
      Offset(0, max(cross.dy - 10, 0)),
      Offset(0, min(cross.dy + 10, size.height)),
      linePaint,
    );

    textPainter.paint(canvas,
        Offset(-5 - textPainter.width, cross.dy - textPainter.height / 2));
  }

  void _drawPointHighlight(Canvas canvas, Offset cross, Color color) {
    canvas.drawCircle(
      cross,
      theme.point.radius + 1,
      Paint()..color = Colors.grey,
    );
    canvas.drawCircle(
      cross,
      theme.point.radius,
      Paint()..color = color,
    );
  }

  void drawYPointerMarkers(
    Canvas canvas,
    Size size,
    ChartSeries series,
    IntersactionInfo intersactionInfo,
  ) {
    final cross = intersactionInfo.offset;
    final entity = intersactionInfo.nearestEntity;
    final entityPoint = retrieveAbsolutePoint(entity);
    if (intersactionInfo.deltaToNearest < 10) {
      _drawYMarker(
          canvas, size, entityPoint, series.color, entity.ordinate.toString());
      _drawPointHighlight(canvas, entityPoint, series.color);
    } else {
      var chartPoint = bounds.minOrdinate +
          (1 - cross.dy / size.height) *
              (bounds.maxOrdinate - bounds.minOrdinate);
      var entity = mapper.ordinateMapper.fromDouble(chartPoint);
      var str = mapper.ordinateMapper.getString(entity);

      _drawYMarker(canvas, size, cross,
          Color.alphaBlend(series.color.withOpacity(0.4), Colors.grey), str);
    }
  }

  void _drawXMarker(
      Canvas canvas, Size size, double xPos, Color color, String text) {
    final textStyle =
        TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold);
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    var width = textPainter.width + theme.xHighlightMarker.mainAxisMargin * 2;
    var backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          theme.background.withOpacity(0),
          theme.background,
          theme.background,
          theme.background.withOpacity(0),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Offset(xPos - width / 2, size.height) &
          Size(width, theme.outerSpace.bottom));

    canvas.drawRect(
      Rect.fromLTRB(xPos - width / 2, size.height + theme.xAxis.width,
          xPos + width / 2, size.height + theme.outerSpace.bottom),
      backgroundPaint,
    );
    textPainter.paint(
        canvas, Offset(xPos - textPainter.width / 2, size.height));
  }

  void drawXPointerMarker(
    Canvas canvas,
    Size size,
  ) {
    var chartPoint = bounds.minAbscissa +
        (xPositionAbs / size.width) * (bounds.maxAbscissa - bounds.minAbscissa);
    var entity = mapper.abscissaMapper.fromDouble(chartPoint);
    var str = mapper.abscissaMapper.getString(entity);

    _drawXMarker(canvas, size, xPositionAbs, Colors.grey, str);
  }

  void drawInterscationHighlight(
    Canvas canvas,
    Size size,
    ChartSeries series,
    IntersactionInfo intersactionInfo,
  ) {
    final offset = intersactionInfo.offset;
    final cross = intersactionInfo.offset.toPoint();
    final line = intersactionInfo.line;

    var partPointLeft = partOf(
      Pair(line.a.toPoint(), cross),
      20,
    );
    var partLeft =
        Offset(partPointLeft.x.toDouble(), partPointLeft.y.toDouble());
    var partPointRight = partOf(
      Pair(line.b.toPoint(), cross),
      20,
    );
    var partRight =
        Offset(partPointRight.x.toDouble(), partPointRight.y.toDouble());

    var paint = Paint()
      ..strokeWidth = 3
      ..shader = LinearGradient(
        colors: [
          Colors.grey.withOpacity(0),
          Colors.grey,
          Colors.grey.withOpacity(0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(partLeft &
          Size(
            partRight.dx - partLeft.dx,
            partRight.dy - partLeft.dy,
          ));

    canvas.drawLine(
      partLeft,
      offset,
      paint,
    );
    canvas.drawLine(
      partRight,
      offset,
      paint,
    );
  }
}
