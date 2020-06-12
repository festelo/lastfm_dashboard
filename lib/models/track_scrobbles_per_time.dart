import 'models.dart';
import 'package:shared/models.dart';

class _TrackScrobblesPerTimeProperties {
  String get name => 'name';
  String get trackId => 'trackId';
  String get groupedDate => 'groupedDate';
  String get artistId => 'artistId';
  String get id => 'id';
  String get userId => 'userId';
  String get period => 'period';
  String get count => 'count';

  const _TrackScrobblesPerTimeProperties();
}

class TrackScrobblesPerTime {
  static const properties = _TrackScrobblesPerTimeProperties();

  final String trackId;
  final String artistId;
  final String userId;
  final DateTime groupedDate;
  final DatePeriod period;
  final int count;

  const TrackScrobblesPerTime(
      {this.trackId,
      this.artistId,
      this.period,
      this.groupedDate,
      this.userId,
      this.count});

  TrackScrobblesPerTime.deserialize(Map<String, dynamic> map)
      : artistId = map[properties.artistId],
        trackId = map[properties.trackId],
        userId = map[properties.userId],
        period = DatePeriod.values.firstWhere(
          (e) => e.name == map[properties.period] as String,
          orElse: () => null,
        ),
        count = map[properties.count],
        groupedDate = map[properties.groupedDate] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                map[properties.groupedDate],
              ).subtract(DateTime.now().timeZoneOffset);
}
