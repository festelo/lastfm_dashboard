import 'package:quiver_hashcode/hashcode.dart';

class Tuple<TA, TB> {
  final TA a;
  final TB b;
  Tuple(this.a, this.b);

  @override
  bool operator ==(Object other) =>
      other is Tuple<TA, TB> && a == other.a && b == other.b;

  @override
  int get hashCode => hash2(a, b);

  @override
  String toString() => 'Tuple($a, $b)';
}