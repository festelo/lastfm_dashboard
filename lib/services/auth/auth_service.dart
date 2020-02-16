import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthServicePreferences {
  const AuthServicePreferences(this.preferences);

  final SharedPreferences preferences;

  Future<String> getCurrentUsername() async {
    return preferences.getString('currentUser');
  }

  Future<bool> setCurrentUsername(String value) async {
    return preferences.setString('currentUser', value);
  }
}

class AuthService {
  AuthService({
    String username,
    @required this.authServicePreferences,
  }) : _currentUserSubject = BehaviorSubject.seeded(username);

  AuthServicePreferences authServicePreferences;
  BehaviorSubject<String> _currentUserSubject;

  ValueStream<String> get currentUser => _currentUserSubject?.stream;

  static Future<AuthService> load(AuthServicePreferences servicePreferences) async {
    final service = AuthService(authServicePreferences: servicePreferences);
    await service.loadUser();
    return service;
  }

  Future<void> loadUser() async {
    final username = await authServicePreferences.getCurrentUsername();
    _currentUserSubject.add(username);
  }

  Future<void> switchUser(String username) async {
    await authServicePreferences.setCurrentUsername(username);
    _currentUserSubject.add(username);
  }

  Future<void> logOut() async {
    await authServicePreferences.setCurrentUsername(null);
    _currentUserSubject.add(null);
  }

  Future<void> close() async {
    await _currentUserSubject?.close();
  }
}
