import 'dart:io';
import 'package:lastfm_dashboard_infrastructure/internal/database_moor/daos/artist_user_info.dart';
import 'package:moor/moor.dart';

import 'daos/generic.dart';
import 'daos/track_scrobbles_per_time.dart';

part 'database.g.dart';

@UseMoor(
  include: {
    'tables.moor',
    'queries/track_scrobbles_per_time_get_by_artist.moor',
    'queries/scrobbles_count.moor',
    'queries/artists_by_user_detailed.moor',
    'queries/get_last_first_scrobble_date.moor',
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
  MoorDatabase(QueryExecutor e) : super(e);
  MoorDatabase.connect(DatabaseConnection connection) : super.connect(connection);
  Future<void> setTmpDirForAndroid(String folder) async {
    if (Platform.isAndroid) {
      await customStatement('PRAGMA temp_store_directory="${folder}"');
    }
  }

  @override
  int get schemaVersion => 1;
}