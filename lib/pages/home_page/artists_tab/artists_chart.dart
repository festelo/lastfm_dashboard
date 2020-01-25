import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/base_chart.dart';

class ArtistsChart extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: BaseChart([
        ChartSeries()
      ])
    );
  }
}