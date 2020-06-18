import 'package:lastfm_dashboard_domain/domain.dart';
import '../db_mapper.dart';

@deprecated
class UnimplementedMapper extends SqliteMapper<dynamic> {
  @override
  User fromMap(Map<String, dynamic> dbMap) {
    throw UnimplementedError();
  }

  @override
  String get idColumn => throw UnimplementedError();

  @override
  String key(dynamic object) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap(dynamic obj) {
    throw UnimplementedError();
  }
  const UnimplementedMapper();
}