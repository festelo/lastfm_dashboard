import 'dart:async';

import 'package:f_charts/widgets.dart';
import 'package:f_charts/widget_models.dart';
import 'package:f_charts/data_models.dart';
import 'package:flutter/material.dart';

class Chart<T1, T2> extends StatefulWidget {
  final ChartData<T1, T2> chartData;
  final ChartMapper<T1, T2> mapper;
  final ChartBounds<T1, T2> bounds;
  final ChartMarkersPointer<T1, T2> markersPointer;
  final ChartTheme theme;
  final ChartGestureHandlerBuilder gestureHandlerBuilder;
  final String title;

  final PointPressedCallback<T1, T2> pointPressed;
  final SwipedCallback swiped;

  Chart({
    @required this.chartData,
    @required this.mapper,
    this.theme = const ChartTheme(),
    this.pointPressed,
    this.markersPointer,
    this.swiped,
    this.title,
    this.gestureHandlerBuilder = const PointerHandlerBuilder(),
    this.bounds,
  }) : assert((theme.yMarkers != null || theme.xMarkers != null) &&
            markersPointer != null);
  @override
  _ChartState createState() => _ChartState<T1, T2>();
}

class _ChartState<T1, T2> extends State<Chart<T1, T2>>
    with SingleTickerProviderStateMixin {
  ChartController<T1, T2> chartController;
  ChartGestureHandler gestureHandler;

  @override
  void initState() {
    super.initState();
    chartController = ChartController<T1, T2>(
      widget.chartData,
      widget.mapper,
      widget.markersPointer,
      this,
      state: ChartState()..title = widget.title,
      theme: widget.theme,
      pointPressed: widget.pointPressed,
      swiped: widget.swiped,
      bounds: widget.bounds,
    );
    gestureHandler = widget.gestureHandlerBuilder.build(chartController);
    chartController.initLayers();
    chartController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(Chart<T1, T2> oldWidget) {
    super.didUpdateWidget(oldWidget);
    asyncUpdate(oldWidget);
  }

  Completer _updateCompleter;

  Future<void> asyncUpdate(Chart<T1, T2> oldWidget) async {
    await _updateCompleter?.future;
    if (oldWidget.chartData != widget.chartData) {
      _updateCompleter = Completer();
      await startAnimation(
        widget.chartData,
        boundsFrom: oldWidget.bounds,
        boundsTo: widget.bounds,
      );
      _updateCompleter.complete();
    }
    if (oldWidget.theme != widget.theme) {
      chartController.theme = widget.theme;
    }
    if (oldWidget.markersPointer != widget.markersPointer) {
      chartController.markersPointer = widget.markersPointer;
    }
    if (oldWidget.mapper != widget.mapper) {
      chartController.mapper = widget.mapper;
    }
    if (oldWidget.pointPressed != widget.pointPressed) {
      chartController.pointPressed = widget.pointPressed;
    }
    if (oldWidget.swiped != widget.swiped) {
      chartController.swiped = widget.swiped;
    }
    if (oldWidget.bounds != widget.bounds) {
      chartController.bounds = widget.bounds;
    }
    if (oldWidget.title != widget.title) {
      chartController.state.title = widget.title;
    }
    chartController.redraw();
  }

  @override
  void dispose() {
    super.dispose();
    chartController?.dispose();
  }

  Future<void> startAnimation(
    ChartData<T1, T2> to, {
    ChartBounds<T1, T2> boundsFrom,
    ChartBounds<T1, T2> boundsTo,
  }) async {
    await chartController.move(to);
  }

  @override
  Widget build(BuildContext context) {
    return ChartDrawBox(chartController, gestureHandler);
  }
}
