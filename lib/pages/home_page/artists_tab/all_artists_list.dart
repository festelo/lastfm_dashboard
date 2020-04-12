import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/pages/home_page/artists_tab/artist_list_item.dart';
import 'package:provider/provider.dart';

class AllArtistsList extends StatelessWidget {
  const AllArtistsList();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Consumer<ArtistsViewModel>(builder: (_, vm, snap) {
          if (vm.artistsDetailed == null ||
              (vm.artistsDetailed.isEmpty &&
                  Provider.of<UsersBloc>(context).isUserRefreshing(user.id)))
            return Center(
              child: CircularProgressIndicator(),
            );
          final selectionsById = vm.artistSelections
              ?.asMap()
              ?.map((key, value) => MapEntry(value.artistId, value))
              ?? {};
          final artistSelection = (artistIndex) =>
              selectionsById[vm.artistsDetailed[artistIndex].name];
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10),
            itemCount: vm.artistsDetailed.length,
            itemBuilder: (_, i) => ArtistListItem(
              selection: artistSelection(i),
              artistDetails: vm.artistsDetailed[i],
            ),
          );
        }),
      ),
    );
  }
}
