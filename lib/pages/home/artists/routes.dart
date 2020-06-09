import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home/artists/chart/chart_page.dart';
import 'artists_list/artists_list_page.dart';

class Routes {
  static MaterialPageRoute artistsList() =>
      MaterialPageRoute(builder: (_) => AritstsListPage());
  
  static MaterialPageRoute chart() =>
      MaterialPageRoute(builder: (_) => ChartPage());
}
