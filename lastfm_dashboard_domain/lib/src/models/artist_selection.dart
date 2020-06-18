import 'entity.dart';

class ArtistSelection extends Entity {
  final dynamic artistId;
  final dynamic userId;
  final int color;

  ArtistSelection({
    String id,
    this.artistId,
    this.userId,
    this.color,
  }): super(id);
}
