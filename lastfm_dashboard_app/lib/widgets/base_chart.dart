import 'package:flutter/material.dart';

import 'package:f_charts/f_charts.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:shared/models.dart';

class BaseChart extends StatelessWidget {
  final ChartData<DateTime, int> previousData;
  final ChartData<DateTime, int> nextData;
  final ChartData<DateTime, int> data;
  final void Function(ChartEntity<DateTime, int> entity) pointPressed;
  final BeforeSwipeCallback<DateTime, int> beforeSwipe;
  final AfterSwipeCallback<DateTime, int> afterSwipe;
  final DatePeriod range;
  final Pair<DateTime> bounds;

  const BaseChart(
    this.data, {
    this.pointPressed,
    this.range,
    this.beforeSwipe,
    this.afterSwipe,
    this.bounds,
    this.previousData,
    this.nextData,
  });

  String get title {
    switch (range) {
      case DatePeriod.month:
        return bounds.a.toHumanable('y');
      case DatePeriod.week:
        return bounds.a.toHumanable('MMM y');
      case DatePeriod.day:
        return bounds.b
            .toHumanable('# - d MMM y')
            .replaceFirst('#', bounds.a.day.toString());
      case DatePeriod.hour:
        return bounds.a.toHumanable('E, d MMM y');
      default:
        return bounds.a.toString();
    }
  }

  String formatDate(DateTime t) {
    switch (range) {
      case DatePeriod.day:
        return t.toHumanable('d');
      case DatePeriod.month:
        return t.toHumanable('MMM');
      case DatePeriod.week:
        return t.toHumanable('d');
      case DatePeriod.hour:
        return t.toHumanable('H');
      default:
        return t.toString();
    }
  }

  int get yShowEvery {
    switch (range) {
      case DatePeriod.month:
        return 2;
      case DatePeriod.hour:
        return 3;
      default:
        return 1;
    }
  }

  int getChartYStep() {
    switch (range) {
      case DatePeriod.month:
        return 300;
      case DatePeriod.week:
        return 100;
      case DatePeriod.day:
        return 10;
      case DatePeriod.hour:
        return 4;
      default:
        return 1;
    }
  }

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
        DateMapper(formatter: formatDate),
        IntMapper(),
      ),
      title: title,
      drag: DragController(
        beforeSwipe: beforeSwipe,
        afterSwipe: afterSwipe,
        leftData: previousData,
        rightData: nextData,
      ),
      theme: chartTheme,
      pointPressed: pointPressed,
      gestureHandlerBuilder: const HybridHandlerBuilder(),
      markersPointer: ChartMarkersPointer(
        DatePeriodMarkersPointer(range, showEvery: yShowEvery),
        IntMarkersPointer(
          getChartYStep(),
        ),
      ),
    );
  }
}
