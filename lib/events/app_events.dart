import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/app_bloc.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';

class AppEventInfo extends EventInfo {}

class SwitchUserEventInfo extends AppEventInfo {
  final String username;
  final AuthService authService;

  SwitchUserEventInfo({
    this.username,
    this.authService
  });
}

Future<Returner<AppViewModel>> switchUser(
  SwitchUserEventInfo i, 
  EventConfiguration<AppViewModel> c,
) async {
  i.authService.switchUser(i.username);
  return (AppViewModel c) => c.copyWith(
    currentUserId: i.username
  );
}