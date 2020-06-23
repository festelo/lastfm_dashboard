import 'dart:async';

import 'package:f_charts/f_charts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

DateTime previous;

class DragController<T1, T2> {
  final BeforeSwipeCallback<T1, T2> beforeSwipe;
  final AfterSwipeCallback<T1, T2> afterSwipe;
  final ChartData<T1, T2> leftData;
  final ChartData<T1, T2> rightData;

  AnimationController animationController;
  ChartController controller;

  DragController({
    this.beforeSwipe,
    this.afterSwipe,
    this.leftData,
    this.rightData,
  });

  void updateController(ChartController controller) {
    this.controller = controller;
    animationController = AnimationController(
        vsync: controller.vsync, duration: Duration(milliseconds: 200));
  }

  void start() {
    controller.state.isDragging = true;
  }

  void addOffset(Offset offset) {
    controller.state.draggingOffset += offset;
    controller.state.isDragging = true;
    controller.notifyListeners();
  }

  void _returnFromDrag(RelativeOffset relative) {
    final tween = ChartTween.single(
      controller.data,
      controller.mapper,
      animatedSeriesBuilder: SimpleAnimatedSeriesBuilderSingle.direct(
        initialOffset: relative,
      ),
    );
    final animation = animationController.drive(tween);
    controller.move(
        controller.data, animation, () => animationController.forward(from: 0));
  }

  void _end() {
    controller.state.isDragging = false;
    controller.state.draggingOffset = Offset(0, 0);
  }

  void end() {
    _end();
    controller.notifyListeners();
  }

  void endWithAnimation(Velocity velocity, Size size) {
    var draggingOffset = controller.state.draggingOffset;

    final relative = RelativeOffset.withViewport(
      draggingOffset.dx,
      draggingOffset.dy,
      size,
    );

    if (controller.state.isSwitching) {
      end();
      return;
    }

    if (draggingOffset.dx.abs() < 40) {
      _returnFromDrag(relative);
      controller.notifyListeners();
      return;
    }

    var axis = draggingOffset.dx < 0 ? AxisDirection.left : AxisDirection.right;
    handleMove(axis, relative, velocity, size);
  }

  Future<void> handleMove(
    AxisDirection axis,
    RelativeOffset offset,
    Velocity velocity,
    Size size,
  ) async {
    ChartData<T1, T2> newData;

    switch (axis) {
      case AxisDirection.right:
        newData = leftData;
        break;
      case AxisDirection.left:
        newData = rightData;
        break;
      default:
        newData = null;
        break;
    }

    final allowed =
        newData != null && (beforeSwipe == null || beforeSwipe(axis));

    if (!allowed) {
      _returnFromDrag(offset);
      return;
    }

    final animationBuilder = SimpleAnimatedSeriesBuilder.direct(
      axis,
      initialOffset: offset,
      curve: Curves.linear,
    );

    final tween = ChartTween.between(
        controller.data, newData, controller.mapper,
        animatedSeriesBuilder: animationBuilder);

    final animation = animationController.drive(tween);
    await controller.move(
      newData,
      animation,
      () => _animateWithPhysics(velocity, size),
    );
    if (afterSwipe != null) afterSwipe(newData, axis);
  }

  Future<void> _animateWithPhysics(
    Velocity velocity,
    Size size,
  ) async {
    final pixelsPerSecond = velocity.pixelsPerSecond;
    final unitsPerSecondX = pixelsPerSecond.dx;
    final unitVelocity = unitsPerSecondX / size.width;
    final simulation = SpringSimulation(
      SpringDescription(
        mass: 20.0,
        stiffness: 4,
        damping: 2,
      ),
      0,
      1,
      unitVelocity,
    );
    animationController.animateWith(simulation);
  }
}
