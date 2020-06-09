import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics/epic_state.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'accounts_modal.dart';

import 'artists/artists_tab.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends EpicState<HomePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  User user;
  
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

  @override
  Future<void> onLoad() async {
    subscribe<UserSwitched>(userSwitched);
    await refreshUser();
  }

  Future<void> userSwitched(UserSwitched e) async {
    await refreshUser();
  }

  Future<void> refreshUser([String username]) async {
    user = await provider.get<User>(currentUserKey);
  }

  @override
  Widget build(BuildContext context) {
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
}