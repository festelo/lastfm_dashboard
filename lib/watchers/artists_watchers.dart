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
  final stream = auth.currentUser
    .flatMap((userId) => 
      userId == null ? Stream.empty() :
      db.users[userId].artistSelections.changes());
  
  await for(final s in stream) {
    c.throwIfCancelled();
    yield (vm) => vm.copyWith(
      artistSelections: s
    );
  }
}

class _ArtistsWithScrobbles {
  final List<TrackScrobble> scrobbles;
  final List<Artist> artists;
  _ArtistsWithScrobbles(this.artists, this.scrobbles);
}

class ArtistsWatcherInfo {}
Stream<Returner<ArtistsViewModel>> artistsWatcher(
  ArtistsWatcherInfo i, 
  EventConfiguration<ArtistsViewModel> c,
) async* {
  final db = c.context.get<LocalDatabaseService>();
  final auth = c.context.get<AuthService>();

  final scrobblesStream = auth.currentUser
    .flatMap((userId) => 
      userId == null ? Stream.empty() :
      db.users[userId].scrobbles.changes());

  final artistsStream = db.artists.changes();

  final combinedStream = Rx.combineLatest2(scrobblesStream, artistsStream,
    (a, b) => _ArtistsWithScrobbles(b, a)
  ).throttleTime(Duration(seconds: 10), trailing: true);
      
  await for(final m in combinedStream) {
    c.throwIfCancelled();
    final artistsListens = <Artist, int>{}; 
    for(final s in m.scrobbles) {
      final artist = m.artists.firstWhere((a) => a.id == s.artistId,
        orElse: () => Artist(name: 'Unknown#' + s.artistId));
      artistsListens[artist] = (artistsListens[artist] ?? 0) + 1;
    }
    yield (vm) => vm.copyWith(
      artistsWithListens: artistsListens.entries.map((entry) => 
        ArtistWithListenInfo(
          artist: entry.key,
          scrobbles: entry.value
        )
      ).toList()
    );
  }
}