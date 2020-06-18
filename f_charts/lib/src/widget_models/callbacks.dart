import 'package:f_charts/data_models.dart';
import 'package:flutter/painting.dart';

typedef PointPressedCallback<T1, T2> = void Function(ChartEntity<T1, T2> entity);
typedef BeforeSwipeCallback<T1, T2> = bool Function(AxisDirection direction);
typedef AfterSwipeCallback<T1, T2> = void Function(ChartData<T1, T2>, AxisDirection);