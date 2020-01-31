abstract class DatabaseMappedModel {
  const DatabaseMappedModel();
  String get id;

  /// Map which contains only properties that db
  /// should contain to succesfull deseriallization
  Map<String, dynamic> toDbMap();
}
