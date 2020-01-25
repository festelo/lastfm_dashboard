import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home_page/accounts_modal.dart';

import 'artists_tab/artists_tab.dart';

class HomePage extends StatelessWidget {
  static const image = "https://lastfm.freetls.fastly.net/i/u/avatar170s/9d2c9621f61b7a07532ada4b9fbd70a3.webp";
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("Last.FM Dashboard"),
        actions: <Widget>[
          Builder(
            builder: (ctx) => Container(
            margin: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: IconButton(
              icon: CircleAvatar(
                backgroundImage: NetworkImage(image),
              ),
              onPressed: () {
                
                scaffoldKey.currentState.showBottomSheet(
                  (_) => AccountsModal(),
                  shape: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 2
                    ),
                  ),
                );
              },
            )
          )
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(child: ArtistsTab()),
          // Not in bottomNavigationBar property to let bottom sheet be over the bottom nav bar
          BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                title: Text("Tracks")
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                title: Text("Artists")
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                title: Text("Tags")
              ),
            ],
          )
        ]
      )
    );
  }
}