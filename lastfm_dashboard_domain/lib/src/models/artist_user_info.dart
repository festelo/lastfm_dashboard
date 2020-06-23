import 'package:lastfm_dashboard_domain/domain.dart';

class ArtistUserInfo {
  final String artistId;
  final String userId;
  final String mbid;
  final String url;
  final int scrobbles;
  final ImageInfo imageInfo;

  const ArtistUserInfo({
    this.mbid,
    this.url,
    this.imageInfo,
    this.scrobbles,
    this.artistId,
    this.userId,
  });
}
