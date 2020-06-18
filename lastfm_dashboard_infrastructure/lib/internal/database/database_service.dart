import 'dart:async';

import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:shared/models.dart';

abstract class ExecutorWrapper {
  dynamic get executor;
}

abstract class LocalDatabaseManager {
  Collection<TrackScrobble> get trackScrobbles;
  Collection<User> get users;
  Collection<Artist> get artists;
  Collection<Track> get tracks;
  ArtistSelectionCollection get artistSelections;

  UserArtistDetailsQuery get userArtistDetails;

  TrackScrobblesPerTimeQuery get trackScrobblesPerTimeQuery;

  Future<T> transaction<T>(
      FutureOr<T> Function(ExecutorWrapper transaction) action);

  FutureOr<void> dispose();
}

abstract class Query {
  Query through(ExecutorWrapper database);
}

abstract class TrackScrobblesPerTimeQuery extends Query {
  Future<List<TrackScrobblesPerTime>> getByArtist({
    DatePeriod period,
    List<String> userIds,
    List<String> artistIds,
    DateTime start,
    DateTime end,
  });
}

abstract class Queryable<T> extends Query {
  @override
  Queryable<T> through(ExecutorWrapper database);
  Future<List<T>> getAll();
  ReadOnlyEntity<T> operator [](String id);
  Stream<List<T>> changes();
}

abstract class ArtistSelectionCollection extends Collection<ArtistSelection> {
  Future<List<ArtistSelection>> getWhere({
    String userId,
  });
}

abstract class UserArtistDetailsQuery extends Query {
  Future<List<ArtistUserInfo>> getWhere({
    List<String> artistIds,
    List<String> userIds,
    SortDirection scrobblesSort,
  });
}

abstract class Collection<T> extends Queryable<T> {
  @override
  Collection<T> through(ExecutorWrapper database);
  Future<void> addAll(List<T> states);
  Future<void> add(T state);
  @override
  Entity<T> operator [](String id);
}

abstract class ReadOnlyEntity<T> {
  ReadOnlyEntity<T> through(ExecutorWrapper database);
  Future<T> get();
}

abstract class Entity<T> extends ReadOnlyEntity<T> {
  @override
  Entity<T> through(ExecutorWrapper database);
  //Future<void> update(Map<String, dynamic> map, {bool createIfNotExist});
  Future<void> updateSelective(T Function(T) updater,
      {bool createIfNotExist = true});
  Future<void> delete();
}
