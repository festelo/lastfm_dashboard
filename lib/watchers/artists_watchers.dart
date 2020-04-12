import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class ArtistSelectionsWatcherInfo {}

Stream<Returner<ArtistsViewModel>> artistSelectionsWatcher(
  ArtistSelectionsWatcherInfo i,
  EventConfiguration<ArtistsViewModel> c,
) async* {
  final db = c.context.get<LocalDatabaseService>();
  final auth = c.context.get<AuthService>();
  final stream = auth.currentUser.switchMap((userId) => userId == null
      ? Stream<List<UserArtistDetails>>.empty()
      : db.artistSelections.changesWhere(userId: userId));

  await for (final details in stream) {
    c.throwIfCancelled();
    if (details == null || details.isEmpty)
      yield (vm) => vm.copyWith(artistSelections: []);
    else {
      yield (vm) => vm.copyWith(artistSelections: details);
    }
  }
}

class _SetupDetails {
  final String userId;
  _SetupDetails(this.userId);
}

class _ArtistsWatcherUpdateDetails {
  final List<UserArtistDetails> artists;
  final int count;
  _ArtistsWatcherUpdateDetails(this.artists, this.count);
}

class ArtistsWatcherInfo {}

Stream<Returner<ArtistsViewModel>> artistsWatcher(
  ArtistsWatcherInfo info,
  EventConfiguration<ArtistsViewModel> config,
) async* {
  final db = config.context.get<LocalDatabaseService>();
  final auth = config.context.get<AuthService>();

  final currentUserStream = auth.currentUser;

  final loadDetailsStream =
      currentUserStream.map((e) => e == null ? null : _SetupDetails(e));

  final artistsUpdatesStream = loadDetailsStream.switchMap((d) => d == null
      ? Stream<List<UserArtistDetails>>.empty()
      : db.userArtistDetails.changesWhere(
          userId: d.userId,
          scrobblesSort: SortDirection.descending));

  final combinedStream = Rx.combineLatest2(
    artistsUpdatesStream,
    currentUserStream.switchMap((userId) => userId == null
        ? Stream<int>.value(0)
        : db.userArtistDetails.countWhere(userId: userId)),
    (a, b) => _ArtistsWatcherUpdateDetails(a, b),
  );

  await for (final details in combinedStream) {
    config.throwIfCancelled();
    yield (vm) => vm.copyWith(
          artistsDetailed: details.artists,
          totalCount: details.count,
        );
  }
}
