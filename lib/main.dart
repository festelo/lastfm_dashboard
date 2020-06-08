import 'package:flutter/material.dart';
import 'package:epic/container.dart';
import 'package:lastfm_dashboard/models/identifiers.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/services/local_database/mobile/database_service.dart';
import 'package:provider/provider.dart';
import 'package:epic/epic.dart';
import 'models/models.dart';
import 'pages/home_page/home_page.dart';

Future<void> main() async {
  print('ok, let\'s start');
  WidgetsFlutterBinding.ensureInitialized();
  final container = EpicContainer();

  container.addScoped<LastFMApi>(
    () => LastFMApi(),
    dispose: (t) => t.dispose(),
  );

  container.addScoped<LocalDatabaseService>(
    () => MobileDatabaseBuilder().build(),
    dispose: (t) => t.dispose(),
  );

  container.addScoped<AuthService>(
    () => AuthService.load(),
    dispose: (t) => t.close(),
  );

  container.addTransientComplex<User>((p) async {
    final db = await p.get<LocalDatabaseService>();
    final auth = await p.get<AuthService>();
    return auth.currentUser.value == null
        ? null
        : db.users[auth.currentUser.value].get();
  }, key: CurrentUser);

  final manager = EpicManager(container);
  manager.events.listen((event) { print(event); });

  final widget = MultiProvider(
    providers: [
      Provider<EpicManager>.value(
        value: manager,
      ),
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
          headline6: TextStyle(
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
          headline6: TextStyle(
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
