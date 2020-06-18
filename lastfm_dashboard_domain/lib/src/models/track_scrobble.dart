import 'entity.dart';

class TrackScrobble extends Entity {
  final String trackId;
  final String artistId;
  final String userId;
  final DateTime date;

  TrackScrobble({
    String id,
    this.trackId,
    this.artistId,
    this.date,
    this.userId,
  }): super(id);
}
