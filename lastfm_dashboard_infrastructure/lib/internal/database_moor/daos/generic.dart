import 'dart:async';

import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:moor/moor.dart';

import '../database.dart';
import '../mappers.dart';

abstract class GenericTableAccessor<TEntity,
        TMoor extends Insertable<DataClass>>
    extends DatabaseAccessor<MoorDatabase> {
  GenericTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);
  Table get table;
  MoorMapper<TEntity, TMoor> get mapper;

  Future<void> addOrUpdate(TEntity state) async {
    final moor = mapper.toMoor(state);
    final res = await into(table).insertOnConflictUpdate(moor);
    return res;
  }

  Future<void> addOrUpdateAll(List<TEntity> states) async {
    final moors = states.map(mapper.toMoor).toList();
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(table, moors);
    });
  }

  Future<List<TEntity>> getAll() async {
    final all = await db.select(table).get();
    return all.cast<TMoor>().map(mapper.toDomain).toList();
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() action) {
    return db.transaction(() async => await action());
  }

  Future<void> deleteEntity(id) async {
    await db.delete(table)
      ..where((t) => t.primaryKey.first.equals(id));
  }

  Future<void> deleteEntityWhere(Expression<bool> statement) async {
    await db.delete(table)
      ..where((t) => statement);
  }

  Future<TEntity> get(id) async {
    final select = await db.select(table)
      ..where((t) => t.primaryKey.first.equals(id));
    final t = await select.getSingle();
    return mapper.toDomain(t as TMoor);
  }

  Future<List<TEntity>> getWhere(Expression<bool> statement) async {
    final select = await db.select(table)
      ..where((t) => statement);
    final t = await select.get();
    return t.cast<TMoor>().map(mapper.toDomain).toList();
  }
}

class UserTableAccessor extends GenericTableAccessor<User, MoorUser> {
  UserTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);

  @override
  MoorMapper<User, MoorUser> get mapper => UserMapper();

  @override
  Table get table => db.users;
}

class ArtistTableAccessor extends GenericTableAccessor<Artist, MoorArtist> {
  ArtistTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);

  @override
  MoorMapper<Artist, MoorArtist> get mapper => ArtistMapper();

  @override
  Table get table => db.artists;
}

class TrackTableAccessor extends GenericTableAccessor<Track, MoorTrack> {
  TrackTableAccessor(MoorDatabase attachedDatabase) : super(attachedDatabase);

  @override
  MoorMapper<Track, MoorTrack> get mapper => TrackMapper();

  @override
  Table get table => db.artists;
}

class TrackScrobbleTableAccessor
    extends GenericTableAccessor<TrackScrobble, MoorTrackScrobble> {
  TrackScrobbleTableAccessor(MoorDatabase attachedDatabase)
      : super(attachedDatabase);

  @override
  MoorMapper<TrackScrobble, MoorTrackScrobble> get mapper =>
      TrackScrobbleMapper();

  @override
  Table get table => db.artists;
}

class ArtistSelectionTableAccessor
    extends GenericTableAccessor<ArtistSelection, MoorArtistSelection> {
  ArtistSelectionTableAccessor(MoorDatabase attachedDatabase)
      : super(attachedDatabase);

  @override
  MoorMapper<ArtistSelection, MoorArtistSelection> get mapper =>
      ArtistSelectionMapper();

  @override
  Table get table => db.artists;
}

class ArtistsTableAccessor
    extends GenericTableAccessor<Artist, MoorArtist> {
  ArtistsTableAccessor(MoorDatabase attachedDatabase)
      : super(attachedDatabase);

  @override
  MoorMapper<Artist, MoorArtist> get mapper =>
      ArtistMapper();

  @override
  Table get table => db.artists;
}
