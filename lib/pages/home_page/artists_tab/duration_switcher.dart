import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/events/artitsts_events.dart';
import 'package:provider/provider.dart';

class DurationSwitcher extends StatelessWidget {
  final double width;
  final double height;
  final double margin;
  DurationSwitcher({
    this.width = 160,
    this.height = 40,
    this.margin = 20
  });
  
  final durations = [
    Duration(hours: 1),
    Duration(days: 1),
    Duration(days: 7),
    Duration(days: 30),
  ];
  final durationNames = [
    'Hour',
    'Day',
    'Week',
    'Month',
  ];

  @override
  Widget build(BuildContext context) {
    final duration = context.select(
      (ArtistsViewModel v) => v.scrobblesDuration,
    );
    final i = durations.indexOf(duration);
    final text = durationNames[i];
    return Card(
      color: Theme.of(context).canvasColor,
      margin: EdgeInsets.all(margin),
      child: Container(
        height: 40,
        width: 160,
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText2,
              ),
              width: 50,
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.add, size: 18),
                onPressed: () {
                  context.read<EventsContext>().push(
                        SetArtistScrobblesDurationEventInfo(
                          duration: durations[(i + 1) % durations.length],
                        ),
                        setArtistScrobblesDuration,
                      );
                },
              ),
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.remove, size: 18),
                onPressed: () {
                  var newI = i - 1;
                  if (newI == -1) newI = durations.length - 1;
                  context.read<EventsContext>().push(
                        SetArtistScrobblesDurationEventInfo(
                          duration: durations[newI],
                        ),
                        setArtistScrobblesDuration,
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
