import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/components/loading_screen.dart';
import 'package:lastfm_dashboard/provider.dart';

import 'pages/home_page/home_page.dart';

void main() => runApp(DashboardApp());

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
            fontSize: 18
          ),
        )
      ),
      cardColor: Colors.grey[350],
      cardTheme: CardTheme(
        elevation: 3
      ),
      canvasColor: Colors.grey[350],
      scaffoldBackgroundColor: Colors.grey[200],
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
            fontSize: 18
          ),
        )
      ),
      textTheme: TextTheme(
        bodyText2: TextStyle(
          color: Colors.white60
        )
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[850],
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.grey[900],
      ),
      dividerColor: Colors.grey[800],
      canvasColor: Colors.grey[900]
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      darkTheme: darkTheme(),
      home: ProviderWrapper(
        child: HomePage(),
        loadingChild: LoadingScreen()
      )
    );
  }
}