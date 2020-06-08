import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/constants.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/models/database_mapped_model.dart';
import 'package:quiver/core.dart';
import 'package:collection/collection.dart';

import 'db_setup.dart' if (dart.library.html) 'db_setup_web.dart';

import 'migrations.dart';
typedef Constructor<T> = T Function(String id, Map<String, dynamic> data);

class SembastExecutorWrapper extends ExecutorWrapper {
  @override
  final DatabaseClient executor;
  SembastExecutorWrapper(this.executor);
}

class WebDatabaseBuilder {
  WebDatabaseBuilder({
    this.path = WebDatabaseInfo.databaseFileName,
    this.usersStorePath = WebDatabaseInfo.usersPath,
    this.artistsStorePath = WebDatabaseInfo.artistsPath,
    this.tracksStorePath = WebDatabaseInfo.tracksPath,
    this.trackScrobblesStorePath = WebDatabaseInfo.trackScrobblesPath,
    this.artistSelectionsStorePath = WebDatabaseInfo.artistSelectionsStorePath,
    this.databaseVersion = WebDatabaseInfo.databaseVersion,
  });

  final String usersStorePath;
  final String artistsStorePath;
  final String tracksStorePath;
  final String trackScrobblesStorePath;
  final String artistSelectionsStorePath;
  final String path;
  final int databaseVersion;

  StoreRef<String, Map<String, dynamic>> usersStore() =>
      StoreRef<String, Map<String, dynamic>>(usersStorePath);

  StoreRef<String, Map<String, dynamic>> artistsStore() =>
      StoreRef<String, Map<String, dynamic>>(artistsStorePath);

  StoreRef<String, Map<String, dynamic>> tracksStore() =>
      StoreRef<String, Map<String, dynamic>>(tracksStorePath);

  StoreRef<String, Map<String, dynamic>> scrobblesStore() =>
      StoreRef<String, Map<String, dynamic>>(trackScrobblesStorePath);

  StoreRef<String, Map<String, dynamic>> artistSelectionsStore() =>
      StoreRef<String, Map<String, dynamic>>(artistSelectionsStorePath);

  Future<WebDatabaseService> build() async {
    final fullPath = await getFullPath(path);
    final dbFactory = getDatabaseFactory();
    final db = await dbFactory.openDatabase(
      fullPath,
      version: databaseVersion,
      mode: DatabaseMode.neverFails,
      onVersionChanged: (db, oldVersion, newVersion) async {
        await migrate(
          database: db,
          databaseBuilder: this,
          current: oldVersion,
          expected: newVersion,
        );
      },
    );
    return WebDatabaseService(
      db,
      usersStore: usersStore(),
      artistsStore: artistsStore(),
      tracksStore: tracksStore(),
      trackScrobblesStore: scrobblesStore(),
      artistSelectionsStore: artistSelectionsStore(),
    );
  }
}

class WebDatabaseService {
  final Database database;

  @override
  final UsersCollection users;
  @override
  final ArtistsCollection artists;
  @override
  final TracksCollection tracks;
  @override
  final TrackScrobblesCollection trackScrobbles;
  @override
  final ArtistSelectionsCollection artistSelections;
  @override
  final UserArtistDetailsSembastQueryable userArtistDetails;

  WebDatabaseService(
    this.database, {
    @required StoreRef<String, Map<String, dynamic>> usersStore,
    @required StoreRef<String, Map<String, dynamic>> artistsStore,
    @required StoreRef<String, Map<String, dynamic>> tracksStore,
    @required StoreRef<String, Map<String, dynamic>> trackScrobblesStore,
    @required StoreRef<String, Map<String, dynamic>> artistSelectionsStore,
  })  : users = UsersCollection(database, usersStore),
        artists = ArtistsCollection(database, artistsStore),
        tracks = TracksCollection(database, tracksStore),
        trackScrobbles =
            TrackScrobblesCollection(database, trackScrobblesStore),
        artistSelections =
            ArtistSelectionsCollection(database, artistSelectionsStore),
        userArtistDetails = UserArtistDetailsSembastQueryable(
            database,
            usersStore,
            artistsStore,
            trackScrobblesStore,
            artistSelectionsStore);

