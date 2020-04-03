extension DateTimeExtensions on DateTime {
  String toHumanable() {
    String _pad(int s) => s.toString().padLeft(2, '0');
    final sday = _pad(day);
    final smonth = _pad(month);
    final sminute = _pad(minute);
    return '$sday.$smonth.$year $hour:$sminute';
  }
}
extension ListExtensions<T> on List<T> {
  List<T> replaceByIndex(int index, T newValue) {
    this[index] = newValue;
    return this;
  }
  
  List<T> replaceWhere(
    bool Function(T) condition, 
    T newValue, 
    {bool first = false}
  ) {
    for(var i = 0; i < length; i++) {
      if (condition(this[i])) {
        this[i] = newValue;
        if (first) break;
      }
    }
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