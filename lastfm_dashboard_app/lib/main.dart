import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home/home_page.dart';
import 'package:provider/provider.dart';
import 'package:epic/epic.dart';
import 'package:epic/watcher.dart';
import 'di.dart';

Future<void> main() async {
  print('ok, let\'s start');
  WidgetsFlutterBinding.ensureInitialized();

  final manager = EpicManager();
  final container = configureDependencies(manager);

  manager.events.listen((event) {
    print(event);
  });

  print('starting watchers');
  await container.startWatchers();

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
