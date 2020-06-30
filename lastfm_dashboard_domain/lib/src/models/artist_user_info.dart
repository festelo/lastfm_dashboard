import 'package:lastfm_dashboard_domain/domain.dart';

class ArtistInfoForUser {
  final String artistId;
  final String name;
  final String userId;
  final String mbid;
  final String url;
  final int scrobbles;
  final ImageInfo imageInfo;

  const ArtistInfoForUser({
    this.mbid,
    this.url,
    this.imageInfo,
    this.scrobbles,
    this.artistId,
    this.name,
    this.userId,
  });
}
