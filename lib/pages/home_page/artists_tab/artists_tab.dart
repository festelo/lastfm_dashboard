import 'package:flutter/material.dart';
import './artists_chart.dart';
import 'all_artists_list.dart';
import 'selected_artists_list.dart';

/// Providers required:
/// - AuthService
/// - LocalDatabaseService
class ArtistsTab extends StatefulWidget {
  @override
  _ArtistsTabState createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    animation = Tween<double>(begin: 0, end: 1).animate(controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (animation.value != 0) {
            controller.reverse();
            return false;
          } else
            return true;
        },
        child: LayoutBuilder(
          builder: (ctx, cnst) => Stack(
            children: [
              Positioned(
                top: animation.value * cnst.maxHeight,
                height: cnst.maxHeight,
                width: cnst.maxWidth,
                child: Opacity(
                  opacity: 1 - animation.value,
                  child: Column(
                    children: [
                      Expanded(child: ArtistsChart()),
                      Expanded(
                        child: SelectedArtistsList(
                          addArtistPressed: () {
                            controller.forward();
                          },
                        ),
                      ),
                      SizedBox(height: 20)
                    ],
                  ),
                ),
              ),
              Positioned(
                top: cnst.maxHeight - animation.value * cnst.maxHeight,
                height: cnst.maxHeight,
                width: cnst.maxWidth,
                child: Opacity(
                  opacity: animation.value,
                  child: Column(
                    children: [
                      Expanded(child: const AllArtistsList()),
                      RaisedButton(onPressed: () {
                        controller.reverse();
                      })
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}
