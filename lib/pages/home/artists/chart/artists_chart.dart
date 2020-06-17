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
  ChartViewModel get vm => Provider.of<ChartViewModel>(context, listen: false);
  DatePeriod get boundsPeriod => vm.boundsPeriod;
  DatePeriod get pointsPeriod => vm.pointsPeriod;
  DatePeriod get nextPeriod => vm.nextPeriod;
  Pair<DateTime> get nextBounds => vm.nextBounds;
  Pair<DateTime> get bounds => vm.bounds;
  Pair<DateTime> get previousBounds => vm.previousBounds;
  ChartData<DateTime, int> data;
  ChartData<DateTime, int> previousData;
  ChartData<DateTime, int> nextData;

  @override
  Future<void> onLoad() async {
    final currentUser = await provider.get<User>(currentUserKey);
    final userId = currentUser.id;

    handleVM<ChartViewModel>(
      (_) => refreshData(),
    );

    handle<UserScrobblesAdded>(
      userScrobblesAdded,
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

  Future<ChartData<DateTime, int>> getData(
    DatePeriod period, [
    DateTime periodStart,
    DateTime periodEnd,
  ]) async {
    final db = await provider.get<LocalDatabaseService>();
    final currentUser = await provider.get<User>(currentUserKey);
    final selections = await db.artistSelections.getWhere(
      userId: currentUser.id,
    );

    final scrobblesList = await db.trackScrobblesPerTimeQuery.getByArtist(
      period: pointsPeriod,
      artistIds: selections.map((e) => e.artistId).toList(),
      userIds: [currentUser.id],
      start: periodStart,
      end: periodEnd,
    );

    if (scrobblesList.isEmpty && periodStart == null && periodEnd == null)
      return ChartData([]);

    final start = periodStart ??
        scrobblesList
            .map((c) => c.groupedDate)
            .reduce((a, b) => a.compareTo(b) == 1 ? b : a);

    final end = periodEnd ??
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

    for (final date in pointsPeriod.iterateBounds(start, end)) {
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
    return ChartData(series.values.toList());
  }

  bool dataRefresing = false;

  Future<void> refreshData() async {
    setState(() => dataRefresing = true);

    if (previousBounds != null)
      previousData = await getData(
        boundsPeriod,
        previousBounds.a,
        previousBounds.b,
      );

    data = await getData(boundsPeriod, bounds?.a, bounds?.b);

    if (nextBounds != null)
      nextData = await getData(
        boundsPeriod,
        nextBounds.a,
        nextBounds.b,
      );

    setState(() => dataRefresing = false);
  }

  Future<void> updateRange(DateTime time, DatePeriod newRange,
      [int offset = 0]) async {
    context.read<ChartViewModel>().updateRange(time, newRange, offset);
  }

  Future<void> moveBounds({bool forward = true}) async {
    context.read<ChartViewModel>().moveBounds(forward: forward);
  }

  bool get swipesAvailable =>
      !dataRefresing && bounds.a != null && bounds.b != null;

  ChartData<DateTime, int> handleScrobbleAdding(
    UserScrobblesAdded e,
    ChartData<DateTime, int> data,
    Map<String, List<TrackScrobble>> scrobblesPerArtist,
  ) {
    if (data == null) return null;
    final newSeries = [...data.series.map((e) => e.deepCopy())];
    for (final series in newSeries) {
      final scrobbles = scrobblesPerArtist[series.name];
      if (scrobbles == null) continue;
      for (final scrobble in scrobbles) {
        final normalized = pointsPeriod.normalize(scrobble.date);
        final index = series.entities.indexWhere(
          (s) => s.abscissa == normalized,
        );
        if (index == -1) continue;
        series.entities[index] =
            ChartEntity(normalized, series.entities[index].ordinate + 1);
      }
    }
    return ChartData(newSeries);
  }

  void userScrobblesAdded(UserScrobblesAdded e) {
    final scrobblesPerArtist =
        groupBy<TrackScrobble, String>(e.newScrobbles, (c) => c.userId);
    final previousData = this.previousData;
    final data = this.data;
    final nextData = this.nextData;
    final newPreviousData =
        handleScrobbleAdding(e, previousData, scrobblesPerArtist);
    final newData = handleScrobbleAdding(e, data, scrobblesPerArtist);
    final newNextData = handleScrobbleAdding(e, nextData, scrobblesPerArtist);
    if (previousData == this.previousData) this.previousData = newPreviousData;
    if (data == this.data) this.data = newData;
    if (nextData == this.nextData) this.nextData = newNextData;
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
        range: boundsPeriod,
        bounds: bounds,
        previousData: previousData,
        nextData: nextData,
        beforeSwipe: (_) => swipesAvailable,
        afterSwipe: (_, a) {
          if (a == AxisDirection.up || a == AxisDirection.down) return false;
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
