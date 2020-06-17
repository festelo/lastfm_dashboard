import 'package:epic/epic.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics/epic_state.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/extensions.dart';
import 'package:lastfm_dashboard/widgets/no_glow_scroll_behavior.dart';
import 'user_list_item.dart';

class UsersList extends StatefulWidget {
  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends EpicState<UsersList> {
  String _errorText;
  var _connecting = false;

  User currentUser;
  List<User> users;
  List<String> refresingUsers;
  List<String> removingUsers;

  @override
  Future<void> onLoad() async {
    final db = await provider.get<LocalDatabaseService>();
    users = await db.users.getAll();
    currentUser = await provider.get<User>(currentUserKey);

    refresingUsers = epicManager.runned
        .whereType<RefreshUserEpic>()
        .map((e) => e.username)
        .toList();

    removingUsers = epicManager.runned
        .whereType<RemoveUserEpic>()
        .map((e) => e.username)
        .toList();

    handle(userAdded);
    handle(userRemoved);
    handle(userRefreshed);
    map<EpicStarted, String>(
      userRemovingStarted,
      (e) => (e.runned.epic as RemoveUserEpic).username,
      where: (e) => e.runned.epic is RemoveUserEpic,
    );
    map<EpicStarted, String>(
      userRefresingStarted,
      (e) => (e.runned.epic as RefreshUserEpic).username,
      where: (e) => e.runned.epic is RefreshUserEpic,
    );
  }

  void userRemovingStarted(String username) {
    removingUsers.add(username);
    apply();
  }

  void userRefresingStarted(String username) {
    refresingUsers.add(username);
    apply();
  }

  void userAdded(UserAdded event) {
    users.add(event.user);
    apply();
  }

  void userRemoved(UserRemoved event) {
    users.removeWhere((u) => u.username == event.username);
    removingUsers.remove(event.username);
    apply();
  }

  void userRefreshed(UserRefreshed event) {
    users.replaceWhere(
      (u) => u.username == event.oldUser.username,
      event.newUser,
    );
    refresingUsers.remove(event.oldUser.username);
    apply();
  }

  final TextEditingController _connectingController = TextEditingController();

  Future<void> addPress(String username) async {
    try {
      setState(() => _errorText = null);
      await add(username);
      Navigator.of(context).pop();
    } on Exception catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  Future<void> add(String username) async {
    final addRunned = epicManager.start(AddUserEpic(username));
    await addRunned.completed;

    final switchRunned = epicManager.start(SwitchUserEpic(username));
    await switchRunned.completed;

    epicManager.start(RefreshUserEpic(username));
  }

  Future<void> remove(String username) async {
    final current = await provider.get(currentUserKey);
    if (username == current.username) {
      final switchUser = epicManager.start(SwitchUserEpic(null));
      await switchUser.completed;
    }
    epicManager.start(RemoveUserEpic(username));
  }

  void switchAccount(String username) {
    epicManager.start(SwitchUserEpic(username));
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading) {
      content = Container(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (users.isEmpty) {
      content = Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'There\'s no accounts yet',
          style: Theme.of(context).textTheme.bodyText2,
        ),
      );
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        itemCount: users.length,
        itemBuilder: (_, i) => UserListItem(
          user: users[i],
          current: currentUser?.username == users[i].username,
          refreshing: refresingUsers.contains(users[i].username),
          removing: removingUsers.contains(users[i].username),
          onRemove: () => remove(users[i].username),
          onSwitch: () => switchAccount(users[i].username),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: ScrollConfiguration(
              behavior: NoGlowScrollBehavior(),
              child: content,
            ),
          ),
          if (!_connecting)
            Container(
              width: double.infinity,
              child: FlatButton(
                onPressed: () {
                  setState(() => _connecting = true);
                },
                child: Text('Connect account'),
              ),
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: _connectingController,
                    onSubmitted: (t) => addPress(t),
                    decoration: InputDecoration(
                      errorText: _errorText,
                      hintText: 'Last.FM username or link',
                      suffix: IconButton(
                        onPressed: () {
                          addPress(_connectingController.text);
                        },
                        icon: Icon(Icons.check_circle),
                      ),
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}
