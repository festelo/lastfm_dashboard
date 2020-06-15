import 'package:lastfm_dashboard/models/models.dart';
import 'package:epic/container.dart';

class CurrentUserKey extends Key<User> { const CurrentUserKey(); }
const currentUserKey = CurrentUserKey();

class UserRefreshingKey extends Key<bool> { const UserRefreshingKey(); }
const userRefreshingKey = UserRefreshingKey();