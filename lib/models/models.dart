import 'database_mapped_model.dart';

class ImageInfo {
  final String small;
  final String medium;
  final String large;
  final String extraLarge;

  ImageInfo({
    this.small,
    this.medium,
    this.large,
    this.extraLarge
  });

  ImageInfo.fromMap(Map<String, dynamic> map):
    small = map['small'],
    medium = map['medium'],
    large = map['large'],
    extraLarge = map['extraLarge'];

  Map<String, dynamic> toMap() => {
    'small': small,
    'medium': medium,
    'large': large,
    'extraLarge': extraLarge
  };
}

class User extends DatabaseMappedModel {
  @override String get id => username;

  final String username;
  final DateTime lastSync;
  final int playCount;
  final ImageInfo imageInfo;

  User({
    this.username,
    this.lastSync,
    this.playCount,
    this.imageInfo
  });

  User.deserialize(this.username, Map<String, dynamic> dbMap):
    playCount = dbMap['playCount'],
    imageInfo = dbMap['imageInfo'] == null
      ? null
      : ImageInfo.fromMap(dbMap['imageInfo']),
    lastSync = dbMap['lastSync'] == null 
      ? null
      : DateTime.fromMillisecondsSinceEpoch(dbMap['lastSync']);

  @override
  Map<String, dynamic> toDbMap() => {
    'lastSync': lastSync?.millisecondsSinceEpoch,
    'playCount': playCount,
    'imageInfo': imageInfo?.toMap()
  };
}

class Artist extends DatabaseMappedModel {
  // final String id;
  @override String get id => name;
  final String name;
  final String mbid;
  final String url;
  final ImageInfo imageInfo;

  Artist({
    this.mbid,
    this.name,
    this.url,
    this.imageInfo
  });

  Artist.deserialize(this.name, Map<String, dynamic> map):
    mbid = map['mbid'],
    url = map['url'],
    imageInfo = map['imageInfo'] == null
      ? null
      : ImageInfo.fromMap(map['imageInfo']);
  
  @override
  Map<String, dynamic> toDbMap() => {
    'mbid': mbid,
    'url': url,
    'imageInfo': imageInfo?.toMap()
  };
}

class Track extends DatabaseMappedModel {
  @override String get id => artistId + '@' + name;
  final String mbid;
  final String name;
  final String artistId;
  final ImageInfo imageInfo;
  final String url;
  final bool loved;

  Track({
    this.name,
    this.mbid,
    this.artistId,
    this.imageInfo,
    this.url,
    this.loved
  });

  Track.deserialize(Map<String, dynamic> map):
    mbid = map['mbid'],
    name = map['name'],
    url = map['url'],
    loved = map['loved'],
    artistId = map['artistId'],
    imageInfo = map['imageInfo'] == null
      ? null
      : ImageInfo.fromMap(map['imageInfo']);
  
  @override
  Map<String, dynamic> toDbMap() => {
    'name': name,
    'mbid': mbid,
    'url': url,
    'artistId': artistId,
    'loved': loved,
    'imageInfo': imageInfo?.toMap()
  };
}

class _TrackScrobbleProperties {
  String get name => 'name';
  String get trackId => 'trackId';
  String get date => 'date';
  String get artistId => 'artistId';
  String get id => 'id';
  const _TrackScrobbleProperties();
}

class TrackScrobble extends DatabaseMappedModel {
  static const properties = _TrackScrobbleProperties();

  @override final String id;
  final String trackId;
  final String artistId;
  final DateTime date;

  TrackScrobble({
    this.id,
    this.trackId,
    this.artistId,
    this.date
  });

  TrackScrobble.deserialize(this.id, Map<String, dynamic> map):
    artistId = map[properties.artistId],
    trackId = map[properties.trackId],
    date = map[properties.date] == null 
      ? null
      : DateTime.fromMillisecondsSinceEpoch(map[properties.date]);
  
  @override
  Map<String, dynamic> toDbMap() => {
    properties.trackId: trackId,
    properties.artistId: artistId,
    properties.date: date?.millisecondsSinceEpoch
  };
}