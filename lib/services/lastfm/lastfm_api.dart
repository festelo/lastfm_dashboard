import 'dart:convert';
import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/sensitive.dart' as sensitive;
import 'package:lastfm_dashboard/extensions.dart';
import 'package:http/http.dart' as http;

class LastFMScrobble {
  final Artist artist;
  final Track track;
  final DateTime date;

  const LastFMScrobble({this.artist, this.track, this.date});

  TrackScrobble toTrackScrobble() =>
      TrackScrobble(artistId: artist.id, trackId: track.id, date: date);
}

class LastFMApi {
  static const apiKey = sensitive.lastFmKey;
  final _client = http.Client();

  Future<dynamic> _request(
    String method,
    Map<String, String> parameters,
  ) async {
    final uri = Uri.http('ws.audioscrobbler.com', '/2.0',
        {'method': method, 'api_key': apiKey, 'format': 'json', ...parameters});
    final response = await _client.get(uri);
    final decoded = json.decode(response.body);
    if (decoded['error'] != null) {
      throw Exception(decoded);
    }
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
    final resp = await _request('user.getinfo', {'user': username});
    return User(
      imageInfo: _deserializeImage(resp['user']['image']),
      playCount: int.tryParse(resp['user']['playcount']),
      username: username,
    );
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

  Stream<LastFMScrobble> getUserScrobbles(
    String username, {
    DateTime from,
    DateTime to,
    Cancelled cancelled,
    int requestLimit = 200,
  }) async* {
    assert(requestLimit != null && requestLimit > 0 && requestLimit <= 200);
    for (var i = 1;; i++) {
      var scrobbles = <dynamic>[];
      final resp = await _request('user.getrecenttracks', {
        'user': username,
        'extended': '1',
        'limit': requestLimit.toString(),
        'page': i.toString(),
        if (from != null) 'from': from.secondsSinceEpoch.toString(),
        if (to != null) 'to': to.secondsSinceEpoch.toString()
      });

      if (resp['recenttracks']['track'].isEmpty) break;

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

      if (cancelled != null && cancelled()) throw CancelledException();

      for (final scrobble in scrobbles) {
        yield _deserializeScrobble(scrobble);
      }

      print('$i/$totalPages');
      if (i >= totalPages) break;
    }
  }
}
