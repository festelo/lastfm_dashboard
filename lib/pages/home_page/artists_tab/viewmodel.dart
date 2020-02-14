import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:rxdart/rxdart.dart';

class SingleArtistViewModel {
  final Artist artist;
  final int scrobbles;
  final Color selectionColor;
  SingleArtistViewModel({
    this.artist,
    this.scrobbles,
    this.selectionColor
  });
}
class _SingleArtistViewModelMutable {
  Artist artist;
  int scrobbles;
  _SingleArtistViewModelMutable({
    this.artist,
    this.scrobbles
  });
  SingleArtistViewModel toImmutable() =>
    SingleArtistViewModel(artist: artist, scrobbles: scrobbles);
}

class ArtistsViewModel {
  final LocalDatabaseService db;
  final AuthService authService;

  StreamSubscription _authSubscription;
  StreamSubscription _scrobblesSubscription;

  ArtistsViewModel({
    this.db,
    this.authService
  }) {
    _authSubscription = authService.currentUser.listen((username) {
      _scrobblesSubscription?.cancel();
      _scrobblesSubscription = db.users[username].scrobbles.changes().listen(
        (d) => _updateArtists(d)
      );
    });
  }

  Future<void> _updateArtists(List<TrackScrobble> scrobbles) async {
    for (final a in _artists.values)
      a.scrobbles = 0;

    for(final scrobble in scrobbles) {
      if(_artists[scrobble.artistId] == null) {
        _artists[scrobble.artistId] = _SingleArtistViewModelMutable(
          artist: await db.artists[scrobble.artistId].get(),
          scrobbles: 1
        );
      } else {
        _artists[scrobble.artistId].scrobbles++;
      }
    }
    _artistsSubject.add(_artists.values.toList());
  }

  final _artists = <String, _SingleArtistViewModelMutable>{}; 

  final BehaviorSubject<List<_SingleArtistViewModelMutable>> _artistsSubject = BehaviorSubject.seeded(null);
  Stream<List<SingleArtistViewModel>> get artists => 
    _artistsSubject
      .stream
      .map((s) => s
        .where((a) => a.scrobbles > 0)
        .map((a) => a.toImmutable())
        .toList()
        ..sort(
          (b, a) => a.scrobbles.compareTo(b.scrobbles)
        )
      );

    Future<void> close() async {
      await _authSubscription?.cancel();
      await _scrobblesSubscription?.cancel();
      await _artistsSubject?.close();
    }
}