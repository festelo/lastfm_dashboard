import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/loading_screen.dart';
import 'package:lastfm_dashboard/pages/home_page/home_page.dart';
import 'package:lastfm_dashboard/provider.dart';

void main() => runApp(DashboardApp());

class DashboardApp extends StatelessWidget {
  ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.red,
      appBarTheme: AppBarTheme(
        color: Colors.grey.shade300,
        elevation: 6,
        textTheme: TextTheme(
          headline: TextStyle(
            color: Colors.red,
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
      primarySwatch: Colors.red,
      primaryColor: Colors.grey.shade900,
      accentColor: Colors.redAccent,
      appBarTheme: AppBarTheme(
        color: Colors.grey.shade900,
        textTheme: TextTheme(
          headline: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      textTheme: TextTheme(body2: TextStyle(color: Colors.white60)),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey.shade800,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.grey.shade900,
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
      home: ProviderWrapper(
        child: HomePage(),
        loadingChild: LoadingScreen(),
      ),
    );
  }
}
