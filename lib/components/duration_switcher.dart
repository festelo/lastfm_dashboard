import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics/epic_state.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/view_models/chart_view_model.dart';
import 'package:provider/provider.dart';

class DurationSwitcher extends StatefulWidget {
  final double width;
  final double height;
  final double margin;

  const DurationSwitcher(
      {Key key, this.width = 160, this.height = 40, this.margin = 20})
      : super(key: key);

  @override
  _DurationSwitcherState createState() => _DurationSwitcherState();
}

class _DurationSwitcherState extends EpicState<DurationSwitcher> {
  final durationNames = [
    'Hour',
    'Day',
    'Week',
    'Month',
  ];

  ChartViewModel vm;

  String getDurationName() {
    switch (vm.period) {
      case DatePeriod.day:
        return 'Day';
      case DatePeriod.week:
        return 'Week';
      case DatePeriod.hour:
        return 'Hour';
      case DatePeriod.month:
        return 'Month';
      default:
        return 'Month';
    }
  }

  @override
  FutureOr<void> onLoad() {
    vm = context.read<ChartViewModel>();
    subscribeVM<ChartViewModel>(vm);
  }

  DatePeriod get nextPeriod {
    final i = DatePeriod.values.indexOf(vm.period);
    final newI = i + 1;
    if (newI == DatePeriod.values.length) return null;
    return DatePeriod.values[newI];
  }

  DatePeriod get previousPeriod {
    final i = DatePeriod.values.indexOf(vm.period);
    final newI = i - 1;
    if (newI == -1) return null;
    return DatePeriod.values[newI];
  }

  @override
  Widget build(BuildContext context) {
    final text = getDurationName();
    return Card(
      color: Theme.of(context).canvasColor,
      margin: EdgeInsets.all(widget.margin),
      child: Container(
        height: 40,
        width: 160,
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText2,
              ),
              width: 50,
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.add, size: 18),
                onPressed: nextPeriod == null || vm.bounds[nextPeriod] == null
                    ? null
                    : () {
                        vm.period = nextPeriod;
                      },
              ),
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.remove, size: 18),
                onPressed:
                    previousPeriod == null || vm.bounds[previousPeriod] == null
                        ? null
                        : () {
                            vm.period = previousPeriod;
                          },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
