import 'dart:io';
import 'dart:isolate';
import 'package:lastfm_dashboard_infrastructure/internal/database_moor/daos/artist_user_info.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:shared/models.dart';

import 'daos/generic.dart';
import 'daos/track_scrobbles_per_time.dart';

part 'database.g.dart';

@UseMoor(
  include: {
    'tables.moor',
    'queries/track_scrobbles_per_time_get_by_artist.moor',
    'queries/scrobbles_count.moor',
    'queries/artists_by_user_detailed.moor',
  },
  daos: [
    UserTableAccessor,
    TrackScrobbleTableAccessor,
    TrackTableAccessor,
    ArtistSelectionTableAccessor,
    TrackScrobblesPerTimeMoorDataAccessor,
    ArtistUserInfoDataAccessor,
    ArtistTableAccessor,
  ],
)
class MoorDatabase extends _$MoorDatabase {
  MoorDatabase(String folder) : super(_openConnection(folder));
  MoorDatabase.connect(DatabaseConnection connection) : super.connect(connection);

  static Future<MoorDatabase> isolated(String folder, [String tempDirectory]) async {
    final isolate = await _createMoorIsolate(folder);
    final connection = await isolate.connect();
    final db = MoorDatabase.connect(connection);
    if (tempDirectory != null) {
      await db.setTmpDirForAndroid(tempDirectory);
    }
    return db;
  }

  Future<void> setTmpDirForAndroid(String folder) async {
    if (Platform.isAndroid) {
      await customStatement('PRAGMA temp_store_directory="${folder}"');
    }
  }

  @override
  int get schemaVersion => 1;
}

Future<MoorIsolate> _createMoorIsolate(String folder) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _startBackground,
    Tuple(folder, receivePort.sendPort),
  );
  return (await receivePort.first as MoorIsolate);
}

void _startBackground(Tuple<String, SendPort> arg) {
  final database = _openConnection(arg.a);
  final moorIsolate = MoorIsolate.inCurrent(() => DatabaseConnection.fromExecutor(database));
  arg.b.send(moorIsolate);
}

LazyDatabase _openConnection(String folder) {
  return LazyDatabase(() async {
    final file = File(p.join(folder, 'moor.sqlite'));
    return VmDatabase(file);
  });
}