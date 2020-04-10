import 'package:collection/collection.dart';
import 'package:lastfm_dashboard/extensions.dart';

abstract class DatabaseMappedModel {
  const DatabaseMappedModel();
  String get id;

  /// Map which contains only properties that db
  /// should contain to succesfull deseriallization
  Map<String, dynamic> toDbMap();

  Map<String, dynamic> toDbMapFlat() {
    final dbMap = toDbMap();
    return dbMap.flat();
  }

  Map<String, dynamic> diff(DatabaseMappedModel other) {
    final oldMap = other.toDbMap();
    final newMap = toDbMap();
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