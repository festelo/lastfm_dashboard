import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toHumanable([String pattern = 'dd.MM.yyyy HH:mm']) {
    final formatter = DateFormat(pattern);
    return formatter.format(this);
  }

  int get secondsSinceEpoch => (millisecondsSinceEpoch / 1000).round();
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> replaceWhere(bool Function(T) condition, T newValue) sync* {
    for (final e in this) {
      if (condition(e)) {
        yield newValue;
      }
      yield e;
    }
  }

  Iterable<T> changeWhere(
    bool Function(T) condition,
    T Function(T) replacer,
  ) sync* {
    for (final e in this) {
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

  List<T> removeFirstWhere(bool Function(T) condition) {
    for (var i = 0; i < length; i++) {
      if (condition(this[i])) {
        removeAt(i);
        break;
      }
    }
    return this;
  }
}

extension MapExtensions<T> on Map<String, T> {

  Map<String, dynamic> flat() {
    final retMap = <String, dynamic>{};
    for (final d in entries) {
      if (d.value is Map<String, dynamic>) {
        final flatted = (d.value as Map<String, dynamic>).flat();
        retMap.addAll(flatted.map((a, b) => MapEntry(d.key + '_' + a, b)));
      } else {
        retMap[d.key] = d.value;
      }
    }
    return retMap;
  }
}

extension NullExtensions<T> on T {
  RetT nullOr<RetT>(RetT Function(T) fun) {
    return this == null ? null : fun(this);
  }
}

extension BoolExtensions<T> on bool {
  int get integer => this ? 1 : 0;
}

extension NumExtensions<T> on num {
  bool get boolean => this == 1 ? true : false;
}
