import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/no_glow_scroll_behavior.dart';
import 'package:lastfm_dashboard/epics/epic_state.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/extensions.dart';
import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';

class UserAccountModal extends StatelessWidget {
  final User user;
  final bool current;
  final bool removing;
  final bool refreshing;
  final VoidCallback onRemove;
  final VoidCallback onSwitch;

  const UserAccountModal({
    Key key,
    this.user,
    this.current,
    this.removing,
    this.refreshing,
    this.onRemove,
    this.onSwitch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorFilter = !current
        ? null
        : ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOver,
          );

    final border = !current
        ? null
        : Border.all(
            color: Theme.of(context).accentColor,
            width: 1,
          );

    final checkChild = !current
        ? null
        : Icon(
            Icons.check,
            color: Theme.of(context).accentColor,
          );

    final endWidget = refreshing || removing
        ? Padding(
            padding: EdgeInsets.only(right: 11, left: 11),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(),
            ),
          )
        : IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.delete,
            ),
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        child: Row(
          children: <Widget>[
            Stack(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    image: user.imageInfo?.small != null
                      ? DecorationImage(
                        image: NetworkImage(
                          user.imageInfo?.small,
                        ),
                        colorFilter: colorFilter,
                        fit: BoxFit.cover,
                      )
                      : null,
                    shape: BoxShape.circle,
                    border: border,
                  ),
                  child: checkChild,
                ),
              ],
            ),
            SizedBox(
              width: 20,
            ),
            Expanded(
              child: Text(
                user.username,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            Text(user.lastSync?.toHumanable() ?? ''),
            endWidget
          ],
        ),
        onTap: current || removing
            ? null
            : () {
                onSwitch();
                Navigator.of(context).pop();
              },
      ),
    );
  }
}

class AccountsModal extends StatefulWidget {
  @override
  _AccountsModalState createState() => _AccountsModalState();
}

class _AccountsModalState extends EpicState<AccountsModal> {
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

    subscribe(userAdded);
    subscribe(userRemoved);
    subscribe(userRefreshed);
    map<EpicStarted, String>(
      userRemovingStarted,
      (e) => (e.runned.epic as RemoveUserEpic).username,
      where: (e) => e.runned.epic is RemoveUserEpic,
    );
    map<EpicStarted, String>(
      userRemovingStarted,
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
      content = Center(
        child: CircularProgressIndicator(),
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
        itemBuilder: (_, i) => UserAccountModal(
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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Accounts management',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
              IconButton(
                iconSize: 24,
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
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
