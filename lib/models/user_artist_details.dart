import 'dart:ui';

import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class _UserArtistDetailsProperties {
  String get selected => 'selected';
  String get userId => 'userId';
  String get artistId => 'artistId';
  String get scrobbles => 'scrobbles';

  const _UserArtistDetailsProperties();
}

class UserArtistDetails extends DatabaseMappedObject {
  static const properties = _UserArtistDetailsProperties();

  final String artistName;
  final String artistId;
  final String mbid;
  final String url;
  final int scrobbles;
  final String userId;
  final ImageInfo imageInfo;

  const UserArtistDetails({
    this.mbid,
    this.artistName,
    this.url,
    this.imageInfo,
    this.scrobbles,
    this.artistId,
    this.userId,
  });

  UserArtistDetails.deserialize(Map<String, dynamic> map)
      : mbid = map['mbid'],
        url = map['url'],
        artistName = map['name'],
        scrobbles = map['scrobbles'],
        artistId = map[properties.artistId],
        userId = map[properties.userId],
        imageInfo = ImageInfo.fromMap(map.unpackDbMap('imageInfo'));

  @override
  Map<String, dynamic> toDbMap() => {
        'name': artistName,
        'mbid': mbid,
        'url': url,
        'scrobbles': scrobbles,
        properties.artistId: artistId,
        properties.userId: userId,
        'imageInfo': imageInfo?.toMap()
      };
}
