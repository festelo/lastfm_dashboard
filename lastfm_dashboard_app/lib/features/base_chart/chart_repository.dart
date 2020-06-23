import 'package:f_charts/data_models.dart';
import 'package:shared/models.dart';

abstract class ChartRepository {
  Future<DateBounds> getAllTimeBounds();

  Future<ChartData<DateTime, int>> getChartData(
    DatePeriod interval, [
    DateTime periodStart,
    DateTime periodEnd,
  ]);
}