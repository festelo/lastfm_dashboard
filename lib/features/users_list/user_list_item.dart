
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/models/user.dart';
import 'package:lastfm_dashboard/extensions.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final bool current;
  final bool removing;
  final bool refreshing;
  final VoidCallback onRemove;
  final VoidCallback onSwitch;

  const UserListItem({
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