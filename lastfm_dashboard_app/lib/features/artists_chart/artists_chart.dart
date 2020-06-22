import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics_ui/epic_bloc_state_mixin.dart';
import 'package:lastfm_dashboard/features/base_chart/chart_bloc.dart';
import 'package:lastfm_dashboard/widgets/base_chart.dart';
import 'package:shared/models.dart';

import 'artists_chart_bloc.dart';

class ArtistsChart extends StatefulWidget {
  @override
  _ArtistsChartState createState() => _ArtistsChartState();
}

class _ArtistsChartState extends State<ArtistsChart>
    with EpicBlocStateMixin<ArtistsChart, ArtistsChartBloc> {
  ArtistsChartViewModel get vm => bloc.vm;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!vm.initialized)
      child = Center(
        child: CircularProgressIndicator(),
      );
    else if (vm.currentData.series.isEmpty)
      child = Container();
    else
      child = BaseChart(vm.currentData,
          range: vm.interval,
          bounds: Pair(vm.periodStart, vm.periodEnd),
          previousData: vm.previousData,
          nextData: vm.nextData, beforeSwipe: (a) {
        if (a == AxisDirection.left) {
          return vm.period
                  .addOffset(vm.periodStart, 1)
                  .isBefore(vm.allTimeBounds.b) &&
              vm.nextData != null;
        }
        if (a == AxisDirection.right) {
          return vm.period
                  .addOffset(vm.periodStart, -1)
                  .isAfter(vm.allTimeBounds.a) &&
              vm.previousData != null;
        }
        return false;
      }, afterSwipe: (_, a) {
        if (a == AxisDirection.up || a == AxisDirection.down) return false;
        if (a == AxisDirection.right) {
          bloc.pushEvent(MoveBack());
        }
        if (a == AxisDirection.left) {
          bloc.pushEvent(MoveNext());
        }
        return true;
      },
          pointPressed: vm.innerPeriod == null
              ? null
              : (e) {
                  if (!vm.allTimeBounds.contains(e.abscissa)) {
                    return;
                  }
                  bloc.pushEvent(MovePeriod(
                    periodStart: e.abscissa,
                    period: vm.innerPeriod,
                  ));
                });

    return child;
  }
}
