import 'package:flutter/material.dart';

import 'package:f_charts/f_charts.dart';
import 'package:lastfm_dashboard/extensions.dart';

enum ChartDateRange { month, day, hour }

class BaseChart extends StatelessWidget {
  final ChartData<DateTime, int> data;
  final void Function(ChartEntity<DateTime, int> entity) pointPressed;
  final ChartDateRange range;

  const BaseChart(
    this.data, {
    this.pointPressed,
    this.range,
  });

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
        : ChartTheme(background: theme.scaffoldBackgroundColor);
    chartTheme = chartTheme.copyWith(
      outerSpace: EdgeInsets.all(40),
    );
    return Chart(
      chartData: data,
      mapper: ChartMapper(
        DateMapper(formatter: (t) {
          switch (range) {
            case ChartDateRange.day:
              return t.toHumanable('d');
            case ChartDateRange.month:
              return t.toHumanable('MMM');
            case ChartDateRange.hour:
              return t.toHumanable('h');
            default:
              return t.toString();
          }
        }),
        IntMapper(),
      ),
      theme: chartTheme,
      pointPressed: pointPressed,
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
