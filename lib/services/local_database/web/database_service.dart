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
import 'package:shared/models.dart';

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

class WebDatabaseService extends LocalDatabaseService {
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
  final TrackScrobblesPerTimeQuery trackScrobblesPerTimeQuery;

  UserArtistDetailsSembastQuery _userArtistDetails;
  @override
  UserArtistDetailsSembastQuery get userArtistDetails => _userArtistDetails;

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
        trackScrobblesPerTimeQuery =
            TrackScrobblesPerTimeSembastQuery(database, trackScrobblesStore) {
    _userArtistDetails = UserArtistDetailsSembastQuery(
      database,
      trackScrobblesStore,
      artists,
    );
  }

  @override
  Future<T> transaction<T>(
      FutureOr<T> Function(SembastExecutorWrapper) action) {
    return database.transaction((t) => action(SembastExecutorWrapper(t)));
  }

  @override
  Future<void> dispose() async {
    await database.close();
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
      final key = await record.add(database, data);
      if (key != null) return;
    }
    await record.update(database, data);
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

class ArtistSelectionsCollection extends _DatabaseCollection<ArtistSelection>
    implements ArtistSelectionCollection {
  ArtistSelectionsCollection(
    DatabaseClient database,
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => ArtistSelection.deserialize(data));

  @override
  ArtistSelectionsCollection through(ExecutorWrapper database) {
    return ArtistSelectionsCollection(database.executor, store);
  }

  @override
  Future<List<ArtistSelection>> getWhere({
    String userId,
  }) async {
    if (userId == null) return await getAll();
    final cuserId = ArtistSelection.properties.userId;
    final query = store.query(
      finder: Finder(filter: Filter.equals(cuserId, userId)),
    );
    final snapshots = await query.getSnapshots(database);
    return snapshots.map((e) => constructor(e.key, e.value)).toList();
  }
}

class UserArtistDetailsSembastQuery extends UserArtistDetailsQuery {
  final DatabaseClient database;

  UserArtistDetailsSembastQuery(
    this.database,
    this.scrobblesStore,
    this.artists,
  );

  final StoreRef<String, Map<String, dynamic>> scrobblesStore;
  final ArtistsCollection artists;

  @override
  UserArtistDetailsSembastQuery through(ExecutorWrapper database) {
    return UserArtistDetailsSembastQuery(
        database.executor, scrobblesStore, artists);
  }

  String _tempId(String artistId, String userId) {
    return artistId + '###' + userId;
  }

  @override
  Future<List<UserArtistDetails>> getWhere({
    List<String> userIds,
    List<String> artistIds,
    SortDirection scrobblesSort,
  }) async {
    final cuserId = TrackScrobble.properties.userId;
    final cartistId = TrackScrobble.properties.artistId;

    final query = scrobblesStore.query(
      finder: Finder(
        filter: Filter.and(
          [
            if (userIds != null && userIds.isNotEmpty)
              Filter.inList(cuserId, userIds),
            if (artistIds != null && artistIds.isNotEmpty)
              Filter.inList(cartistId, artistIds),
          ],
        ),
      ),
    );

    final tempMap = <String, int>{};
    final tempList = <UserArtistDetails>[];
    for (final scrobbleS in await query.getSnapshots(database)) {
      final scrobble = TrackScrobble.deserialize(scrobbleS.value);
      final tempId = _tempId(scrobble.artistId, scrobble.userId);
      if (!tempMap.containsKey(tempId)) {
        tempMap[tempId] = 0;
        final artist = await artists[scrobble.artistId].get();
        tempList.add(UserArtistDetails(
          artistId: scrobble.artistId,
          artistName: scrobble.artistId,
          imageInfo: artist.imageInfo,
          mbid: artist.mbid,
          url: artist.url,
          userId: scrobble.userId,
          scrobbles: -1,
        ));
      }
      tempMap[tempId]++;
    }

    final resList = <UserArtistDetails>[];
    for (final s in tempList) {
      final tempId = _tempId(s.artistId, s.userId);
      resList.add(UserArtistDetails(
        artistId: s.artistId,
        artistName: s.artistName,
        imageInfo: s.imageInfo,
        mbid: s.mbid,
        url: s.url,
        userId: s.userId,
        scrobbles: tempMap[tempId],
      ));
    }
    if (scrobblesSort != null) {
      if (scrobblesSort == SortDirection.ascending) {
        resList.sort((a, b) => a.scrobbles.compareTo(b.scrobbles));
      }
      if (scrobblesSort == SortDirection.descending) {
        resList.sort((b, a) => a.scrobbles.compareTo(b.scrobbles));
      }
    }
    return resList;
  }
}

class TrackScrobblesPerTimeSembastQuery implements TrackScrobblesPerTimeQuery {
  final StoreRef<String, Map<String, dynamic>> scrobblesStore;
  final DatabaseClient database;

  TrackScrobblesPerTimeSembastQuery(this.database, this.scrobblesStore);

  @override
  TrackScrobblesPerTimeSembastQuery through(ExecutorWrapper database) {
    return TrackScrobblesPerTimeSembastQuery(database.executor, scrobblesStore);
  }

  DateTime _groupDate(DatePeriod period, DateTime date) {
    return period.normalize(date);
  }

  String _tempId(String artistId, String userId) {
    return artistId + '###' + userId;
  }

  @override
  Future<List<TrackScrobblesPerTime>> getByArtist({
    List<String> artistIds,
    List<String> userIds,
    @required DatePeriod period,
    DateTime start,
    DateTime end,
  }) async {
    final cdate = TrackScrobble.properties.date;
    final cuserId = TrackScrobble.properties.userId;
    final cartistId = TrackScrobble.properties.artistId;

    final tempMap = <String, int>{};
    final tempList = <TrackScrobblesPerTime>[];

    final query = scrobblesStore.query(
      finder: Finder(
        filter: Filter.and([
          if (userIds != null && userIds.isNotEmpty)
            Filter.inList(cuserId, userIds),
          if (artistIds != null && artistIds.isNotEmpty)
            Filter.inList(cartistId, artistIds),
          if (start != null)
            Filter.greaterThanOrEquals(cdate, start.millisecondsSinceEpoch),
          if (end != null) Filter.lessThan(cdate, end.millisecondsSinceEpoch),
        ]),
      ),
    );

    for (final scrobbleS in await query.getSnapshots(database)) {
      final scrobble = TrackScrobble.deserialize(scrobbleS.value);
      final groupedDate = _groupDate(period, scrobble.date);
      final tempId = _tempId(scrobble.artistId, scrobble.userId);
      if (!tempMap.containsKey(tempId)) {
        tempList.add(TrackScrobblesPerTime(
          artistId: scrobble.artistId,
          count: -1,
          groupedDate: groupedDate,
          period: period,
          trackId: scrobble.trackId,
          userId: scrobble.userId,
        ));
        tempMap[tempId] = 0;
      }
      tempMap[tempId]++;
    }

    final res = <TrackScrobblesPerTime>[];
    for (final s in tempList) {
      final tempId = _tempId(s.artistId, s.userId);
      res.add(TrackScrobblesPerTime(
        artistId: s.artistId,
        groupedDate: s.groupedDate,
        period: s.period,
        trackId: s.trackId,
        userId: s.userId,
        count: tempMap[tempId],
      ));
    }

    return res;
  }
}
