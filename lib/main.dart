import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:epic/container.dart';
import 'package:lastfm_dashboard/models/identifiers.dart';
import 'package:lastfm_dashboard/pages/home/home_page.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:lastfm_dashboard/services/local_database/mobile/database_service.dart';
import 'package:lastfm_dashboard/services/local_database/web/database_service.dart';
import 'package:lastfm_dashboard/watchers/user_watchers.dart';
import 'package:provider/provider.dart';
import 'package:epic/epic.dart';
import 'package:epic/watcher.dart';
import 'constants.dart';
import 'models/models.dart';

Future<void> main() async {
  print('ok, let\'s start');
  WidgetsFlutterBinding.ensureInitialized();

  final manager = EpicManager();
  final container = EpicContainer();
  manager.registerContainer(container);
  addDependencies(container);

  manager.events.listen((event) {
    print(event);
  });

  print('starting watchers');
  container.startWatchers();

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

void addDependencies(EpicContainer container) {
  container.addSingleton(() => defaultRefreshConfig);

  container.addScoped<LastFMApi>(
    () => LastFMApi(),
    dispose: (t) => t.dispose(),
  );

  if (kIsWeb) {
    container.addSingleton<LocalDatabaseService>(
      () => WebDatabaseBuilder().build(),
    );
  } else {
    container.addSingleton<LocalDatabaseService>(
      () => MobileDatabaseBuilder().build(),
    );
  }

  container.addSingleton<AuthService>(
    () => AuthService.load(),
  );

  container.addTransientComplex<User>((p) async {
    final db = await p.get<LocalDatabaseService>();
    final auth = await p.get<AuthService>();
    return auth.currentUser.value == null
        ? null
        : db.users[auth.currentUser.value].get();
  }, key: currentUserKey);

  container.addWatcher<RefreshWatcher>((p) async {
    final db = await p.get<LocalDatabaseService>();
    final config = await p.get<RefreshConfig>();
    final manager = await p.get<EpicManager>();
    return RefreshWatcher(manager, db, config);
  });
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
