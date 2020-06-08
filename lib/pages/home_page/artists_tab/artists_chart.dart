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

  @override
  Future<void> onLoad() async {
    final currentUser = await provider.get<User>(CurrentUser);
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
    refreshData();
  }

  void artistSelected(ArtistSelected e) {
    refreshData();
  }

  void artistSelectionRemoved(ArtistSelectionRemoved e) {
    refreshData();
  }

  Future<void> refreshData() async {
    final db = await provider.get<LocalDatabaseService>();
    final currentUser = await provider.get<User>(CurrentUser);
    final selections = await db.artistSelections.getAll();
    final scrobblesList = await db.trackScrobblesPerTimeQuery.getByArtist(
        duration: Duration(days: 30),
        artistIds: selections.map((e) => e.artistId).toList(),
        userId: currentUser.id);
    final scrobbles = groupBy<TrackScrobblesPerTime, String>(
        scrobblesList, (s) => s.artistId);
    final series = selections
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: loading ? CircularProgressIndicator() : BaseChart(data),
    );
  }
}
