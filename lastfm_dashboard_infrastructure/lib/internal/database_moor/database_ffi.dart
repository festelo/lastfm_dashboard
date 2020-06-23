import 'dart:io';
import 'dart:isolate';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:shared/models.dart';

import 'database.dart';

class FFIDatabase extends MoorDatabase {
  FFIDatabase(String folder) : super(_openConnection(folder));

  static Future<MoorDatabase> isolated(String folder, [String tempDirectory]) async { 
    final isolate = await _createMoorIsolate(folder);
    final connection = await isolate.connect();
    final db = MoorDatabase.connect(connection);
    if (tempDirectory != null) {
      await db.setTmpDirForAndroid(tempDirectory);
    }
    return db;
  }
}

Future<MoorIsolate> _createMoorIsolate(String folder) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _startBackground,
    Tuple(folder, receivePort.sendPort),
  );
  return (await receivePort.first as MoorIsolate);
}


void _startBackground(Tuple<String, SendPort> arg) {
  final database = _openConnection(arg.a);
  final moorIsolate = MoorIsolate.inCurrent(() => DatabaseConnection.fromExecutor(database));
  arg.b.send(moorIsolate);
}


LazyDatabase _openConnection(String folder) {
  return LazyDatabase(() async {
    final file = File(p.join(folder, 'moor.sqlite'));
    return VmDatabase(file);
  });
}
