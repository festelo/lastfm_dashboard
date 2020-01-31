import 'database_mapped_model.dart';
class User extends DatabaseMappedModel {
  String get id => username;

  final String username;
  final String imageUrl;
  final DateTime lastSync;

  User({
    this.username,
    this.lastSync,
    this.imageUrl
  });

  User.deserialize(String username, Map<String, dynamic> dbMap):
    username = username,
    imageUrl = dbMap['imageUrl'],
    lastSync = dbMap['lastSync'] == null 
      ? null
      : DateTime.fromMillisecondsSinceEpoch(dbMap['lastSync']);

  @override
  Map<String, dynamic> toDbMap() => {
    'imageUrl': imageUrl,
    'lastSync': lastSync?.millisecondsSinceEpoch
  };
}

class Artist extends DatabaseMappedModel {
  final String id;
  final String name;

  Artist({
    this.id,
    this.name,
  });

  Artist.deserialize(String id, Map<String, dynamic> map):
    id = id,
    name = map['name'];
  
  @override
  Map<String, dynamic> toDbMap() => {
    'name': name
  };
}

class Track extends DatabaseMappedModel {
  final String id;
  final String name;
  final String artistId;

  Track({
    this.id,
    this.name,
    this.artistId
  });

  Track.deserialize(String id, Map<String, dynamic> map):
    id = id,
    name = map['name'],
    artistId = map['artistId'];
  
  @override
  Map<String, dynamic> toDbMap() => {
    'name': name,
    'artistId': artistId
  };
}

class _TrackScrobbleProperties {
  final String name = "name";
  final String trackId = "trackId";
  final String date = "date";
  final String artistId = "artistId";
  final String id = "id";
  const _TrackScrobbleProperties();
}

class TrackScrobble extends DatabaseMappedModel {
  static const properties = _TrackScrobbleProperties();

  final String id;
  final String name;
  final String trackId;
  final String artistId;
  final DateTime date;

  TrackScrobble({
    this.id,
    this.name,
    this.trackId,
    this.artistId,
    this.date
  });

  TrackScrobble.deserialize(String id, Map<String, dynamic> map):
    id = id,
    name = map[properties.name],
    artistId = map[properties.artistId],
    trackId = map[properties.trackId],
    date = map[properties.date] == null 
      ? null
      : DateTime.fromMillisecondsSinceEpoch(map[properties.date]);
  
  @override
  Map<String, dynamic> toDbMap() => {
    properties.name: name,
    properties.trackId: trackId,
    properties.artistId: artistId,
    properties.date: date?.millisecondsSinceEpoch
  };
}