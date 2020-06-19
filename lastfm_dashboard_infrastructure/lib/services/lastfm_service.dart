import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:lastfm_dashboard_infrastructure/internal/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard_infrastructure/models.dart';
import 'package:moor/moor.dart';

class UpdateInfo {
  final List<TrackScrobble> newScrobbles;
  final List<Artist> newArtists;
  final List<Track> newTracks;
  UpdateInfo({
    this.newArtists = const [],
    this.newScrobbles = const [],
    this.newTracks = const [],
  });
}

class LastFMService {
  LastFMService({
    @required this.api,
    @required this.users,
    @required this.artists,
    @required this.tracks,
    @required this.trackScrobbles,
  });
  final LastFMApi api;
  final UsersRepository users;
  final ArtistsRepository artists;
  final TracksRepository tracks;
  final TrackScrobblesRepository trackScrobbles;

  Future<void> updateUserById(String id) async {
    final user = await users.get(id);
    return await updateUser(user);
  }

  Future<User> getUser(String username) async {
    final user = await api.getUser(username);
    return User(
      id: '#@#${user.username}',
      imageInfo: user.imageInfo,
      lastSync: null,
      playCount: user.playCount,
      setupSync: user.setupSync,
      username: user.username,
    );
  }

  Stream<UpdateInfo> updateUser(User user,
      [CancellationToken cancellationToken]) async* {
    if (!user.setupSync.passed) {
      final substream =
          _updateUser(user, null, user.setupSync.earliestScrobble);
      await for (final c in substream) {
        user = user.copyWith(
            setupSync: UserSetupSync(
                passed: false,
                earliestScrobble: c.newScrobbles
                    .map((c) => c.date)
                    .reduce((a, b) => a.compareTo(b) == 1 ? b : a)));
        await users.addOrUpdate(user);
        yield c;
      }
    } else {
      final substream = _updateUser(user, null, user.lastSync);
      await for (final c in substream) {
        user = user.copyWith(
            lastSync: c.newScrobbles
                .map((c) => c.date)
                .reduce((a, b) => a.compareTo(b) == 1 ? a : b));
        await users.addOrUpdate(user);
        yield c;
      }
    }
  }

  Stream<UpdateInfo> _updateUser(User user, DateTime from, DateTime to,
      [CancellationToken cancellationToken]) async* {
    var pageNumbers = 2;
    for (var i = 1; i < pageNumbers; i++) {
      final response = await api.getUserScrobbles(
        user.username,
        to: to,
        from: from,
        page: i,
      );
      pageNumbers = response.pagesCount;
      final scrobbles = response.scrobbles;

      if (scrobbles.isEmpty) {
        return;
      }

      cancellationToken?.throwIfCancelled();
      yield await _addLastFmScrobbles(user.id, scrobbles);
    }
  }

  Future<UpdateInfo> _addLastFmScrobbles(
    String userId,
    List<LastFMScrobble> scrobbles,
  ) async {
    List<TrackScrobble> newScrobbles = [];
    List<Artist> newArtists = [];
    List<Track> newTracks = [];

    Set<String> artistIds = {};
    Set<String> trackIds = {};

    for (final s in scrobbles) {
      final artistId = '${s.artist.mbid}#@#${s.artist.name}';
      if (artistIds.add(artistId)) {
        final artist = Artist(
          id: artistId,
          mbid: s.artist.mbid,
          name: s.artist.name,
          url: s.artist.url,
        );
        newArtists.add(artist);
      }
      final trackId = '${s.track.mbid}#@#${s.track.name}#@#${artistId}';
      if (trackIds.add(trackId)) {
        final track = Track(
          id: trackId,
          artistId: artistId,
          imageInfo: s.track.imageInfo,
          loved: s.track.loved,
          mbid: s.track.mbid,
          name: s.track.name,
          url: s.track.url,
        );
        newTracks.add(track);
      }
      final scrobble = TrackScrobble(
        artistId: artistId,
        trackId: trackId,
        date: s.date,
        userId: userId,
      );
      newScrobbles.add(scrobble);
    }
    
    await tracks.transaction(() async {
      await artists.addOrUpdateAll(newArtists);
      await tracks.addOrUpdateAll(newTracks);
      await trackScrobbles.addOrUpdateAll(newScrobbles);
    });

    return UpdateInfo(
      newScrobbles: newScrobbles,
      newArtists: newArtists,
      newTracks: newTracks,
    );
  }
}
