import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/constants.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
//import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/models/database_mapped_model.dart';

import 'migrations.dart';

typedef Constructor<T> = T Function(String id, Map<String, dynamic> data);

class DatabaseBuilder {
  DatabaseBuilder({
    this.path = LocalDatabaseInfo.databaseFileName,
    this.usersStorePath = LocalDatabaseInfo.usersPath,
    this.artistsStorePath = LocalDatabaseInfo.artistsPath,
    this.tracksStorePath = LocalDatabaseInfo.tracksPath,
    this.trackScrobblesStorePath = LocalDatabaseInfo.trackScrobblesPath,
    this.artistSelectionsStorePath = 
      LocalDatabaseInfo.artistSelectionsStorePath,
    this.databaseVersion = LocalDatabaseInfo.databaseVersion,
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

  StoreRef<String, Map<String, dynamic>> scrobblesSubstore(String userId) =>
    StoreRef<String, Map<String, dynamic>>(
      trackScrobblesStorePath + '_' + userId
    );

  StoreRef<String, Map<String, dynamic>> artistSelectionsSubstore
    (String userId) =>
      StoreRef<String, Map<String, dynamic>>(
        artistSelectionsStorePath + '_' + userId
      );

  Future<LocalDatabaseService> build() async {
    String fullPath;
    DatabaseFactory dbFactory;
    if (kIsWeb) {
      fullPath = './' + path;
      dbFactory = null; //databaseFactoryWeb;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      fullPath = join(directory.path, path);
      dbFactory = databaseFactoryIo;
    }
    final db = await dbFactory.openDatabase(fullPath,
      version: databaseVersion,
      mode: DatabaseMode.neverFails,
      onVersionChanged: (db, oldVersion, newVersion) async {
        await migrate(
          database: db,
          databaseBuilder: this,
          current: oldVersion,
          expected: newVersion
        );
      },
    );
    return LocalDatabaseService(db,
      usersStore: usersStore(),
      artistsStore: artistsStore(),
      tracksStore: tracksStore(),
      trackScrobblesSubstore: scrobblesSubstore,
      artistSelectionsSubstore: artistSelectionsSubstore
    );
  }
}

class LocalDatabaseService {
  final Database database;

  final UsersCollection users;
  final ArtistsCollection artists;
  final TracksCollection tracks;

  LocalDatabaseService(this.database, {
    @required StoreRef<String, Map<String, dynamic>> usersStore,
    @required StoreRef<String, Map<String, dynamic>> artistsStore,
    @required StoreRef<String, Map<String, dynamic>> tracksStore,
    @required StoreRef<String, Map<String, dynamic>> 
      Function(String userId) trackScrobblesSubstore,
    @required StoreRef<String, Map<String, dynamic>> 
      Function(String userId) artistSelectionsSubstore
  }) :
    users = UsersCollection(database, usersStore, 
      trackScrobblesSubstore, artistSelectionsSubstore),
    artists = ArtistsCollection(database, artistsStore),
    tracks = TracksCollection(database, tracksStore);
}

class DatabaseEntity<T extends DatabaseMappedModel> {
  final String id;
  final RecordRef<String, Map<String, dynamic>> record;
  final Database database;
  final Constructor<T> constructor;

  DatabaseEntity({this.id, this.record, this.database, this.constructor});

  Future<T> get() async {
    final data = await record.get(database);
    if (data == null) return null;
    return constructor(id, data);
  }

  Future<bool> exist() async {
    return await record.exists(database);
  }

  Future<void> update(Map<String, dynamic> data, {
    bool createIfNotExist = false
  }) async {
    if (createIfNotExist) {
      await record.add(database, data);
    } else {
      await record.update(database, data);
    }
  }

  /// Works slow, but updates only affected properties
  /// If the object doesn't exist empty constructor will be 
  /// sent to modificator as parameter
  Future<T> updateSelective(T Function(T) modificator) async {
    final initial = constructor(id, {});
    final state = modificator(initial);
    final diff = state.diff(initial);
    final rec = await record.update(database, diff);
    return constructor(id, rec);
  }


  /// Create/add object to databse. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated. 
  /// 
  /// Returns object Id.
  Future<void> create(T state, {Map<String, dynamic> additional}) async {
    final map = state.toDbMap();
    if(additional != null) { map.addAll(additional); }
    await record.put(database, state.toDbMap());
  }

  /// Returns Stream that will return object with this [id]
  /// after every change
  Stream<T> changes(String id) {
    return record
      .onSnapshot(database)
      .map((d) => d == null ? null : constructor(id, d.value));
  }

  Future<void> delete() async {
    await record.delete(database);
  }
}
class UserEntity extends DatabaseEntity<User> {
  final StoreRef<String, Map<String, dynamic>> 
    Function(String userId) scrobblesSubstore;

  final StoreRef<String, Map<String, dynamic>> 
    Function(String userId) artistSelectionsSubstore;

  UserEntity({
    @required this.scrobblesSubstore,
    @required this.artistSelectionsSubstore,
    String id, 
    RecordRef<String, Map<String, dynamic>> record,
    Database database, 
    User Function(String, Map<String, dynamic>) constructor
  }): super(
    id: id, 
    record: record,
    database: database, 
    constructor: constructor
  );

  StoreRef<String, Map<String, dynamic>> _scrobblesStoreRef
    (String userId) => scrobblesSubstore(userId);

  StoreRef<String, Map<String, dynamic>> _artistSelectionsStoreRef
    (String userId) => artistSelectionsSubstore(userId);

  TrackScrobblesCollection get scrobbles {
    return TrackScrobblesCollection(
      database,
      _scrobblesStoreRef(id)
    );
  }

  ArtistSelectionsCollection get artistSelections {
    return ArtistSelectionsCollection(
      database,
      _artistSelectionsStoreRef(id)
    );
  }
  
  @override
  Future<void> delete() async {
    await artistSelections.delete();
    await scrobbles.delete();
    await super.delete();
  }
}

class _DatabaseCollection<T extends DatabaseMappedModel> {
  final StoreRef<String, Map<String, dynamic>> store;
  final Database database;
  final Constructor<T> constructor;

  _DatabaseCollection(this.database, this.store, this.constructor);

  DatabaseEntity<T> operator [](String id) => DatabaseEntity<T>(
    id: id,
    database: database,
    constructor: constructor,
    record: record(id)
  );

  RecordRef<String, Map<String, dynamic>> record(String id){
    return store.record(id);
  }

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
  Stream<List<T>> changes() {
    return store.query()
      .onSnapshots(database)
      .map((list) => 
        list.map((d) => d == null || d.value == null 
          ? null 
          : constructor(d.key, d.value)).toList()
      );
  }

  /// Adds object to database. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated. 
  /// 
  /// Returns object Id.
  Future<String> add(T state, {Map<String, dynamic> additional}) async {
    final map = state.toDbMap();
    if(additional != null) { map.addAll(additional); }
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
  Future<List<String>> addAll(Iterable<T> states) async {
    final List<T> statesWithId = [];
    final List<T> statesWithoutId = [];
    final List<String> ids = [];
    for(final s in states) {
      if (s.id != null) {
        statesWithId.add(s);
      } else {
        statesWithoutId.add(s);
      }
    }
    if (statesWithoutId.isNotEmpty) {
      final newIds = 
        await store
          .addAll(database, 
            statesWithoutId
              .map((s) => s.toDbMap())
              .toList()
          );
      ids.addAll(newIds);
    }
    for(final s in statesWithId) {
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
    Database database, 
    StoreRef<String, Map<String, dynamic>> store,
    this.scrobblesSubstore,
    this.artistSelectionsSubstore
  ) : super(database, store, (id, data) => User.deserialize(id, data));
  
  final StoreRef<String, Map<String, dynamic>> 
    Function(String userId) scrobblesSubstore;

  final StoreRef<String, Map<String, dynamic>> 
    Function(String userId) artistSelectionsSubstore;

  @override
  UserEntity operator [](String id) => UserEntity(
    id: id,
    database: database,
    constructor: constructor,
    record: record(id),
    scrobblesSubstore: scrobblesSubstore,
    artistSelectionsSubstore: artistSelectionsSubstore
  );

  @override
  Future<void> delete() async {
    final users = await getAll();
    final futures = users
      .map((v) => this[v.id].scrobbles.delete());
    await Future.wait(futures);
    await super.delete();
    return;
  }
}

class ArtistsCollection extends _DatabaseCollection<Artist> {
  ArtistsCollection(
    Database database, 
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => Artist.deserialize(id, data));
}

class TracksCollection extends _DatabaseCollection<Track> {
  TracksCollection(
    Database database, 
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => Track.deserialize(data));
}

class TrackScrobblesCollection extends _DatabaseCollection<TrackScrobble> {
  TrackScrobblesCollection(
    Database database, 
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => TrackScrobble.deserialize(data));

  Stream<int> countByArtistStream(String artistId) {
    return store
      .query(finder: Finder(
        filter: Filter.equals(
          TrackScrobble.properties.artistId,
          artistId
        )
      ))
      .onSnapshots(database)
      .map((s) => s.length);
  }
}

class ArtistSelectionsCollection extends _DatabaseCollection<ArtistSelection> {
  ArtistSelectionsCollection(
    Database database, 
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => ArtistSelection.deserialize(data));
}
