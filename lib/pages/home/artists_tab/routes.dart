import 'package:flutter/material.dart';
import 'artists_list_page.dart';
import 'chart_page.dart';

class Routes {
  static MaterialPageRoute artistsList() =>
      MaterialPageRoute(builder: (_) => AritstsListPage());
  
  static MaterialPageRoute chart() =>
      MaterialPageRoute(builder: (_) => ChartPage());
}
