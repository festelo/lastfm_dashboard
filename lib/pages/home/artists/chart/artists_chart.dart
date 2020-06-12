import 'dart:async';

import 'package:collection/collection.dart';
import 'package:f_charts/f_charts.dart' hide Pair;
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

    final scrobbles = groupBy<TrackScrobblesPerTime, String>(
        scrobblesList, (s) => s.artistId);
    final series = selections
        .where((e) => scrobbles[e.artistId] != null)
        .map(
          (e) => ChartSeries(
            color: e.selectionColor,
            name: e.artistId,
            entities: scrobbles[e.artistId]
                .map((e) => ChartEntity(e.groupedDate, e.count))
                .toList(),
          ),
        )
        .toList();
    data = ChartData(series);
  }

  Future<void> updateRange(DateTime time, DatePeriod newRange) async {
    if (newRange == DatePeriod.month) {
      bounds[newRange] = Pair(
        DateTime(time.year),
        DateTime(time.year + 1),
      );
    }
    if (newRange == DatePeriod.day) {
      bounds[newRange] = Pair(
        DateTime(time.year, time.month),
        DateTime(time.year, time.month + 1),
      );
    }
    if (newRange == DatePeriod.hour) {
      bounds[newRange] = Pair(
        DateTime(time.year, time.month, time.day),
        DateTime(time.year, time.month, time.day + 1),
      );
    }
    period = newRange;
    await refreshData();
    context.read<ChartViewModel>().period = newRange;
    context.read<ChartViewModel>().bounds = bounds;
  }

  DatePeriod getNextRange() {
    final nextIndex = DatePeriod.values.indexOf(period) + 1;
    if (nextIndex == DatePeriod.values.length) return null;
    return DatePeriod.values[nextIndex];
  }

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
