import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class UserAdded {
  final User user;
  UserAdded(this.user);
}

class UserRemoved {
  final String username;
  UserRemoved(this.username);
}

class UserRefreshed {
  final User oldUser;
  final User newUser;

  UserRefreshed(this.oldUser, this.newUser);
}

class UserScrobblesAdded {
  final User user;
  final List<TrackScrobble> newScrobbles;
  final List<Artist> newArtists;
  final List<Track> newTracks;

  UserScrobblesAdded(
    this.user, {
    this.newScrobbles,
    this.newArtists,
    this.newTracks,
  });
}

class UserSwitched {
  final String username;
  UserSwitched(this.username);
}

class AddUserEpic extends Epic {
  final String username;

  AddUserEpic(this.username);

  @override
  Future<void> call(EpicContext context, notify) async {
    final lastFMApi = await context.provider.get<LastFMApi>();
    final db = await context.provider.get<LocalDatabaseService>();

    final user = await lastFMApi.getUser(username);
    if (user == null) throw Exception('User not found');
    context.throwIfCancelled();

    await db.users.add(user);
    notify(UserAdded(user));
  }
}

class RemoveUserEpic extends Epic {
  final String username;

  RemoveUserEpic(this.username);

  @override
  Future<void> call(EpicContext context, notify) async {
    final db = await context.provider.get<LocalDatabaseService>();
    final currentUser = await context.provider.get<User>();
    if (currentUser?.username == username)
      throw Exception('Can\'t delete current user');

    await db.users[username].delete();
    notify(UserRemoved(username));
  }
}

class SwitchUserEpic extends Epic {
  final String username;

  SwitchUserEpic(this.username);

  @override
  Future<void> call(EpicContext context, notify) async {
    final auth = await context.provider.get<AuthService>();
    await auth.switchUser(username);
    notify(UserSwitched(username));
  }
}

class RefreshUserEpic extends Epic {
  final String username;

  RefreshUserEpic(this.username);

  @override
  Future<void> call(EpicContext context, notify) async {
    final db = await context.provider.get<LocalDatabaseService>();
    final lastFMApi = await context.provider.get<LastFMApi>();
    final user = await db.users[username].get();

    final Set<Artist> artists = {};
    final Set<Track> tracks = {};
    DateTime lastTime;

    var pageNumbers = 2;

    for (var i = 1; i < pageNumbers; i++) {
      final response = await lastFMApi.getUserScrobbles(
        user.username,
        to: user.setupSync.passed ? null : user.setupSync.latestScrobble,
        from: user.setupSync.passed ? user.lastSync : null,
        page: i,
      );

      pageNumbers = response.pagesCount;
      final scrobbles = response.scrobbles;

      if (scrobbles.isEmpty) {
        continue;
      }

      final newAritsts = scrobbles
          .where((s) => artists.add(s.artist))
          .map((c) => c.artist)
          .toList();

      final newTracks = scrobbles
          .where((s) => tracks.add(s.track))
          .map((c) => c.track)
          .toList();

      final trackScrobbles =
          scrobbles.map((e) => e.toTrackScrobble(user.id)).toList();

      final updater = (User u) => u.copyWith(
            setupSync: u.setupSync.copyWith(
              latestScrobble: scrobbles.last.date,
            ),
          );

      lastTime =
          scrobbles.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);

      context.throwIfCancelled();
      await db.transaction((t) async {
        for (final artist in newAritsts) {
          await db.artists[artist.id]
              .through(t)
              .updateSelective((a) => artist, createIfNotExist: true);
        }

        for (final track in newTracks) {
          await db.tracks[track.id]
              .through(t)
              .updateSelective((t) => track, createIfNotExist: true);
        }

        await db.trackScrobbles
            .through(t)
            .addAll(scrobbles.map((e) => e.toTrackScrobble(user.id)).toList());

        await db.users[user.id].through(t).updateSelective(updater);
      });
      notify(UserScrobblesAdded(
        user,
        newArtists: newAritsts,
        newTracks: newTracks,
        newScrobbles: trackScrobbles,
      ));
    }
    if (lastTime != null) {
      final lastSyncUpdater = (User u) => u.copyWith(lastSync: lastTime);
      await db.users[user.id].updateSelective(lastSyncUpdater);
      notify(UserRefreshed(user, lastSyncUpdater(user)));
    }
  }
}