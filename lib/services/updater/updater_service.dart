import 'dart:async';

import 'package:lastfm_dashboard/constants.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/shared/progressable_future.dart';
import 'package:rxdart/streams.dart';
import 'package:rxdart/subjects.dart';
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
  bool _disposed = false;

  final BehaviorSubject<Map<String, ProgressableFuture<void, int>>> 
    _currentUpdatesSubject = BehaviorSubject.seeded({});
    
  ValueStream<Map<String, ProgressableFuture<void, int>>> 
    get currentUpdates => _currentUpdatesSubject.stream;
  
  ProgressableFuture<void, int> _updateUser(User user, {bool silent = true}) {
    return ProgressableFuture((p, c) async {
      final db = _databaseService;
      try {
        final scrobblesProgressable = _lastFMApi.getUserScrobbles(
          user.username, 
          from: user.lastSync
        );
        scrobblesProgressable.chain(p, c);
        if(_disposed) return;
        _currentUpdatesSubject.add({
          ..._currentUpdatesSubject.value,
          user.username: scrobblesProgressable
        });
        try {
          final scrobbles = await scrobblesProgressable;
          if(_disposed) return;
          final artists = scrobbles.map((a) => a.artist).toSet();
          final tracks = scrobbles.map((a) => a.track).toSet().toList();

          for(final artist in artists) {
            db.artists[artist.id].update(
              artist.toDbMap(), 
              createIfNotExist: true
            );
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
          if(_disposed) return;
        } on CancelledException catch(_) {
          print('cancelled');
        } finally {
          _currentUpdatesSubject.add({
            ..._currentUpdatesSubject.value,
          }..remove(user.username));
        }
      } catch (e) {
        if (!silent) rethrow;
        print('Error updating user ${user.username}.\n${e.toString()}');
      }
    });
  }

  Future<void> _update({bool silent = true}) async {
    _updateLock.synchronized(() async {
      final users = await _databaseService.users.getAll();
      for (final user in users) {
        await _updateUser(user);
      }
    });
  }
  
  ProgressableFuture<void, int> updateUser(String username) {
    return ProgressableFuture((p, c) async {
      Future<void> body() async {
        final user = await _databaseService.users[username].get();
        final f = _updateUser(user, silent: false)..chain(p, c);
        await f;
      }
      await _updateLock.synchronized(body);
    });
  }
  
  Future<void> update() async {
    return await _update(silent: false);
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    _currentUpdatesSubject?.close();
  }
}