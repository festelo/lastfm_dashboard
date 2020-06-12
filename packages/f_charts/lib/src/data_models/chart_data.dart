import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:f_charts/data_models.dart';

class ChartData<TAbscissa, TOrdinate> {
  final List<ChartSeries<TAbscissa, TOrdinate>> series;
  const ChartData(this.series);

  @override
  bool operator ==(Object other) =>
      other is ChartData<TAbscissa, TOrdinate> &&
      const DeepCollectionEquality().equals(other.series, series);
}

class ChartSeries<TAbscissa, TOrdinate> {
  final List<ChartEntity<TAbscissa, TOrdinate>> entities;
  final Color color;
  final String name;

  const ChartSeries({this.entities, this.color, this.name});

  @override
  bool operator ==(Object other) =>
      other is ChartSeries<TAbscissa, TOrdinate> &&
      other.color == color &&
      other.name == name &&
      const DeepCollectionEquality().equals(other.entities, entities);
}

class ChartBounds<TAbscissa, TOrdinate> {
  final TAbscissa minAbscissa;
  final TAbscissa maxAbscissa;
  final TOrdinate minOrdinate;
  final TOrdinate maxOrdinate;

  ChartBounds(
    this.minAbscissa,
    this.maxAbscissa,
    this.minOrdinate,
    this.maxOrdinate,
  ) : assert(minOrdinate != maxOrdinate && minAbscissa != maxAbscissa,
            'min and max bounds can\'t be equal');

  ChartBounds.only({
    this.minAbscissa,
    this.maxAbscissa,
    this.minOrdinate,
    this.maxOrdinate,
  });
}

class ChartBoundsDoubled extends ChartBounds<double, double> {
  ChartBoundsDoubled(
    double minAbscissa,
    double maxAbscissa,
    double minOrdinate,
    double maxOrdinate,
  ) : super(minAbscissa, maxAbscissa, minOrdinate, maxOrdinate);

  static ChartBoundsDoubled fromBounds<T1, T2>(
    ChartBounds<T1, T2> bounds,
    ChartMapper<T1, T2> mapper,
  ) {
    final minAbscissa = mapper.abscissaMapper.toDouble(bounds.minAbscissa);
    final maxAbscissa = mapper.abscissaMapper.toDouble(bounds.maxAbscissa);
    final minOrdinate = mapper.ordinateMapper.toDouble(bounds.minOrdinate);
    final maxOrdinate = mapper.ordinateMapper.toDouble(bounds.maxOrdinate);
    return ChartBoundsDoubled(
        minAbscissa, maxAbscissa, minOrdinate, maxOrdinate);
  }

  static ChartBoundsDoubled fromData<T1, T2>(
    ChartData<T1, T2> data,
    ChartMapper<T1, T2> mapper,
  ) {
    return fromBounds(mapper.getBounds(data), mapper);
  }

  static ChartBoundsDoubled fromDataOr<T1, T2>(
    ChartData<T1, T2> data,
    ChartMapper<T1, T2> mapper,
    ChartBounds<T1, T2> or,
  ) {
    return fromBounds(mapper.getBounds(data, or: or), mapper);
  }
}

class ChartEntity<TAbscissa, TOrdinate> {
  final TOrdinate ordinate;
  final TAbscissa abscissa;
  ChartEntity(this.abscissa, this.ordinate);

  @override
  bool operator ==(Object other) =>
      other is ChartEntity<TAbscissa, TOrdinate> &&
      other.ordinate == ordinate &&
      other.abscissa == abscissa;
}
