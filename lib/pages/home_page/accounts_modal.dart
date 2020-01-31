import 'package:flutter/material.dart';
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

  Widget userWidget(User user) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: 5
    ),
    child: InkWell(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundImage: user.imageInfo?.small == null
              ? null
              : NetworkImage(user.imageInfo?.small),
          ),
          SizedBox(width: 20,),
          Expanded(
            child: Text(user.username,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          IconButton(
            onPressed: () { remove(user.username); },
            icon: Icon(Icons.delete),
          )
        ],
      ),
      onTap: () {
        switchAccount(user.username);
        Navigator.of(context).pop();
      }
    )
  );

  void add(String username) {
    Provider.of<HomePageViewModel>(context, listen: false)
      .addAccountAndSwitch(username);
  }

  void remove(String username) {
    Provider.of<HomePageViewModel>(context, listen: false)
      .removeAccount(
        username
      );
  }

  void switchAccount(String username) {
    Provider.of<HomePageViewModel>(context, listen: false)
      .switchAccount(
        username
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
                  style: Theme.of(context).textTheme.subtitle1
                ),
              ),
              IconButton(
                iconSize: 24,
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          SizedBox(height: 10,),
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
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    );
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snap.data.length,
                    itemBuilder: (_, i) => userWidget(snap.data[i])
                  );
                }
              )
            )
          ),
          if(!_connecting)
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
                      hintText: "Last.FM username or link",
                      suffix: IconButton(
                        onPressed: () {
                          add(_connectingController.text);
                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.check_circle),
                      )
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