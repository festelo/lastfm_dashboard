class TrackScrobblesPerTime {
  final String trackId;
  final String artistId;
  final String userId;
  final DateTime groupedDate;
  final int count;

  const TrackScrobblesPerTime({
    this.trackId,
    this.artistId,
    this.groupedDate,
    this.userId,
    this.count,
  });
}
