extension DateTimeExtensions on DateTime {
  String toHumanable() {
    String _pad(int s) => s.toString().padLeft(2, '0');
    final sday = _pad(day);
    final smonth = _pad(month);
    final sminute = _pad(minute);
    return '$sday.$smonth.$year $hour:$sminute';
  }
}