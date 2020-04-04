extension DateTimeExtensions on DateTime {
  String toHumanable() {
    String _pad(int s) => s.toString().padLeft(2, '0');
    final sday = _pad(day);
    final smonth = _pad(month);
    final sminute = _pad(minute);
    return '$sday.$smonth.$year $hour:$sminute';
  }

  int get secondsSinceEpoch => (millisecondsSinceEpoch / 1000).round();
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> replaceWhere(
    bool Function(T) condition, 
    T newValue
  ) sync* {
    for(final e in this) {
      if (condition(e)) {
        yield newValue;
      }
      yield e;
    }
  }

  Iterable<T> changeWhere(
    bool Function(T) condition, 
    T Function(T) replacer
  ) sync* {
    for(final e in this) {
      if (condition(e)) {
        yield replacer(e);
      } else {
        yield e;
      }
    }
  }
}

extension ListExtensions<T> on List<T> {
  List<T> replaceByIndex(int index, T newValue) {
    this[index] = newValue;
    return this;
  }

  List<T> removeFirstWhere(
    bool Function(T) condition
  ) {
    for(var i = 0; i < length; i++) {
      if (condition(this[i])) {
        removeAt(i);
        break;
      }
    }
    return this;
  }
}