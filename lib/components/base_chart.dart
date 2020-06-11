import 'package:flutter/material.dart';

import 'package:f_charts/f_charts.dart';
import 'package:lastfm_dashboard/extensions.dart';

class BaseChart extends StatelessWidget {
  final ChartData<DateTime, int> data;

  const BaseChart(this.data);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var chartTheme = theme.brightness == Brightness.dark
        ? ChartTheme().copyWith(
          background: theme.scaffoldBackgroundColor,
          xPointer: LineTheme(color: theme.backgroundColor, width: 2),
          line: LineTheme(width: 2, color: theme.accentColor),
          xAxis: LineTheme(color: theme.backgroundColor),
          yAxis: LineTheme(color: theme.backgroundColor),
          point: CircleTheme(color: theme.accentColor, radius: 1),
          yMarkers: MarkersTheme(
            line: LineTheme(color: theme.backgroundColor.withOpacity(0.3)),
          ),
        )
        : ChartTheme(
          background: theme.scaffoldBackgroundColor
        );
    chartTheme = chartTheme.copyWith(
      outerSpace: EdgeInsets.all(40),
    );
    return Chart(
      chartData: data,
      mapper: ChartMapper(
        DateMapper(formatter: (t) => t.toHumanable('MMM')),
        IntMapper(),
      ),
      theme: chartTheme,
      gestureHandlerBuilder: const HybridHandlerBuilder(),
      markersPointer: ChartMarkersPointer(
        DateTimeMarkersPointer(
          Duration(days: 60),
        ),
        IntMarkersPointer(100),
      ),
    );
  }
}
