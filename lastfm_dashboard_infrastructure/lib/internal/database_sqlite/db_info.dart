class SqliteDatabaseInfo {
  final String usersTable;
  final String artistsTable;
  final String tracksTable;
  final String trackScrobblesTable;
  final String artistSelectionsTable;

  final String artistsDetailedView;

  final String databaseFileName;
  final int databaseVersion;

  const SqliteDatabaseInfo({
    this.databaseFileName: 'app.db',
    this.usersTable: 'users',
    this.artistsTable: 'artists',
    this.tracksTable: 'tracks',
    this.trackScrobblesTable: 'track_scrobbles',
    this.artistSelectionsTable: 'artist_selections',
    this.artistsDetailedView: 'artists_by_user_detailed',
    this.databaseVersion: 2,
  });
}
