import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/constants.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lastfm_dashboard/extensions.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/models/database_mapped_model.dart';
import 'package:random_string/random_string.dart';
import 'package:collection/collection.dart';
import '../database_service.dart';
import './db_setup_io.dart';
import 'migrations.dart';

typedef Constructor<T> = T Function(String id, Map<String, dynamic> data);

const String cid = MobileDatabaseInfo.idColumn;

class SqliteDatabaseException implements Exception {
  final String message;
  SqliteDatabaseException(this.message);
}

class Change {
  final dynamic id;
  final Map<String, dynamic> updated;
  final bool deleted;
  Change(this.id, {this.updated = const {}, this.deleted = false});
}

class Event {
  final String tableName;
  final List<dynamic> itemsId;
  final List<Change> changes;
  Event(
      {@required this.tableName,
      @required this.itemsId,
      @required this.changes});
}

class SqliteExecutorWrapper extends ExecutorWrapper {
  @override
  final DatabaseExecutor executor;
  SqliteExecutorWrapper(this.executor);
}

String newId() => randomString(128);

class MobileDatabaseBuilder {
  MobileDatabaseBuilder(
      {this.path = MobileDatabaseInfo.databaseFileName,
      this.absolutePath = false,
      this.usersStorePath = MobileDatabaseTableNames.usersPath,
      this.artistsStorePath = MobileDatabaseTableNames.artistsPath,
      this.tracksStorePath = MobileDatabaseTableNames.tracksPath,
      this.trackScrobblesStorePath =
          MobileDatabaseTableNames.trackScrobblesPath,
      this.artistsDetailedStorePath =
          MobileDatabaseViewNames.artistsDetailedPath,
      this.artistSelectionsStorePath =
          MobileDatabaseTableNames.artistSelectionsStorePath,
      this.databaseVersion = MobileDatabaseInfo.databaseVersion,
      this.dbFactory});

  final String usersStorePath;
  final String artistsStorePath;
  final String tracksStorePath;
  final String trackScrobblesStorePath;
  final String artistSelectionsStorePath;
  final String artistsDetailedStorePath;
  final String path;
  final bool absolutePath;
  final int databaseVersion;
  final DatabaseFactory dbFactory;

  Future<MobileDatabaseService> build() async {
    final fullPath = absolutePath ? path : await getFullPath(path);
    final dbFactory = this.dbFactory ?? databaseFactory;
    final db = await dbFactory.openDatabase(
      fullPath,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onUpgrade: (db, oldVersion, newVersion) async => await migrate(
          database: db,
          current: oldVersion,
          expected: newVersion,
        ),
      ),
    );
    final events = PublishSubject<Event>();
    return MobileDatabaseService(db, events,
        usersStorePath: usersStorePath,
        artistsStorePath: artistsStorePath,
        tracksStorePath: tracksStorePath,
        trackScrobblesStorePath: trackScrobblesStorePath,
        artistSelectionsStorePath: artistSelectionsStorePath,
        artistsDetailedStorePath: artistsDetailedStorePath);
  }
}

class MobileDatabaseService extends LocalDatabaseService {
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
  final UserArtistDetailsQueryable userArtistDetails;

  final PublishSubject<Event> events;

  MobileDatabaseService(
    this.database,
    this.events, {
    @required String usersStorePath,
    @required String artistsStorePath,
    @required String tracksStorePath,
    @required String trackScrobblesStorePath,
    @required String artistSelectionsStorePath,
    @required String artistsDetailedStorePath,
  })  : users = UsersCollection(database, usersStorePath, events),
        artists = ArtistsCollection(database, artistsStorePath, events),
        tracks = TracksCollection(database, tracksStorePath, events),
        trackScrobbles =
            TrackScrobblesCollection(database, trackScrobblesStorePath, events),
        artistSelections = ArtistSelectionsCollection(
            database, artistSelectionsStorePath, events),
        userArtistDetails = UserArtistDetailsCollection(
            database, artistsDetailedStorePath, events, [
          trackScrobblesStorePath,
          artistsStorePath,
        ]);

