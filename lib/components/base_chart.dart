import 'package:flutter/material.dart';

import 'package:charts_flutter/flutter.dart' as charts;

enum ChartColor { orange, red, green, blue, pink }

class ChartSeries {
  final List<ChartEntity> entities;
  final ChartColor color;
  final String name;

  ChartSeries({this.entities, this.color, this.name});
}

class ChartEntity {
  final DateTime date;
  final int scrobbles;

  ChartEntity({this.scrobbles, this.date});
}

class BaseChart extends StatelessWidget {
  BaseChart(this.series);

  final List<ChartSeries> series;

  static List<charts.Series<ChartEntity, DateTime>> _convertChartSeries(
    List<ChartSeries> series,
  ) {
    return series
        .map(
          (s) => charts.Series<ChartEntity, DateTime>(
            id: s.name,
            displayName: s.name,
            domainFn: (ChartEntity entity, _) => entity.date,
            measureFn: (ChartEntity entity, _) => entity.scrobbles,
            data: s.entities,
            colorFn: (_, __) {
              if (s.color == ChartColor.orange)
                return charts.MaterialPalette.deepOrange.shadeDefault;

              if (s.color == ChartColor.red)
                return charts.MaterialPalette.red.shadeDefault;

              if (s.color == ChartColor.green)
                return charts.MaterialPalette.green.shadeDefault;

              if (s.color == ChartColor.blue)
                return charts.MaterialPalette.blue.shadeDefault;

              if (s.color == ChartColor.pink)
                return charts.MaterialPalette.pink.shadeDefault;

              return charts.MaterialPalette.transparent;
            },
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: charts.TimeSeriesChart(
        _convertChartSeries(series),
        animate: false,
        behaviors: [
          charts.PanBehavior(),
          charts.SeriesLegend(),
        ],
        defaultInteractions: false,
        defaultRenderer: charts.LineRendererConfig(includePoints: true),
        domainAxis: charts.DateTimeAxisSpec(
          viewport: charts.DateTimeExtents(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          ),
        ),
        primaryMeasureAxis: charts.NumericAxisSpec(
          viewport: charts.NumericExtents(0, 100),
        ),
      ),
    );
  }
}
