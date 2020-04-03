
class Counter {
  final int count;
  Counter(this.count);

  Counter copyWith({int count}) => Counter(count);
}