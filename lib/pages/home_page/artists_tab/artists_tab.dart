import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home_page/artists_tab/duration_switcher.dart';
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
  var durationSwitcherOffsetX = 0.0;
  var durationSwitcherOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 250),
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
              Positioned(
                right: 0 - durationSwitcherOffsetX,
                top: 0 + durationSwitcherOffsetY,
                child: GestureDetector(
                  child: Container(
                      child: DurationSwitcher(
                    width: 160,
                    height: 40,
                    margin: 20,
                  )),
                  onPanUpdate: (e) {
                    const width = 160 + 40;
                    const height = 40 + 40;
                    final newOffsetX = durationSwitcherOffsetX + e.delta.dx;
                    final newOffsetY = durationSwitcherOffsetY + e.delta.dy;
                    var approvedOffsetX = durationSwitcherOffsetX;
                    var approvedOffsetY = durationSwitcherOffsetY;
                    if (newOffsetX <= 0 &&
                        newOffsetX >= -(cnst.maxWidth - width)) {
                      approvedOffsetX = newOffsetX;
                    }
                    if (newOffsetY >= 0 &&
                        newOffsetY <= cnst.maxHeight - height) {
                      approvedOffsetY = newOffsetY;
                    }
                    setState(() {
                      durationSwitcherOffsetX = approvedOffsetX;
                      durationSwitcherOffsetY = approvedOffsetY;
                    });
                  },
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
