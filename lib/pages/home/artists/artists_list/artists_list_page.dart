import 'package:flutter/material.dart';

import 'all_artists_list.dart';

class AritstsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: AllArtistsList()),
        RaisedButton(onPressed: () {
          Navigator.pop(context);
        })
      ],
    );
  }
}