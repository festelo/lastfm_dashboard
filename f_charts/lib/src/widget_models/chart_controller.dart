import 'dart:async';

import 'package:f_charts/animations.dart';
import 'package:f_charts/src/widget_models/drag_controller.dart';
import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:f_charts/src/extensions.dart';
import 'package:f_charts/layers.dart';

class ChartController<T1, T2> implements Listenable {
  final ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();
  final ChartState state;
  final TickerProvider vsync;

  ChartTheme theme;
  ChartMapper<T1, T2> mapper;
  ChartMarkersPointer<T1, T2> markersPointer;
  PointPressedCallback<T1, T2> pointPressed;
  ChartBounds<T1, T2> bounds;
  Completer _moveCompleter;

  DragController _drag;
  DragController get drag => _drag;
  void set drag(DragController value) {
    _drag = value;
    _drag.updateController(this);
  }

  Future get replaceLock {
    if (_moveCompleter != null) {
      return _moveCompleter.future;
    }
    return Future.value();
  }

  void redraw() {
    initLayers();
    notifyListeners();
  }

  ChartData<T1, T2> data;

  ChartController(
    this.data,
    this.mapper,
    this.markersPointer,
    this.vsync, {
    this.bounds,
    this.theme = const ChartTheme(),
    ChartState state = null,
    this.pointPressed,
    DragController drag,
  })  : state = state ?? ChartState(),
        moveAnimationController = AnimationController(
          vsync: vsync,
          duration: Duration(milliseconds: 500),
        ) {
    this.drag = drag;
  }

  ChartMoveLayer _moveLayer;
  ChartDrawBaseLayer _baseLayer;
  ChartInteractionLayer _interactionLayer;
  ChartDecorationLayer _decorationLayer;

  List<Layer> get layers => [
        _decorationLayer,
        if (state.isSwitching) _moveLayer,
        _baseLayer,
        _interactionLayer,
      ].where((e) => e != null).toList();

  AnimationController moveAnimationController;

  void initLayers() {
    _baseLayer =
        ChartDrawBaseLayer.calculate(data, theme, state, mapper, bounds);
    _interactionLayer = ChartInteractionLayer<T1, T2>.calculate(
      data,
      theme,
      state,
      mapper,
      pointPressed: pointPressed,
      bounds: bounds,
    );
    _decorationLayer = ChartDecorationLayer.calculate(
      data: data,
      theme: theme,
      markersPointer: markersPointer,
      mapper: mapper,
      bounds: bounds,
      state: state,
    );
  }

  void setXPointerPosition(double value) {
    _interactionLayer.xPositionAbs = value;
    notifyListeners();
  }

  bool tap(Offset position) {
    var interacted = false;
    for (final l in layers) {
      if (l.hitTest(position)) interacted = true;
    }
    return interacted;
  }

  Offset translateOuterOffset(Offset offset) {
    return offset - Offset(theme.outerSpace.left, theme.outerSpace.top);
  }

  ChartTween buildAnimation(
    ChartData<T1, T2> to, {
    ChartBounds<T1, T2> boundsFrom,
    ChartBounds<T1, T2> boundsTo,
    SimpleAnimatedSeriesBuilder seriesBuilder,
  }) {
    final animation = ChartTween.between(
      data,
      to,
      mapper,
      boundsFrom: boundsFrom ?? bounds,
      boundsTo: boundsTo ?? bounds,
      animatedSeriesBuilder: seriesBuilder,
    );
    return animation;
  }

  Future<void> replaceData(ChartData<T1, T2> to) async {
    await _moveCompleter?.future;
    final tween = buildAnimation(to);
    if (tween.pointsDifferent()) {
      final animation = moveAnimationController.drive(tween);
      await move(to, animation, () => moveAnimationController.forward(from: 0));
    } else {
      data = to;
      initLayers();
      notifyListeners();
    }
  }

  Future<void> move(
    ChartData<T1, T2> to,
    Animation<List<SeriesAnimationData>> animation, [
    void Function() start,
  ]) async {
    state.isSwitching = true;
    state.draggingOffset = Offset(0, 0);
    if (_moveCompleter != null) {
      await _moveCompleter.future;
    }
    final completer = _moveCompleter = Completer();

    _moveLayer = ChartMoveLayer(
      animation: animation,
      state: state,
      theme: theme,
    );
    for (final l in _listeners) {
      animation.addListener(l);
    }
    try {
      if (start != null) start();
      await animation.completed;
    } finally {
      for (final l in _listeners) {
        animation.removeListener(l);
      }
    }
    data = to;
    state.isSwitching = false;
    initLayers();
    notifyListeners();
    completer.complete();
  }

  @override
  void addListener(listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        print(e);
      }
    }
  }

  void dispose() {
    moveAnimationController?.dispose();
  }
}
