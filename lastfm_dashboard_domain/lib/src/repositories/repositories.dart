import 'dart:async';

import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:lastfm_dashboard_domain/src/models/artist_user_info.dart';
import 'package:shared/models.dart';

import '../../domain.dart';
import '../../domain.dart';
part 'base.dart';

enum SortDirection { ascending, descending }

abstract class TrackScrobblesPerTimeRepository
    extends _TranscationableRepository {
  Future<List<TrackScrobblesPerTime>> getByArtist({
    DatePeriod period,
    List<String> userIds,
    List<String> artistIds,
    DateTime start,
    DateTime end,
  });
}

abstract class ArtistSelectionsRepository
    extends _CollectionRepository<ArtistSelection> {
  Future<List<ArtistSelection>> getWhere({
    String userId,
  });
  Future<void> createOrUpdate(ArtistSelection sel);
  Future<void> deleteForUser(String userId, String artistId);
}

abstract class ArtistUserInfoRepository extends _TranscationableRepository {
  Future<List<ArtistUserInfo>> getWhere({
    List<String> artistIds,
    List<String> userIds,
    SortDirection scrobblesSort,
  });
}

abstract class TrackScrobblesRepository
    extends _CollectionRepository<TrackScrobble> {}

abstract class UsersRepository extends _CollectionRepository<User> {}

abstract class ArtistsRepository extends _CollectionRepository<Artist> {}

abstract class TracksRepository extends _CollectionRepository<Track> {}
