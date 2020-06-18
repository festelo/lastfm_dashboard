import 'dart:async';

import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:lastfm_dashboard_infrastructure/internal/database_moor/daos/generic.dart';
import 'package:shared/models/date_period.dart';
import '../internal/database_moor/database.dart';
import 'package:moor/moor.dart';

abstract class GenericMoorRepository<TDomain,
    TMoor extends Insertable<DataClass>> {
  GenericTableAccessor<TDomain, TMoor> get dao;

  Future<void> addOrUpdateAll(List<TDomain> states) {
    return dao.addOrUpdateAll(states);
  }

  Future<void> addOrUpdate(TDomain state) {
    return dao.addOrUpdate(state);
  }

  Future<void> delete(id) {
    return dao.deleteEntity(id);
  }

  FutureOr<void> dispose() {}

  Future<TDomain> get(id) {
    return dao.get(id);
  }

  Future<List<TDomain>> getAll() {
    return dao.getAll();
  }

  Future<T> transaction<T>(FutureOr<T> Function() action) {
    return dao.transaction(action);
  }
}

class UsersMoorRepository extends GenericMoorRepository<User, MoorUser>
    implements UsersRepository {
  UsersMoorRepository(this.db);
  final MoorDatabase db;
  @override
  GenericTableAccessor<User, MoorUser> get dao => db.userTableAccessor;
}

class ArtistsMoorRepository
    extends GenericMoorRepository<Artist, MoorArtist>
    implements ArtistsRepository {
  ArtistsMoorRepository(this.db);
  final MoorDatabase db;
  @override
  GenericTableAccessor<Artist, MoorArtist> get dao =>
      db.artistsTableAccessor;
}

class TrackScrobblesMoorRepository
    extends GenericMoorRepository<TrackScrobble, MoorTrackScrobble>
    implements TrackScrobblesRepository {
  TrackScrobblesMoorRepository(this.db);
  final MoorDatabase db;
  @override
  GenericTableAccessor<TrackScrobble, MoorTrackScrobble> get dao =>
      db.trackScrobbleTableAccessor;
}

class TracksMoorRepository extends GenericMoorRepository<Track, MoorTrack>
    implements TracksRepository {
  TracksMoorRepository(this.db);
  final MoorDatabase db;
  @override
  GenericTableAccessor<Track, MoorTrack> get dao => db.trackTableAccessor;
}

class ArtistSelectionsMoorRepository
    extends GenericMoorRepository<ArtistSelection, MoorArtistSelection>
    implements ArtistSelectionsRepository {
  ArtistSelectionsMoorRepository(this.db);
  final MoorDatabase db;
  @override
  GenericTableAccessor<ArtistSelection, MoorArtistSelection> get dao =>
      db.artistSelectionTableAccessor;

  @override
  Future<void> createOrUpdate(ArtistSelection sel) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteForUser(String userId, String artistId) async {
    await db.artistSelectionTableAccessor.deleteEntityWhere(
      db.artistSelections.userId.equals(userId) &
      db.artistSelections.artistId.equals(artistId),
    );
  }

  @override
  Future<List<ArtistSelection>> getWhere({String userId}) async {
    return await db.artistSelectionTableAccessor.getWhere(
      db.artistSelections.userId.equals(userId),
    );
  }
}

class ArtistUserInfoMoorRepository implements ArtistUserInfoRepository {
  ArtistUserInfoMoorRepository(this.db);
  final MoorDatabase db;
  @override
  Future<List<ArtistUserInfo>> getWhere(
      {List<String> artistIds,
      List<String> userIds,
      SortDirection scrobblesSort}) {
    return db.artistUserInfoDataAccessor.getWhere(
      artistIds: artistIds,
      userIds: userIds,
      scrobblesSort: scrobblesSort,
    );
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() action) {
    return transaction(() async => await action());
  }
}

class TrackScrobblesPerTimeMoorRepository
    implements TrackScrobblesPerTimeRepository {
  TrackScrobblesPerTimeMoorRepository(this.db);
  final MoorDatabase db;

  @override
  Future<List<TrackScrobblesPerTime>> getByArtist({
    DatePeriod period,
    List<String> userIds,
    List<String> artistIds,
    DateTime start,
    DateTime end,
  }) {
    return db.trackScrobblesPerTimeMoorDataAccessor.getByArtist(
      period: period,
      userIds: userIds,
      artistIds: artistIds,
      start: start,
      end: end,
    );
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() action) {
    return transaction(() async => await action());
  }
}
