import 'dart:async';

import 'package:lastfm_dashboard/models/models.dart';

abstract class ExecutorWrapper {
  dynamic get executor;
}

abstract class LocalDatabaseService {
  Collection<TrackScrobble> get trackScrobbles;
  Collection<User> get users;
  Collection<Artist> get artists;
  Collection<Track> get tracks;
  Collection<ArtistSelection> get artistSelections;

  UserArtistDetailsQueryable get userArtistDetails;

  Future<T> transaction<T>(
      FutureOr<T> Function(ExecutorWrapper transaction) action);
}

abstract class Queryable<T> {
  Queryable<T> through(ExecutorWrapper database);
  Future<List<T>> getAll();
  ReadOnlyEntity<T> operator [](String id);
}

abstract class UserArtistDetailsQueryable extends Queryable<UserArtistDetails> {
  Stream<List<String>> changesWhere(
      {List<String> ids, bool selected, String userId});

  Future<List<UserArtistDetails>> getWhere(
      {List<String> ids, bool selected, String userId, int skip, int take});

  Stream<int> subscribeCountWhere(
      {List<String> ids, bool selected, String userId});
}

abstract class Collection<T> extends Queryable<T> {
  @override
  Collection<T> through(ExecutorWrapper database);
  Future<void> addAll(List<T> states);
  @override
  Entity<T> operator [](String id);
}

abstract class ReadOnlyEntity<T> {
  ReadOnlyEntity<T> through(ExecutorWrapper database);
}

abstract class Entity<T> extends ReadOnlyEntity<T> {
  @override
  Entity<T> through(ExecutorWrapper database);
  //Future<void> update(Map<String, dynamic> map, {bool createIfNotExist});
  Future<void> updateSelective(T Function(T) updater,
      {bool createIfNotExist = true});
  Future<void> create(T state);
  Future<void> delete();
}
