import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/services/updater/updater_service.dart';
import 'package:lastfm_dashboard/shared/progressable_future.dart';
import 'package:rxdart/rxdart.dart';

class HomePageViewModel {
  final LocalDatabaseService db;
  final AuthService authService;
  final UpdaterService updaterService;
  final LastFMApi lastFMApi;
  final ValueStream<Map<String, ProgressableFuture<void, int>>> currentUpdates;

  HomePageViewModel({
    @required this.db,
    @required this.authService,
    @required this.updaterService,
    @required this.lastFMApi
  }): currentUpdates = updaterService.currentUpdates;

  Stream<User> currentUser() async* {
    await for(final username in authService.currentUser) {
      yield username == null 
        ? null
        : await db.users[username].get();
    }
  }

  ValueStream<String> get currentUsername => authService.currentUser;
  Stream<List<User>> get currentUsers => db.users.changes();
  
  Stream<ProgressableFuture<void, int>> get currentUpdate => 
    CombineLatestStream.combine2<
      String, 
      Map<String, ProgressableFuture<void, int>>,
      ProgressableFuture<void, int>
    >(
      currentUsername,
      currentUpdates,
      (u, updates) => updates[u]
    );

  Future<void> addAccountAndSwitch(String username) async {
    final user = await lastFMApi.getUser(username);
    await db.users[username].create(user);

    final pfuture = updaterService.updateUser(username);
    await for (final p in pfuture.progressChanged) {
      print('Progress is: ${p?.current}/${p?.total}');
    }
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