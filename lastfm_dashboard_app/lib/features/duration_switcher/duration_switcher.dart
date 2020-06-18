import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics_ui/epic_state.dart';
import 'package:shared/models.dart';
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
  ChartViewModel get vm => Provider.of(context, listen: false);

  String getDurationName() {
    switch (vm.boundsPeriod) {
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
    subscribeVM<ChartViewModel>();
  }

  DatePeriod get nextPeriod {
    return vm.nextPeriod;
  }

  DatePeriod get previousPeriod {
    final i = DatePeriod.values.indexOf(vm.boundsPeriod);
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
                onPressed:
                    nextPeriod == null || vm.boundsMap[nextPeriod] == null
                        ? null
                        : () {
                            vm.boundsPeriod = nextPeriod;
                          },
              ),
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.remove, size: 18),
                onPressed: previousPeriod == null ||
                        vm.boundsMap[previousPeriod] == null
                    ? null
                    : () {
                        vm.boundsPeriod = previousPeriod;
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
