import 'dart:async';

import 'package:epic/epic.dart';
import 'package:epic/watcher.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'refresh_config.dart';

class RefreshWatcher extends Watcher {
  final UsersRepository users;
  final EpicManager manager;
  final RefreshConfig config;

  RefreshWatcher(this.manager, this.users, this.config);

  @override
  Future<void> start() async {
    Timer.periodic(
      config.period,
      (_) => refresh()
    );
    refresh();
  }

  Future<void> refresh() async {
    final users = await this.users.getAll();

    for (final u in users) {
      final syncNeeded = u.lastSync == null ||
          u.lastSync.isBefore(DateTime.now().subtract(config.period));

      final alreadySyncing =
          manager.runned.any((e) => e.epic is RefreshUserEpic);

      if (syncNeeded && !alreadySyncing) {
        manager.start(RefreshUserEpic(u.id));
      }
    }
  }
}