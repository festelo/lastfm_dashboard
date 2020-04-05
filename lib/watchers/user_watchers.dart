
import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/constants.dart';
import 'package:lastfm_dashboard/events/users_events.dart';

class UsersUpdaterWatcherInfo {}
Stream<Returner<UsersViewModel>> usersUpdaterWatcher(
  UsersUpdaterWatcherInfo i, 
  EventConfiguration<UsersViewModel> c,
) async* {
  final usersBloc = c.context.get<UsersBloc>();
  while(true) {
    final usersVM = c.context.get<UsersViewModel>();
    
    final users = usersVM.users;
    for(final u in users) {

      final syncNeeded = 
        u.lastSync == null ||
        u.lastSync.isBefore(
          DateTime.now().subtract(UpdaterConfig.period)
        );
        
      final alreadySyncing = usersBloc.userRefreshing(u.id);

      if (syncNeeded && !alreadySyncing) {
        c.context.push(
          RefreshUserEventInfo(
            user: u
          ), 
          refreshUser
        );
      }
    }
    await Future.delayed(UpdaterConfig.period);
  }
}