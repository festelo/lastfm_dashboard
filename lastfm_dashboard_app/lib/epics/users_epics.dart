import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/epics/helpers.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:lastfm_dashboard_infrastructure/services/lastfm_service.dart';

class UserAdded {
  final User user;
  UserAdded(this.user);
}

class UserRemoved {
  final String userId;
  UserRemoved(this.userId);
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
  final String userId;
  UserSwitched(this.userId);
}

class AddUserEpic extends Epic<User> {
  final String username;

  AddUserEpic(this.username);

  @override
  Future<User> call(EpicContext context, notify) async {
    final lastFMApi = await context.provider.get<LastFMService>();
    final users = await context.provider.get<UsersRepository>();

    final user = await lastFMApi.getUser(username);
    if (user == null) throw Exception('User not found');
    context.throwIfCancelled();

    await users.addOrUpdate(user);
    notify(UserAdded(user));
    return user;
  }
}

class RemoveUserEpic extends Epic {
  final String userId;

  RemoveUserEpic(this.userId);

  @override
  Future<void> call(EpicContext context, notify) async {
    final users = await context.provider.get<UsersRepository>();

    await users.delete(userId);
    notify(UserRemoved(userId));
  }
}

class SwitchUserEpic extends Epic {
  final String userId;

  SwitchUserEpic(this.userId);

  @override
  Future<void> call(EpicContext context, notify) async {
    final auth = await context.provider.get<AuthService>();
    await auth.switchUser(userId);
    notify(UserSwitched(userId));
  }
}

class RefreshUserEpic extends Epic {
  final String userId;
  RefreshUserEpic(this.userId);

  @override
  Future<void> call(EpicContext context, notify) async {
    final users = await context.provider.get<UsersRepository>();
    final lastFMApi = await context.provider.get<LastFMService>();
    final user = await users.get(userId);

    await for (final s in lastFMApi.updateUser(user)) {
      context.throwIfCancelled();
      notify(UserScrobblesAdded(
        user,
        newArtists: s.newArtists,
        newTracks: s.newTracks,
        newScrobbles: s.newScrobbles,
      ));
    }
    final newUser = await context.provider.get(currentUserKey);
    notify(UserRefreshed(user, newUser));
  }
}