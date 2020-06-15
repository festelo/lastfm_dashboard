class AccumulatedException implements Exception {
  final List<dynamic> children;
  AccumulatedException(this.children);

  @override
  String toString() => 'Accumulated error:\n' + children.join('\n');
}

class CancelledException implements Exception {}
