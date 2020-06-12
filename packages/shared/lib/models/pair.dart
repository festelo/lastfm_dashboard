import 'tuple.dart';

class Pair<T> extends Tuple<T, T> {
  Pair(T a, T b) : super(a, b);

  @override
  String toString() => 'Pair($a, $b)';
}