  @override
  Future<T> transaction<T>(
      FutureOr<T> Function(SembastExecutorWrapper) action) {
    return database.transaction((t) => action(SembastExecutorWrapper(t)));
  }
}

class DatabaseReadOnlyEntity<T extends DatabaseMappedModel>
    extends ReadOnlyEntity<T> {
  final String id;
  final RecordRef<String, Map<String, dynamic>> record;
  final DatabaseClient database;
  final Constructor<T> constructor;

  DatabaseReadOnlyEntity(
      {this.id, this.record, this.database, this.constructor});

  @override
  DatabaseReadOnlyEntity<T> through(ExecutorWrapper database) {
    return DatabaseReadOnlyEntity(
      id: id,
      record: record,
      database: database.executor,
      constructor: constructor,
    );
  }

  @override
  Future<T> get() async {
    final data = await record.get(database);
    if (data == null) return null;
    return constructor(id, data);
  }

  Future<bool> exist() async {
    return await record.exists(database);
  }

  /// Returns Stream that will return object with this [id]
  /// after every change
  Stream<T> changes(String id) {
    return record
        .onSnapshot(database)
        .map((d) => d == null ? null : constructor(id, d.value));
  }
}

class DatabaseEntity<T extends DatabaseMappedModel>
    extends DatabaseReadOnlyEntity<T> implements Entity<T> {
  DatabaseEntity({
    String id,
    RecordRef<String, Map<String, dynamic>> record,
    DatabaseClient database,
    Constructor<T> constructor,
  }) : super(
            id: id,
            record: record,
            database: database,
            constructor: constructor);

  DatabaseEntity<T> through(ExecutorWrapper database) {
    return DatabaseEntity(
      id: id,
      record: record,
      database: database.executor,
      constructor: constructor,
    );
  }

  Future<void> update(Map<String, dynamic> data,
      {bool createIfNotExist = false}) async {
    if (createIfNotExist) {
      await record.add(database, data);
    } else {
      await record.update(database, data);
    }
  }

  /// Works slow, but updates only affected properties
  /// If the object doesn't exist empty constructor will be
  /// sent to modificator as parameter
  @override
  Future<void> updateSelective(T Function(T) modificator,
      {bool createIfNotExist = true}) async {
    final initial = constructor(id, {});
    final state = modificator(initial);
    final diff = state.diff(initial);
    await update(diff, createIfNotExist: createIfNotExist);
  }

  /// Create/add object to databse. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated.
  ///
  /// Returns object Id.
  @override
  Future<void> create(T state, {Map<String, dynamic> additional}) async {
    final map = state.toDbMap();
    if (additional != null) {
      map.addAll(additional);
    }
    await record.put(database, state.toDbMap());
  }

  @override
  Future<void> delete() async {
    await record.delete(database);
  }
}

abstract class _DatabaseCollection<T extends DatabaseMappedModel>
    extends Collection<T> {
  final StoreRef<String, Map<String, dynamic>> store;
  final DatabaseClient database;
  final Constructor<T> constructor;

  _DatabaseCollection(this.database, this.store, this.constructor);

  @override
  _DatabaseCollection<T> through(ExecutorWrapper database);

  @override
  DatabaseEntity<T> operator [](String id) => DatabaseEntity<T>(
      id: id, database: database, constructor: constructor, record: record(id));

  RecordRef<String, Map<String, dynamic>> record(String id) {
    return store.record(id);
  }

  @override
  Future<List<T>> getAll() async {
    return await store
        .stream(database)
        .map((d) => constructor(d.key, d.value))
        .toList();
  }

  /// Returns Stream that will return list with all objects
  /// after every collection change (e.g. object added into
  /// collection), doesn't track objects properties inside
  /// collection
  @override
  Stream<List<T>> changes() {
    return store.query().onSnapshots(database).map((list) => list
        .map((d) =>
            d == null || d.value == null ? null : constructor(d.key, d.value))
        .toList());
  }

  /// Adds object to database. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated.
  ///
  /// Returns object Id.
  @override
  Future<String> add(T state, {Map<String, dynamic> additional}) async {
    final map = state.toDbMap();
    if (additional != null) {
      map.addAll(additional);
    }
    if (state.id != null) {
      await store.record(state.id).put(database, map);
      return state.id;
    } else {
      final id = await store.add(database, map);
      return id;
    }
  }

  /// Adds objects to database. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated.
  ///
  /// Returns object Id.
  @override
  Future<List<String>> addAll(Iterable<T> states) async {
    final List<T> statesWithId = [];
    final List<T> statesWithoutId = [];
    final List<String> ids = [];
    for (final s in states) {
      if (s.id != null) {
        statesWithId.add(s);
      } else {
        statesWithoutId.add(s);
      }
    }
    if (statesWithoutId.isNotEmpty) {
      final newIds = await store.addAll(
          database, statesWithoutId.map((s) => s.toDbMap()).toList());
      ids.addAll(newIds);
    }
    for (final s in statesWithId) {
      await store.record(s.id).put(database, s.toDbMap());
      ids.add(s.id);
    }
    return ids;
  }

  /// If [id] is specified deletes the object, otherwise deletes
  /// collection
  Future<void> delete() async {
    await store.delete(database);
  }
}

