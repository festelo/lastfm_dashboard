import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:provider/provider.dart';

class ProviderWrapper extends StatefulWidget {
  final Widget child;
  final Widget loadingChild;

  ProviderWrapper({
    @required this.child,
    @required this.loadingChild
  });

  @override
  _ProviderWrapperState createState() => _ProviderWrapperState();
}

class _ProviderWrapperState extends State<ProviderWrapper> {
  List<Future> _futures;

  @override
  void initState() {
    super.initState();
    _futures = [
      AuthService.load(),
      DatabaseBuilder().build()
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait(_futures),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              Provider<AuthService>(
                create: (_) => snap.data[0],
              ),
              Provider<LocalDatabaseService>(
                create: (_) => snap.data[1],
              ),
            ],
            child: widget.child,
          );
        }
        return widget.loadingChild;
      }
    );
  }
}