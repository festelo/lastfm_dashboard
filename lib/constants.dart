class LocalDatabaseInfo {
  static const String databaseFileName = 'app.db';
  static const String usersPath = 'users';
  static const String artistsPath = 'artists';
  static const String tracksPath = 'tracks';
  static const String trackScrobblesPath = 'track_scrobbles';
}

class UpdaterConfig {
  static const Duration period = Duration(
    minutes: 30
  );
}