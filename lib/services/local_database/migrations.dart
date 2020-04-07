import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'database_service.dart';

final _migrations = <int, Future<void> Function(Database, DatabaseBuilder)>{
  1: (db, dbb) async {
    await dbb.usersStore().delete(db);
    await dbb.artistsStore().delete(db);
  },
};

Future<void> migrate({
  @required Database database,
  @required DatabaseBuilder databaseBuilder,
  @required int current,
  @required int expected,
}) async {
  for (var i = current; i < expected; i++) {
    if (_migrations[i] != null) await _migrations[i](database, databaseBuilder);
  }
}
