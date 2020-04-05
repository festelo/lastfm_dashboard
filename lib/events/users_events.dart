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

  const AddUserEventInfo({
    this.username
  });
}

class RemoveUserEventInfo {
  final String username;

  const RemoveUserEventInfo({
    this.username,
  });
}

class RefreshUserEventInfo {
  final User user;

  const RefreshUserEventInfo({
    this.user,
  });
}

Stream<Returner<UsersViewModel>> addUser(
  AddUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async* {
  final lastFMApi = c.context.get<LastFMApi>();
  final db = c.context.get<LocalDatabaseService>();

  final user = await lastFMApi.getUser(i.username);
  if (c.cancelled()) throw CancelledException();

  c.context.push(
    RefreshUserEventInfo(
      user: user
    ), 
    refreshUser
  );

  await db.users[i.username].create(user);
  yield (UsersViewModel c) => c.copyWith(
    users: [...c.users, user]
  );
}

Stream<Returner<UsersViewModel>> removeUser(
  RemoveUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async* {
  final db = c.context.get<LocalDatabaseService>();
  await db.users[i.username].delete();
  yield (UsersViewModel c) => c.copyWith(
    users: [...c.users]..removeFirstWhere(
      (c) => c.username == i.username,
    )
  );
}

Stream<Returner<UsersViewModel>> refreshUser(
  RefreshUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async* {
  final db = c.context.get<LocalDatabaseService>();
  final lastFMApi = c.context.get<LastFMApi>();
  final user = i.user;
  
  final scrobbles = lastFMApi.getUserScrobbles(
    user.username,
    cancelled: c.cancelled,

    to: user.setupSync.passed
      ? null
      : user.setupSync.latestScrobble,

    from: user.setupSync.passed
      ? user.lastSync
      : null
  );

  final Set<Artist> artists = {};
  final Set<Track> tracks = {};

  await for(final scrobbles in scrobbles.bufferCount(200)) {
    if (c.cancelled()) throw CancelledException();

    final newAritsts = scrobbles
      .where((s) => artists.add(s.artist))
      .map((c) => c.artist);

    final newTracks = scrobbles
      .where((s) => tracks.add(s.track))
      .map((c) => c.track);

    final updater = (User u) => u.copyWith(
      setupSync: u.setupSync.copyWith(
        latestScrobble: scrobbles.last.date
      )
    );

    db.transaction((t) async {
      for(final artist in newAritsts) {
        await db.artists[artist.id]
          .through(t)
          .update(
            artist.toDbMap(), 
            createIfNotExist: true
          );
      }

      for(final track in newTracks) {
        await db.artists[track.id]
          .through(t)
          .update(
            track.toDbMap(), 
            createIfNotExist: true
          );
      }

      await db.users[user.id].scrobbles
        .through(t)
        .addAll(
          scrobbles.map((e) => e.toTrackScrobble())
        );

      await db.users[user.id]
        .through(t)
        .updateSelective(updater);
    });

    yield (vm) => vm.copyWith(
      users: vm.users
        .changeWhere(
          (u) => u.id == user.id, 
          updater
        )
        .toList()
    );
  }
}

class SwitchUserEventInfo {
  final String username;

  SwitchUserEventInfo({
    this.username,
  });
}

Stream<Returner<UsersViewModel>> switchUser(
  SwitchUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async* {
  c.context.get<AuthService>().switchUser(i.username);
  yield (UsersViewModel c) => c.copyWith(
    currentUserId: i.username
  );
}