import 'dart:ui';

import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class _UserArtistDetailsProperties {
  String get selected => 'selected';
  String get userId => 'userId';
  String get scrobbles => 'scrobbles';

  const _UserArtistDetailsProperties();
}

class UserArtistDetails extends DatabaseMappedModel {
  static const properties = _UserArtistDetailsProperties();
  @override
  final String id;

  final String name;
  final String artistId;
  final String mbid;
  final String url;
  final int scrobbles;
  final String userId;
  final ImageInfo imageInfo;

  const UserArtistDetails(this.id,
      {this.mbid,
      this.name,
      this.url,
      this.imageInfo,
      this.scrobbles,
      this.artistId,
      this.userId});

  UserArtistDetails.deserialize(this.id, Map<String, dynamic> map)
      : mbid = map['mbid'],
        url = map['url'],
        name = map['name'],
        scrobbles = map['scrobbles'],
        artistId = map['artistId'],
        userId = map[properties.userId],
        imageInfo = ImageInfo.fromMap(map.unpackDbMap('imageInfo'));

  @override
  Map<String, dynamic> toDbMap() => {
        'name': name,
        'mbid': mbid,
        'url': url,
        'scrobbles': scrobbles,
        'artistId': artistId,
        properties.userId: userId,
        'imageInfo': imageInfo?.toMap()
      };
}
