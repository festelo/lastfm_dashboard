import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/duration_switcher.dart';
import 'package:lastfm_dashboard/components/floating_area.dart';
import '../routes.dart';
import './artists_chart.dart';
import 'selected_artists_list.dart';

class ChartPage extends StatelessWidget {
  const ChartPage();

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
        FloatingArea(
          (_) => DurationSwitcher(),
          alignment: Alignment.topRight,
        ),
      ],
    );
  }
}