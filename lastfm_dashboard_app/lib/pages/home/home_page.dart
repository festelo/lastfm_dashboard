import 'dart:async';

import 'package:epic/epic.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics/helpers.dart';
import 'package:lastfm_dashboard/epics_ui/epic_state.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'accounts_modal.dart';

import 'artists_tab/artists_tab.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends EpicState<HomePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  User user;
  bool isRefreshing;
  
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
    isRefreshing = await provider.get(userRefreshingKey);
    handle<UserSwitched>(userSwitched);
    handle<UserRefreshed>(userRefreshed, 
      where: (e) => e.newUser.username == user.username,
    );
    map<EpicStarted, String>(
      userRefresingStarted,
      (e) => (e.runned.epic as RefreshUserEpic).userId,
      where: (e) => e.runned.epic is RefreshUserEpic,
    );
    await refreshUser();
  }

  Future<void> userSwitched(UserSwitched e) async {
    await refreshUser();
  }

  Future<void> refreshUser([String username]) async {
    user = await provider.get(currentUserKey);
  }

  void userRefreshed(UserRefreshed e) {
    isRefreshing = false;
  }

  void userRefresingStarted(String username) {
    isRefreshing = true;
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
            Expanded(child: ArtistsTab(ValueKey(user.id))),
            if (isRefreshing) 
              LinearProgressIndicator(),
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