import 'package:uuid/uuid.dart';

class Entity {
  final String id;
  Entity(String id): id = Uuid().v4();
}