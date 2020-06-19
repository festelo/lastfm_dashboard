import 'package:epic/epic.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/epics/helpers.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/epics_ui/epic_state.dart';
import 'package:lastfm_dashboard/widgets/no_glow_scroll_behavior.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
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
  Future<void> onLoad(provider) async {
    final usersRep = await provider.get<UsersRepository>();
    users = await usersRep.getAll();
    currentUser = await provider.get<User>(currentUserKey);

    refresingUsers = epicManager.runned
        .whereType<RefreshUserEpic>()
        .map((e) => e.userId)
        .toList();

    removingUsers = epicManager.runned
        .whereType<RemoveUserEpic>()
        .map((e) => e.userId)
        .toList();

    handle(userAdded);
    handle(userRemoved);
    handle(userRefreshed);
    map<EpicStarted, String>(
      userRemovingStarted,
      (e) => (e.runned.epic as RemoveUserEpic).userId,
      where: (e) => e.runned.epic is RemoveUserEpic,
    );
    map<EpicStarted, String>(
      userRefresingStarted,
      (e) => (e.runned.epic as RefreshUserEpic).userId,
      where: (e) => e.runned.epic is RefreshUserEpic,
    );
  }

  void userRemovingStarted(String id, _) {
    removingUsers.add(id);
    apply();
  }

  void userRefresingStarted(String id, _) {
    refresingUsers.add(id);
    apply();
  }

  void userAdded(UserAdded event, _) {
    users.add(event.user);
    apply();
  }

  void userRemoved(UserRemoved event, _) {
    users.removeWhere((u) => u.id == event.userId);
    removingUsers.remove(event.userId);
    apply();
  }

  void userRefreshed(UserRefreshed event, _) {
    users.replaceWhere(
      (u) => u.id == event.oldUser.id,
      event.newUser,
    );
    refresingUsers.remove(event.oldUser.id);
    apply();
  }

  final TextEditingController _connectingController = TextEditingController();

  Future<void> addPress(String id) async {
    try {
      setState(() => _errorText = null);
      await add(id);
      Navigator.of(context).pop();
    } on Exception catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  Future<void> add(String username) async {
    final user = await epicManager.wait(AddUserEpic(username));

    final switchRunned = epicManager.start(SwitchUserEpic(user.id));
    await switchRunned.completed;

    epicManager.start(RefreshUserEpic(user.id));
  }

  Future<void> remove(String id) async {
    final current = await gain((p) => p.get(currentUserKey));
    if (id == current.id) {
      final switchUser = epicManager.start(SwitchUserEpic(null));
      await switchUser.completed;
    }
    epicManager.start(RemoveUserEpic(id));
  }

  void switchAccount(String id) {
    epicManager.start(SwitchUserEpic(id));
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
          current: currentUser?.id == users[i].id,
          refreshing: refresingUsers.contains(users[i].id),
          removing: removingUsers.contains(users[i].id),
          onRemove: () => remove(users[i].id),
          onSwitch: () => switchAccount(users[i].id),
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
