import 'package:f_charts/widget_models.dart';
import 'package:f_charts/utils.dart';
import 'package:flutter/material.dart';

abstract class ChartGestureHandlerBuilder {
  const ChartGestureHandlerBuilder();
  ChartGestureHandler build(ChartController controller);
}

abstract class ChartGestureHandler {
  final ChartController _controller;

  bool _tapped = false;
  Offset _location;
  Size _size;
  ChartGestureHandler(this._controller);

  void attachContext(BuildContext context) {
    _size = MediaQuery.of(context).size;
  }

  bool interact(Offset offset) {
    if (_controller.tap(offset)) return true;
    return false;
  }

  @mustCallSuper
  bool tapDown(Offset offset) {
    _location = offset;
    _tapped = true;
    return true;
  }

  @mustCallSuper
  void tapUp(Offset offset) {
    _location = offset;
    _tapped = false;
  }

  @mustCallSuper
  void dragEnd(Velocity velocity) {
    _tapped = false;
  }

  @mustCallSuper
  void tapMove(Offset offset, Offset delta) {
    _location = offset;
  }
}

class HybridHandlerBuilder extends ChartGestureHandlerBuilder {
  const HybridHandlerBuilder();
  HybridHandler build(ChartController controller) {
    return HybridHandler(controller);
  }
}

enum HybridBehavior { pointer, gesture, none }

class HybridHandler extends ChartGestureHandler {
  HybridBehavior behavior;

  HybridHandler(ChartController controller) : super(controller);

  DateTime tapStartTime;
  Offset offset;
  Offset startOffset;
  bool tapHandled;

  @override
  bool tapDown(Offset offset) {
    super.tapDown(offset);
    tapStartTime = DateTime.now();
    tapHandled = false;
    startOffset = offset;
    this.offset = offset;
    if (_controller.theme.xPointer != null && _controller.drag != null) {
      behavior = HybridBehavior.gesture;
      handleTapDelay(offset);
      return true;
    }
    if (_controller.drag != null) {
      behavior = HybridBehavior.gesture;
      return true;
    }
    if (_controller.theme.xPointer != null) {
      behavior = HybridBehavior.pointer;
      _controller.setXPointerPosition(offset.dx);
      return true;
    }
    return false;
  }

  Future<void> handleTapDelay(Offset offset) async {
    await Future.delayed(Duration(milliseconds: 200));
    if (!tapHandled && (offset - _location).abs() < Offset(5, 20)) {
      behavior = HybridBehavior.pointer;
      _controller.setXPointerPosition(offset.dx);
      _controller.drag.end();
    }
  }

  @override
  void tapMove(Offset offset, Offset delta) async {
    super.tapMove(offset, delta);
    this.offset = offset;
    if (!_tapped) return;

    if (behavior == HybridBehavior.pointer) {
      _controller.setXPointerPosition(offset.dx);
    } else if (behavior == HybridBehavior.gesture) {
      _controller.drag.addOffset(delta);
    }
  }

  @override
  void tapUp(Offset offset) {
    super.tapUp(offset);
    final curTime = DateTime.now();
    tapHandled = true;
    if (curTime.difference(tapStartTime).inMilliseconds < 200 &&
        (startOffset - _location).abs() < Offset(5, 20)) {
      if (super.interact(offset)) return;
    }
    if (behavior == HybridBehavior.pointer) {
      _controller.setXPointerPosition(null);
    }
  }

  @override
  void dragEnd(Velocity velocity) {
    super.dragEnd(velocity);
    if (behavior == HybridBehavior.pointer) {
      _controller.setXPointerPosition(null);
    } else if (behavior == HybridBehavior.gesture) {
      if (!_controller.state.isDragging) return;
      _controller.drag.endWithAnimation(velocity, _size);
    }
  }
}

class PointerHandlerBuilder extends ChartGestureHandlerBuilder {
  const PointerHandlerBuilder();
  PointerHandler build(ChartController controller) {
    return PointerHandler(controller);
  }
}

class PointerHandler extends ChartGestureHandler {
  PointerHandler(ChartController controller) : super(controller);

  @override
  bool tapDown(Offset offset) {
    if (!super.tapDown(offset)) return false;
    if (_controller.state.isSwitching) return false;
    _controller.setXPointerPosition(offset.dx);
    return true;
  }

  @override
  void tapMove(Offset offset, Offset delta) async {
    super.tapMove(offset, delta);
    _controller.setXPointerPosition(offset.dx);
  }

  @override
  void tapUp(Offset offset) {
    super.tapUp(offset);
    _controller.setXPointerPosition(null);
  }

  @override
  void dragEnd(Velocity velocity) {
    super.dragEnd(velocity);
    _controller.setXPointerPosition(null);
  }
}

class GestureHandlerBuilder extends ChartGestureHandlerBuilder {
  const GestureHandlerBuilder();
  GestureHandler build(ChartController controller) {
    return GestureHandler(controller);
  }
}

class GestureHandler extends ChartGestureHandler {
  GestureHandler(ChartController controller) : super(controller);

  @override
  bool tapDown(Offset offset) {
    if (!super.tapDown(offset)) return false;
    if (_controller.state.isSwitching) return false;
    _controller.drag.start();
    return true;
  }

  @override
  void tapMove(Offset offset, Offset delta) async {
    super.tapMove(offset, delta);
    if (!_controller.state.isDragging) return;
    _controller.drag.addOffset(delta);
  }

  @override
  void tapUp(Offset offset) {
    super.tapUp(offset);
    if (!_controller.state.isDragging) return;
    _controller.drag.end();
  }

  @override
  void dragEnd(Velocity velocity) {
    super.dragEnd(velocity);
    if (!_controller.state.isDragging) return;
    _controller.drag.endWithAnimation(velocity, _size);
  }
}
