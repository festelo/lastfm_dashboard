import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics/artists_epics.dart';
import 'package:lastfm_dashboard/epics/epic_state.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import '../artist_list_item.dart';

class AllArtistsList extends StatefulWidget {
  @override
  _AllArtistsListState createState() => _AllArtistsListState();
}

class _AllArtistsListState extends EpicState<AllArtistsList> {
  List<UserArtistDetails> userArtists;
  Map<String, ArtistSelection> selections;
  bool userRefreshing;
  String userId;

  @override
  Future<void> onLoad() async {
    final db = await provider.get<LocalDatabaseService>();
    final currentUser = await provider.get(currentUserKey);
    userId = currentUser.id;
    userArtists = await db.userArtistDetails.getWhere(
      userIds: [userId],
      scrobblesSort: SortDirection.descending,
    );
    final selectionList = await db.artistSelections.getWhere(userId: userId);
    selections = Map.fromEntries(selectionList.map((e) => MapEntry(e.id, e)));
    userRefreshing = await provider.get(userRefreshingKey);

    handle<UserScrobblesAdded>(
      scrobblesAdded,
      where: (e) => e.user.username == userId,
    );

    handle<ArtistSelected>(
      artistSelected,
      where: (e) => e.selection.userId == userId,
    );

    handle<ArtistSelectionRemoved>(
      artistSelectionRemoved,
      where: (e) => e.userId == userId,
    );
  }

  Future<void> scrobblesAdded(UserScrobblesAdded e) async {
    final db = await provider.get<LocalDatabaseService>();

    final updatedArtistIds =
        e.newScrobbles.map((e) => e.artistId).toSet().toList();
    final updatedArtistList =
        await db.userArtistDetails.getWhere(artistIds: updatedArtistIds);
    final updatedArtistMap =
        Map.fromEntries(updatedArtistList.map((e) => MapEntry(e.artistId, e)));

    for (var i = 0; i < userArtists.length; i++) {
      final updatedArtist = updatedArtistMap[userArtists[i].artistId];
      if (updatedArtist != null) {
        userArtists[i] = updatedArtist;
      }
    }

    for (var i = 0; i < updatedArtistList.length; i++) {
      final contains =
          userArtists.any((c) => c.artistId == updatedArtistList[i].artistId);
      if (!contains) {
        userArtists.add(updatedArtistList[i]);
      }
    }
  }

  void artistSelected(ArtistSelected e) {
    selections[e.selection.artistId] = e.selection;
  }

  void artistSelectionRemoved(ArtistSelectionRemoved e) {
    selections.remove(e.artistId);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(0),
        child: loading || userArtists.isEmpty && userRefreshing
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 10),
                itemCount: userArtists.length,
                itemBuilder: (_, i) => ArtistListItem(
                  selection: selections[userArtists[i].artistId],
                  artistDetails: userArtists[i],
                ),
              ),
      ),
    );
  }
}
