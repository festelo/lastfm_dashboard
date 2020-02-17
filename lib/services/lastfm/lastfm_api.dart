import 'package:lastfm_dashboard/models/models.dart';
import 'package:dio/dio.dart';
import 'package:lastfm_dashboard/sensitive.dart' as sensitive;

class LastFMScrobble {
  final Artist artist;
  final Track track;
  final DateTime date;
  LastFMScrobble({
    this.artist,
    this.track,
    this.date
  });
  
  TrackScrobble toTrackScrobble() =>
    TrackScrobble(
      artistId: artist.id,
      trackId: track.id,
      date: date
    );
}

class LastFMApi {
  static const apiKey = sensitive.lastFmKey;
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://ws.audioscrobbler.com/2.0/',
      queryParameters: {
        'api_key': apiKey,
        'format': 'json'
      },
      receiveDataWhenStatusError: true,
    )
  );

  Future<dynamic> _request(
    String method, 
    Map<String, String> parameters
  ) async {
    final response = await _dio.get('/', 
      queryParameters: {
        'method': method,
        ...parameters
      },
    );
    if (response.data['error'] != null) {
      throw Exception(response.data);
    }
    return response.data;
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
    final resp = await _request('user.getinfo', {
      'user': username
    });
    return User(
      imageInfo: _deserializeImage(resp['user']['image']),
      lastSync: DateTime.now(),
      playCount: int.tryParse(resp['user']['playcount']),
      username: username,
    );
  }

  Future<List<LastFMScrobble>> getUserScrobbles(String username, {
    DateTime from
  }) async {
    final scrobbles = <dynamic>[];
    for(var i = 1; ; i++) {
      final resp = await _request('user.getrecenttracks', {
        'user': username,
        'extended': '1',
        'limit': '200',
        'page': i.toString(),
        if (from != null)
          'from': (from.millisecondsSinceEpoch / 1000).toStringAsFixed(0)
      });
      scrobbles.addAll(resp['recenttracks']['track']);
      final totalPages = int.tryParse(
        resp['recenttracks']['@attr']['totalPages']
      );
      if (i >= totalPages) break;
      print('$i/$totalPages');
    }
    final res = <LastFMScrobble>[];
    for (final scrobble in scrobbles) {
      if (
        scrobble['@attr'] != null && 
        scrobble['@attr']['nowplaying'] == 'true'
      ) continue;
      final artist = Artist(
        imageInfo: _deserializeImage(scrobble['image']), // bypass
        name: scrobble['artist']['name'],
        mbid: scrobble['artist']['mbid'],
        url: scrobble['artist']['url']
      );
      final track = Track(
        imageInfo: _deserializeImage(scrobble['image']),
        artistId: artist.id,
        mbid: scrobble['mbid'],
        name: scrobble['name'],
        url: scrobble['url'],
        loved: scrobble['loved'] == '1'
      );
      res.add(
        LastFMScrobble(
          artist: artist,
          track: track,
          date: DateTime.now()
        )
      );
    }
    return res;
  }
}