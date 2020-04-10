import 'dart:ui';
import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class _ArtistSelectionProperties {
  String get artistId => 'artistId';
  String get userId => 'userId';
  String get selectionColor => 'selectionColor';

  const _ArtistSelectionProperties();
}

class ArtistSelection extends DatabaseMappedModel {
  static const properties = _ArtistSelectionProperties();

  @override
  final String id;

  final String artistId;
  final String userId;
  final Color selectionColor;

  const ArtistSelection(this.id,
      {this.artistId, this.selectionColor, this.userId});

  ArtistSelection.deserialize(this.id, Map<String, dynamic> map)
      : artistId = map[properties.artistId],
        selectionColor =
            (map[properties.selectionColor] as int).nullOr((t) => Color(t)),
        userId = map[properties.userId];

  @override
  Map<String, dynamic> toDbMap() => {
        properties.artistId: artistId,
        properties.selectionColor: selectionColor.value,
        properties.userId: userId
      };
}
