class WebDatabaseInfo {
  final String databaseFileName;
  final String usersPath;
  final String artistsPath;
  final String tracksPath;
  final String trackScrobblesPath;
  final String artistSelectionsStorePath;
  final int databaseVersion;
  const WebDatabaseInfo({
    this.databaseFileName: 'app.db',
    this.usersPath: 'users',
    this.artistsPath: 'artists',
    this.tracksPath: 'tracks',
    this.trackScrobblesPath: 'track_scrobbles',
    this.artistSelectionsStorePath: 'artist_selections',
    this.databaseVersion: 2,
  });
}
