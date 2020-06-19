import 'dart:async';

import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:moor/moor.dart';
import 'package:shared/models.dart';

import '../database.dart';
import '../mappers.dart';

class TrackScrobblesPerTimeMoorDataAccessor
    extends DatabaseAccessor<MoorDatabase> {
  TrackScrobblesPerTimeMoorDataAccessor(MoorDatabase attachedDatabase,
      {this.mapper = const TrackScrobblesPerTimeMapper()})
      : super(attachedDatabase);
  final TrackScrobblesPerTimeMapper mapper;

  Future<List<TrackScrobblesPerTime>> getByArtist({
    DatePeriod period,
    List<String> userIds,
    List<String> artistIds,
    DateTime start,
    DateTime end,
  }) async {
    String groupedQuery;
    final cdate = this.db.trackScrobbles.date.$name;
    if (period == DatePeriod.day) {
      groupedQuery =
          "strftime('%s000', date($cdate, 'start of day'))";
    }
    if (period == DatePeriod.month) {
      groupedQuery =
          "strftime('%s000', date($cdate, 'start of month'))";
    }
    if (period == DatePeriod.week) {
      groupedQuery =
          "strftime('%s000', date($cdate, '-6 days', 'weekday 1'))";
    }
    final where =
        (Constant(userIds == null) | db.trackScrobbles.userId.isIn(userIds)) &
        (Constant(artistIds == null) | db.trackScrobbles.artistId.isIn(artistIds)) &
        (Constant(start == null) | db.trackScrobbles.date.isBiggerOrEqualValue(start)) &
        (Constant(end == null) | db.trackScrobbles.date.isSmallerThanValue(end));
    final res = await db
        .track_scrobbles_per_time_get_by_artist(
          CustomExpression<int>(groupedQuery),
          where,
        )
        .get();

    return res.map((e) => mapper.toDomain(e)).toList();
  }
}
