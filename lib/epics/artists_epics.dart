import 'dart:ui';

import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class ArtistSelected {
  final ArtistSelection selection;
  ArtistSelected(this.selection);
}

class ArtistSelectionRemoved {
  final String artistId;
  final String userId;
  ArtistSelectionRemoved(this.artistId, this.userId);
}

class SelectArtistEpic extends Epic {
  final String artistId;
  final Color selectionColor;
  SelectArtistEpic(this.artistId, this.selectionColor);

  @override
  Future<void> call(EpicContext context, notify) async {
    final db = await context.provider.get<LocalDatabaseService>();
    final user = await context.provider.get<User>(currentUserKey);

    if (user == null) throw Exception('User can\'t be null');

    final artistSelection = ArtistSelection(
      artistId: artistId,
      selectionColor: selectionColor,
      userId: user.id,
    );

    await db.artistSelections[artistSelection.id].updateSelective(
      (a) => artistSelection,
      createIfNotExist: true,
    );
    
    notify(ArtistSelected(artistSelection));
  }
}

class RemoveArtistSelectionEpic extends Epic {
  final String artistId;
  RemoveArtistSelectionEpic(this.artistId);
  
  @override
  Future<void> call(EpicContext context, notify) async {
    final db = await context.provider.get<LocalDatabaseService>();
    final user = await context.provider.get<User>(currentUserKey);
    if (user == null) throw Exception('User can\'t be null');

    final artistSelection = ArtistSelection(
      artistId: artistId,
      userId: user.id,
    );
    await db.artistSelections[artistSelection.id].delete();
    
    notify(ArtistSelectionRemoved(artistId, user.id));
  }
}