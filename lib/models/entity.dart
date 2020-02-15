abstract class Entity {
  const Entity();
  
  String get id;

  /// Map which contains only properties that db
  /// should contain to succesfull deseriallization
  Map<String, dynamic> toDbMap();
}
