import 'package:quiver/core.dart';

class Pair<T> {
  final T a;
  final T b;
  Pair(this.a, this.b);

  @override
  bool operator ==(Object other) =>
      other is Pair<T> && a == other.a && b == other.b;

  @override
  int get hashCode => hash2(a, b);

  @override
  String toString() => 'Pair($a, $b)';
}