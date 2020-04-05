
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';

import 'database_service.dart';

FutureOr<String> getFullPath(String path) async {
  final directory = await getApplicationDocumentsDirectory();
  return join(directory.path, path);
}

DatabaseFactory getDatabaseFactory() {
  return databaseFactoryIo;
}