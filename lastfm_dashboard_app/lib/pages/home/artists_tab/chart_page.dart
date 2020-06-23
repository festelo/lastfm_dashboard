import 'package:epic/epic.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/features/artists_chart/artists_chart.dart';
import 'package:lastfm_dashboard/features/artists_chart/artists_chart_bloc.dart';
import 'package:lastfm_dashboard/features/artists_list/selected_artists_list.dart';
import 'package:lastfm_dashboard/features/base_chart/duration_switcher/duration_switcher.dart';
import 'package:lastfm_dashboard/widgets/floating_area.dart';
import 'package:provider/provider.dart';
import 'routes.dart';

class ChartPage extends StatelessWidget {
  const ChartPage();

  @override
  Widget build(BuildContext context) {
    return Provider<ArtistsChartBloc>(
      create: (_) {
        final epic = Provider.of<EpicManager>(context, listen: false);
        return ArtistsChartBloc(epic);
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
            (_) => DurationSwitcher<ArtistsChartBloc>(),
            alignment: Alignment.topLeft,
          ),
        ],
      ),
    );
  }
}
