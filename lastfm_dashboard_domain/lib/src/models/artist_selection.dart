import 'entity.dart';

class ArtistSelection extends Entity {
  final String artistId;
  final String userId;
  final int color;

  ArtistSelection({
    String id,
    this.artistId,
    this.userId,
    this.color,
  }): super(id);
}
