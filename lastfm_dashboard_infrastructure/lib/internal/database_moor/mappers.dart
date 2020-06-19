import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:moor/moor.dart';
import 'database.dart';

abstract class MoorMapper<TDomain, TMoor extends DataClass> {
  const MoorMapper();
  Insertable<TMoor> toMoor(TDomain domain);
  TDomain toDomain(TMoor moor);
}

abstract class QueryMapper<TDomain, TMoor> {
  const QueryMapper();
  TDomain toDomain(TMoor moor);
}

class UserMapper extends MoorMapper<User, MoorUser> {
  const UserMapper();
  emptyDomain() => User();
  @override
  toDomain(m) {
    return User(
      id: m.id,
      username: m.username,
      imageInfo: ImageInfo(
        extraLarge: m.imageInfoExtraLarge,
        large: m.imageInfoLarge,
        medium: m.imageInfoMedium,
        small: m.imageInfoSmall,
      ),
      lastSync: m.lastSync,
      playCount: m.playCount,
      setupSync: UserSetupSync(
        earliestScrobble: m.setupSyncEarliestScrobble,
        passed: m.setupSyncPassed,
      ),
    );
  }

  @override
  MoorUser toMoor(d) {
    return MoorUser(
      id: d.id,
      username: d.username,
      imageInfoExtraLarge: d.imageInfo?.extraLarge,
      imageInfoLarge: d.imageInfo?.large,
      imageInfoMedium: d.imageInfo?.medium,
      imageInfoSmall: d.imageInfo?.small,
      lastSync: d.lastSync,
      playCount: d.playCount,
      setupSyncEarliestScrobble: d.setupSync?.earliestScrobble,
      setupSyncPassed: d.setupSync?.passed,
    );
  }
}

class TrackScrobbleMapper extends MoorMapper<TrackScrobble, MoorTrackScrobble> {
  const TrackScrobbleMapper();
  emptyDomain() => TrackScrobble();
  @override
  toDomain(m) {
    return TrackScrobble(
      id: m.id,
      artistId: m.artistId,
      date: m.date,
      trackId: m.trackId,
    );
  }

  @override
  MoorTrackScrobble toMoor(d) {
    return MoorTrackScrobble(
      id: d.id,
      date: d.date,
      userId: d.userId,
      artistId: d.artistId,
      trackId: d.trackId,
    );
  }
}

class ArtistMapper extends MoorMapper<Artist, MoorArtist> {
  const ArtistMapper();
  emptyDomain() => Artist();
  @override
  toDomain(m) {
    return Artist(
      imageInfo: ImageInfo(
        extraLarge: m.imageInfoExtraLarge,
        large: m.imageInfoLarge,
        medium: m.imageInfoMedium,
        small: m.imageInfoSmall,
      ),
      id: m.id,
      mbid: m.mbid,
      name: m.name,
      url: m.url,
    );
  }

  @override
  MoorArtist toMoor(d) {
    return MoorArtist(
      imageInfoExtraLarge: d.imageInfo?.extraLarge,
      imageInfoLarge: d.imageInfo?.large,
      imageInfoMedium: d.imageInfo?.medium,
      imageInfoSmall: d.imageInfo?.small,
      mbid: d.mbid,
      url: d.url,
      id: d.id,
    );
  }
}

class ArtistUserInfoMapper
    extends QueryMapper<ArtistUserInfo, ArtistsByUserDetailedResult> {
  const ArtistUserInfoMapper();
  @override
  toDomain(m) {
    return ArtistUserInfo(
      artistId: m.artistId,
      userId: m.userId,
      imageInfo: ImageInfo(
        extraLarge: m.imageInfoExtraLarge,
        large: m.imageInfoLarge,
        medium: m.imageInfoMedium,
        small: m.imageInfoSmall,
      ),
      mbid: m.mbid,
      scrobbles: m.scrobbles,
      url: m.url,
    );
  }
}

class TrackScrobblesPerTimeMapper extends QueryMapper<TrackScrobblesPerTime,
    TrackScrobblesPerTimeGetByArtistResult> {
  const TrackScrobblesPerTimeMapper();

  @override
  toDomain(m) {
    return TrackScrobblesPerTime(
      artistId: m.artistId,
      count: m.count,
      groupedDate: m.groupedDate.nullOr((c) =>
          DateTime.fromMillisecondsSinceEpoch(c)
              .subtract(DateTime.now().timeZoneOffset)),
      trackId: m.trackId,
      userId: m.userId,
    );
  }
}

class TrackMapper extends MoorMapper<Track, MoorTrack> {
  const TrackMapper();
  emptyDomain() => Track();
  @override
  toDomain(m) {
    return Track(
      artistId: m.artistId,
      loved: m.loved,
      imageInfo: ImageInfo(
        extraLarge: m.imageInfoExtraLarge,
        large: m.imageInfoLarge,
        medium: m.imageInfoMedium,
        small: m.imageInfoSmall,
      ),
      mbid: m.mbid,
      name: m.name,
      url: m.url,
    );
  }

  @override
  MoorTrack toMoor(d) {
    return MoorTrack(
      imageInfoExtraLarge: d.imageInfo?.extraLarge,
      imageInfoLarge: d.imageInfo?.large,
      imageInfoMedium: d.imageInfo?.medium,
      imageInfoSmall: d.imageInfo?.small,
      mbid: d.mbid,
      url: d.url,
      id: d.id,
      loved: d.loved,
      artistId: d.artistId,
      name: d.name,
    );
  }
}

class ArtistSelectionMapper
    extends MoorMapper<ArtistSelection, MoorArtistSelection> {
  const ArtistSelectionMapper();
  emptyDomain() => ArtistSelection();
  @override
  toDomain(m) {
    return ArtistSelection(
      id: m.id,
      artistId: m.artistId,
      color: m.selectionColor,
      userId: m.userId,
    );
  }

  @override
  MoorArtistSelection toMoor(d) {
    return MoorArtistSelection(
      id: d.id,
      artistId: d.artistId,
      selectionColor: d.color,
      userId: d.userId,
    );
  }
}
