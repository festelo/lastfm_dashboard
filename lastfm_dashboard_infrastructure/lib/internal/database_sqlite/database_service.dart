/* YET NOT SUPPORTED CODE // TODO


import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard_infrastructure/services/database/database_service.dart';
import 'package:lastfm_dashboard_infrastructure/services/database_sqlite/db_mapper.dart';
import 'package:lastfm_dashboard_infrastructure/services/database_sqlite/mappers/user.dart';
import 'package:lastfm_dashboard_infrastructure/services/database_sqlite/mappers/user_artist_details.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:random_string/random_string.dart';
import 'package:collection/collection.dart';
import 'package:shared/models.dart';
import './db_setup_io.dart';
import 'db_info.dart';
import 'mappers/unimplemented_mapper.dart';
import 'migrations.dart';

typedef Constructor<T> = T Function(String id, Map<String, dynamic> data);

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

class SqliteDatabaseBuilder {
  SqliteDatabaseBuilder(
    SqliteDatabaseInfo info, {
    this.absolutePath = false,
    this.dbFactory,
  })  : path = info.databaseFileName,
        usersStorePath = info.usersTable,
        artistsStorePath = info.artistsTable,
        tracksStorePath = info.tracksTable,
        trackScrobblesStorePath = info.trackScrobblesTable,
        artistSelectionsStorePath = info.artistSelectionsTable,
        artistsDetailedStorePath = info.artistsDetailedView,
        databaseVersion = info.databaseVersion;

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
    return MobileDatabaseService(
      db,
      events,
      usersStorePath: usersStorePath,
      artistsStorePath: artistsStorePath,
      tracksStorePath: tracksStorePath,
      trackScrobblesStorePath: trackScrobblesStorePath,
      artistSelectionsStorePath: artistSelectionsStorePath,
      artistsDetailedStorePath: artistsDetailedStorePath,
    );
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
  final UserArtistDetailsQuery userArtistDetails;

  @override
  final TrackScrobblesPerTimeQuery trackScrobblesPerTimeQuery;

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
        userArtistDetails =
            UserArtistDetailsCollection(database, artistsDetailedStorePath),
        trackScrobblesPerTimeQuery = TrackScrobblesPerTimeQuery(
            database, events, trackScrobblesStorePath);

  @override
  Future<T> transaction<T>(FutureOr<T> Function(SqliteExecutorWrapper) action) {
    return database.transaction((t) => action(SqliteExecutorWrapper(t)));
  }

  @override
  Future<void> dispose() async {
    await database.close();
  }
}

class DatabaseReadOnlyEntity<T> implements ReadOnlyEntity<T> {
  final String id;
  final DatabaseExecutor database;
  final SqliteMapper<T> mapper;
  final String tableName;
  final PublishSubject<Event> events;
  String get cid => mapper.idColumn;

  DatabaseReadOnlyEntity({
    this.id,
    @required this.database,
    @required this.mapper,
    @required this.tableName,
    @required this.events,
  });

  @override
  DatabaseReadOnlyEntity<T, SqliteMapper<T>> through(ExecutorWrapper database) {
    return DatabaseReadOnlyEntity(
      id: id,
      tableName: tableName,
      database: database.executor,
      mapper: mapper,
      events: events,
    );
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
    return mapper.fromMap(map);
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

class DatabaseEntity<T> extends DatabaseReadOnlyEntity<T> implements Entity<T> {
  DatabaseEntity({
    String id,
    @required DatabaseExecutor database,
    @required SqliteMapper<T> mapper,
    @required String tableName,
    @required PublishSubject<Event> events,
  }) : super(
          id: id,
          database: database,
          mapper: mapper,
          tableName: tableName,
          events: events,
        );

  @override
  DatabaseEntity<T> through(ExecutorWrapper database) {
    return DatabaseEntity(
      id: id,
      tableName: tableName,
      database: database.executor,
      mapper: mapper,
      events: events,
    );
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

  @override
  Future<void> updateSelective(T Function(T) modificator,
      {bool createIfNotExist = true}) async {
    final initial = mapper.defaultValue();
    final state = modificator(initial);
    final diff = mapper.diff(state, initial);
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

abstract class DatabaseReadOnlyCollection<T> implements Queryable<T> {
  final String tableName;
  final DatabaseExecutor database;
  final PublishSubject<Event> events;
  final SqliteMapper<T> mapper;

  DatabaseReadOnlyCollection(
    this.database,
    this.tableName,
    this.events,
    this.mapper,
  );

  @override
  DatabaseReadOnlyEntity<T> operator [](String id) => DatabaseReadOnlyEntity<T>(
        id: id,
        database: database,
        mapper: mapper,
        tableName: tableName,
        events: events,
      );

  @override
  DatabaseReadOnlyCollection<T> through(ExecutorWrapper database);

  @override
  Future<List<T>> getAll() async {
    final entities = await _getAllMapped();
    return entities.map((d) => mapper.fromMap(d)).toList();
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
    yield watching.map((e) => mapper.fromMap(e)).toList();
    yield* events
        .where((e) => e.tableName == tableName)
        .asyncMap((event) => _getAllMapped())
        .where((newValues) =>
            !const DeepCollectionEquality().equals(watching, newValues))
        .map((newValues) {
      watching = newValues;
      return newValues.map((e) => mapper.fromMap(e)).toList();
    });
  }
}

abstract class DatabaseCollection<T> extends DatabaseReadOnlyCollection<T>
    implements Collection<T> {
  DatabaseCollection(
    DatabaseExecutor database,
    String tableName,
    PublishSubject<Event> events,
    SqliteMapper<T> mapper,
  ) : super(database, tableName, events, mapper);

  String get cid => mapper.idColumn;

  @override
  DatabaseEntity<T> operator [](String id) => DatabaseEntity<T>(
        id: id,
        database: database,
        mapper: mapper,
        tableName: tableName,
        events: events,
      );

  @override
  DatabaseCollection<T> through(ExecutorWrapper database);

  /// Adds object to database. If [id] is specified, then
  /// the object will be created with this Id, otherwise Id
  /// will be generated.
  @override
  Future<void> add(T state) async {
    final id = mapper.key(state) ?? newId();
    await database.insert(tableName, {cid: id, ...mapper.toMap(state)});
    events.add(Event(
        changes: [Change(id, updated: mapper.toMap(state))],
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
              cid: mapper.key(c) ?? newId(),
              ...mapper.toMap(c),
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
  ) : super(database, tableName, events, UserMapper());
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
  ) : super(database, tableName, events, UnimplementedMapper() as dynamic);

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
  ) : super(database, tableName, events, UnimplementedMapper() as dynamic);

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
  ) : super(database, tableName, events, UnimplementedMapper() as dynamic);

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
    PublishSubject<Event> events, {
    this.userArtistDetailsMapper = const UserArtistDetailsMapper(),
  }) : super(database, tableName, events, UnimplementedMapper() as dynamic);
  final UserArtistDetailsMapper userArtistDetailsMapper;

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
      if (userId != null) userArtistDetailsMapper.columns.userId + ' = ?',
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

  Future<List<Map<String, dynamic>>> _getValues(
    List<String> statements,
    List<dynamic> params,
  ) async {
    final idsQuery = [
      'SELECT * FROM $tableName',
      if (statements.isNotEmpty) 'WHERE ' + statements.join(' and\n'),
    ].join('\n');
    final idsMap = await database.rawQuery(idsQuery, [
      ...params,
    ]);
    return idsMap;
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

    var watching = await _getValues(statements, params);
    yield watching.map((e) => mapper.fromMap(e)).toList();
    yield* events
        .where((e) => e.tableName == tableName)
        .asyncMap((event) => _getValues(statements, params))
        .where((newValues) =>
            !const DeepCollectionEquality().equals(watching, newValues))
        .map((newValues) {
      watching = newValues;
      return newValues.map((e) => mapper.fromMap(e)).toList();
    });
  }

  @override
  Future<List<ArtistSelection>> getWhere({String userId}) async {
    final statements = _getWhereStatements(
      userId: userId,
    );
    assert(statements.isNotEmpty);
    final params = _getWhereParams(
      userId: userId,
    );
    final values = await _getValues(statements, params);
    return values.map((e) => mapper.fromMap(e)).toList();
  }
}

class UserArtistDetailsCollection implements UserArtistDetailsQuery {
  UserArtistDetailsCollection(
    this.database,
    this.viewName, {
    this.userArtistDetailsMapper = const UserArtistDetailsMapper(),
  });

  final UserArtistDetailsMapper userArtistDetailsMapper;
  final DatabaseExecutor database;
  final String viewName;

  @override
  UserArtistDetailsCollection through(ExecutorWrapper database) {
    return UserArtistDetailsCollection(database.executor, viewName);
  }

  List<String> _getWhereStatements({
    List<String> userIds,
    List<String> artistIds,
  }) {
    final cuserId = userArtistDetailsMapper.columns.userId;
    final cartistId = userArtistDetailsMapper.columns.artistId;
    final statements = [
      if (userIds != null && userIds.isNotEmpty)
        '$cuserId in  (${List.filled(userIds.length, '?').join(', ')})',
      if (artistIds != null && artistIds.isNotEmpty)
        '$cartistId in  (${List.filled(artistIds.length, '?').join(', ')})',
    ];
    return statements;
  }

  List<dynamic> _getWhereParams({
    List<String> userIds,
    List<String> artistIds,
  }) {
    final params = [
      if (artistIds != null && artistIds.isNotEmpty) ...artistIds,
      if (userIds != null && userIds.isNotEmpty) ...userIds,
    ];
    return params;
  }

  @override
  Future<List<UserArtistDetails>> getWhere({
    List<String> userIds,
    List<String> artistIds,
    int skip,
    int take,
    SortDirection scrobblesSort,
  }) async {
    final statements = _getWhereStatements(
      userIds: userIds,
      artistIds: artistIds,
    );
    assert(statements.isNotEmpty || skip != null || take != null);
    final params = _getWhereParams(
      userIds: userIds,
      artistIds: artistIds,
    );
    final selectQuery = [
      'SELECT * FROM $viewName',
      if (statements.isNotEmpty) 'WHERE ' + statements.join(' and\n'),
      if (scrobblesSort != null)
        'ORDER BY ${userArtistDetailsMapper.columns.scrobbles} ' +
            (scrobblesSort == SortDirection.descending ? 'desc' : 'asc'),
      if (take != null) 'LIMIT ?',
      if (skip != null) 'OFFSET ?',
    ].join('\n');
    final maps = await database.rawQuery(selectQuery, [
      ...params,
      if (take != null) take,
      if (skip != null) skip,
    ]);
    return maps.map((c) => userArtistDetailsMapper.fromMap(c)).toList();
  }
}

class TrackScrobblesPerTimeSqliteQuery implements TrackScrobblesPerTimeQuery {
  TrackScrobblesPerTimeSqliteQuery(
    this.database,
    this.events,
    this.scrobblesTable, {
    this.trackScrobblesPerTimeMapper = const UnimplementedMapper() as dynamic,
  });

  final PublishSubject<Event> events;
  final DatabaseExecutor database;
  final String scrobblesTable;

  final LiteMapper<TrackScrobblesPerTime> trackScrobblesPerTimeMapper;

  @override
  TrackScrobblesPerTimeQuery through(ExecutorWrapper database) {
    return TrackScrobblesPerTimeSqliteQuery(
        database.executor, events, scrobblesTable);
  }

  List<String> _getWhereStatements({
    List<String> ids,
    List<String> userIds,
    List<String> artistIds,
    DateTime start,
    DateTime end,
  }) {
    final cdate = TrackScrobble.properties.date;
    final cuserId = TrackScrobble.properties.userId;
    final cartistId = TrackScrobble.properties.artistId;

    final statements = [
      if (ids != null && ids.isNotEmpty)
        '$cid in  (${List.filled(ids.length, '?').join(', ')})',
      if (userIds != null && userIds.isNotEmpty)
        '$cuserId in (${List.filled(userIds.length, '?').join(', ')})',
      if (artistIds != null && artistIds.isNotEmpty)
        '$cartistId in  (${List.filled(artistIds.length, '?').join(', ')})',
      if (start != null) '$cdate >= ?',
      if (end != null) '$cdate < ?',
    ];
    return statements;
  }

  List<dynamic> _getWhereParams({
    List<String> ids,
    List<String> userIds,
    List<String> artistIds,
    DateTime start,
    DateTime end,
  }) {
    final params = [
      if (ids != null) ...ids,
      if (userIds != null) ...userIds,
      if (artistIds != null) ...artistIds,
      if (start != null) start.millisecondsSinceEpoch,
      if (end != null) end.millisecondsSinceEpoch,
    ];
    return params;
  }

  Future<List<Map<String, dynamic>>> _getValues(
    List<String> statements,
    List<dynamic> params,
    DatePeriod period,
  ) async {
    final cdate = TrackScrobble.properties.date;
    final cgroupedDate = TrackScrobblesPerTime.properties.groupedDate;
    final cuserId = TrackScrobble.properties.userId;
    final cperiod = TrackScrobblesPerTime.properties.period;
    final ccount = TrackScrobblesPerTime.properties.count;
    final cartistId = TrackScrobble.properties.artistId;

    final periodStr = period.name;

    String groupedQuery;
    if (period == DatePeriod.day) {
      groupedQuery =
          "CAST(strftime('%s000', date($cdate / 1000, 'unixepoch', 'start of day')) as INTEGER)";
    }
    if (period == DatePeriod.month) {
      groupedQuery =
          "CAST(strftime('%s000', date($cdate / 1000, 'unixepoch', 'start of month')) as INTEGER)";
    }
    if (period == DatePeriod.week) {
      groupedQuery =
          "CAST(strftime('%s000', date($cdate / 1000, 'unixepoch', '-6 days', 'weekday 1')) as INTEGER)";
    }
    if (period == DatePeriod.hour) {
      groupedQuery = '''
        (CAST(strftime('%s', date($cdate / 1000, 'unixepoch', 'start of day')) as INTEGER) + (($cdate / 1000) - 
         CAST(strftime('%s', date($cdate / 1000, 'unixepoch', 'start of day')) as INTEGER)) / 3600 * 3600) * 1000
      ''';
    }

    final idsQuery = [
      '''
      SELECT
        $groupedQuery as $cgroupedDate,
        '$periodStr' as $cperiod,
        $cuserId,
        $cartistId,
        count(*) as $ccount
      FROM $scrobblesTable''',
      if (statements.isNotEmpty) 'WHERE ' + statements.join(' and\n'),
      '''
      GROUP BY
        $cgroupedDate,
        $cartistId,
        $cuserId''',
    ].join('\n');
    final idsMap = await database.rawQuery(idsQuery, [
      ...params,
    ]);
    return idsMap;
  }

  @override
  Future<List<TrackScrobblesPerTime>> getByArtist({
    List<String> ids,
    List<String> artistIds,
    List<String> userIds,
    @required DatePeriod period,
    DateTime start,
    DateTime end,
  }) async {
    final statements = _getWhereStatements(
      ids: ids,
      userIds: userIds,
      artistIds: artistIds,
      start: start,
      end: end,
    );
    assert(statements.isNotEmpty);
    final params = _getWhereParams(
      ids: ids,
      userIds: userIds,
      artistIds: artistIds,
      start: start,
      end: end,
    );

    final values = await _getValues(statements, params, period);
    return values.map((e) => trackScrobblesPerTimeMapper.fromMap(e)).toList();
  }
}
*/