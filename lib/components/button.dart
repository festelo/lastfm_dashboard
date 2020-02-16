import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const ActionButton({this.text = '', this.onTap});

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      color: Theme.of(context).accentColor,
      textColor: Theme.of(context).primaryColor,
      splashColor: Theme.of(context).primaryColorLight,
      onPressed: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(context).textTheme.body1,
        ),
      ),
    );
  }
}

class ActionOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const ActionOutlineButton({this.text = '', this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      borderSide: BorderSide(color: Theme.of(context).accentColor),
      textColor: Theme.of(context).primaryColor,
      splashColor: Theme.of(context).primaryColorLight,
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.body1,
        ),
      ),
    );
  }
}
