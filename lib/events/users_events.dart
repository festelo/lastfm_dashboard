import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/extensions.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';


class UsersEventInfo extends EventInfo { 
  const UsersEventInfo(); 
}

class AddUserEventInfo extends UsersEventInfo {
  final String username;

  const AddUserEventInfo({
    this.username
  });
}

class RemoveUserEventInfo extends UsersEventInfo {
  final String username;

  const RemoveUserEventInfo({
    this.username,
  });
}

class RefreshUserEventInfo extends UsersEventInfo {
  final User user;

  const RefreshUserEventInfo({
    this.user,
  });
}

Future<Returner<UsersViewModel>> addUser(
  AddUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async {
  final lastFMApi = c.context.get<LastFMApi>();
  final db = c.context.get<LocalDatabaseService>();

  final user = await lastFMApi.getUser(i.username);
  if (c.cancelled()) throw CancelledException();

  c.context.push(
    RefreshUserEventInfo(
      user: user
    ), 
    refreshUser,
    () => UsersEventInfo()
  );

  await db.users[i.username].create(user);
  return (UsersViewModel c) => c.copyWith(
    users: [...c.users, user]
  );
}

Future<Returner<UsersViewModel>> removeUser(
  RemoveUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async {
  final db = c.context.get<LocalDatabaseService>();
  await db.users[i.username].delete();
  return (UsersViewModel c) => c.copyWith(
    users: [...c.users]..removeFirstWhere(
      (c) => c.username == i.username,
    )
  );
}

Future<Returner<UsersViewModel>> refreshUser(
  RefreshUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async {
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

  await for(final scrobble in scrobbles) {
    if (c.cancelled()) throw CancelledException();
    final isNewArtist = artists.add(scrobble.artist);
    if (isNewArtist) {
      await db.artists[scrobble.artist.id].update(
        scrobble.artist.toDbMap(), 
        createIfNotExist: true
      );
    }

    final isNewTrack = tracks.add(scrobble.track);
    if (isNewTrack) {
      await db.tracks[scrobble.track.id].update(
        scrobble.track.toDbMap(), 
        createIfNotExist: true
      );
    }

    await db.users[user.id].scrobbles.add(scrobble.toTrackScrobble());

    final updater = (User u) => u.copyWith(
      setupSync: u.setupSync.copyWith(
        latestScrobble: scrobble.date
      )
    );

    final updatedUser = await db.users[user.id]
      .writeSelective(updater);

    c.update((vm) => vm.copyWith(
      users: vm.users
        .changeWhere(
          (u) => u.id == updatedUser.id, 
          updater
        )
        .toList()
    ));
  }
  return null;
}