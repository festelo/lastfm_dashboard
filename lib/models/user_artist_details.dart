import 'dart:ui';

import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class _UserArtistDetailsProperties {
  String get selected => 'selected';
  String get userId => 'userId';

  const _UserArtistDetailsProperties();
}

class UserArtistDetails extends DatabaseMappedModel {
  static const properties = _UserArtistDetailsProperties();
  @override
  final String id;

  final String name;
  final String mbid;
  final String url;
  final int scrobbles;
  final Color selectionColor;
  final bool selected;
  final String userId;
  final ImageInfo imageInfo;

  const UserArtistDetails(this.id,
      {this.mbid,
      this.name,
      this.url,
      this.imageInfo,
      this.scrobbles,
      this.selectionColor,
      this.selected,
      this.userId});

  UserArtistDetails.deserialize(this.id, Map<String, dynamic> map)
      : mbid = map['mbid'],
        url = map['url'],
        name = map['name'],
        scrobbles = map['scrobbles'],
        userId = map[properties.userId],
        selectionColor = Color(map['selectionColor']),
        imageInfo = ImageInfo.fromMap(map.unpackDbMap('imageInfo')),
        selected = map[properties.selected] ?? false;

  @override
  Map<String, dynamic> toDbMap() => {
        'name': name,
        'mbid': mbid,
        'url': url,
        'scrobbles': scrobbles,
        'selectionColor': selectionColor.value,
        properties.selected: selected,
        properties.userId: userId,
        'imageInfo': imageInfo?.toMap()
      };
}
