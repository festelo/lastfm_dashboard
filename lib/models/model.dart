class User {
  final String imageUrl;
  final String username;
  final DateTime lastSync;

  User({
    this.username,
    this.lastSync,
    this.imageUrl
  });
}

class Track {
  final String id;
  final String name;
  final String artistId;
  final String artistName;

  Track({
    this.id,
    this.name,
    this.artistId,
    this.artistName
  });
}

class TrackScrobble {
  final String id;
  final String name;
  final String artistId;
  final String artistName;
  final String trackId;
  final DateTime date;

  TrackScrobble({
    this.id,
    this.name,
    this.artistId,
    this.artistName,
    this.trackId,
    this.date
  });
}