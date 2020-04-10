import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:provider/provider.dart';

class ArtistsList extends StatefulWidget {
  @override
  _ArtistsListState createState() => _ArtistsListState();
}

class _ArtistsListState extends State<ArtistsList> {
  Widget listItem({
    String name,
    String image,
    int scrobbles,
    Color selectionColor,
    VoidCallback onPressed,
  }) {
    return FlatButton(
      onPressed: onPressed,
      padding: EdgeInsets.all(0),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Container(
              color: selectionColor,
              height: 44,
              width: 2,
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectionColor,
              ),
              height: 46,
              width: 46,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          image != null ? NetworkImage(image) : null,
                    ),
                  ),
                  if (selectionColor != null)
                    Center(
                      child: Icon(
                        Icons.check,
                        color: selectionColor,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 20,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  Text(
                    '$scrobbles scrobbles',
                    style: Theme.of(context).textTheme.caption,
                  )
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
            SizedBox(
              width: 12,
            ),
          ],
        ),
      ),
    );
  }

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
              itemBuilder: (_, i) => listItem(
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
