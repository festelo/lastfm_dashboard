import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/no_glow_scroll_behavior.dart';

class AccountsModal extends StatefulWidget {
  @override
  _AccountsModalState createState() => _AccountsModalState();
}

class _AccountInfo {
  final String image;
  final String name;
  _AccountInfo({this.name, this.image});
}

class _AccountsModalState extends State<AccountsModal> {
  static const image = "https://lastfm.freetls.fastly.net/i/u/avatar170s/9d2c9621f61b7a07532ada4b9fbd70a3.webp";
  var _connecting = false;

  final accounts = [
    _AccountInfo(
      name: "festelo",
      image: image
    ),
    _AccountInfo(
      name: "festelotw",
      image: image
    ),
    _AccountInfo(
      name: "festelotw2",
      image: image
    ),
  ];

  TextEditingController _connectingController = TextEditingController();

  Widget userWidget(_AccountInfo account) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: 5
    ),
    child: Row(
      children: <Widget>[
        CircleAvatar(
          backgroundImage: NetworkImage(account.image),
        ),
        SizedBox(width: 20,),
        Expanded(
          child: Text(account.name,
            style: Theme.of(context).textTheme.subhead,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.delete),
        )
      ],
    ),
  );

  void add(String text) {
    setState(() {
      accounts.insert(0, _AccountInfo(
        name: _connectingController.text,
        image: image
      ));
    });
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
                  style: Theme.of(context).textTheme.subhead
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
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: accounts.length,
                itemBuilder: (_, i) => userWidget(accounts[i % accounts.length])
              ),
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
                          Navigator.of(context).pop();
                          add(_connectingController.text);
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