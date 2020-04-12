import 'package:flutter/material.dart';
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
        child: Consumer<ArtistsViewModel>(
          builder: (_, vm, snap) {
            if (vm.artistsDetailed == null ||
                (vm.artistsDetailed.isEmpty &&
                Provider.of<UsersBloc>(context).isUserRefreshing(user.id))
              )
              return Center(
                child: CircularProgressIndicator(),
              );
              
            return ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: 10
              ),
              itemCount: vm.artistsDetailed.length,
              itemBuilder: (_, i) => ArtistListItem(
                image: vm.artistsDetailed[i].imageInfo.small,
                name: vm.artistsDetailed[i].name,
                scrobbles: vm.artistsDetailed[i].scrobbles,
                // selectionColor: vm.artistsWithListens[i].s,
                // onPressed: () => setState(() => 
                //   artistsArray[i].selectionColor = [
                //     Colors.red,
                //     Colors.green,
                //     Colors.orange,
                //     Colors.yellow,
                //     null
                //   ][counter++ % 5]
                // )
              ),
            );
          }
        ),
      ),
    );
  }
}
