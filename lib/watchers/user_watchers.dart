import 'dart:async';

import 'package:epic/epic.dart';
import 'package:epic/watcher.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class RefreshWatcher extends Watcher {
  final LocalDatabaseService db;
  final EpicManager manager;
  final RefreshConfig config;

  RefreshWatcher(this.manager, this.db, this.config);

  @override
  Future<void> start() async {
    Timer.periodic(
      config.period,
      (_) => refresh()
    );
    refresh();
  }

  Future<void> refresh() async {
    final users = await db.users.getAll();

    for (final u in users) {
      final syncNeeded = u.lastSync == null ||
          u.lastSync.isBefore(DateTime.now().subtract(config.period));

      final alreadySyncing =
          manager.runned.any((e) => e.epic is RefreshUserEpic);

      if (syncNeeded && !alreadySyncing) {
        manager.start(RefreshUserEpic(u.username));
      }
    }
  }
}