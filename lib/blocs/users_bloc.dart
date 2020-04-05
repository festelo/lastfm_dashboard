import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/events/users_events.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/watchers/user_watchers.dart';
import 'package:rxdart/rxdart.dart';

class UsersViewModel {
  final List<User> users;
  final String currentUserId;

  UsersViewModel({
    this.users,
    this.currentUserId
  });

  UsersViewModel copyWith({
    List<User> users,
    String currentUserId
  }) => UsersViewModel(
    users: users ?? this.users,
    currentUserId: currentUserId ?? this.currentUserId
  );
}

class UsersBloc extends Bloc<UsersViewModel> with BlocWithInitializationEvent {
  @override
  final BehaviorSubject<UsersViewModel> model;

  UsersBloc([UsersViewModel viewModel]):
    model = BehaviorSubject.seeded(viewModel);
    
  @override
  Stream<Returner<UsersViewModel>> initializationEvent(
    void _,
    EventConfiguration<UsersViewModel> c
  ) async* {
    final ldb = c.context.get<LocalDatabaseService>();
    final authService = c.context.get<AuthService>();
    final users = await ldb.users.getAll();
    await authService.loadUser();
    final userId = authService.currentUser.value;
    yield (_) => UsersViewModel(
      users: users,
      currentUserId: userId
    );
    
    c.context.push(UsersUpdaterWatcherInfo(), usersUpdaterWatcher);
  }

  bool userRefreshing(String uid) {
    return working
      .any((c) => 
        c.info is RefreshUserEventInfo &&
        (c.info as RefreshUserEventInfo).user.id == uid
      );
  }
  

  User _currentUserFetcher(UsersViewModel b) {
    return b?.currentUserId == null
      ? null
      : b.users.firstWhere((u) => u.id == b.currentUserId, orElse: () => null);
  }

  ValueStream<User> get currentUser => model
    .map(_currentUserFetcher)
    .shareValueSeeded(_currentUserFetcher(model.value));
    
  @override
  List<ValueStream> get streams => [currentUser]; 
}