import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics_ui/epic_bloc_state_mixin.dart';
import 'package:lastfm_dashboard/features/base_chart/chart_bloc.dart';
import 'package:shared/models.dart';

class DurationSwitcher<T extends ChartBloc> extends StatefulWidget {
  final double width;
  final double height;
  final double margin;

  const DurationSwitcher(
      {Key key, this.width = 160, this.height = 40, this.margin = 20})
      : super(key: key);

  @override
  _DurationSwitcherState createState() => _DurationSwitcherState<T>();
}

class _DurationSwitcherState<T extends ChartBloc>
    extends State<DurationSwitcher>
    with EpicBlocStateMixin<DurationSwitcher, T>{
  ChartViewModel get vm => bloc.vm;

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

  DatePeriod get nextPeriod {
    return vm.innerPeriod;
  }

  DatePeriod get previousPeriod {
    final i = vm.supportedPeriods.indexOf(vm.period);
    final newI = i - 1;
    if (newI == -1) return null;
    return vm.supportedPeriods[newI];
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
                onPressed: null,
              ),
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.remove, size: 18),
                onPressed: previousPeriod == null
                    ? null
                    : () {
                        bloc.pushEvent(MovePeriod(
                            period: previousPeriod,
                            periodStart:
                                previousPeriod.normalize(vm.periodStart)));
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
