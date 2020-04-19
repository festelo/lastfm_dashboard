import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/extensions.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class AddUserEventInfo {
  final String username;
  final bool switchAfter;

  const AddUserEventInfo({this.username, this.switchAfter = true});
}

class RemoveUserEventInfo {
  final String username;

  const RemoveUserEventInfo({this.username});
}

class RefreshUserEventInfo {
  final User user;

  const RefreshUserEventInfo({this.user});
}

Stream<Returner<UsersViewModel>> addUser(
  AddUserEventInfo info,
  EventConfiguration<UsersViewModel> config,
) async* {
  final lastFMApi = config.context.get<LastFMApi>();
  final db = config.context.get<LocalDatabaseService>();

  final user = await lastFMApi.getUser(info.username);
  if (user == null) throw EventException('User not found');
  if (config.cancelled()) throw CancelledException();

  config.context.push(RefreshUserEventInfo(user: user), refreshUser);
  await db.users.add(user);
  yield (UsersViewModel c) => c.copyWith(users: [...c.users, user]);

  if (info.switchAfter) {
    config.context.push(
      SwitchUserEventInfo(username: user.username),
      switchUser,
    );
  }
}

Stream<Returner<UsersViewModel>> removeUser(
  RemoveUserEventInfo info,
  EventConfiguration<UsersViewModel> config,
) async* {
  final db = config.context.get<LocalDatabaseService>();
  final currentUser = config.context.get<User>();
  if (currentUser.username == info.username) {
    config.context.push(SwitchUserEventInfo(username: null), switchUser);
  }
  await db.users[info.username].delete();
  yield (UsersViewModel c) => c.copyWith(
        users: [...c.users]..removeFirstWhere(
            (c) => c.username == info.username,
          ),
      );
}

Stream<Returner<UsersViewModel>> refreshUser(
  RefreshUserEventInfo info,
  EventConfiguration<UsersViewModel> config,
) async* {
  final db = config.context.get<LocalDatabaseService>();
  final lastFMApi = config.context.get<LastFMApi>();
  final user = info.user;

  const limit = 200;
  final scrobbles = lastFMApi.getUserScrobbles(
    user.username,
    cancelled: config.cancelled,
    to: user.setupSync.passed ? null : user.setupSync.latestScrobble,
    from: user.setupSync.passed ? user.lastSync : null,
    requestLimit: 200,
  );

  final Set<Artist> artists = {};
  final Set<Track> tracks = {};
  DateTime lastTime;

  await for (final scrobbles in scrobbles.bufferCount(limit)) {
    if (config.cancelled()) throw CancelledException();
    if (scrobbles.isEmpty) {
      continue;
    }

    final newAritsts =
        scrobbles.where((s) => artists.add(s.artist)).map((c) => c.artist);

    final newTracks =
        scrobbles.where((s) => tracks.add(s.track)).map((c) => c.track);

    final updater = (User u) => u.copyWith(
          setupSync: u.setupSync.copyWith(
            latestScrobble: scrobbles.last.date,
          ),
        );
    lastTime =
        scrobbles.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
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

    yield (vm) => vm.copyWith(
          users: vm.users.changeWhere((u) => u.id == user.id, updater).toList(),
        );
  }
  if (lastTime != null) {
    final lastSyncUpdater = (User u) => u.copyWith(
          lastSync: lastTime,
        );
    await db.users[user.id].updateSelective(lastSyncUpdater);
    yield (vm) => vm.copyWith(
          users: vm.users
              .changeWhere((u) => u.id == user.id, lastSyncUpdater)
              .toList(),
        );
  }
}

class SwitchUserEventInfo {
  final String username;

  const SwitchUserEventInfo({this.username});
}

Stream<Returner<UsersViewModel>> switchUser(
  SwitchUserEventInfo info,
  EventConfiguration<UsersViewModel> config,
) async* {
  config.context.get<AuthService>().switchUser(info.username);
  yield (UsersViewModel c) => c.copyWith(
        currentUserId: info.username,
        logOut: info.username == null ? true : false,
      );
}
