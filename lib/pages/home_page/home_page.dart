import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/pages/home_page/accounts_modal.dart';
import 'package:provider/provider.dart';

import 'artists_tab/artists_tab.dart';

/// Providers: 
/// - LocalDatabaseService
/// - AuthService
/// - LastFMApi
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _HomePageContent();
  }
}

class _HomePageContent extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  
  void accountsManagement(BuildContext context) {
    scaffoldKey.currentState.showBottomSheet(
      (_) => AccountsModal(),
      shape: Border(
        top: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 2
        ),
      ),
    );
  }

  Widget content(BuildContext context, User user) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Last.FM Dashboard'),
        actions: <Widget>[
          if (user == null) Container()
          else Container(
            margin: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: IconButton(
              icon: CircleAvatar(
                backgroundImage: user.imageInfo?.small == null
                  ? null
                  : NetworkImage(user.imageInfo?.small),
              ),
              onPressed: () => accountsManagement(context)
            )
          )
        ],
      ),
      body: user == null 
        ? Center(
          child: Card(
            child: Container(
              height: 100,
              width: double.infinity,
              child: FlatButton(
                child: Text('Pick an account'),
                onPressed: () => accountsManagement(context)
              ),
            ),
          ),
        )
        : Column(
          children: [
            Expanded(child: ArtistsTab()),
            // Not in bottomNavigationBar property to let bottom sheet 
            // be over the bottom nav bar
            BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.music_note),
                  title: Text('Tracks')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  title: Text('Artists')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music),
                  title: Text('Tags')
                ),
              ],
            )
          ]
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return content(context, Provider.of<UsersViewModel>(context).currentUser);
  }
}