
import 'dart:async';

import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

FutureOr<String> getFullPath(String path) {
  return './' + path;
}

DatabaseFactory getDatabaseFactory() {
  return databaseFactoryWeb;
}