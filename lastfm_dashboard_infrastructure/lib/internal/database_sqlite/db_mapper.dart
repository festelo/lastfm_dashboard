import 'package:collection/collection.dart';

Map<String, T> unpackDbMap<T>(Map<String, dynamic> map, String name) {
  return map[name] ?? selectPrefixed(map, name + '_');
}

Map<String, T> selectPrefixed<T>(Map<String, dynamic> map, Pattern prefix) {
  return Map<String, T>.fromEntries(map.entries
      .where((c) => c.key.startsWith(prefix))
      .map((c) => MapEntry(c.key.replaceFirst(prefix, ''), c.value)));
}

abstract class LiteMapper<T> {
  const LiteMapper();
  Map<String, dynamic> toMap(T obj);
  T fromMap(Map<String, dynamic> obj);
  
  Map<String, dynamic> diff(T a, T b) {
    final oldMap = toMap(a);
    final newMap = toMap(b);
    final map = <String, dynamic>{};

    final eq = const DeepCollectionEquality().equals;
    for (final key in newMap.keys) {
      if (!eq(oldMap[key], newMap[key])) {
        map[key] = newMap[key];
      }
    }
    return map;
  }
}

abstract class SqliteMapper<T> extends LiteMapper<T> {
  T defaultValue() => fromMap({});

  String get idColumn => 'id';

  String key(T object);
  const SqliteMapper();
}