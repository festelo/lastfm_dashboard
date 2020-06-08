import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/constants.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class UserRefreshWatcher extends Epic {
  @override
  Future<void> call(EpicContext context, notify) async {
    final db = await context.provider.get<LocalDatabaseService>();
    while (true) {
      context.throwIfCancelled();
      final users = await db.users.getAll();

      for (final u in users) {
        final syncNeeded = u.lastSync == null ||
            u.lastSync.isBefore(DateTime.now().subtract(UpdaterConfig.period));

        final alreadySyncing =
            context.manager.runned.any((e) => e.epic is RefreshUserEpic);

        if (syncNeeded && !alreadySyncing) {
          context.manager.start(RefreshUserEpic(u.username));
        }
      }
      await Future.delayed(UpdaterConfig.period);
    }
  }
}