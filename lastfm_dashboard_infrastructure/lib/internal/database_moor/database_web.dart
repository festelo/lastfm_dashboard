import 'package:moor/moor.dart';
import 'package:moor/moor_web.dart' as w;
import 'database.dart';

class WebDatabase extends MoorDatabase {
  WebDatabase(String name) : super(_openConnectionWeb(name));
  WebDatabase.isolated(String name,
      [String workerPath, String sqlJsPath = 'sql-wasm.js'])
      : super(_openConnectionWebWorker(name, workerPath, sqlJsPath));
}

LazyDatabase _openConnectionWebWorker(
    String name, String workerPath, String sqlJsPath) {
  final storage = w.MoorWebStorageFactory.indexedDb(
    name,
    inWebWorker: true,
    migrateFromLocalStorage: false,
  );
  return LazyDatabase(() async {
    return w.WebDatabase.withDelegate(
        w.MoorWorkerClient(workerPath, sqlJsPath, storage));
  });
}

LazyDatabase _openConnectionWeb(String name) {
  return LazyDatabase(() async {
    return w.WebDatabase.withStorage(
        w.MoorWebStorage.indexedDbIfSupported(name, inWebWorker: true));
  });
}
