import 'package:flutter/material.dart';

import 'package:charts_flutter/flutter.dart' as c;

enum ChartColor {
  orange,
  red,
  green,
  blue,
  pink
}

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
  static List<c.Series<ChartEntity, DateTime>> _convertChartSeries(List<ChartSeries> series) {
    return series.map((s) =>
      c.Series<ChartEntity, DateTime>(
        id: s.name,
        displayName: s.name,
        domainFn: (ChartEntity entity, _) => entity.date,
        measureFn: (ChartEntity entity, _) => entity.scrobbles,
        data: s.entities,
        colorFn: (_, __) {
          if (s.color == ChartColor.orange)
            return c.MaterialPalette.deepOrange.shadeDefault;
          
          if (s.color == ChartColor.red)
            return c.MaterialPalette.red.shadeDefault;

          if (s.color == ChartColor.green)
            return c.MaterialPalette.green.shadeDefault;

          if (s.color == ChartColor.blue)
            return c.MaterialPalette.blue.shadeDefault;

          if (s.color == ChartColor.pink)
            return c.MaterialPalette.pink.shadeDefault;
          
          return c.MaterialPalette.transparent;
        },
      )
    );
  }

  final List<ChartSeries> series;

  BaseChart(this.series);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: c.LineChart(_convertChartSeries(series),
        animate: false,
        behaviors: [
          c.PanBehavior(),
          c.SeriesLegend()
        ],
        defaultInteractions: false,
        defaultRenderer: c.LineRendererConfig(includePoints: true),
        domainAxis: c.DateTimeAxisSpec(
          viewport: c.DateTimeExtents(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          )
        ),
        primaryMeasureAxis: c.NumericAxisSpec(
          viewport: c.NumericExtents(0, 100)
        ),
      )
    );
  }
}