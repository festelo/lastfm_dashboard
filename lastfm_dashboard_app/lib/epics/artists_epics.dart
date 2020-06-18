import 'dart:ui';

import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/epics/helpers.dart';
import 'package:lastfm_dashboard_domain/domain.dart';

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
  final Color selectionColor;
  final String artistId;

  SelectArtistEpic(this.artistId, this.selectionColor);

  @override
  Future<void> call(EpicContext context, notify) async {
    final artistSelections =
        await context.provider.get<ArtistSelectionsRepository>();
    final artists = await context.provider.get<ArtistsRepository>();

    final user = await context.provider.get(currentUserKey);
    final artist = await artists.get(artistId);

    if (user == null) throw Exception('User not found');

    final artistSelection = ArtistSelection(
      artistId: artist.id,
      userId: user.id,
      color: selectionColor.value,
    );

    await artistSelections.createOrUpdate(artistSelection);

    notify(ArtistSelected(artistSelection));
  }
}

class RemoveArtistSelectionEpic extends Epic {
  final String artistId;
  RemoveArtistSelectionEpic(this.artistId);

  @override
  Future<void> call(EpicContext context, notify) async {
    final artistSelections =
        await context.provider.get<ArtistSelectionsRepository>();
    final currentUser = await context.provider.get(currentUserKey);

    await artistSelections.deleteForUser(currentUser.id, artistId);

    notify(ArtistSelectionRemoved(artistId, currentUser.id));
  }
}
