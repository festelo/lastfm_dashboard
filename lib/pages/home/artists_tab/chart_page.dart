import 'package:epic/epic.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/features/artists_chart/artists_chart.dart';
import 'package:lastfm_dashboard/features/artists_list/selected_artists_list.dart';
import 'package:lastfm_dashboard/view_models/chart_view_model.dart';
import 'package:lastfm_dashboard/widgets/duration_switcher.dart';
import 'package:lastfm_dashboard/widgets/floating_area.dart';
import 'package:provider/provider.dart';
import 'routes.dart';

class ChartPage extends StatelessWidget {
  const ChartPage();

  @override
  Widget build(BuildContext context) {
    return Provider<ChartViewModel>(
      create: (_) {
        final epic = Provider.of<EpicManager>(context, listen: false);
        return ChartViewModel(epic);
      },
      child: Stack(
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
            alignment: Alignment.topLeft,
          ),
        ],
      ),
    );
  }
}
