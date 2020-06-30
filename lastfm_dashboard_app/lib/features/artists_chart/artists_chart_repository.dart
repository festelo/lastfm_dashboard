import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:epic/container.dart';
import 'package:f_charts/data_models.dart';
import 'package:lastfm_dashboard/features/artists_chart/artists_chart_bloc.dart';
import 'package:lastfm_dashboard/features/base_chart/chart_repository.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:shared/models.dart';

class ArtistsChartRepository extends ChartRepository {
  final EpicProvider provider;
  final ArtistsChartViewModel vm;
  String get userId => vm.userId;
  ArtistsChartRepository(this.provider, this.vm);

  @override
  Future<DateBounds> getAllTimeBounds() async {
    final trackScrobbles = await provider.get<TrackScrobblesRepository>();
    final pair = await trackScrobbles.getScrobblesBounds(
      userIds: [userId],
      artistIds: vm.usedArtistIds,
    );
    return DateBounds(pair.a, pair.b);
  }

  Future<List<ArtistSelection>> getSelections() async {
    final artistSelectionsRep =
        await provider.get<ArtistSelectionsRepository>();

    final selections = await artistSelectionsRep.getWhere(
      userId: userId,
    );

    return selections;
  }

  @override
  Future<ChartData<DateTime, int>> getChartData(
    DatePeriod interval, [
    DateTime periodStart,
    DateTime periodEnd,
  ]) async {
    final trackScrobblesPerTimeRep =
        await provider.get<TrackScrobblesPerTimeRepository>();
    final artistSelectionsRep =
        await provider.get<ArtistSelectionsRepository>();

    final selections = await artistSelectionsRep.getWhere(
      userId: userId,
    );

    final scrobblesList = await trackScrobblesPerTimeRep.getByArtist(
      period: interval,
      artistIds: selections.map((e) => e.artistId).toList(),
      userIds: [userId],
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
        color: Color(selection.color),
        name: selection.artistId,
        entities: [],
      );
    }

    for (final date in interval.iterateBounds(start, end)) {
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
}
