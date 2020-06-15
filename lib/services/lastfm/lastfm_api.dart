import 'dart:convert';
import 'package:lastfm_dashboard/models/exceptions.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/config.dart';
import 'package:lastfm_dashboard/extensions.dart';
import 'package:http/http.dart' as http;

class LastFMException {
  final String message;
  final int code;
  LastFMException({this.message, this.code});
}

class LastFMScrobble {
  final Artist artist;
  final Track track;
  final DateTime date;

  const LastFMScrobble({this.artist, this.track, this.date});

  TrackScrobble toTrackScrobble(String userId) => TrackScrobble(
        artistId: artist.id,
        trackId: track.id,
        date: date,
        userId: userId,
      );
}

class GetUserScrobblesResponse {
  List<LastFMScrobble> scrobbles;
  int pagesCount;
  GetUserScrobblesResponse(this.scrobbles, this.pagesCount);
}

class LastFMApi {
  static const apiKey = Config.lastFmKey;
  final _client = http.Client();

  Future<T> _retryOnThrow<T>(Future<T> Function() fun, {int times = 3}) async {
    final errors = [];
    for (var i = 0; i < times; i++) {
      try {
        return await fun();
      } catch (e) {
        errors.add(e);
      }
    }
    throw AccumulatedException(errors);
  }

  Future<dynamic> _request(
    String method,
    Map<String, String> parameters,
  ) async {
    final uri = Uri.https('ws.audioscrobbler.com', '/2.0',
        {'method': method, 'api_key': apiKey, 'format': 'json', ...parameters});

    final decoded = await _retryOnThrow(() async {
      final response = await _client.get(uri);
      final body = utf8.decode(response.bodyBytes);
      final decoded = json.decode(body);
      if (decoded['error'] != null) {
        throw LastFMException(
            message: decoded['message'], code: decoded['error']);
      }
      return decoded;
    });

    return decoded;
  }

  ImageInfo _deserializeImage(List<dynamic> list) {
    if (list == null) return ImageInfo();
    String extraLargeImage;
    String largeImage;
    String mediumImage;
    String smallImage;
    for (final image in list) {
      if (image['size'] == 'extralarge') {
        extraLargeImage = image['#text'];
      }
      if (image['size'] == 'large') {
        largeImage = image['#text'];
      }
      if (image['size'] == 'medium') {
        mediumImage = image['#text'];
      }
      if (image['size'] == 'small') {
        smallImage = image['#text'];
      }
    }
    return ImageInfo(
      extraLarge: extraLargeImage.isNotEmpty ? extraLargeImage : null,
      large: largeImage.isNotEmpty ? largeImage : null,
      medium: mediumImage.isNotEmpty ? mediumImage : null,
      small: smallImage.isNotEmpty ? smallImage : null,
    );
  }

  Future<User> getUser(String username) async {
    try {
      final resp = await _request('user.getinfo', {'user': username});
      return User(
        imageInfo: _deserializeImage(resp['user']['image']),
        playCount: int.tryParse(resp['user']['playcount']),
        username: username,
      );
    } on LastFMException catch (e) {
      if (e.code == 6) return null;
      rethrow;
    }
  }

  LastFMScrobble _deserializeScrobble(dynamic scrobble) {
    final artist = Artist(
      imageInfo: _deserializeImage(scrobble['image']), // bypass
      name: scrobble['artist']['name'],
      mbid: scrobble['artist']['mbid'],
      url: scrobble['artist']['url'],
    );

    final track = Track(
      imageInfo: _deserializeImage(scrobble['image']),
      artistId: artist.id,
      mbid: scrobble['mbid'],
      name: scrobble['name'],
      url: scrobble['url'],
      loved: scrobble['loved'] == '1',
    );

    return LastFMScrobble(
      artist: artist,
      track: track,
      date: DateTime.fromMillisecondsSinceEpoch(
          int.parse(scrobble['date']['uts']) * 1000),
    );
  }

  Future<GetUserScrobblesResponse> getUserScrobbles(
    String username, {
    DateTime from,
    DateTime to,
    int count = 200,
    int page = 1,
  }) async {
    assert(count != null && count > 0 && count <= 200);
    var scrobbles = <dynamic>[];
    final resp = await _request('user.getrecenttracks', {
      'user': username,
      'extended': '1',
      'limit': count.toString(),
      'page': page.toString(),
      if (from != null) 'from': from.secondsSinceEpoch.toString(),
      if (to != null) 'to': to.secondsSinceEpoch.toString()
    });

    if (resp['recenttracks']['track'].isEmpty)
      return GetUserScrobblesResponse([], page);

    if (resp['recenttracks']['track'] is Map) {
      scrobbles.add(resp['recenttracks']['track']);
    } else {
      scrobbles.addAll(resp['recenttracks']['track']);
    }

    scrobbles = scrobbles
        .where((scrobble) =>
            scrobble['@attr'] == null ||
            scrobble['@attr']['nowplaying'] != 'true')
        .toList();

    final totalPages =
        int.tryParse(resp['recenttracks']['@attr']['totalPages']);

    return GetUserScrobblesResponse(
        scrobbles.map(_deserializeScrobble).toList(), totalPages);
  }

  void dispose() {
    _client.close();
  }
}
