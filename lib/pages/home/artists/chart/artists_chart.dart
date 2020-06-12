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

class ArtistsChart extends StatefulWidget {
  @override
  _ArtistsChartState createState() => _ArtistsChartState();
}

class _ArtistsChartState extends EpicState<ArtistsChart> {
  ChartData<DateTime, int> data;
  ChartDateRange dateRange = ChartDateRange.month;
  DateTime start;
  DateTime end;

  @override
  Future<void> onLoad() async {
    final currentUser = await provider.get<User>(currentUserKey);
    final userId = currentUser.id;

    subscribe<UserScrobblesAdded>(
      scrobblesAdded,
      where: (e) => e.user.username == userId,
    );

    subscribe<ArtistSelected>(
      artistSelected,
      where: (e) => e.selection.userId == userId,
    );

    subscribe<ArtistSelectionRemoved>(
      artistSelectionRemoved,
      where: (e) => e.userId == userId,
    );

    await refreshData();
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

    Duration duration;
    if (dateRange == ChartDateRange.month) {
      duration = Duration(days: 30);
    }
    if (dateRange == ChartDateRange.day) {
      duration = Duration(days: 1);
    }
    if (dateRange == ChartDateRange.hour) {
      duration = Duration(hours: 1);
    }

    final scrobblesList = await db.trackScrobblesPerTimeQuery.getByArtist(
      duration: duration,
      artistIds: selections.map((e) => e.artistId).toList(),
      userId: currentUser.id,
      start: start,
      end: end,
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

  Future<void> updateRange(DateTime time, ChartDateRange newRange) async {
    if (newRange == ChartDateRange.month) {
      start = DateTime(time.year, time.month);
      end = DateTime(time.year, time.month + 1);
    }
    if (newRange == ChartDateRange.day) {
      start = DateTime(time.year, time.month, time.day);
      end = DateTime(time.year, time.month, time.day + 1);
    }
    if (newRange == ChartDateRange.hour) {
      start = DateTime(time.year, time.month, time.day, time.hour);
      end = DateTime(time.year, time.month, time.day, time.hour + 1);
    }
    dateRange = newRange;
    await refreshData();
    apply();
  }

  ChartDateRange getNextRange() {
    final nextIndex = (ChartDateRange.values.indexOf(dateRange) + 1) %
        ChartDateRange.values.length;
    return ChartDateRange.values[nextIndex];
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
        range: dateRange,
        pointPressed: (e) => updateRange(
          e.abscissa,
          getNextRange(),
        ),
      );

    return child;
  }
}
