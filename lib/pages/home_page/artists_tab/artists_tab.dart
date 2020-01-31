import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:provider/provider.dart';
import './artists_chart.dart';
import './artists_list.dart';
import './viewmodel.dart';

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
    return Provider<ArtistsViewModel>(
      create: (_) => ArtistsViewModel(
        db: Provider.of<LocalDatabaseService>(context),
        authService: Provider.of<AuthService>(context),
      ),
      dispose: (_, a) => a.close(),
      child: Column(
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
      )
    );
  }
}