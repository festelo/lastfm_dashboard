import 'dart:async';

import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:moor/moor.dart';
import 'package:shared/models.dart';

import '../database.dart';
import '../mappers.dart';

abstract class GenericTableAccessor<TEntity, TMoor extends DataClass,
    TTable extends Table> extends DatabaseAccessor<MoorDatabase> {
  GenericTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);

  TableInfo<TTable, TMoor> get tableInfo;
  MoorMapper<TEntity, TMoor> get mapper;

  Future<void> addOrUpdate(TEntity state) async {
    final moor = mapper.toMoor(state);
    final res =
        await into(tableInfo).insert(moor, mode: InsertMode.insertOrReplace);
    return res;
  }

  Future<void> addOrUpdateAll(List<TEntity> states) async {
    final moors = states.map(mapper.toMoor).toList();
    await db.batch((batch) {
      batch.insertAll(tableInfo, moors, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<TEntity>> getAll() async {
    final all = await db.select(tableInfo).get();
    return all.cast<TMoor>().map(mapper.toDomain).toList();
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() action) {
    return db.transaction(() async => await action());
  }

  Future<void> deleteEntity(id) async {
    await db.delete(tableInfo)
      ..where((t) => t.primaryKey.first.equals(id));
  }

  Future<void> deleteEntityWhere(Expression<bool> statement) async {
    await db.delete(tableInfo)
      ..where((t) => statement);
  }

  Future<TEntity> get(id) async {
    final select = await db.select(tableInfo)
      ..where((t) => t.primaryKey.first.equals(id));
    final t = await select.getSingle();
    return t.nullOr((t) => mapper.toDomain(t as TMoor));
  }

  Future<List<TEntity>> getWhere(Expression<bool> statement) async {
    final select = await db.select(tableInfo)
      ..where((t) => statement);
    final t = await select.get();
    return t.cast<TMoor>().map(mapper.toDomain).toList();
  }
}

class UserTableAccessor extends GenericTableAccessor<User, MoorUser, Users> {
  UserTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);

  @override
  MoorMapper<User, MoorUser> get mapper => UserMapper();

  @override
  Users get tableInfo => db.users;
}

class ArtistTableAccessor
    extends GenericTableAccessor<Artist, MoorArtist, Artists> {
  ArtistTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);

  @override
  MoorMapper<Artist, MoorArtist> get mapper => ArtistMapper();

  @override
  Artists get tableInfo => db.artists;
}

class TrackTableAccessor
    extends GenericTableAccessor<Track, MoorTrack, Tracks> {
  TrackTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);

  @override
  MoorMapper<Track, MoorTrack> get mapper => TrackMapper();

  @override
  Tracks get tableInfo => db.tracks;
}

class TrackScrobbleTableAccessor extends GenericTableAccessor<TrackScrobble,
    MoorTrackScrobble, TrackScrobbles> {
  TrackScrobbleTableAccessor(MoorDatabase attachedDatabase)
      : super(attachedDatabase);

  @override
  MoorMapper<TrackScrobble, MoorTrackScrobble> get mapper =>
      TrackScrobbleMapper();

  @override
  TrackScrobbles get tableInfo => db.trackScrobbles;

  Future<Pair<DateTime>> getScrobblesBounds({
    List<String> userIds,
    List<String> artistIds,
  }) async {
    final where =
        tableInfo.userId.isIn(userIds) & tableInfo.artistId.isIn(artistIds);
    final data = await db.get_last_first_scrobble_date(where).getSingle();
    return Pair(data.firstScrobbleDate, data.lastScrobbleDate);
  }
}

class ArtistSelectionTableAccessor extends GenericTableAccessor<ArtistSelection,
    MoorArtistSelection, ArtistSelections> {
  ArtistSelectionTableAccessor(MoorDatabase attachedDatabase)
      : super(attachedDatabase);

  @override
  MoorMapper<ArtistSelection, MoorArtistSelection> get mapper =>
      ArtistSelectionMapper();

  @override
  ArtistSelections get tableInfo => db.artistSelections;
}
