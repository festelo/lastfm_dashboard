import 'package:epic/container.dart';
import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard_domain/domain.dart';

class CurrentUserKey extends Key<User> {
  const CurrentUserKey();
}

const currentUserKey = CurrentUserKey();

class UserRefreshingKey extends Key<bool> {
  const UserRefreshingKey();
}

const userRefreshingKey = UserRefreshingKey();

void defineUserHelpers(EpicContainer container) {
  container.addTransientComplex<User>(_currentUser, key: currentUserKey);
  container.addTransientComplex<bool>(_userRefreshing, key: userRefreshingKey);
}

Future<User> _currentUser(EpicProvider p) async {
  final users = await p.get<UsersRepository>();
  final auth = await p.get<AuthService>();
  return auth.currentUser.value == null
      ? null
      : users.get(auth.currentUser.value);
}

Future<bool> _userRefreshing(EpicProvider p) async {
  final user = await p.get(currentUserKey);
  if (user == null) return false;
  final epicManager = await p.get<EpicManager>();
  return epicManager.runned
      .map((e) => e.epic)
      .whereType<RefreshUserEpic>()
      .any((e) => e.userId == user.id);
}
