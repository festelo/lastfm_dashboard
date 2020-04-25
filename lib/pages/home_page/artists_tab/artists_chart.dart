import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/components/base_chart.dart';
import 'package:provider/provider.dart';

class ArtistsChart extends StatelessWidget {
  const ArtistsChart();
  /*[
          ChartSeries(
            entities: [],
            color: ChartColor.blue,
            name: 'Sample'
          )
        ]*/
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Consumer<ArtistsViewModel>(
        builder: (ctx, vm, _) {
          if (vm.scrobblesPerArtist == null || vm.scrobblesPerArtist.isEmpty)
            return Container();
          final selectionsByArtistId = vm.artistSelections
              .asMap()
              .map((key, value) => MapEntry(value.artistId, value));

          final artistSelection = (String id) => selectionsByArtistId[id];
          return BaseChart(
            vm.scrobblesPerArtist.entries
                .map(
                  (e) => ChartSeries(
                    color: ChartColor(
                      artistSelection(e.key)?.selectionColor ??
                          Colors.transparent,
                    ),
                    name: e.key,
                    entities: e.value
                        .map((e) => ChartEntity(
                            date: e.groupedDate, scrobbles: e.count))
                        .toList(),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
