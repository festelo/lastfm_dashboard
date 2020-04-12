import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:provider/provider.dart';
import './artist_list_item.dart';

class SelectedArtistsList extends StatelessWidget {
  final VoidCallback addArtistPressed;
  const SelectedArtistsList({this.addArtistPressed});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Consumer<ArtistsViewModel>(builder: (_, vm, snap) {
          if (vm.artistSelections == null ||
              (vm.artistsDetailed.isEmpty &&
                  Provider.of<UsersBloc>(context).isUserRefreshing(user.id)))
            return Center(
              child: CircularProgressIndicator(),
            );
          final selectionsByArtistId = vm.artistSelections
              .asMap()
              .map((key, value) => MapEntry(value.artistId, value));

          final selectedArtists = vm.artistSelections
              .map(
                (sel) => vm.artistsDetailed.firstWhere(
                    (artistDetails) => artistDetails.artistId == sel.artistId,
                    orElse: () => null),
              )
              .where((sel) => sel != null)
              .toList();

          final artistSelection = (artistIndex) =>
              selectionsByArtistId[selectedArtists[artistIndex].name];

          if (selectedArtists.isEmpty)
            return FlatButton(
              child: Center(
                child: Text(
                  'Nothing is picked\nTap to add an artist',
                  textAlign: TextAlign.center,
                ),
              ),
              onPressed: addArtistPressed,
            );

          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 10),
                itemCount: selectedArtists.length,
                itemBuilder: (_, i) => ArtistListItem(
                  selection: artistSelection(i),
                  artistDetails: selectedArtists[i],
                  drawSelectionCircle: false,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 60,
              child: FlatButton(
                onPressed: addArtistPressed,
                child: Text('Select new artist'),
              ),
            )
          ]);
        }),
      ),
    );
  }
}
