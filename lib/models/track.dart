import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class Track extends DatabaseMappedModel {
  @override
  String get id => artistId + '@' + name;
  final String mbid;
  final String name;
  final String artistId;
  final ImageInfo imageInfo;
  final String url;
  final bool loved;

  const Track({
    this.name,
    this.mbid,
    this.artistId,
    this.imageInfo,
    this.url,
    this.loved,
  });

  Track.deserialize(Map<String, dynamic> map)
      : mbid = map['mbid'],
        name = map['name'],
        url = map['url'],
        loved = (map['loved'] as int).boolean,
        artistId = map['artistId'],
        imageInfo = ImageInfo.fromMap(map.unpackDbMap('imageInfo'));

  @override
  Map<String, dynamic> toDbMap() => {
        'name': name,
        'mbid': mbid,
        'url': url,
        'artistId': artistId,
        'loved': loved.integer,
        'imageInfo': imageInfo?.toMap()
      };
}