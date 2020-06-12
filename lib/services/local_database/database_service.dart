import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/models/models.dart';

enum SortDirection { ascending, descending }

abstract class ExecutorWrapper {
  dynamic get executor;
}

abstract class LocalDatabaseService {
  Collection<TrackScrobble> get trackScrobbles;
  Collection<User> get users;
  Collection<Artist> get artists;
  Collection<Track> get tracks;
  ArtistSelectionCollection get artistSelections;

  UserArtistDetailsQueryable get userArtistDetails;

  TrackScrobblesPerTimeQuery get trackScrobblesPerTimeQuery;

  Future<T> transaction<T>(
      FutureOr<T> Function(ExecutorWrapper transaction) action);

  FutureOr<void> dispose();
}

abstract class Query {
  Query through(ExecutorWrapper database);
}

abstract class TrackScrobblesPerTimeQuery extends Query {
  Stream<List<TrackScrobblesPerTime>> changesByArtist({
    @required DatePeriod period,
    List<String> ids,
    String userId,
    List<String> artistIds,
    DateTime start,
    DateTime end,
  });
  Future<List<TrackScrobblesPerTime>> getByArtist({
    @required DatePeriod period,
    List<String> ids,
    String userId,
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
  Stream<List<ArtistSelection>> changesWhere({
    String userId,
  });
}

abstract class UserArtistDetailsQueryable extends Queryable<UserArtistDetails> {
  Stream<List<UserArtistDetails>> changesWhere({
    List<String> ids,
    List<String> userIds,
    List<String> artistIds,
    int skip,
    int take,
    SortDirection scrobblesSort,
  });

  Future<List<UserArtistDetails>> getWhere({
    List<String> ids,
    List<String> artistIds,
    List<String> userIds,
    int skip,
    int take,
    SortDirection scrobblesSort,
  });

  Stream<int> countWhere({
    List<String> ids,
    List<String> userIds,
    List<String> artistIds,
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
