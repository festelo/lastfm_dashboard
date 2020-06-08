import 'package:flutter/material.dart';

import 'package:f_charts/f_charts.dart';

class BaseChart extends StatelessWidget {
  final ChartData<DateTime, int> data;

  const BaseChart(this.data);

  @override
  Widget build(BuildContext context) {
    return Chart(
      chartData: data,
      mapper: ChartMapper(DateMapper(), IntMapper()),
      gestureHandlerBuilder: const HybridHandlerBuilder(),
      markersPointer: ChartMarkersPointer(
        DateTimeMarkersPointer(
          Duration(days: 30),
        ),
        IntMarkersPointer(100),
      ),
    );
  }
}
