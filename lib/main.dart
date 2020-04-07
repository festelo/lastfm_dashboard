import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/blocs/artists_bloc.dart';
import 'package:lastfm_dashboard/blocs/users_bloc.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api_mock.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:provider/provider.dart';

import 'bloc.dart';
import 'blocs/users_bloc.dart';
import 'pages/home_page/home_page.dart';
import 'providers.dart';

Future<void> main() async {
  print('ok, let\'s start');
  WidgetsFlutterBinding.ensureInitialized();
  final authService = await AuthService.load();
  print('auth service loaded');
  final dbService = await DatabaseBuilder().build();
  print('db configured');
  final lastFmApi = LastFMApiMock();

  final blocCombiner = BlocCombiner([UsersBloc(), ArtistsBloc()]);

  final eventsContext = EventsContext(
    blocs: blocCombiner.flatBlocs(),
    streams: blocCombiner.flatStreams(),
    models: blocCombiner.flatModels(),
    singletones: [
      authService,
      dbService,
      lastFmApi,
    ],
  );
  print('eventsContext initialized');

  await initializeBlocs(eventsContext, blocCombiner.flatBlocs());
  print('blocs initialized');

  final widget = MultiProvider(
    providers: [
      Provider<AuthService>.value(
        value: authService,
      ),
      Provider<LocalDatabaseService>.value(
        value: dbService,
      ),
      Provider<LastFMApi>.value(
        value: lastFmApi,
      ),
      ...getProviders(blocCombiner, eventsContext)
    ],
    child: DashboardApp(),
  );
  print('ready to launch');
  runApp(widget);
}

class DashboardApp extends StatelessWidget {
  // This widget is the root of your application.

  ThemeData theme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.red,
      appBarTheme: AppBarTheme(
        color: Colors.grey[350],
        elevation: 6,
        textTheme: TextTheme(
          headline5: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      cardColor: Colors.grey[350],
      cardTheme: CardTheme(elevation: 3),
      canvasColor: Colors.grey[350],
      scaffoldBackgroundColor: Colors.grey[200],
      fontFamily: 'Google Sans',
    );
  }

  ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.red,
      primaryColor: Colors.grey[900],
      accentColor: Colors.redAccent,
      appBarTheme: AppBarTheme(
        color: Colors.grey[900],
        textTheme: TextTheme(
          headline5: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyText2: TextStyle(
          color: Colors.white60,
        ),
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[850],
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.grey[900],
      ),
      dividerColor: Colors.grey[800],
      canvasColor: Colors.grey[900],
      fontFamily: 'Google Sans',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last.fm Dashboard',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      darkTheme: darkTheme(),
      home: HomePage(),
    );
  }
}
