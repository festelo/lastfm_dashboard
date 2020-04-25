import 'package:flutter/material.dart';

import 'package:charts_flutter/flutter.dart' as c;
import 'package:charts_common/src/common/palette.dart';

enum ChartColorr { orange, red, green, blue, pink }

class ChartColor {
  final Color value;
  c.Color get chartColor => c.Color(
        a: value.alpha,
        r: value.red,
        g: value.green,
        b: value.blue,
      );
  ChartColor(this.value);
}

class ChartSeries {
  final List<ChartEntity> entities;
  final ChartColor color;
  final String name;

  const ChartSeries({this.entities, this.color, this.name});
}

class ChartEntity {
  final DateTime date;
  final int scrobbles;

  const ChartEntity({this.scrobbles, this.date});
}

class BaseChart extends StatelessWidget {
  static List<c.Series<ChartEntity, DateTime>> _convertChartSeries(
    List<ChartSeries> series,
  ) {
    return series
        .map((s) => c.Series<ChartEntity, DateTime>(
              id: s.name,
              displayName: s.name,
              domainFn: (ChartEntity entity, _) => entity.date,
              measureFn: (ChartEntity entity, _) => entity.scrobbles,
              data: s.entities,
              colorFn: (_, __) {
                return s.color.chartColor;
              },
            ))
        .toList();
  }

  final List<ChartSeries> series;

  const BaseChart(this.series);

  @override
  Widget build(BuildContext context) {
    return c.TimeSeriesChart(
      _convertChartSeries(series),
      animate: false,
      behaviors: [c.PanAndZoomBehavior()],
      defaultInteractions: false,
      defaultRenderer: c.LineRendererConfig(includePoints: true),
      primaryMeasureAxis: const c.NumericAxisSpec(),
    );
  }
}
