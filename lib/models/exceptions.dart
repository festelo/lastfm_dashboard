class AccumulatedException implements Exception {
  final List<dynamic> children;
  AccumulatedException(this.children);
}


class CancelledException implements Exception {}