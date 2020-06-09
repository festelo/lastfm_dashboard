import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/duration_switcher.dart';
import '../routes.dart';
import './artists_chart.dart';
import 'selected_artists_list.dart';

class ChartPage extends StatefulWidget {
  const ChartPage();

  @override
  _ArtistsTabContentState createState() => _ArtistsTabContentState();
}

class _ArtistsTabContentState extends State<ChartPage> {
  var durationSwitcherOffsetX = 0.0;
  var durationSwitcherOffsetY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: ArtistsChart()),
            Expanded(
              child: SelectedArtistsList(
                addArtistPressed: () {
                  Navigator.push(context, Routes.artistsList());
                },
              ),
            ),
            SizedBox(height: 20)
          ],
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
                  newOffsetX >= -(context.size.width - width)) {
                approvedOffsetX = newOffsetX;
              }
              if (newOffsetY >= 0 &&
                  newOffsetY <= context.size.height - height) {
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
