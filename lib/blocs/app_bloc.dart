import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/events/app_events.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class AppViewModel {
  final String currentUserId;

  AppViewModel(this.currentUserId);

  AppViewModel copyWith({
    String currentUserId
  }) => AppViewModel(currentUserId ?? this.currentUserId);
}

class AppBloc extends Bloc<AppViewModel> {
  final UsersBloc usersBloc;

  @override
  final BehaviorSubject<AppViewModel> model;

  AppBloc._({
    this.usersBloc,
    String currentUserId
  }): model = BehaviorSubject.seeded(AppViewModel(currentUserId));

  static Future<AppBloc> load(
    LocalDatabaseService db, 
    AuthService authService
  ) async {
    await authService.loadUser();
    return AppBloc._(
      usersBloc: await UsersBloc.load(db),
      currentUserId: authService.currentUser.value
    );
  }

  User _currentUserFetcher(AppViewModel a, UsersViewModel b) {
    return a.currentUserId == null
      ? null
      : b.users.firstWhere((u) => u.id == a.currentUserId, orElse: () => null);
  }

  ValueStream<User> get currentUser => 
    Rx.combineLatest2<AppViewModel, UsersViewModel, User>(
      model, 
      usersBloc.model,
      _currentUserFetcher
    ).publishValueSeeded(
      _currentUserFetcher(model.value, usersBloc.model.value)
    );

  @override
  List<Bloc> flatBlocs() => [this, ...usersBloc.flatBlocs()]; 

  @override
  List<ValueStream> get streams => [currentUser]; 
}