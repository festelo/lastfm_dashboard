import 'package:lastfm_dashboard_infrastructure/internal/database_moor/database.dart';
import 'package:lastfm_dashboard_infrastructure/internal/database_moor/database_web.dart';

Future<MoorDatabase> buildDatabase() async {
  return WebDatabase.isolated('web-db', 'sql-worker.js');
}