import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics/artists_epics.dart';
import 'package:lastfm_dashboard/epics/epic_state.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/pages/home_page/artists_tab/artist_list_item.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class SelectedArtistsList extends StatefulWidget {
  final VoidCallback addArtistPressed;
  const SelectedArtistsList({this.addArtistPressed});

  @override
  _SelectedArtistsListState createState() => _SelectedArtistsListState();
}

class _SelectedArtistsListState extends EpicState<SelectedArtistsList> {
  List<ArtistSelection> selections;
  Map<String, UserArtistDetails> artists;
  bool userRefreshing;
  String userId;

  @override
  Future<void> onLoad() async {
    final db = await provider.get<LocalDatabaseService>();
    final currentUser = await provider.get<User>(currentUserKey);
    userId = currentUser.id;
    selections = await db.artistSelections.getWhere(userId: userId);
    if (selections.isNotEmpty) {
      final artistList = await db.userArtistDetails
          .getWhere(artistIds: selections.map((e) => e.artistId).toList());
      artists = Map.fromEntries(artistList.map((e) => MapEntry(e.artistId, e)));
    } else {
      artists = {};
    }

    userRefreshing = epicManager.runned
        .map((e) => e.epic)
        .whereType<RefreshUserEpic>()
        .any((e) => e.username == currentUser.username);

    subscribe<ArtistSelected>(
      artistSelected,
      where: (e) => e.selection.userId == userId,
    );

    subscribe<ArtistSelectionRemoved>(
      artistSelectionRemoved,
      where: (e) => e.userId == userId,
    );

    subscribe<UserScrobblesAdded>(
      scrobblesAdded,
      where: (e) => e.user.username == userId,
    );
  }

  Future<void> artistSelected(ArtistSelected e) async {
    final db = await provider.get<LocalDatabaseService>();
    artists[e.selection.artistId] = await db.userArtistDetails
        .getWhere(artistIds: [e.selection.artistId]).then((e) => e.first);
    final i = selections.indexWhere((s) => s.artistId == e.selection.artistId);
    if (i != -1)
      selections[i] = e.selection;
    else
      selections.add(e.selection);
  }

  void artistSelectionRemoved(ArtistSelectionRemoved e) {
    selections.removeWhere((s) => s.artistId == e.artistId);
  }

  Future<void> scrobblesAdded(UserScrobblesAdded e) async {
    final db = await provider.get<LocalDatabaseService>();

    final updatedArtistIds =
        e.newScrobbles.map((e) => e.artistId).toSet().toList();
    final updatedArtistList =
        await db.userArtistDetails.getWhere(artistIds: updatedArtistIds);
    
    for (final artist in updatedArtistList) {
      artists[artist.artistId] = artist;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading || artists.isEmpty && userRefreshing) {
      content = Center(
        child: CircularProgressIndicator(),
      );
    } else if (selections.isEmpty) {
      content = FlatButton(
        child: Center(
          child: Text(
            'Nothing is picked\nTap to add an artist',
            textAlign: TextAlign.center,
          ),
        ),
        onPressed: widget.addArtistPressed,
      );
    } else {
      content = Column(children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10),
            itemCount: selections.length,
            itemBuilder: (_, i) => ArtistListItem(
              selection: selections[i],
              artistDetails: artists[selections[i].artistId],
              drawSelectionCircle: false,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 60,
          child: FlatButton(
            onPressed: widget.addArtistPressed,
            child: Text('Select new artist'),
          ),
        )
      ]);
    }
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(0),
        child: content,
      ),
    );
  }
}
