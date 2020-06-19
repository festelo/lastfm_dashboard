import 'dart:io';
import 'package:lastfm_dashboard_infrastructure/internal/database_moor/daos/artist_user_info.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:path/path.dart' as p;

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

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection(String folder) {
  return LazyDatabase(() async {
    final file = File(p.join(folder, 'moor.sqlite'));
    return VmDatabase(file);
  });
}
