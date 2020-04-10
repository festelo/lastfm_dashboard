import 'models.dart';

class _TrackScrobbleProperties {
  String get name => 'name';
  String get trackId => 'trackId';
  String get date => 'date';
  String get artistId => 'artistId';
  String get id => 'id';
  String get userId => 'userId';

  const _TrackScrobbleProperties();
}

class TrackScrobble extends DatabaseMappedModel {
  static const properties = _TrackScrobbleProperties();

  @override
  String get id => '${trackId.hashCode}#${artistId.hashCode}#${date.hashCode}';

  final String trackId;
  final String artistId;
  final String userId;
  final DateTime date;

  const TrackScrobble({this.trackId, this.artistId, this.date, this.userId});

  TrackScrobble.deserialize(Map<String, dynamic> map)
      : artistId = map[properties.artistId],
        trackId = map[properties.trackId],
        userId = map[properties.userId],
        date = map[properties.date] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map[properties.date]);

  @override
  Map<String, dynamic> toDbMap() => {
        properties.trackId: trackId,
        properties.artistId: artistId,
        properties.userId: userId,
        properties.date: date?.millisecondsSinceEpoch
      };
}