import 'package:f_charts/widget_models.dart';
import 'package:f_charts/utils.dart';
import 'package:flutter/material.dart';

abstract class ChartGestureHandlerBuilder {
  const ChartGestureHandlerBuilder();
  ChartGestureHandler build(ChartController controller);
}

abstract class ChartGestureHandler {
  final ChartController _controller;
  BuildContext _context;

  bool _tapped = false;
  Offset _location;
  Size get _size => _context?.size;
  ChartGestureHandler(this._controller);

  void attachContext(BuildContext context) {
    this._context = context;
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
  void tapUp() {
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
  bool tapHandled;

  @override
  bool tapDown(Offset offset) {
    super.tapDown(offset);
    tapStartTime = DateTime.now();
    tapHandled = false;
    this.offset = offset;
    if (_controller.theme.xPointer != null && _controller.swiped != null) {
      behavior = HybridBehavior.gesture;
      handleTapDelay(offset);
      return true;
    }
    if (_controller.swiped != null) {
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
      _controller.endDrag(_size, withAnimation: false);
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
      _controller.addDraggingOffset(delta);
    }
  }

  @override
  void tapUp() {
    super.tapUp();
    final curTime = DateTime.now();
    tapHandled = true;
    if (curTime.difference(tapStartTime).inMilliseconds < 200 &&
        (offset - _location).abs() < Offset(5, 20)) {
      if (super.interact(offset)) return;
    }
    if (behavior == HybridBehavior.pointer) {
      _controller.setXPointerPosition(null);
    } else if (behavior == HybridBehavior.gesture) {
      if (!_controller.state.isDragging) return;
      _controller.endDrag(_size);
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
  void tapUp() {
    super.tapUp();
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
    _controller.startDragging();
    return true;
  }

  @override
  void tapMove(Offset offset, Offset delta) async {
    super.tapMove(offset, delta);
    if (!_controller.state.isDragging) return;
    _controller.addDraggingOffset(delta);
  }

  @override
  void tapUp() {
    super.tapUp();
    if (!_controller.state.isDragging) return;
    _controller.endDrag(_size);
  }
}
