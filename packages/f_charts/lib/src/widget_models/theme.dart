import 'dart:ui';

import 'package:flutter/material.dart';

class ChartTheme {
  final LineTheme xPointer;
  final MarkersTheme yMarkers;
  final MarkersTheme xMarkers;
  final HighlightMarker xHighlightMarker;
  final HighlightMarker yHighlightMarker;
  final LineTheme line;
  final LineTheme xAxis;
  final LineTheme yAxis;
  final CircleTheme point;
  final EdgeInsets outerSpace;
  final Color background;

  const ChartTheme({
    this.xPointer = const LineTheme(color: Colors.grey),
    this.line = const LineTheme(width: 2),
    this.xAxis = const LineTheme(color: Colors.grey),
    this.yAxis = const LineTheme(color: Colors.grey),
    this.point = const CircleTheme(),
    this.yMarkers = const MarkersTheme(),
    this.xMarkers = const MarkersTheme(line: null),
    this.outerSpace = const EdgeInsets.all(20),
    this.background = Colors.white,
    this.xHighlightMarker = const HighlightMarker(),
    this.yHighlightMarker = const HighlightMarker(),
  });

  ChartTheme copyWith({
    LineTheme xPointer,
    MarkersTheme yMarkers,
    MarkersTheme xMarkers,
    LineTheme line,
    LineTheme xAxis,
    LineTheme yAxis,
    CircleTheme point,
    HighlightMarker xHighlightMarker,
    HighlightMarker yHighlightMarker,
    EdgeInsets outerSpace,
    Color background,
  }) {
    return ChartTheme(
      xPointer: xPointer ?? this.xPointer,
      yMarkers: yMarkers ?? this.yMarkers,
      xMarkers: xMarkers ?? this.xMarkers,
      line: line ?? this.line,
      xAxis: xAxis ?? this.xAxis,
      yAxis: yAxis ?? this.yAxis,
      point: point ?? this.point,
      xHighlightMarker: xHighlightMarker ?? this.xHighlightMarker,
      yHighlightMarker: yHighlightMarker ?? this.yHighlightMarker,
      outerSpace: outerSpace ?? this.outerSpace,
      background: background ?? this.background,
    );
  }
}

class LineTheme {
  final double width;
  final Color color;
  const LineTheme({this.width = 1, this.color = Colors.black});
}

class CircleTheme {
  final double radius;
  final Color color;
  const CircleTheme({this.radius = 5, this.color = Colors.black});
}

class MarkersTheme {
  final LineTheme line;
  final TextStyle text;
  const MarkersTheme({
    this.line = const LineTheme(width: 1, color: Colors.black12),
    this.text = const TextStyle(color: Colors.grey, fontSize: 12),
  });
}

class HighlightMarker {
  final double mainAxisMargin;
  const HighlightMarker({this.mainAxisMargin = 20});
}
