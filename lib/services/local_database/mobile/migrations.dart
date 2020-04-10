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
      setupSync_latestScrobble INTEGER NOT NULL DEFAULT 0
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
    await db.execute('''CREATE VIEW artists_by_user_detailed 
    AS
    SELECT
      artists.id,
      artists.mbid,
      artists.url,
      (SELECT COUNT(*) FROM track_scrobbles 
        WHERE track_scrobbles.artistId = artists.id and 
        track_scrobbles.userId = users.id
      ) as scrobbles,
      artist_selections.selectionColor as selectionColor,
      CASE WHEN artist_selections.selectionColor IS NOT NULL
        THEN 1
        ELSE 0
      END AS selected,
      users.id as userId,
      artists.imageInfo_small,
      artists.imageInfo_medium,
      artists.imageInfo_large,
      artists.imageInfo_extraLarge
    FROM artists
    CROSS JOIN users
    LEFT JOIN artist_selections ON 
      artist_selections.artistId = artists.id and
      artist_selections.userId = users.id
    ''');
  },
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
