import 'package:flutter/foundation.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class HomePageViewModel {
  final LocalDatabaseService db;
  final AuthService authService;

  HomePageViewModel({
    @required this.db,
    @required this.authService
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

  Future<void> addAccountAndSwitch(User user) async {
    await db.users.create(user);
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