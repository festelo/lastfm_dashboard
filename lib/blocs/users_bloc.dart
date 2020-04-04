import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/events/users_events.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class UsersViewModel {
  final List<User> users;

  UsersViewModel(this.users);

  UsersViewModel copyWith({
    List<User> users
  }) => UsersViewModel(users ?? this.users);
}

class UsersBloc extends Bloc<UsersViewModel, UsersEventInfo> {
  @override
  final BehaviorSubject<UsersViewModel> model;

  UsersBloc._(UsersViewModel viewModel):
    model = BehaviorSubject.seeded(viewModel);

  static Future<UsersBloc> load(
    LocalDatabaseService db
  ) async {
    return UsersBloc._(
      UsersViewModel(await db.users.getAll())
    );
  }

  bool userRefreshing(String uid) {
    return working
      .any((c) => 
        c.info is RefreshUserEventInfo &&
        (c.info as RefreshUserEventInfo).user.id == uid
      );
  }
}