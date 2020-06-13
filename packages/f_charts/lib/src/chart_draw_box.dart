import 'package:f_charts/widget_models.dart';
import 'package:f_charts/layers.dart';
import 'package:flutter/material.dart';

class ChartPaint extends CustomPainter {
  final EdgeInsets chartPadding;
  final List<Layer> layers;

  ChartPaint({
    this.layers,
    this.chartPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset(0,0) & size);
    canvas.translate(chartPadding.left, chartPadding.top);
    final newSize = Size(
      size.width - chartPadding.left - chartPadding.right,
      size.height - chartPadding.top - chartPadding.bottom,
    );
    for (final layer in layers) {
      if (layer.shouldDraw()) layer.draw(canvas, newSize);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ChartDrawBox extends StatelessWidget {
  final ChartController controller;
  final ChartGestureHandler modeHandler;
  ChartDrawBox(this.controller, this.modeHandler);

  Widget gestureDetector(BuildContext context) {
    void Function(DragDownDetails) onHorizontalDragDown;
    void Function(TapUpDetails) onTapUp;
    void Function(DragUpdateDetails) onHorizontalDragUpdate;
    void Function(DragEndDetails) onHorizontalDragEnd;

    onHorizontalDragDown = (d) {
      final offset = controller.translateOuterOffset(d.localPosition);
      modeHandler.tapDown(offset);
    };

    onTapUp = (d) {
      modeHandler.tapUp();
    };

    onHorizontalDragEnd = (_) {
      modeHandler.tapUp();
    };

    onHorizontalDragUpdate = (d) {
      final offset = controller.translateOuterOffset(d.localPosition);
      modeHandler.tapMove(offset, d.delta);
    };

    return GestureDetector(
      onHorizontalDragDown: onHorizontalDragDown,
      onTapUp: onTapUp,
      onHorizontalDragEnd: onHorizontalDragEnd,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
    );
  }

  @override
  Widget build(BuildContext context) {
    modeHandler.attachContext(context);
    return CustomPaint(
      size: Size.infinite,
      foregroundPainter: ChartPaint(
        layers: controller.layers,
        chartPadding: controller.theme.outerSpace,
      ),
      child: gestureDetector(context),
    );
  }
}
