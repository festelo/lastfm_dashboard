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
import 'package:provider/provider.dart';
import 'package:shared/models.dart';

class ArtistsChart extends StatefulWidget {
  @override
  _ArtistsChartState createState() => _ArtistsChartState();
}

class _ArtistsChartState extends EpicState<ArtistsChart> {
  ChartData<DateTime, int> data;
  ChartViewModel get vm => Provider.of<ChartViewModel>(context, listen: false);
  DatePeriod get period => vm.period;
  DatePeriod get nextPeriod => vm.nextPeriod;
  Map<DatePeriod, Pair<DateTime>> get bounds => vm.bounds;

  @override
  Future<void> onLoad() async {
    final currentUser = await provider.get<User>(currentUserKey);
    final userId = currentUser.id;

    handleVM<ChartViewModel>(
      (_) => refreshData(),
    );

    handle<UserScrobblesAdded>(
      (_) => refreshData(),
      where: (e) => e.user.username == userId,
    );

    handle<ArtistSelected>(
      (_) => refreshData(),
      where: (e) => e.selection.userId == userId,
    );

    handle<ArtistSelectionRemoved>(
      (_) => refreshData(),
      where: (e) => e.userId == userId,
    );

    await refreshData();
  }

  Future<void> refreshData() async {
    final db = await provider.get<LocalDatabaseService>();
    final currentUser = await provider.get<User>(currentUserKey);
    final selections = await db.artistSelections.getWhere(
      userId: currentUser.id,
    );

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
        if (series[scrobble.artistId] == null) continue;
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
    await context.read<ChartViewModel>().updateRange(time, newRange, offset);
  }

  Future<void> moveBounds({bool forward = true}) async {
    await context.read<ChartViewModel>().moveBounds(forward: forward);
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
        bounds: bounds[period],
        swiped: !swipesAvailable
            ? null
            : (a) {
                if (a == AxisDirection.up || a == AxisDirection.down)
                  return false;
                moveBounds(forward: a == AxisDirection.right ? true : false);
                return true;
              },
        pointPressed: nextPeriod == null
            ? null
            : (e) => updateRange(
                  e.abscissa,
                  nextPeriod,
                ),
      );

    return child;
  }
}
