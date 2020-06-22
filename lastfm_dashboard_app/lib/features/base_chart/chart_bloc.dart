import 'package:epic/epic.dart';
import 'package:f_charts/data_models.dart';
import 'package:lastfm_dashboard/epics_ui/epic_bloc.dart';
import 'package:shared/models.dart';
import 'chart_repository.dart';

class ChartViewModel {
  DateBounds allTimeBounds;

  DateTime periodStart;
  DatePeriod period;

  final List<DatePeriod> supportedPeriods = [
    DatePeriod.year,
    DatePeriod.month,
    DatePeriod.week,
    DatePeriod.day,
  ];

  final Map<DatePeriod, DatePeriod> datePeriodToInterval = {
    DatePeriod.year: DatePeriod.month,
    DatePeriod.month: DatePeriod.week,
    DatePeriod.week: DatePeriod.day,
    DatePeriod.day: DatePeriod.hour,
  };

  DatePeriod get innerPeriod {
    final currentPeriodIndex = supportedPeriods.indexOf(period);
    final innerPeriodIndex = currentPeriodIndex + 1;
    if (innerPeriodIndex == supportedPeriods.length) return null;
    return supportedPeriods[innerPeriodIndex];
  }
  DatePeriod get interval  {
    if (period == null) return null;
    return datePeriodToInterval[period];
  }

  ChartData<DateTime, int> previousData;
  ChartData<DateTime, int> nextData;

  ChartData<DateTime, int> currentData;

  bool refreshing = false;
  bool initialized = false;

  ChartViewModel({
    this.allTimeBounds,
    this.period,
    this.periodStart,
    this.previousData,
    this.nextData,
    this.currentData,
  });
}

class MoveNext {}

class MoveBack {}

class MovePeriod {
  final DatePeriod period;
  final DateTime periodStart;
  MovePeriod({this.period, this.periodStart});
}

abstract class ChartBloc extends EpicBloc {
  ChartViewModel get vm;
  ChartBloc(EpicManager manager) : super(manager);

  Future<bool> handleBase(event, ChartRepository rep) async {
    if (event is InitStateEvent) {
      await initState(rep);
      return true;
    }
    if (event is MovePeriod) {
      await wrapInLoading(movePeriod(
        rep,
        event.period,
        event.periodStart,
      ));
      return true;
    }
    if (event is MoveBack) {
      await wrapInLoading(moveBack(rep));
      return true;
    }
    if (event is MoveNext) {
      await wrapInLoading(moveNext(rep));
      return true;
    }
    return false;
  }

  Future<void> wrapInLoading(Future<void> fun) async {
    vm.refreshing = true;
    notify();
    try {
      await fun;
    } finally {
      vm.refreshing = false;
    }
  }

  Future<void> initState(ChartRepository rep) async {
    assert(vm != null);
    assert(vm.interval != null && vm.period != null);
    await refreshData(rep);
    vm.initialized = true;
  }

  Future<void> moveNext(ChartRepository rep) async {
    final periodStart = vm.period.addOffset(vm.periodStart, 1);
    final nextPeriodStart = vm.period.addOffset(vm.periodStart, 2);

    final previousData = vm.currentData;
    final currentData = vm.nextData;
    final nextData = await rep.getChartData(
      vm.interval,
      periodStart,
      nextPeriodStart,
    );

    vm.previousData = previousData;
    vm.currentData = currentData;
    vm.nextData = nextData;
    vm.periodStart = periodStart;
  }

  Future<void> moveBack(ChartRepository rep) async {
    final periodStart = vm.period.addOffset(vm.periodStart, -1);
    final nextPeriodStart = vm.periodStart;

    final previousData = await rep.getChartData(
      vm.interval,
      periodStart,
      nextPeriodStart,
    );
    final currentData = vm.previousData;
    final nextData = vm.currentData;

    vm.previousData = previousData;
    vm.currentData = currentData;
    vm.nextData = nextData;
    vm.periodStart = periodStart;
  }

  Future<void> movePeriod(
    ChartRepository rep,
    DatePeriod period,
    DateTime periodStart,
  ) async {
    vm.periodStart = periodStart;
    vm.period = period;
    await refreshData(rep);
  }

  Future<void> refreshData(ChartRepository rep) async {
    final period = vm.period;
    final interval = vm.interval;
    final periodStart = vm.periodStart;
    vm.previousData = await rep.getChartData(
      interval,
      period.addOffset(periodStart, -1),
      period.addOffset(periodStart, 0),
    );
    vm.currentData = await rep.getChartData(
      interval,
      period.addOffset(periodStart, 0),
      period.addOffset(periodStart, 1),
    );
    vm.nextData = await rep.getChartData(
      interval,
      period.addOffset(periodStart, 1),
      period.addOffset(periodStart, 2),
    );
    await refreshAllTimeBounds(rep);
  }

  Future<void> refreshAllTimeBounds(ChartRepository rep) async {
    vm.allTimeBounds = await rep.getAllTimeBounds();
  }
}
