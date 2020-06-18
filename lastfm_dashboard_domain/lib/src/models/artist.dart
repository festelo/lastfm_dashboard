import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:lastfm_dashboard_domain/src/models/entity.dart';

class Artist extends Entity {
  final String name;
  final String mbid;
  final String url;
  final ImageInfo imageInfo;

  Artist({
    String id,
    this.mbid,
    this.name,
    this.url,
    this.imageInfo,
  }): super(id);
}
