import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/button.dart';
import 'package:lastfm_dashboard/components/no_glow_scroll_behavior.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/pages/home_page/viewmodel.dart';
import 'package:provider/provider.dart';

class AccountsModal extends StatefulWidget {
  @override
  _AccountsModalState createState() => _AccountsModalState();
}

class _AccountsModalState extends State<AccountsModal> {
  var _connecting = false;

  TextEditingController _connectingController = TextEditingController();

  Widget userWidget(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        child: InkWell(
          onTap: () {
            switchAccount(user.username);
            Navigator.of(context).pop();
          },
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  backgroundImage: user.imageInfo?.small == null
                      ? null
                      : NetworkImage(user.imageInfo?.small),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.username,
                  style: Theme.of(context).textTheme.subtitle,
                ),
              ),
              IconButton(
                onPressed: () => remove(user.username),
                icon: Icon(Icons.delete),
              )
            ],
          ),
        ),
      ),
    );
  }

  void add(String username) {
    Provider.of<HomePageViewModel>(context, listen: false)
        .addAccountAndSwitch(username);
  }

  void remove(String username) {
    Provider.of<HomePageViewModel>(context, listen: false)
        .removeAccount(username);
  }

  void switchAccount(String username) {
    Provider.of<HomePageViewModel>(context, listen: false)
        .switchAccount(username);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Account management',
                  style: Theme.of(context).textTheme.subtitle,
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ScrollConfiguration(
              behavior: NoGlowScrollBehavior(),
              child: StreamBuilder<List<User>>(
                stream: Provider.of<HomePageViewModel>(context).currentUsers,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return CircularProgressIndicator();
                  if (snap.error != null)
                    return Padding(
                      padding: EdgeInsets.all(30),
                      child: Text('There\'s some problems'),
                    );
                  if (snap.data.length == 0)
                    return Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'There\'s no accounts yet',
                        style: Theme.of(context).textTheme.body2,
                      ),
                    );
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snap.data.length,
                    itemBuilder: (_, i) => userWidget(snap.data[i]),
                  );
                },
              ),
            ),
          ),
          if (!_connecting)
            ActionOutlineButton(
              onTap: () => setState(() => _connecting = true),
              text: 'Connect account',
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    autofocus: true,
                    cursorColor: Theme.of(context).accentColor,
                    controller: _connectingController,
                    onSubmitted: (text) {
                      add(_connectingController.text);
                      Navigator.of(context).pop();
                    },
                    decoration: InputDecoration(
                      hintText: "Last.fm username or link",
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
