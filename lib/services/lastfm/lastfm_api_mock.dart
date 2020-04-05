import 'dart:math';

import 'package:lastfm_dashboard/models/models.dart';

import 'lastfm_api.dart';

ImageInfo _imageInfo = ImageInfo(
  extraLarge: 'http://placekitten.com/g/200/300',
  large: 'http://placekitten.com/g/200/300',
  medium: 'http://placekitten.com/g/200/300',
  small: 'http://placekitten.com/g/200/300',
);

Map<String, User> _users = Map.fromIterable(
    List.generate(
      50,
      (i) => User(
        imageInfo: _imageInfo,
        playCount: 17 * i,
        username: 'mock_user_$i',
      ),
    ),
    key: (u) => u.username,
    value: (u) => u);

List<Artist> _artists = List.generate(
  10,
  (i) => Artist(
      imageInfo: _imageInfo,
      mbid: 'artist_$i',
      name: 'aritst_$i',
      url: 'https://festelo.tk'),
);

List<Track> _tracks = List.generate(
  100,
  (i) => Track(
      imageInfo: _imageInfo,
      artistId: _artists[i % _artists.length].id,
      mbid: 'track_$i',
      name: 'track_$i',
      url: 'https://festelo.tk',
      loved: i % 10 == 0),
);

Map<String, List<LastFMScrobble>> _userScrobbles = _users.map(
  (key, value) => MapEntry(
    key,
    List.generate(
      pow(key.hashCode, 2) % 10000,
      (i) => LastFMScrobble(
        track: _tracks[key.hashCode % _tracks.length],
        artist: _artists.firstWhere(
            (a) => a.id == _tracks[key.hashCode % _tracks.length].artistId),
        date: DateTime.now().subtract(Duration(hours: 2 * i)),
      ),
    ),
  ),
);

class LastFMApiMock implements LastFMApi {
  @override
  Future<User> getUser(String username) {
    return Future.value(_users[username]);
  }

  @override
  Stream<LastFMScrobble> getUserScrobbles(
    String username, {
    DateTime from,
    DateTime to,
    cancelled,
    int requestLimit = 200,
  }) {
    if (_userScrobbles[username] == null) return Stream<LastFMScrobble>.empty();
    return Stream<LastFMScrobble>.fromIterable(_userScrobbles[username].where(
        (s) =>
            (from == null || s.date.isAfter(from)) &&
            (to == null || s.date.isBefore(to))));
  }
}
