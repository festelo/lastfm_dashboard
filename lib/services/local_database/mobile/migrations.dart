import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

final _migrations = <int, Future<void> Function(Database)>{
  0: (db) async {
    await db.execute('''CREATE TABLE users (
      id TEXT PRIMARY KEY NOT NULL,
      lastSync INTEGER NOT NULL DEFAULT 0,
      playCount INTEGER NOT NULL DEFAULT 0,
      imageInfo_small TEXT,
      imageInfo_medium TEXT,
      imageInfo_large TEXT,
      imageInfo_extraLarge TEXT,
      setupSync_passed BOOLEAN NOT NULL DEFAULT 0,
      setupSync_latestScrobble INTEGER
    )''');
    await db.execute('''CREATE TABLE artists (
      id TEXT PRIMARY KEY NOT NULL,
      mbid TEXT,
      url TEXT,
      imageInfo_small TEXT,
      imageInfo_medium TEXT,
      imageInfo_large TEXT,
      imageInfo_extraLarge TEXT
    )''');
    await db.execute('''CREATE TABLE tracks (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT,
      mbid TEXT,
      url TEXT,
      artistId TEXT,
      loved BOOLEAN NOT NULL DEFAULT 0,
      imageInfo_small TEXT,
      imageInfo_medium TEXT,
      imageInfo_large TEXT,
      imageInfo_extraLarge TEXT
    )''');
    await db.execute('''CREATE TABLE track_scrobbles (
      id TEXT PRIMARY KEY NOT NULL,
      trackId TEXT,
      artistId TEXT,
      userId TEXT NOT NULL,
      date INTEGER
    )''');
    await db.execute('''CREATE TABLE artist_selections (
      id TEXT PRIMARY KEY NOT NULL,
      artistId TEXT NOT NULL UNIQUE,
      userId TEXT NOT NULL,
      selectionColor INTEGER
    )''');
    await db.execute('''CREATE VIEW scrobbles_count 
    AS
    SELECT 
      artistid,
      userId,
      count(*) as scrobbles
    FROM 
      track_scrobbles
    GROUP BY 
      artistid,
      userId;
    ''');
    await db.execute('''CREATE VIEW artists_by_user_detailed 
    AS
    SELECT
      scrobbles_count.artistId || '@' || scrobbles_count.userId as id,
      scrobbles_count.artistId as name,
      artists.mbid,
      artists.url,
      scrobbles,
      artist_selections.selectionColor as selectionColor,
      CASE WHEN artist_selections.selectionColor IS NOT NULL
        THEN 1
        ELSE 0
      END AS selected,
      scrobbles_count.userId as userId,
      artists.imageInfo_small,
      artists.imageInfo_medium,
      artists.imageInfo_large,
      artists.imageInfo_extraLarge
    FROM scrobbles_count
    LEFT JOIN artist_selections ON 
      artist_selections.artistId = scrobbles_count.artistId and
      artist_selections.userId = scrobbles_count.userId
    INNER JOIN artists ON artists.id = scrobbles_count.artistId
    ''');
  },
  1: (db) async {
    await db.execute('''DROP VIEW IF EXISTS artists_by_user_detailed ''');
    await db.execute('''CREATE VIEW artists_by_user_detailed 
    AS
    SELECT
      scrobbles_count.artistId || '@' || scrobbles_count.userId as id,
      scrobbles_count.artistId as name,
      scrobbles_count.artistId,
      artists.mbid,
      artists.url,
      scrobbles,
      scrobbles_count.userId as userId,
      artists.imageInfo_small,
      artists.imageInfo_medium,
      artists.imageInfo_large,
      artists.imageInfo_extraLarge
    FROM scrobbles_count
    INNER JOIN artists ON artists.id = scrobbles_count.artistId
    ''');
  }
};

Future<void> migrate({
  @required Database database,
  @required int current,
  @required int expected,
}) async {
  for (var i = current; i < expected; i++) {
    if (_migrations[i] != null) await _migrations[i](database);
  }
}
