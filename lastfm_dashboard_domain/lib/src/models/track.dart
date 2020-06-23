import 'package:lastfm_dashboard_domain/domain.dart';
import 'entity.dart';

class Track extends Entity {
  final String mbid;
  final String name;
  final String artistId;
  final ImageInfo imageInfo;
  final String url;
  final bool loved;

  Track({
    String id,
    this.name,
    this.mbid,
    this.artistId,
    this.imageInfo,
    this.url,
    this.loved,
  }): super(id);
}