class UsersCollection extends _DatabaseCollection<User> {
  UsersCollection(
    DatabaseClient database,
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => User.deserialize(id, data));

  @override
  UsersCollection through(ExecutorWrapper database) {
    return UsersCollection(database.executor, store);
  }
}

class ArtistsCollection extends _DatabaseCollection<Artist> {
  ArtistsCollection(
    DatabaseClient database,
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => Artist.deserialize(id, data));

  @override
  ArtistsCollection through(ExecutorWrapper database) {
    return ArtistsCollection(database.executor, store);
  }
}

class TracksCollection extends _DatabaseCollection<Track> {
  TracksCollection(
    DatabaseClient database,
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => Track.deserialize(data));

  @override
  TracksCollection through(ExecutorWrapper database) {
    return TracksCollection(database.executor, store);
  }
}

class TrackScrobblesCollection extends _DatabaseCollection<TrackScrobble> {
  TrackScrobblesCollection(
    DatabaseClient database,
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => TrackScrobble.deserialize(data));

  @override
  TrackScrobblesCollection through(ExecutorWrapper database) {
    return TrackScrobblesCollection(database.executor, store);
  }
}

class ArtistSelectionsCollection extends _DatabaseCollection<ArtistSelection> {
  ArtistSelectionsCollection(
    DatabaseClient database,
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store,
            (id, data) => ArtistSelection.deserialize(data));

  @override
  ArtistSelectionsCollection through(ExecutorWrapper database) {
    return ArtistSelectionsCollection(database.executor, store);
  }
}

class _ArtistWithSelectionPair {
  final Artist artist;
  final ArtistSelection artistSelection;
  _ArtistWithSelectionPair(this.artist, this.artistSelection);
}

class _UserArtistPair {
  final String userId;
  final String artistId;
  _UserArtistPair(this.userId, this.artistId);
  @override
  bool operator ==(o) =>
      o is _UserArtistPair && o.userId == userId && o.artistId == artistId;

  @override
  int get hashCode => hash2(userId.hashCode, artistId.hashCode);
}

class _ScrobblesCountByUserArtist {
  final String userId;
  final String artistId;
  final int count;
  _ScrobblesCountByUserArtist(this.userId, this.artistId, this.count);
  @override
  bool operator ==(o) =>
      o is _ScrobblesCountByUserArtist &&
      o.userId == userId &&
      o.artistId == artistId &&
      o.count == count;

  @override
  int get hashCode => hash3(userId.hashCode, artistId.hashCode, count.hashCode);
}

class UserArtistDetailsSembastQueryable extends UserArtistDetailsQueryable {
  final DatabaseClient database;

  UserArtistDetailsSembastQueryable(this.database, this.usersStore,
      this.artistsStore, this.scrobblesStore, this.artistSelectionsStore);

  final StoreRef<String, Map<String, dynamic>> usersStore;
  final StoreRef<String, Map<String, dynamic>> artistsStore;
  final StoreRef<String, Map<String, dynamic>> artistSelectionsStore;
  final StoreRef<String, Map<String, dynamic>> scrobblesStore;

