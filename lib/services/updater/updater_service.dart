import 'dart:async';

import 'package:lastfm_dashboard/constants.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:synchronized/synchronized.dart';

class UpdaterService {
  final LastFMApi _lastFMApi;
  final LocalDatabaseService _databaseService;

  Timer _timer;

  UpdaterService({
    LastFMApi lastFMApi,
    LocalDatabaseService databaseService
  }): 
    _lastFMApi = lastFMApi,
    _databaseService = databaseService;

  Future<void> start() async {
    if (_timer != null) {
      throw Exception('Updater service already started');
    }
    _timer = Timer.periodic(
      UpdaterConfig.period,
      (_) => _update()
    );
    await _update();
  }
  final _updateLock = Lock();
  
  Future<void> _updateUser(User user, {bool silent = true}) async {
    final db = _databaseService;
    try {
      final scrobbles = await _lastFMApi.getUserScrobbles(
        user.username, 
        from: user.lastSync
      );
      final artists = scrobbles.map((a) => a.artist).toSet();
      final tracks = scrobbles.map((a) => a.track).toSet().toList();

      for(final artist in artists) {
        db.artists[artist.id].update(artist.toDbMap(), createIfNotExist: true);
      }

      for(final track in tracks) {
        db.tracks[track.id].update(track.toDbMap(), createIfNotExist: true);
      }

      await db.users[user.id].scrobbles.addAll(
        scrobbles.map((e) => e.toTrackScrobble())
      );

      await db.users[user.id].writeSelective(
        (u) => u.copyWith(
          lastSync: DateTime.now()
        )
      );
    } catch (e) {
      if (!silent) rethrow;
      print('Error updating user ${user.username}.\n${e.toString()}');
    }
  }

  Future<void> _update({bool silent = true}) async {
    _updateLock.synchronized(() async {
      final users = await _databaseService.users.getAll();
      for (final user in users) {
        await _updateUser(user);
      }
    });
  }
  
  Future<void> updateUser(String username) async {
    Future<void> body() async {
      final user = await _databaseService.users[username].get();
      await _updateUser(user, silent: false);
    }
    await _updateLock.synchronized(body);
  }
  
  Future<void> update() async {
    return await _update(silent: false);
  }

  Future<void> dispose() async {
    _timer?.cancel();
  }
}