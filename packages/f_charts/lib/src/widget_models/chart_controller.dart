import 'package:collection/collection.dart';
import 'package:f_charts/animations.dart';
import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared/models.dart';

import 'package:f_charts/layers.dart';

class ChartController<T1, T2> implements Listenable {
  final ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();
  final ChartState state;

  ChartTheme theme;
  ChartMapper<T1, T2> mapper;
  ChartMarkersPointer<T1, T2> markersPointer;
  PointPressedCallback<T1, T2> pointPressed;
  ChartBounds<T1, T2> bounds;
  SwipedCallback swiped;

  void redraw() {
    initLayers();
    notifyListeners();
  }
  

  ChartData<T1, T2> data;

  ChartController(
    this.data,
    this.mapper,
    this.markersPointer,
    TickerProvider vsync, {
    this.bounds,
    this.theme = const ChartTheme(),
    ChartState state = null,
    this.pointPressed,
    this.swiped,
  })  : state = state ?? ChartState(),
        moveAnimationController = AnimationController(
          vsync: vsync,
          duration: Duration(milliseconds: 500),
        );

  ChartMoveLayer _moveLayer;
  ChartDrawBaseLayer _baseLayer;
  ChartInteractionLayer _interactionLayer;
  ChartDecorationLayer _decorationLayer;

  RelativeOffset _lastDraggingOffset;
  AxisDirection _lastSwipeDirection;
  bool _swipeAnimationExpected = false;

  List<Layer> get layers => [
        _decorationLayer,
        if (state.isSwitching) _moveLayer,
        _baseLayer,
        _interactionLayer,
      ].where((e) => e != null).toList();

  AnimationController moveAnimationController;

  void initLayers() {
    _baseLayer = ChartDrawBaseLayer.calculate(data, theme, state, mapper, bounds);
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
    );
  }

  void setXPointerPosition(double value) {
    _interactionLayer.xPositionAbs = value;
    notifyListeners();
  }

  void startDragging() {
    state.isDragging = true;
  }

  void addDraggingOffset(Offset offset) {
    state.draggingOffset += offset;
    state.isDragging = true;
    notifyListeners();
  }

  void _returnFromDrag(RelativeOffset relative) {
    move(
      data,
      animation: MoveAnimation.single(
        data,
        mapper,
        animatedSeriesBuilder: SimpleAnimatedSeriesBuilderSingle.direct(
          initialOffset: relative,
        ),
      ),
    );
  }

  void endDrag(Size size, {bool withAnimation = true}) {
    var draggingOffset = state.draggingOffset;

    state.isDragging = false;
    state.draggingOffset = Offset(0, 0);

    if (swiped == null || !withAnimation) {
      notifyListeners();
      return;
    }

    final relative = _lastDraggingOffset = RelativeOffset.withViewport(
      draggingOffset.dx,
      draggingOffset.dy,
      size,
    );

    if (draggingOffset.dx.abs() < 80) {
      _returnFromDrag(relative);
      notifyListeners();
      return;
    }

    var axis = draggingOffset.dx < 0 ? AxisDirection.left : AxisDirection.right;

    var handled = swiped(axis);
    if (!handled)
      _returnFromDrag(relative);
    else {
      _lastSwipeDirection = axis;
      _swipeAnimationExpected = true;
    }
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

  Future<void> move(
    ChartData<T1, T2> to, {
    MoveAnimation animation,
    ChartBounds<T1, T2> boundsFrom,
    ChartBounds<T1, T2> boundsTo,
  }) async {
    state.isSwitching = true;

    if (animation == null) {
      if (_swipeAnimationExpected) {
        animation = MoveAnimation.between(
          data,
          to,
          mapper,
          animatedSeriesBuilder: SimpleAnimatedSeriesBuilder.direct(
            _lastSwipeDirection,
            initialOffset: _lastDraggingOffset,
          ),
          boundsFrom: boundsFrom ?? bounds,
          boundsTo: boundsTo ?? bounds,
        );
        _swipeAnimationExpected = false;
      } else {
        animation = MoveAnimation.between(data, to, mapper);
      }
    }

    var fromToPointsDifferent = animation.series.any(
      (e) => !const DeepCollectionEquality().equals(
        e.points(AlwaysStoppedAnimation(0.0)).map((e) => Pair(e.dx.toStringAsFixed(5), e.dy.toStringAsFixed(5))),
        e.points(AlwaysStoppedAnimation(1.0)).map((e) => Pair(e.dx.toStringAsFixed(5), e.dy.toStringAsFixed(5)))
      ),
    );
    if (fromToPointsDifferent) {
      final moveAnimation = animation;
      _moveLayer = ChartMoveLayer(
        animation: moveAnimation,
        parent: moveAnimationController,
        theme: theme,
      );
      await moveAnimationController.forward(from: 0);
    }

    data = to;
    state.isSwitching = false;
    initLayers();
    notifyListeners();
  }

  @override
  void addListener(listener) {
    _listeners.add(listener);
    moveAnimationController.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _listeners.remove(listener);
    moveAnimationController.removeListener(listener);
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
