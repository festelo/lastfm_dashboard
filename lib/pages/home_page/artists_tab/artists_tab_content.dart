import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home_page/artists_tab/duration_switcher.dart';
import './artists_chart.dart';
import 'all_artists_list.dart';
import 'selected_artists_list.dart';

/// Providers required:
/// - AuthService
/// - LocalDatabaseService
class ArtistsTabContent extends StatefulWidget {
  final double height;
  final double width;
  const ArtistsTabContent({@required this.height, @required this.width});

  @override
  _ArtistsTabContentState createState() => _ArtistsTabContentState();
}

class _ArtistsTabContentState extends State<ArtistsTabContent>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  static const _animationDuration = Duration(milliseconds: 250);

  Animation<RelativeRect> selectedArtistsAnimation;
  Animation<RelativeRect> allArtistsAnimation;
  Animation<double> opacityAnimation;
  Animation<double> opacityAnimationReversed;
  
  var durationSwitcherOffsetX = 0.0;
  var durationSwitcherOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    selectedArtistsAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0, 0, 0, 0),
      end: RelativeRect.fromLTRB(0, widget.height, 0, -widget.height * 2),
    ).animate(controller);
    allArtistsAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0, widget.height, 0, -widget.height * 2),
      end: RelativeRect.fromLTRB(0, 0, 0, 0),
    ).animate(controller);
    opacityAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(controller);
    opacityAnimationReversed = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(controller);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.value != 0) {
          controller.reverse();
          return false;
        } else
          return true;
      },
      child: Stack(
        children: [
          PositionedTransition(
            rect: selectedArtistsAnimation,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Column(
                children: [
                  Expanded(child: const ArtistsChart()),
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
          PositionedTransition(
            rect: allArtistsAnimation,
            child: FadeTransition(
              opacity: opacityAnimationReversed,
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
                if (newOffsetX <= 0 && newOffsetX >= -(widget.width - width)) {
                  approvedOffsetX = newOffsetX;
                }
                if (newOffsetY >= 0 && newOffsetY <= widget.height - height) {
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
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}
