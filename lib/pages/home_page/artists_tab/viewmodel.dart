import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class SingleArtistViewModel {
  final Artist artist;
  final int scrobbles;
  final Color selectionColor;

  SingleArtistViewModel({this.artist, this.scrobbles, this.selectionColor});
}

class SingleArtistViewModelMutable {
  Artist artist;
  int scrobbles;

  SingleArtistViewModelMutable({this.artist, this.scrobbles});

  SingleArtistViewModel toImmutable() =>
      SingleArtistViewModel(artist: artist, scrobbles: scrobbles);
}

class ArtistsViewModel {
  final LocalDatabaseService db;
  final AuthService authService;

  StreamSubscription _authSubscription;
  StreamSubscription _scrobblesSubscription;

  final _artists = <String, SingleArtistViewModelMutable>{};

  BehaviorSubject<List<SingleArtistViewModelMutable>> _artistsSubject =
      BehaviorSubject.seeded(null);

  Stream<List<SingleArtistViewModel>> get artists =>
      _artistsSubject.stream.map((artist) => artist
          .where((a) => a.scrobbles > 0)
          .map((a) => a.toImmutable())
          .toList()
            ..sort((b, a) => a.scrobbles.compareTo(b.scrobbles)));

  ArtistsViewModel({this.db, this.authService}) {
    _authSubscription = authService.currentUser.listen((username) {
      _scrobblesSubscription?.cancel();
      _scrobblesSubscription = db.users[username].scrobbles
          .changes()
          .listen((d) => _updateArtists(d));
    });
  }

  Future<void> _updateArtists(List<TrackScrobble> scrobbles) async {
    _artists.values.forEach((a) => a.scrobbles = 0);
    for (final scrobble in scrobbles) {
      if (_artists[scrobble.artistId] == null) {
        _artists[scrobble.artistId] = SingleArtistViewModelMutable(
          artist: await db.artists[scrobble.artistId].get(),
          scrobbles: 1,
        );
      } else {
        _artists[scrobble.artistId].scrobbles++;
      }
    }
    _artistsSubject.add(_artists.values.toList());
  }

  Future<void> close() async {
    await _authSubscription?.cancel();
    await _scrobblesSubscription?.cancel();
    await _artistsSubject?.close();
  }
}