  @override
  Future<T> transaction<T>(FutureOr<T> Function(SqliteExecutorWrapper) action) {
    return database.transaction((t) => action(SqliteExecutorWrapper(t)));
  }
}

class DatabaseReadOnlyEntity<T extends DatabaseMappedModel>
    implements ReadOnlyEntity<T> {
  final String id;
  final DatabaseExecutor database;
  final Constructor<T> constructor;
  final String tableName;
  final PublishSubject<Event> events;

  DatabaseReadOnlyEntity({
    this.id,
    @required this.database,
    @required this.constructor,
    @required this.tableName,
    @required this.events,
  });

  @override
  DatabaseReadOnlyEntity<T> through(ExecutorWrapper database) {
    return DatabaseReadOnlyEntity(
        id: id,
        tableName: tableName,
        database: database.executor,
        constructor: constructor,
        events: events);
  }

  @override
  Future<T> get() async {
    final elements = await database.query(
      tableName,
      where: '"$cid" = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (elements.isEmpty) return null;
    final map = elements.first;
    return constructor(id, map);
  }

  Future<bool> exists() async {
    final elements = await database.query(
      tableName,
      where: '"$cid" = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (elements.isEmpty) return false;
    return true;
  }

  /// Returns Stream that will emits
  /// after every change
  Stream<Event> changes() async* {
    await for (final e in events
        .where((e) => e.tableName == tableName && e.itemsId.contains(id))) {
      yield e;
    }
  }
}

class DatabaseEntity<T extends DatabaseMappedModel>
    extends DatabaseReadOnlyEntity<T> implements Entity<T> {
  DatabaseEntity({
    String id,
    @required DatabaseExecutor database,
    @required Constructor<T> constructor,
    @required String tableName,
    @required PublishSubject<Event> events,
  }) : super(
            id: id,
            database: database,
            constructor: constructor,
            tableName: tableName,
            events: events);

  @override
  DatabaseEntity<T> through(ExecutorWrapper database) {
    return DatabaseEntity(
        id: id,
        tableName: tableName,
        database: database.executor,
        constructor: constructor,
        events: events);
  }

  Future<void> _update(Map<String, dynamic> data,
      {bool createIfNotExist = false}) async {
    assert(createIfNotExist || this.id != null);
    final id = this.id ?? newId();
    if (createIfNotExist) {
      final columns = data.keys.map((e) => '[$e]').join(', ');
      final placeholders = List.filled(data.keys.length, '?').join(', ');
      final setStatements = data.keys.map((e) => '[$e] = ?').join(',\n');
      /* UPSERT IS NOT SUPPORTED CURRENTLY
      final setStatements =
          data.keys.map((e) => '[$e] = excluded.[$e]').join(',\n');
      await database.execute(''' 
        INSERT INTO $tableName ($cid, $columns)
          VALUES(?, $placeholders) 
          ON CONFLICT($cid) 
          DO UPDATE SET $setStatements;
        ''', [
        id,
        ...data.values,
      ]);
      */
      final batch = database.batch();
      batch.rawInsert('''
         INSERT OR IGNORE INTO $tableName ($cid, $columns) VALUES(?, $placeholders)
      ''', [id, ...data.values]);
      batch.rawInsert('''
         UPDATE $tableName SET $setStatements WHERE $cid=?
      ''', [...data.values, id]);
      await batch.commit(noResult: true);
    } else {
      if (id == null) throw Exception('ID must be set');
      final setStatements = data.keys.map((e) => '[$e] = ?').join(',\n');
      final updated = await database.rawUpdate(''' 
        UPDATE $tableName SET $setStatements WHERE $cid = ?;
        ''', [...data.values, id]);
      if (updated != 1)
        throw SqliteDatabaseException(
            'Entities updated: $updated. Expected: 1');
    }
    events.add(Event(
        changes: [Change(id, updated: data)],
        itemsId: [id],
        tableName: tableName));
  }

  /// Updates only affected properties
  /// Eempty constructor will be
  /// sent to modificator as parameter
  @override
  Future<void> updateSelective(T Function(T) modificator,
      {bool createIfNotExist = true}) async {
    final initial = constructor(id, {});
    final state = modificator(initial);
    final diff = state.diff(initial).flat();
    await _update(diff, createIfNotExist: createIfNotExist);
  }

  @override
  Future<void> delete() async {
    await database.delete(tableName, where: '$cid = ?', whereArgs: [id]);
    events.add(Event(
        changes: [Change(id, deleted: true)],
        itemsId: [id],
        tableName: tableName));
  }
}

abstract class DatabaseReadOnlyCollection<T extends DatabaseMappedModel>
    implements Queryable<T> {
  final String tableName;
  final DatabaseExecutor database;
  final Constructor<T> constructor;
  final PublishSubject<Event> events;

  DatabaseReadOnlyCollection(
    this.database,
    this.tableName,
    this.events,
    this.constructor,
  );

  @override
  DatabaseReadOnlyEntity<T> operator [](String id) => DatabaseReadOnlyEntity<T>(
      id: id,
      database: database,
      constructor: constructor,
      tableName: tableName,
      events: events);

  @override
  DatabaseReadOnlyCollection<T> through(ExecutorWrapper database);

  @override
  Future<List<T>> getAll() async {
    final entities = await _getAllMapped();
    return entities.map((d) => constructor(d[cid], d)).toList();
  }

  Future<List<Map<String, dynamic>>> _getAllMapped() async {
    final entities = await database.query(tableName);
    return entities;
  }

  /// Returns Stream that will emits
  /// after every change
  @override
  Stream<List<T>> changes() async* {
    var watching = await _getAllMapped();
    yield watching.map((e) => constructor(e[cid], e)).toList();
    yield* events
        .where((e) => e.tableName == tableName)
        .asyncMap((event) => _getAllMapped())
        .where((newValues) =>
            !const DeepCollectionEquality().equals(watching, newValues))
        .map((newValues) {
      watching = newValues;
      return newValues.map((e) => constructor(e[cid], e)).toList();
    });
  }
}

abstract class DatabaseCollection<T extends DatabaseMappedModel>
    extends DatabaseReadOnlyCollection<T> implements Collection<T> {
  DatabaseCollection(
    DatabaseExecutor database,
    String tableName,
    PublishSubject<Event> events,
    Constructor<T> constructor,
  ) : super(database, tableName, events, constructor);

  @override
  DatabaseEntity<T> operator [](String id) => DatabaseEntity<T>(
      id: id,
      database: database,
      constructor: constructor,
      tableName: tableName,
      events: events);

  @override
  DatabaseCollection<T> through(ExecutorWrapper database);

  /// Adds object to database. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated.
  @override
  Future<void> add(T state) async {
    final id = state.id ?? newId();
    await database.insert(tableName, {cid: id, ...state.toDbMapFlat()});
    events.add(Event(
        changes: [Change(id, updated: state.toDbMapFlat())],
        itemsId: [id],
        tableName: tableName));
  }

  /// Adds objects to database. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated.
  ///
  /// Returns object Id.
  @override
  Future<void> addAll(List<T> states) async {
    if (states.isEmpty) return;
    final maps = states
        .map((c) => {
              cid: c.id ?? newId(),
              ...c.toDbMapFlat(),
            })
        .toList();
    final keys = maps.first.keys.toList();
    final columns = keys.map((e) => '[$e]').join(', ');
    final valuesPlaceholders = List.filled(keys.length, '?').join(', ');
    final batch = database.batch();
    for (final m in maps) {
      final values = keys.map((k) => m[k]).toList();
      batch.rawInsert('''
        INSERT OR IGNORE INTO '$tableName' ($columns) VALUES ($valuesPlaceholders);
      ''', values);
    }
    await batch.commit(noResult: true);
    events.add(Event(
      itemsId: maps.map((c) => c[cid]).toList(),
      changes:
          maps.map((c) => Change(c[cid], updated: c..remove(cid))).toList(),
      tableName: tableName,
    ));
  }
}

class UsersCollection extends DatabaseCollection<User> {
  UsersCollection(
    DatabaseExecutor database,
    String tableName,
    PublishSubject<Event> events,
  ) : super(database, tableName, events,
            (id, data) => User.deserialize(id, data));
  @override
  UsersCollection through(ExecutorWrapper database) {
    return UsersCollection(database.executor, tableName, events);
  }
}

class ArtistsCollection extends DatabaseCollection<Artist> {
  ArtistsCollection(
    DatabaseExecutor database,
    String tableName,
    PublishSubject<Event> events,
  ) : super(database, tableName, events,
            (id, data) => Artist.deserialize(id, data));

  @override
  ArtistsCollection through(ExecutorWrapper database) {
    return ArtistsCollection(database.executor, tableName, events);
  }
}

class TracksCollection extends DatabaseCollection<Track> {
  TracksCollection(
    DatabaseExecutor database,
    String tableName,
    PublishSubject<Event> events,
  ) : super(database, tableName, events, (id, data) => Track.deserialize(data));

  @override
  TracksCollection through(ExecutorWrapper database) {
    return TracksCollection(database.executor, tableName, events);
  }
}

class TrackScrobblesCollection extends DatabaseCollection<TrackScrobble> {
  TrackScrobblesCollection(
    DatabaseExecutor database,
    String tableName,
    PublishSubject<Event> events,
  ) : super(database, tableName, events,
            (id, data) => TrackScrobble.deserialize(data));

  @override
  TrackScrobblesCollection through(ExecutorWrapper database) {
    return TrackScrobblesCollection(database.executor, tableName, events);
  }
}

class ArtistSelectionsCollection extends DatabaseCollection<ArtistSelection>
    implements ArtistSelectionCollection {
  ArtistSelectionsCollection(
    DatabaseExecutor database,
    String tableName,
    PublishSubject<Event> events,
  ) : super(database, tableName, events,
            (id, data) => ArtistSelection.deserialize(data));

  @override
  ArtistSelectionsCollection through(ExecutorWrapper database) {
    return ArtistSelectionsCollection(database.executor, tableName, events);
  }

  List<String> _getWhereStatements({
    List<String> ids,
    String userId,
  }) {
    final statements = [
      if (ids != null && ids.isNotEmpty)
        '$cid in  (${List.filled(ids.length, '?').join(', ')})',
      if (userId != null) UserArtistDetails.properties.userId + ' = ?',
    ];
    return statements;
  }

  List<dynamic> _getWhereParams({
    List<String> ids,
    String userId,
  }) {
    final params = [
      if (ids != null && ids.isNotEmpty) ...ids,
      if (userId != null) userId,
    ];
    return params;
  }

  @override
  Stream<List<ArtistSelection>> changesWhere({String userId}) async* {
    final statements = _getWhereStatements(
      userId: userId,
    );
    assert(statements.isNotEmpty);
    final params = _getWhereParams(
      userId: userId,
    );
    Future<List<Map<String, dynamic>>> getValues() async {
      final idsQuery = [
        'SELECT * FROM $tableName',
        if (statements.isNotEmpty) 'WHERE ' + statements.join(' and\n'),
      ].join('\n');
      final idsMap = await database.rawQuery(idsQuery, [
        ...params,
      ]);
      return idsMap;
    }

    var watching = await getValues();
    yield watching.map((e) => constructor(e[cid], e)).toList();
    yield* events
        .where((e) => e.tableName == tableName)
        .asyncMap((event) => getValues())
        .where((newValues) =>
            !const DeepCollectionEquality().equals(watching, newValues))
        .map((newValues) {
      watching = newValues;
      return newValues.map((e) => constructor(e[cid], e)).toList();
    });
  }
}

class UserArtistDetailsCollection
    extends DatabaseReadOnlyCollection<UserArtistDetails>
    implements UserArtistDetailsQueryable {
  UserArtistDetailsCollection(DatabaseExecutor database, String tableName,
      PublishSubject<Event> events, this.dependsTables)
      : super(database, tableName, events,
            (id, data) => UserArtistDetails.deserialize(id, data));
  final List<String> dependsTables;

  @override
  UserArtistDetailsCollection through(ExecutorWrapper database) {
    return UserArtistDetailsCollection(
        database.executor, tableName, events, dependsTables);
  }

  List<String> _getWhereStatements({
    List<String> ids,
    String userId,
  }) {
    final statements = [
      if (ids != null && ids.isNotEmpty)
        '$cid in  (${List.filled(ids.length, '?').join(', ')})',
      if (userId != null) UserArtistDetails.properties.userId + ' = ?',
    ];
    return statements;
  }

  List<dynamic> _getWhereParams({
    List<String> ids,
    String userId,
  }) {
    final params = [
      if (ids != null && ids.isNotEmpty) ...ids,
      if (userId != null) userId,
    ];
    return params;
  }

  @override
  Stream<List<UserArtistDetails>> changesWhere(
      {List<String> ids,
      String userId,
      int skip,
      int take,
      SortDirection scrobblesSort}) async* {
    final statements = _getWhereStatements(
      ids: ids,
      userId: userId,
    );
    assert(statements.isNotEmpty || skip != null || take != null);
    final params = _getWhereParams(
      ids: ids,
      userId: userId,
    );
    Future<List<Map<String, dynamic>>> getValues() async {
      final idsQuery = [
        'SELECT * FROM $tableName',
        if (statements.isNotEmpty) 'WHERE ' + statements.join(' and\n'),
        if (scrobblesSort != null)
          'ORDER BY ${UserArtistDetails.properties.scrobbles} ' +
              (scrobblesSort == SortDirection.descending ? 'desc' : 'asc'),
        if (take != null) 'LIMIT ?',
        if (skip != null) 'OFFSET ?',
      ].join('\n');
      final idsMap = await database.rawQuery(idsQuery, [
        ...params,
        if (take != null) take,
        if (skip != null) skip,
      ]);
      return idsMap;
    }

    var watching = await getValues();
    yield watching.map((e) => constructor(e[cid], e)).toList();
    yield* events
        .where((e) => dependsTables.contains(e.tableName))
        .asyncMap((event) => getValues())
        .where((newValues) =>
            !const DeepCollectionEquality().equals(watching, newValues))
        .map((newValues) {
      watching = newValues;
      return newValues.map((e) => constructor(e[cid], e)).toList();
    });
  }

  @override
  Stream<int> countWhere({List<String> ids, String userId}) async* {
    final statements = _getWhereStatements(
      ids: ids,
      userId: userId,
    );
    assert(statements.isNotEmpty);
    final params = _getWhereParams(
      ids: ids,
      userId: userId,
    );
    final countQuery = '''
      SELECT COUNT(*) FROM $tableName WHERE
        ${statements.join(' and\n')};
    ''';
    var watching =
        Sqflite.firstIntValue(await database.rawQuery(countQuery, params));
    yield watching;
    yield* events
        .where((e) => dependsTables.contains(e.tableName))
        .asyncMap((event) => database.rawQuery(countQuery, params))
        .map((event) => Sqflite.firstIntValue(event))
        .where((newValue) => newValue != watching)
        .map((newValue) {
      watching = newValue;
      return newValue;
    });
  }

  @override
  Future<List<UserArtistDetails>> getWhere(
      {List<String> ids,
      String userId,
      int skip,
      int take,
      SortDirection scrobblesSort}) async {
    final statements = _getWhereStatements(
      ids: ids,
      userId: userId,
    );
    assert(statements.isNotEmpty || skip != null || take != null);
    final params = _getWhereParams(
      ids: ids,
      userId: userId,
    );
    final selectQuery = [
      'SELECT * FROM $tableName',
      if (statements.isNotEmpty) 'WHERE ' + statements.join(' and\n'),
      if (scrobblesSort != null)
        'ORDER BY ${UserArtistDetails.properties.scrobbles} ' +
            (scrobblesSort == SortDirection.descending ? 'desc' : 'asc'),
      if (take != null) 'LIMIT ?',
      if (skip != null) 'OFFSET ?',
    ].join('\n');
    final maps = await database.rawQuery(selectQuery, [
      ...params,
      if (take != null) take,
      if (skip != null) skip,
    ]);
    return maps.map((c) => constructor(c[cid], c)).toList();
  }
}
