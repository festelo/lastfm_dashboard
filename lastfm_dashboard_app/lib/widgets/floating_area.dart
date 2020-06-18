import 'package:flutter/material.dart';

class FloatingArea extends StatefulWidget {
  final WidgetBuilder childBuilder;
  final Alignment alignment;

  const FloatingArea(
    this.childBuilder, {
    this.alignment = Alignment.topLeft,
  });

  @override
  _FloatingAreaState createState() => _FloatingAreaState();
}

class _FloatingAreaState extends State<FloatingArea> {
  var offsetX = 0.0;
  var offsetY = 0.0;
  final childKey = GlobalKey();
  var leftDiff = 0.0;
  var topDiff = 0.0;
  var panning = false;
  var padding = EdgeInsets.all(0);
  Alignment localAlign;

  @override
  void initState() {
    super.initState();
    localAlign = widget.alignment;
  }

  void updatePadding() {
    if (localAlign != Alignment.topLeft) {
      localAlign = Alignment.topLeft;
    }
    setState(() {
      padding = EdgeInsets.only(
        left: offsetX,
        top: offsetY
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: GestureDetector(
        child: Container(
          padding: padding,
          alignment: localAlign,
          child: GestureDetector(
            child: Container(
              child: Builder(
                key: childKey,
                builder: widget.childBuilder,
              ),
            ),
          ),
        ),
        onPanStart: (e) {
          final childRenderObject = childKey.currentContext.findRenderObject();
          final translation =
              childRenderObject.getTransformTo(null)?.getTranslation();
          if (translation == null || childRenderObject.paintBounds == null)
            return;
          final childRect = childRenderObject.paintBounds
              .shift(Offset(translation.x, translation.y));

          final x = e.globalPosition.dx;
          final y = e.globalPosition.dy;

          final leftDiff = x - childRect.left;
          final topDiff = y - childRect.top;

          if (leftDiff < 0 || leftDiff > childRect.width) return;
          if (topDiff < 0 || topDiff > childRect.height) return;

          this.leftDiff = leftDiff;
          this.topDiff = topDiff;
          panning = true;
        },
        onPanEnd: (e) {
          panning = false;
        },
        onPanUpdate: (e) {
          if (!panning) return;
          final width = childKey.currentContext.size.width;
          final height = childKey.currentContext.size.height;
          final newOffsetX = e.localPosition.dx - leftDiff;
          final newOffsetY = e.localPosition.dy - topDiff;
          var approvedOffsetX = offsetX;
          var approvedOffsetY = offsetY;
          if (newOffsetX >= 0 && newOffsetX <= context.size.width - width) {
            approvedOffsetX = newOffsetX;
          }
          if (newOffsetY >= 0 && newOffsetY <= context.size.height - height) {
            approvedOffsetY = newOffsetY;
          }
          offsetX = approvedOffsetX;
          offsetY = approvedOffsetY;
          updatePadding();
        },
      ),
    );
  }
}
