import 'dart:async';

import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/constants.dart';
import 'package:lastfm_dashboard/events/user_events.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class UpdaterService {
  final LastFMApi _lastFMApi;
  final LocalDatabaseService _databaseService;
  final UsersBloc usersBloc;

  Timer _timer;

  UpdaterService({
    LastFMApi lastFMApi,
    LocalDatabaseService databaseService,
    this.usersBloc
  }): 
    _lastFMApi = lastFMApi,
    _databaseService = databaseService;

  Future<void> start() async {
    if (_timer != null) {
      throw Exception('Updater service already started');
    }
    _timer = Timer.periodic(
      UpdaterConfig.period,
      (_) => update()
    );
    await update();
  }
  
  Future<void> update() async {
    final users = await _databaseService.users.getAll();
    for(final u in users) {

      final syncNeeded = 
        u.lastSync == null ||
        u.lastSync.isBefore(
          DateTime.now().subtract(UpdaterConfig.period)
        );
        
      final alreadySyncing = usersBloc.userRefreshing(u.id);

      if (syncNeeded && !alreadySyncing) {
        usersBloc.push(
          RefreshUserEventInfo(
            db: _databaseService,
            lastFMApi: _lastFMApi,
            user: u
          ),
          refreshUser
        );
      }
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
  }
}