  @override
  UserArtistDetailsSembastQueryable through(ExecutorWrapper database) {
    return UserArtistDetailsSembastQueryable(database.executor, usersStore,
        artistsStore, scrobblesStore, artistSelectionsStore);
  }

  @override
  ReadOnlyEntity<UserArtistDetails> operator [](String id) {
    throw UnimplementedError();
  }

  @override
  Stream<List<UserArtistDetails>> changesWhere(
      {List<String> ids,
      bool selected, // +
      String userId, // +
      int skip,
      int take,
      SortDirection scrobblesSort}) {
    final users = usersStore
        .query(
          finder: userId == null ? null : Finder(filter: Filter.byKey(userId)),
        )
        .onSnapshots(database);

    final scrobbles = scrobblesStore.query().onSnapshots(database).map(
          (list) => groupBy<RecordSnapshot<String, Map<String, dynamic>>,
                  _UserArtistPair>(
            list,
            (c) => _UserArtistPair(c.value[TrackScrobble.properties.userId],
                c.value[TrackScrobble.properties.artistId]),
          )
              .entries
              .map((e) => _ScrobblesCountByUserArtist(
                  e.key.userId, e.key.artistId, e.value.length))
              .toList(),
        );
    final artistSelectedPairs = artistSelectionsStore
        .query()
        .onSnapshots(database)
        .switchMap((artistSelections) {
      final artistSelectionsDeserialized = artistSelections
          .map((e) => ArtistSelection.deserialize(e.value));
      final artistSelectionByArtist = Map<String, ArtistSelection>.fromIterable(
          artistSelectionsDeserialized,
          key: (sel) => sel.artistId,
          value: (sel) => sel);
      return artistsStore
          .query(
            finder: Finder(
                filter: selected == null
                    ? null
                    : Filter.custom(
                        (artist) => selected
                            ? artistSelectionByArtist.containsKey(artist.key)
                            : !artistSelectionByArtist.containsKey(artist.key),
                      )),
          )
          .onSnapshots(database)
          .map((list) => list
              .map((e) => _ArtistWithSelectionPair(
                  Artist.deserialize(e.key, e.value),
                  artistSelectionByArtist[e.key]))
              .toList());
    });
    return Rx.combineLatest3<
            List<RecordSnapshot<String, Map<String, dynamic>>>,
            List<_ScrobblesCountByUserArtist>,
            List<_ArtistWithSelectionPair>,
            List<UserArtistDetails>>(users, scrobbles, artistSelectedPairs,
        (u, s, a) {
      final mapped = s.map((scrobbles) {
        final artistSelectedPair = a
            .firstWhere((a) => a.artist.id == scrobbles.artistId, orElse: null);
        if (artistSelectedPair == null) return null;
        return UserArtistDetails(scrobbles.artistId + '@' + scrobbles.userId,
            imageInfo: artistSelectedPair.artist.imageInfo,
            mbid: artistSelectedPair.artist.mbid,
            name: artistSelectedPair.artist.name,
            scrobbles: scrobbles.count,
            url: artistSelectedPair.artist.url,
            userId: scrobbles.userId);
      }).toList();
      if (scrobblesSort != null) {
        mapped.sort((a, b) => scrobblesSort == SortDirection.ascending
            ? a.scrobbles.compareTo(b.scrobbles)
            : b.scrobbles.compareTo(a.scrobbles));
      }
      Iterable<UserArtistDetails> ret = mapped;
      if (skip != null) {
        ret = mapped.skip(skip);
      }
      if (take != null) {
        ret = mapped.take(take);
      }
      return ret.toList();
    });
  }

  @override
  Stream<int> countWhere({List<String> ids, bool selected, String userId}) {
    return Stream.value(0);
  }

  @override
  Future<List<UserArtistDetails>> getAll() {
    throw UnimplementedError();
  }

  @override
  Future<List<UserArtistDetails>> getWhere(
      {List<String> ids,
      bool selected,
      String userId,
      int skip,
      int take,
      SortDirection scrobblesSort}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<UserArtistDetails>> changes() {
    throw UnimplementedError();
  }
}
