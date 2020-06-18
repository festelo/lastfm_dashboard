import 'dart:async';
import 'dart:math';

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:f_charts/animations.dart';
import 'package:f_charts/data_models.dart';
import 'package:flutter/animation.dart';
import 'package:shared/models.dart';

extension MapExtensions<T1, T2> on Map<T1, T2> {
  Map<T2, T1> reverse() => this.map((key, value) => MapEntry(value, key));
}

extension OffsetExtenstions on Offset {
  Point toPoint() {
    return Point(this.dx, this.dy);
  }

  Offset abs() {
    return Offset(this.dx.abs(), this.dy.abs());
  }
}

extension RelativeOffsetExtenstions on RelativeOffset {
  Point toRelativePoint() {
    return Point(this.dx, this.dy);
  }
}

extension OffsetPairExtenstions on Pair<Offset> {
  Pair<Point> toPointPair() {
    return Pair<Point>(this.a.toPoint(), this.b.toPoint());
  }
}

extension PointPairExtenstions on Pair<Point> {
  num get x1 => this.a.x;
  num get x2 => this.b.x;
  num get y1 => this.a.y;
  num get y2 => this.b.y;
}

extension AnimationExtensions on Animation {
  Future<void> get completed async {
    final completer = Completer();
    if (status != AnimationStatus.forward &&
        status != AnimationStatus.reverse) {
      throw Exception('Not started');
    }
    final fun = (AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (!completer.isCompleted) completer.complete();
      }
    };
    this.addStatusListener(fun);
    await completer.future;
    this.removeStatusListener(fun);
  }
}

extension AnimatedSeriesExtensions on Animatable<List<SeriesAnimationData>> {
  bool pointsDifferent() {
    final formatPoints = (List<RelativeOffset> o) => o.map(
          (e) => Pair(e.dx.toStringAsFixed(5), e.dy.toStringAsFixed(5)),
        );
        
    final equals = const DeepCollectionEquality().equals(
      this.transform(0).map((e) => formatPoints(e.points)).toList(),
      this.transform(1).map((e) => formatPoints(e.points)).toList(),
    );
    return !equals;
  }
}

extension ChartEntityExtensions<T1, T2> on ChartEntity<T1, T2> {
  RelativeOffset toRelativeOffset(
      ChartMapper<T1, T2> mapper, ChartBoundsDoubled bounds) {
    var abscissaVal =
        mapper.abscissaMapper.toDouble(this.abscissa) - bounds.minAbscissa;
    var ordinateVal =
        mapper.ordinateMapper.toDouble(this.ordinate) - bounds.minOrdinate;
    final height = bounds.maxOrdinate - bounds.minOrdinate;
    final width = bounds.maxAbscissa - bounds.minAbscissa;
    var size = Size(width == 0 ? 1 : width, height == 0 ? 1 : height);
    return RelativeOffset.withViewport(
      abscissaVal,
      ordinateVal,
      size,
    ).reverseY();
  }
}

kek() {}
