import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/services/updater/updater_service.dart';
import 'package:rxdart/rxdart.dart';

class HomePageViewModel {
  final LocalDatabaseService db;
  final AuthService authService;
  final UpdaterService updaterService;
  final LastFMApi lastFMApi;

  HomePageViewModel({
    @required this.db,
    @required this.authService,
    @required this.updaterService,
    @required this.lastFMApi
  });

  Stream<User> currentUser() async* {
    await for(final username in authService.currentUser) {
      yield username == null 
        ? null
        : await db.users[username].get();
    }
  }

  ValueStream<String> get currentUsername => authService.currentUser;
  Stream<List<User>> get currentUsers => db.users.changes();

  Future<void> addAccountAndSwitch(String username) async {
    final user = await lastFMApi.getUser(username);
    db.users[username].create(user);
    await updaterService.updateUser(username);
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