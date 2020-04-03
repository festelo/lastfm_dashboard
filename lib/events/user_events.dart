import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/extensions.dart';

class AddUserEventInfo extends EventInfo {
  final String username;
  final LastFMApi lastFMApi;
  final LocalDatabaseService db;

  AddUserEventInfo({
    this.username,
    this.lastFMApi,
    this.db
  });
}

class RemoveUserEventInfo extends EventInfo {
  final String username;
  final LocalDatabaseService db;

  RemoveUserEventInfo({
    this.username,
    this.db
  });
}

class SwitchUserEventInfo extends EventInfo {
  final String username;
  final AuthService authService;

  SwitchUserEventInfo({
    this.username,
    this.authService
  });
}

class RefreshUserEventInfo extends EventInfo {
  final User user;
  final LastFMApi lastFMApi;
  final LocalDatabaseService db;

  RefreshUserEventInfo({
    this.user,
    this.lastFMApi,
    this.db
  });
}

Future<Returner<UsersViewModel>> addUser(
  AddUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async {
  final user = await i.lastFMApi.getUser(i.username);
  if (c.cancelled()) throw CancelledException();

  c.bloc.push(
    RefreshUserEventInfo(
      db: i.db,
      lastFMApi: i.lastFMApi,
      user: user
    ), 
    refreshUser
  );

  await i.db.users[i.username].create(user);
  return (UsersViewModel c) => c.copyWith(
    users: [...c.users, user]
  );
}

Future<Returner<UsersViewModel>> removeUser(
  RemoveUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async {
  await i.db.users[i.username].delete();
  return (UsersViewModel c) => c.copyWith(
    users: [...c.users]..removeFirstWhere(
      (c) => c.username == i.username,
    )
  );
}

Future<Returner<UsersViewModel>> switchUser(
  SwitchUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async {
  i.authService.switchUser(i.username);
  return (UsersViewModel c) => c.copyWith(
    currentUserId: i.username
  );
}

Future<Returner<UsersViewModel>> refreshUser(
  RefreshUserEventInfo i, 
  EventConfiguration<UsersViewModel> c,
) async {
  final db = i.db;
  final user = i.user;
  
  final scrobbles = await i.lastFMApi.getUserScrobbles(
    user.username,
    from: user.lastSync,
    cancelled: c.cancelled
  );

  final artists = scrobbles.map((a) => a.artist).toSet();
  final tracks = scrobbles.map((a) => a.track).toSet().toList();
  if (c.cancelled()) throw CancelledException();
  
  for(final artist in artists) {
    db.artists[artist.id].update(
      artist.toDbMap(), 
      createIfNotExist: true
    );
  }

  for(final track in tracks) {
    db.tracks[track.id].update(track.toDbMap(), createIfNotExist: true);
  }

  await db.users[user.id].scrobbles.addAll(
    scrobbles.map((e) => e.toTrackScrobble())
  );

  final newUser = await db.users[user.id].writeSelective(
    (u) => u.copyWith(
      lastSync: DateTime.now()
    )
  );
  
  return (UsersViewModel c) => c.copyWith(
    users: [...c.users].replaceWhere(
      (c) => c.id == newUser.id,
      newUser,
      first: true
    )
  );
}