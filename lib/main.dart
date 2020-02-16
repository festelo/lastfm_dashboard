import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home_page/home_page.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/services/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard/services/local_database/database_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  
  final authServicePreferences = AuthServicePreferences(sharedPreferences);
  final authService = await AuthService.load(authServicePreferences);
  final dbService = await DatabaseBuilder().build();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => authService,
        ),
        Provider<LocalDatabaseService>(
          create: (_) => dbService,
        ),
        Provider<LastFMApi>(
          create: (_) => LastFMApi(),
        ),
      ],
      child: DashboardApp(),
    ),
  );
}

class DashboardApp extends StatelessWidget {
  final Color brandColor = Color.fromARGB(0xff, 0xc2, 0x0, 0x0);

  ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.red,
      primaryColor: Colors.grey.shade900,
      accentColor: brandColor,
      appBarTheme: AppBarTheme(
        color: Colors.grey.shade300,
        elevation: 6,
        textTheme: TextTheme(
          headline: TextStyle(
            color: brandColor,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      cardColor: Colors.grey.shade300,
      cardTheme: CardTheme(elevation: 3),
      canvasColor: Colors.grey.shade300,
      scaffoldBackgroundColor: Colors.grey.shade200,
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColorBrightness: Brightness.dark,
      primarySwatch: Colors.red,
      primaryColorLight: brandColor,
      accentColorBrightness: Brightness.dark,
      backgroundColor: Colors.grey.shade900,
      primaryColor: Colors.grey.shade900,
      accentColor: brandColor,
      appBarTheme: AppBarTheme(
        color: Colors.grey.shade900,
        textTheme: TextTheme(
          headline: TextStyle(
            fontFamily: 'Lato',
            color: brandColor,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey.shade800,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(8),
          ),
        ),
      ),
      dividerColor: Colors.grey.shade800,
      canvasColor: Colors.grey.shade900,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last.fm Dashboard',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      home: HomePage(),
    );
  }
}
