import 'pair.dart';

class DateBounds extends Pair<DateTime> {
  DateTime get start => a;
  DateTime get end => b;
  bool contains(DateTime t) {
    return start.isBefore(t) && end.isAfter(t);
  } 
  DateBounds(DateTime start, DateTime end) : super(start, end);
}
