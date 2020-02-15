import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class HomePageViewModel {
  final LocalDatabaseService db;
  final AuthService authService;
  final LastFMApi lastFMApi;

  HomePageViewModel({
    @required this.db,
    @required this.authService,
    @required this.lastFMApi,
  });

  ValueStream<String> get currentUsername => authService.currentUser;
  Stream<List<User>> get currentUsers => db.users.changes();

  Stream<User> currentUser() async* {
    await for (final username in authService.currentUser) {
      yield username == null ? null : await db.users[username].get();
    }
  }

  Future<void> addAccountAndSwitch(String username) async {
    final user = await lastFMApi.getUser(username);
    final scrobbles = await lastFMApi.getUserScrobbles(username);
    final artists = scrobbles.map((a) => a.artist).toSet();
    final tracks = scrobbles.map((a) => a.track).toSet().toList();

    for (final artist in artists) {
      db.artists[artist.id].update(artist.toDbMap(), createIfNotExist: true);
    }

    for (final track in tracks) {
      db.tracks[track.id].update(track.toDbMap(), createIfNotExist: true);
    }

    db.users[username].create(user);
    final futures = scrobbles.map((s) => db.users[username].scrobbles.create(
          TrackScrobble(
            artistId: s.artist.id,
            trackId: s.track.id,
            date: s.date,
          ),
        ));
    await Future.wait(futures);
    await switchAccount(user.username);
  }

  Future<void> removeAccount(String username) async {
    if (username == currentUsername.value) {
      await authService.logOut();
    }
    await db.users[username].delete();
  }

  Future<void> switchAccount(String username) async {
    await authService.switchUser(username);
  }

  Future<void> logOut() async {
    await authService.logOut();
  }
}
