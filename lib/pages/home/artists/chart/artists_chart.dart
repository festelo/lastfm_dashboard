import 'dart:async';

import 'package:collection/collection.dart';
import 'package:f_charts/f_charts.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/base_chart.dart';
import 'package:lastfm_dashboard/epics/artists_epics.dart';
import 'package:lastfm_dashboard/epics/epic_state.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/view_models/chart_view_model.dart';
import 'package:lastfm_dashboard/view_models/epic_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared/models.dart';

class ArtistsChart extends StatefulWidget {
  @override
  _ArtistsChartState createState() => _ArtistsChartState();
}

class _ArtistsChartState extends EpicState<ArtistsChart> {
  DatePeriod period;
  ChartData<DateTime, int> data;

  Map<DatePeriod, Pair<DateTime>> bounds;

  @override
  Future<void> onLoad() async {
    final currentUser = await provider.get<User>(currentUserKey);
    final userId = currentUser.id;

    final vm = context.read<ChartViewModel>();
    period = vm.period;
    bounds = vm.bounds;

    handle<ViewModelChanged<ChartViewModel>>(
      viewModelChanged,
      where: (e) => e.viewModel == vm,
    );

    handle<UserScrobblesAdded>(
      scrobblesAdded,
      where: (e) => e.user.username == userId,
    );

    handle<ArtistSelected>(
      artistSelected,
      where: (e) => e.selection.userId == userId,
    );

    handle<ArtistSelectionRemoved>(
      artistSelectionRemoved,
      where: (e) => e.userId == userId,
    );

    await refreshData();
  }

  Future<void> viewModelChanged(ViewModelChanged<ChartViewModel> e) async {
    var refresh = false;
    if (e.viewModel.period != period) {
      period = e.viewModel.period;
      refresh = true;
    }
    if (e.viewModel.bounds != bounds) {
      bounds = e.viewModel.bounds;
      refresh = true;
    }
    if (refresh) {
      await refreshData();
    }
  }

  Future<void> scrobblesAdded(UserScrobblesAdded e) async {
    await refreshData();
  }

  Future<void> artistSelected(ArtistSelected e) async {
    await refreshData();
  }

  Future<void> artistSelectionRemoved(ArtistSelectionRemoved e) async {
    await refreshData();
  }

  Future<void> refreshData() async {
    final db = await provider.get<LocalDatabaseService>();
    final currentUser = await provider.get<User>(currentUserKey);
    final selections = await db.artistSelections.getAll();

    final scrobblesList = await db.trackScrobblesPerTimeQuery.getByArtist(
      period: period,
      artistIds: selections.map((e) => e.artistId).toList(),
      userId: currentUser.id,
      start: bounds[period].a,
      end: bounds[period].b,
    );

    final start = bounds[period].a ??
        scrobblesList
            .map((c) => c.groupedDate)
            .reduce((a, b) => a.compareTo(b) == 1 ? b : a);

    final end = bounds[period].b ??
        scrobblesList
            .map((c) => c.groupedDate)
            .reduce((a, b) => a.compareTo(b) == 1 ? a : b)
            .add(Duration(seconds: 1));

    final perDate = groupBy<TrackScrobblesPerTime, DateTime>(
        scrobblesList, (s) => s.groupedDate);

    final series = <String, ChartSeries<DateTime, int>>{};

    for (final selection in selections) {
      series[selection.artistId] = ChartSeries(
        color: selection.selectionColor,
        name: selection.artistId,
        entities: [],
      );
    }

    for (final date in period.iterateBounds(start, end)) {
      final used = <String>{};
      for (final scrobble in perDate[date] ?? <TrackScrobblesPerTime>[]) {
        series[scrobble.artistId]
            .entities
            .add(ChartEntity(date, scrobble.count));
        used.add(scrobble.artistId);
      }
      final unused = selections.where((e) => !used.contains(e.artistId));
      for (final sel in unused) {
        series[sel.artistId].entities.add(ChartEntity(date, 0));
      }
    }

    data = ChartData(series.values.toList());
  }

  Future<void> updateRange(DateTime time, DatePeriod newRange,
      [int offset = 0]) async {
    if (newRange == DatePeriod.month) {
      bounds[newRange] = Pair(
        DateTime(time.year + offset),
        DateTime(time.year + 1 + offset),
      );
    }
    if (newRange == DatePeriod.week) {
      bounds[newRange] = Pair(
        DateTime(time.year, time.month + offset),
        DateTime(time.year, time.month + 1 + offset),
      );
    }
    if (newRange == DatePeriod.day) {
      bounds[newRange] = Pair(
        DateTime(
          time.year,
          time.month,
          time.day - time.weekday + 1 + offset * 7,
        ),
        DateTime(
          time.year,
          time.month,
          time.day - time.weekday + 1 + (1 + offset) * 7,
        ),
      );
    }
    if (newRange == DatePeriod.hour) {
      bounds[newRange] = Pair(
        DateTime(time.year, time.month, time.day + offset),
        DateTime(time.year, time.month, time.day + 1 + offset),
      );
    }
    period = newRange;
    await refreshData();
    context.read<ChartViewModel>().period = newRange;
    context.read<ChartViewModel>().bounds = bounds;
    apply();
  }

  Future<void> moveBounds({bool forward = true}) async {
    await updateRange(bounds[period].a, period, forward ? 1 : -1);
  }

  DatePeriod getNextRange() {
    final nextIndex = DatePeriod.values.indexOf(period) + 1;
    if (nextIndex == DatePeriod.values.length) return null;
    return DatePeriod.values[nextIndex];
  }

  bool get swipesAvailable =>
      bounds[period].a != null && bounds[period].b != null;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading)
      child = Center(
        child: CircularProgressIndicator(),
      );
    else if (data.series.isEmpty)
      child = Container();
    else
      child = BaseChart(
        data,
        range: period,
        swiped: !swipesAvailable
            ? null
            : (a) {
                if (a == AxisDirection.up || a == AxisDirection.down)
                  return false;
                moveBounds(forward: a == AxisDirection.right ? true : false);
                return true;
              },
        pointPressed: getNextRange() == null
            ? null
            : (e) => updateRange(
                  e.abscissa,
                  getNextRange(),
                ),
      );

    return child;
  }
}
