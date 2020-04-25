import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class _TrackScrobblesPerTimeProperties {
  String get name => 'name';
  String get trackId => 'trackId';
  String get groupedDate => 'groupedDate';
  String get artistId => 'artistId';
  String get id => 'id';
  String get userId => 'userId';
  String get duration => 'duration';
  String get count => 'count';

  const _TrackScrobblesPerTimeProperties();
}

class TrackScrobblesPerTime {
  static const properties = _TrackScrobblesPerTimeProperties();

  final String trackId;
  final String artistId;
  final String userId;
  final DateTime groupedDate;
  final Duration duration;
  final int count;

  const TrackScrobblesPerTime({
    this.trackId,
    this.artistId,
    this.duration,
    this.groupedDate,
    this.userId,
    this.count
  });

  TrackScrobblesPerTime.deserialize(Map<String, dynamic> map)
      : artistId = map[properties.artistId],
        trackId = map[properties.trackId],
        userId = map[properties.userId],
        duration = Duration(seconds: map[properties.duration] as int),
        count = map[properties.count],
        groupedDate = map[properties.groupedDate] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map[properties.groupedDate]);
}
