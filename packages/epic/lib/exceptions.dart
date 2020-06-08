class CancelledException implements Exception { 
  CancelledException(): super();

  @override
  String toString() {
    return 'CancelledException: the epic was cancelled';
  }
}