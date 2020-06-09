import 'models/models.dart';

class WebDatabaseInfo {
  static const String databaseFileName = 'app.db';
  static const String usersPath = 'users';
  static const String artistsPath = 'artists';
  static const String tracksPath = 'tracks';
  static const String trackScrobblesPath = 'track_scrobbles';
  static const String artistSelectionsStorePath = 'artist_selections';
  static const int databaseVersion = 2;
}

class MobileDatabaseTableNames {
  static const String usersPath = 'users';
  static const String artistsPath = 'artists';
  static const String tracksPath = 'tracks';
  static const String trackScrobblesPath = 'track_scrobbles';
  static const String artistSelectionsStorePath = 'artist_selections';
}

class MobileDatabaseViewNames {
  static const String artistsDetailedPath = 'artists_by_user_detailed';
}

class MobileDatabaseInfo {
  static const String idColumn = 'id';
  static const String databaseFileName = 'app.db';
  static const int databaseVersion = 2;
}

const defaultRefreshConfig = RefreshConfig(Duration(minutes: 5));
