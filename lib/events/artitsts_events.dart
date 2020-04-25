import 'dart:ui';

import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class SelectArtistEventInfo {
  final String artistId;
  final Color selectionColor;

  const SelectArtistEventInfo({this.artistId, this.selectionColor});
}

class RemoveArtistSelectionEventInfo {
  final String artistId;

  const RemoveArtistSelectionEventInfo({this.artistId});
}
class SetArtistScrobblesDurationEventInfo {
  final Duration duration;

  const SetArtistScrobblesDurationEventInfo({this.duration});
}

Stream<Returner<ArtistsViewModel>> selectArtist(
  SelectArtistEventInfo info,
  EventConfiguration<ArtistsViewModel> config,
) async* {
  final user = config.context.get<User>();
  if (user == null) throw Exception('User can\'t be null');
  final db = config.context.get<LocalDatabaseService>();
  final artistSelection = ArtistSelection(
      artistId: info.artistId,
      selectionColor: info.selectionColor,
      userId: user.id);
  await db.artistSelections[artistSelection.id].updateSelective(
    (a) => artistSelection,
    createIfNotExist: true,
  );
}

Stream<Returner<ArtistsViewModel>> removeArtistSelection(
  RemoveArtistSelectionEventInfo info,
  EventConfiguration<ArtistsViewModel> config,
) async* {
  final user = config.context.get<User>();
  if (user == null) throw Exception('User can\'t be null');
  final db = config.context.get<LocalDatabaseService>();
  final artistSelection = ArtistSelection(
    artistId: info.artistId,
    userId: user.id,
  );
  await db.artistSelections[artistSelection.id].delete();
}

Stream<Returner<ArtistsViewModel>> setArtistScrobblesDuration(
  SetArtistScrobblesDurationEventInfo info,
  EventConfiguration<ArtistsViewModel> config,
) async* {
  yield (c) => c.copyWith(
    scrobblesDuration: info.duration
  );
}
