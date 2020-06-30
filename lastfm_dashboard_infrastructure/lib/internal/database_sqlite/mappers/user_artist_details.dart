import 'package:lastfm_dashboard_domain/domain.dart';
import 'image.dart';
import '../db_mapper.dart';

class UserArtistDetailsColumns {
  String get selected => 'selected';
  String get userId => 'userId';
  String get artistId => 'artistId';
  String get scrobbles => 'scrobbles';

  const UserArtistDetailsColumns();
}

class UserArtistDetailsMapper extends LiteMapper<ArtistInfoForUser> {
  final UserArtistDetailsColumns columns = const UserArtistDetailsColumns();
  final ImageInfoMapper imageMapper;
  const UserArtistDetailsMapper({this.imageMapper = const ImageInfoMapper()});

  @override
  ArtistInfoForUser fromMap(Map<String, dynamic> map) {
    return ArtistInfoForUser(
      mbid: map['mbid'],
      url: map['url'],
      scrobbles: map['scrobbles'],
      artistId: map[columns.artistId],
      userId: map[columns.userId],
      imageInfo: imageMapper.fromMap(unpackDbMap(map, 'imageInfo')),
    );
  }

  @override
  Map<String, dynamic> toMap(ArtistInfoForUser o) => {
        'mbid': o.mbid,
        'url': o.url,
        'scrobbles': o.scrobbles,
        columns.artistId: o.artistId,
        columns.userId: o.userId,
        'imageInfo': o.imageInfo.nullOr(imageMapper.toMap),
      };
}
