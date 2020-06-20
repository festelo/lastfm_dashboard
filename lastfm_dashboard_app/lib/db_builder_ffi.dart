import 'dart:io';

import 'package:lastfm_dashboard_infrastructure/internal/database_moor/database.dart';
import 'package:lastfm_dashboard_infrastructure/internal/database_moor/database_ffi.dart';
import 'package:path_provider/path_provider.dart';

Future<MoorDatabase> buildDatabase() async {
  String tempFolder;
  if (Platform.isAndroid) {
    tempFolder = await getTemporaryDirectory().then((v) => v.path);
  }
  final folder = await getApplicationDocumentsDirectory();
  return FFIDatabase.isolated(folder.path, tempFolder);
}