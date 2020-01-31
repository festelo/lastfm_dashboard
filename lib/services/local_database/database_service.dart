import 'package:lastfm_dashboard/constants.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/models/database_mapped_model.dart';

typedef Constructor<T> = T Function(String id, Map<String, dynamic> data);

class DatabaseBuilder {
  DatabaseBuilder({
    this.path: LocalDatabaseInfo.databaseFileName,
    this.usersStorePath: LocalDatabaseInfo.usersPath,
    this.artistsStorePath: LocalDatabaseInfo.artistsPath,
    this.tracksStorePath: LocalDatabaseInfo.tracksPath,
    this.trackScrobblesStorePath: LocalDatabaseInfo.trackScrobblesPath,
  });

  final String usersStorePath;
  final String artistsStorePath;
  final String tracksStorePath;
  final String trackScrobblesStorePath;
  final String path;

  StoreRef<String, Map<String, dynamic>> usersStore() =>
    StoreRef<String, Map<String, dynamic>>(usersStorePath);

  StoreRef<String, Map<String, dynamic>> artistsStore() =>
    StoreRef<String, Map<String, dynamic>>(artistsStorePath);

  StoreRef<String, Map<String, dynamic>> tracksStore() =>
    StoreRef<String, Map<String, dynamic>>(tracksStorePath);

  StoreRef<String, Map<String, dynamic>> trackScrobblesStore() =>
    StoreRef<String, Map<String, dynamic>>(trackScrobblesStorePath);

  Future<LocalDatabaseService> build() async {
    final directory = await getApplicationDocumentsDirectory();
    final fullPath = join(directory.path, path);
    final db = await databaseFactoryIo.openDatabase(fullPath);
    return LocalDatabaseService(db,
      usersStore: usersStore(),
      artistsStore: artistsStore(),
      tracksStore: tracksStore(),
      trackScrobblesStore: trackScrobblesStore()
    );
  }
}

class LocalDatabaseService {
  final Database database;

  final UsersCollection users;
  final ArtistsCollection artists;
  final TracksCollection tracks;
  final TrackScrobblesCollection trackScrobbles;

  LocalDatabaseService(this.database, {
    @required StoreRef<String, Map<String, dynamic>> usersStore,
    @required StoreRef<String, Map<String, dynamic>> artistsStore,
    @required StoreRef<String, Map<String, dynamic>> tracksStore,
    @required StoreRef<String, Map<String, dynamic>> trackScrobblesStore
  }) : 
    users = UsersCollection(database, usersStore),
    artists = ArtistsCollection(database, artistsStore),
    tracks = TracksCollection(database, tracksStore),
    trackScrobbles = TrackScrobblesCollection(database, trackScrobblesStore);
}

class DatabaseEntity<T extends DatabaseMappedModel> {
  final String id;
  final RecordRef<String, Map<String, dynamic>> record;
  final Database database;
  final Constructor<T> constructor;

  DatabaseEntity({this.id, this.record, this.database, this.constructor});

  Future<T> get() async {
    final data = await record.get(database);
    return constructor(id, data);
  }

  Future<bool> exist(String id) async {
    return await record.exists(database);
  }

  // Future<void> update(Map<String, dynamic> data, {bool createIfNotExist = false}) async {
  //   if (createIfNotExist) {
  //     await record.add(database, data);
  //   } else {
  //     await record.update(database, data);
  //   }
  // }

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
    return record.onSnapshot(database).map((d) => d == null ? null : constructor(id, d.value));
  }

  Future<void> delete({String id}) async {
    await record.delete(database);
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
      .map((list) => list.map((d) => d == null || d.value == null ? null : constructor(d.key, d.value)).toList());
  }

  /// Create/add object to databse. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated. 
  /// 
  /// Returns object Id.
  Future<String> create(T state, {Map<String, dynamic> additional}) async {
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
  ) : super(database, store, (id, data) => User.deserialize(id, data));
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
  ) : super(database, store, (id, data) => Track.deserialize(id, data));
}

class TrackScrobblesCollection extends _DatabaseCollection<TrackScrobble> {
  TrackScrobblesCollection(
    Database database, 
    StoreRef<String, Map<String, dynamic>> store,
  ) : super(database, store, (id, data) => TrackScrobble.deserialize(id, data));

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
