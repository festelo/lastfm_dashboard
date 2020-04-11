import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class _ArtistProperties {
  String get mbid => 'mbid';
  String get url => 'url';
  String get imageInfo => 'imageInfo';

  const _ArtistProperties();
}
class Artist extends DatabaseMappedModel {
  static const properties = _ArtistProperties();
  // final String id;
  @override
  String get id => name;

  final String name;
  final String mbid;
  final String url;
  final ImageInfo imageInfo;

  const Artist({
    this.mbid,
    this.name,
    this.url,
    this.imageInfo,
  });

  Artist.deserialize(this.name, Map<String, dynamic> map)
      : mbid = map[properties.mbid],
        url = map[properties.url],
        imageInfo = ImageInfo.fromMap(map.unpackDbMap(properties.imageInfo));

  @override
  Map<String, dynamic> toDbMap() =>
      {
        properties.mbid: mbid, 
        properties.url: url, 
        properties.imageInfo: imageInfo?.toMap()
      };
}