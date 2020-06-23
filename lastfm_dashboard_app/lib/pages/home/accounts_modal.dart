import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/features/users_list/users_list.dart';

class AccountsModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        Expanded(
          child: UsersList(),
        )
      ],
    );
  }
}