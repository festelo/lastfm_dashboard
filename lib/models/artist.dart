import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class Artist extends DatabaseMappedModel {
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
      : mbid = map['mbid'],
        url = map['url'],
        imageInfo = ImageInfo.fromMap(map.unpackDbMap('imageInfo'));

  @override
  Map<String, dynamic> toDbMap() =>
      {
        'mbid': mbid, 
        'url': url, 
        'imageInfo': imageInfo?.toMap()
      };
}