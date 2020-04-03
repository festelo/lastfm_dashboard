import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/events/user_events.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class UsersViewModel {
  final List<User> users;
  final String currentUserId;

  User get currentUser => currentUserId == null
    ? null
    : users.firstWhere((c) => c.id == currentUserId);

  UsersViewModel(this.users, {
    this.currentUserId
  });

  UsersViewModel copyWith({
    List<User> users,
    String currentUserId
  }) => UsersViewModel(users ?? this.users, 
    currentUserId: currentUserId ?? this.currentUserId
  );
}

class UsersBloc extends Bloc<UsersViewModel> {
  @override
  final BehaviorSubject<UsersViewModel> model;

  UsersBloc._(UsersViewModel viewModel):
    model = BehaviorSubject.seeded(viewModel);

  bool userRefreshing(String uid) {
    return working
      .any((c) => 
        c.info is RefreshUserEventInfo &&
        (c.info as RefreshUserEventInfo).user.id == uid
      );
  }

  static Future<UsersBloc> load(
    LocalDatabaseService db, 
    AuthService authService
  ) async {
    await authService.loadUser();
    return UsersBloc._(
      UsersViewModel(await db.users.getAll(),
        currentUserId: authService.currentUser.value
      )
    );
  }
}