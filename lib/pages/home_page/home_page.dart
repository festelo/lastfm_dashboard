import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/loading_screen.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/pages/home_page/accounts_modal.dart';
import 'package:lastfm_dashboard/pages/home_page/viewmodel.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:provider/provider.dart';

import 'artists_tab/artists_tab.dart';

/// Providers: 
/// - LocalDatabaseService
/// - AuthService
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<HomePageViewModel>(
      create: (_) => HomePageViewModel(
        authService: Provider.of<AuthService>(context),
        db: Provider.of<LocalDatabaseService>(context),
      ),
      child: _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  static const image = "https://lastfm.freetls.fastly.net/i/u/avatar170s/9d2c9621f61b7a07532ada4b9fbd70a3.webp";
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
        title: Text("Last.FM Dashboard"),
        actions: <Widget>[
          if (user == null) Container()
          else Container(
            margin: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: IconButton(
              icon: CircleAvatar(
                backgroundImage: NetworkImage(image),
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

  @override
  Widget build(BuildContext context) {
    final userStream = Provider.of<HomePageViewModel>(context).currentUser();
    return StreamBuilder<User>(
      stream: userStream,
      initialData: null,
      builder: (_, snap) {
        return snap.connectionState == ConnectionState.waiting
          ? LoadingScreen()
          : content(context, snap.data);
      }
    );
  }
}