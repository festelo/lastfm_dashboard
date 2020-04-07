import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/components/no_glow_scroll_behavior.dart';
import 'package:lastfm_dashboard/events/users_events.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/extensions.dart';
import 'package:provider/provider.dart';

class AccountsModal extends StatefulWidget {
  @override
  _AccountsModalState createState() => _AccountsModalState();
}

class _AccountsModalState extends State<AccountsModal> {
  var _connecting = false;

  final TextEditingController _connectingController = TextEditingController();

  Widget userWidget(User user) {
    final refreshing =
        Provider.of<UsersBloc>(context).isUserRefreshing(user.id);
    final removing = Provider.of<UsersBloc>(context).isUserRemoving(user.id);
    final current = Provider.of<User>(context)?.id == user.id;
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
                      image: DecorationImage(
                          image: NetworkImage(
                            user.imageInfo?.small,
                          ),
                          colorFilter: !current
                              ? null
                              : ColorFilter.mode(
                                  Colors.black.withOpacity(0.6),
                                  BlendMode.srcOver,
                                ),
                          fit: BoxFit.cover),
                      shape: BoxShape.circle,
                      border: !current
                          ? null
                          : Border.all(
                              color: Theme.of(context).accentColor,
                              width: 1,
                            ),
                    ),
                    child: !current
                        ? null
                        : Icon(
                            Icons.check,
                            color: Theme.of(context).accentColor,
                          ),
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
              if (refreshing || removing)
                Padding(
                  padding: EdgeInsets.only(right: 11),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                IconButton(
                  onPressed: () {
                    remove(user.username);
                  },
                  icon: Icon(
                    Icons.delete,
                  ),
                )
            ],
          ),
          onTap: current || removing
              ? null
              : () {
                  switchAccount(user.username);
                  Navigator.of(context).pop();
                }),
    );
  }

  void add(String username) {
    Provider.of<EventsContext>(context, listen: false).push(
      AddUserEventInfo(
        username: username,
      ),
      addUser,
    );
  }

  void remove(String username) {
    Provider.of<EventsContext>(context, listen: false).push(
      RemoveUserEventInfo(
        username: username,
      ),
      removeUser,
    );
  }

  void switchAccount(String username) {
    Provider.of<EventsContext>(context, listen: false).push(
      SwitchUserEventInfo(
        username: username,
      ),
      switchUser,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Consumer<UsersViewModel>(
                builder: (ctx, d, _) => d.users.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'There\'s no accounts yet',
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount:
                            Provider.of<UsersViewModel>(context).users.length,
                        itemBuilder: (_, i) => userWidget(d.users[i]),
                      ),
              ),
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
                    onSubmitted: (t) => add(t),
                    decoration: InputDecoration(
                      hintText: 'Last.FM username or link',
                      suffix: IconButton(
                        onPressed: () {
                          add(_connectingController.text);
                          Navigator.of(context).pop();
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
