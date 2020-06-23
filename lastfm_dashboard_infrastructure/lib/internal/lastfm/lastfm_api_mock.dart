import 'dart:math';

import 'package:lastfm_dashboard_domain/domain.dart';

import 'lastfm_api.dart';

ImageInfo _imageInfo(int r) => ImageInfo(
      extraLarge: 'http://placekitten.com/g/200/300?r=$r',
      large: 'http://placekitten.com/g/200/300?r=$r',
      medium: 'http://placekitten.com/g/200/300?r=$r',
      small: 'http://placekitten.com/g/200/300?r=$r',
    );

Map<String, User> _users = Map.fromIterable(
  List.generate(
    50,
    (i) => User(
      imageInfo: _imageInfo(i),
      playCount: 17 * i,
      username: 'mock_user_$i',
    ),
  ),
  key: (u) => u.username,
  value: (u) => u,
);

List<Artist> _artists = List.generate(
  10,
  (i) => Artist(
    imageInfo: _imageInfo(i),
    mbid: 'artist_$i',
    name: 'aritst_$i',
    url: 'https://festelo.tk',
  ),
);

List<Track> _tracks = List.generate(
  100,
  (i) => Track(
      imageInfo: _imageInfo(i),
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
        track: _tracks[i % _tracks.length],
        artist: _artists
            .firstWhere((a) => a.id == _tracks[i % _tracks.length].artistId),
        date: DateTime.now().subtract(Duration(hours: 2 * i)),
      ),
    ),
  ),
);

class LastFMApiMock implements LastFMApi {
  final String apiKey = 'testApiKey';
  
  @override
  Future<User> getUser(String username) {
    return Future.value(_users[username]);
  }

  @override
  Future<GetUserScrobblesResponse> getUserScrobbles(
    String username, {
    DateTime from,
    DateTime to,
    int count = 200,
    int page = 1,
  }) async {
    if (_userScrobbles[username] == null)
      return GetUserScrobblesResponse([], 1);
    return GetUserScrobblesResponse(
      _userScrobbles[username].skip(page * count).take(count),
      (_userScrobbles[username].length / count).ceil(),
    );
  }

  @override
  void dispose() {
  }
}
