import 'package:flutter/material.dart';

class ArtistListItem extends StatelessWidget {
  final String name;
  final String image;
  final int scrobbles;
  final Color selectionColor;
  final VoidCallback onPressed;

  const ArtistListItem({
    this.name,
    this.image,
    this.scrobbles,
    this.selectionColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: onPressed,
      padding: EdgeInsets.all(0),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Container(
              color: selectionColor,
              height: 44,
              width: 2,
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectionColor,
              ),
              height: 46,
              width: 46,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          image != null ? NetworkImage(image) : null,
                    ),
                  ),
                  if (selectionColor != null)
                    Center(
                      child: Icon(
                        Icons.check,
                        color: selectionColor,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 20,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  Text(
                    '$scrobbles scrobbles',
                    style: Theme.of(context).textTheme.caption,
                  )
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
            SizedBox(
              width: 12,
            ),
          ],
        ),
      ),
    );
  }
}
