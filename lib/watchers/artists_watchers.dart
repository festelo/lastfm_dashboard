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
  final stream = auth.currentUser.switchMap((userId) =>
    userId == null
      ? Stream<List<String>>.empty()
      : db.userArtistDetails.changesWhere(userId: userId, selected: true));

  await for (final ids in stream) {
    c.throwIfCancelled();
    if (ids == null || ids.isEmpty)
      yield (vm) => vm.copyWith(artistSelections: []);
    else {
      final details = await db.userArtistDetails.getWhere(ids: ids);
      yield (vm) => vm.copyWith(artistSelections: details);
    }
  }
}

class _ArtistsLoadDetails {
  final int from;
  final int to;
  _ArtistsLoadDetails(this.from, this.to);
}

class _ArtistsDetails {
  final _ArtistsLoadDetails loadInfo;
  final String userId;
  _ArtistsDetails(this.loadInfo, this.userId);
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

  final viewModelChangesStream = config.context
      .subscribe<ArtistsViewModel>()
      .map((c) => _ArtistsLoadDetails(c.loadFrom, c.loadTo))
      .distinct((a, b) => a.to == b.to && a.from == b.from);

  final currentUserStream = auth.currentUser;

  final loadDetailsStream = Rx.combineLatest2(
    viewModelChangesStream,
    currentUserStream,
    (a, b) => b == null ? null : _ArtistsDetails(a, b),
  );

  final artistsStream = loadDetailsStream.asyncMap((details) async {
    if (details == null) return <UserArtistDetails>[];
    final take = details.loadInfo.to - details.loadInfo.from;
    return await db.userArtistDetails.getWhere(
      skip: details.loadInfo.from,
      take: take,
      userId: details.userId,
    );
  });

  final artistsUpdatesStream = artistsStream.switchMap((d) => d.isEmpty
      ? Stream<List<UserArtistDetails>>.empty()
      : db.userArtistDetails
          .changesWhere(ids: d.map((e) => e.id))
          .asyncMap((ids) => db.userArtistDetails.getWhere(ids: ids))
      ).publish();

  final mergedArtistsStream = Rx.merge([artistsStream, artistsUpdatesStream]);

  final combinedStream = Rx.combineLatest2(
    mergedArtistsStream,
    currentUserStream.switchMap((userId) => userId == null
        ? Stream<int>.value(0)
        : db.userArtistDetails.subscribeCountWhere(userId: userId)),
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
