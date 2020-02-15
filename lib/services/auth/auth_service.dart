import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthServicePreferences {
  const AuthServicePreferences();

  Future<SharedPreferences> get _pref async => SharedPreferences.getInstance();

  Future<String> getCurrentUsername() async {
    final p = await _pref;
    return p.getString('currentUser');
  }

  Future<void> setCurrentUsername(String value) async {
    final p = await _pref;
    await p.setString('currentUser', value);
  }
}

class AuthService {
  AuthServicePreferences preferences;
  BehaviorSubject<String> _currentUserSubject;

  AuthService({
    String username,
    this.preferences = const AuthServicePreferences(),
  }) : _currentUserSubject = BehaviorSubject.seeded(username);

  ValueStream<String> get currentUser => _currentUserSubject?.stream;

  static Future<AuthService> load() async {
    final service = AuthService();
    await service.loadUser();
    return service;
  }

  Future<void> loadUser() async {
    final username = await preferences.getCurrentUsername();
    _currentUserSubject.add(username);
  }

  Future<void> switchUser(String username) async {
    await preferences.setCurrentUsername(username);
    _currentUserSubject.add(username);
  }

  Future<void> logOut() async {
    await preferences.setCurrentUsername(null);
    _currentUserSubject.add(null);
  }

  Future<void> close() async {
    await _currentUserSubject?.close();
  }
}
