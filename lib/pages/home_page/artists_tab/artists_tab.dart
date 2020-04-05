import 'package:flutter/material.dart';
import './artists_chart.dart';
import './artists_list.dart';

/// Providers required:
/// - AuthService
/// - LocalDatabaseService
class ArtistsTab extends StatefulWidget {
  @override
  _ArtistsTabState createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ArtistsChart()
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: ArtistsList()
          )
        )
      ],
    );
  }
}