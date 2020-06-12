import 'dart:math';

import 'package:f_charts/utils.dart';
import 'package:shared/models.dart';

Point intersection(Pair<Point> l1, Pair<Point> l2) {
  var a1 = l1.b.y - l1.a.y;
  var b1 = l1.a.x - l1.b.x;
  var c1 = a1 * l1.a.x + b1 * l1.a.y;

  var a2 = l2.b.y - l2.a.y;
  var b2 = l2.a.x - l2.b.x;
  var c2 = a2 * l2.a.x + b2 * l2.a.y;

  double delta = (a1 * b2 - a2 * b1).toDouble();

  if (delta == 0) return null;

  double x = (b2 * c1 - b1 * c2) / delta;
  double y = (a1 * c2 - a2 * c1) / delta;
  return Point(x, y);
}

Point partOf(Pair<Point> line, double c1) {
  var a = line.x2 - line.x1;
  var b = line.y2 - line.y1;
  var c = sqrt(b * b + a * a);
  if (c == 0) return line.a;

  var sin = b / c;
  var b1 = min(c1, c) * sin;

  var cos = a / c;
  var a1 = min(c1, c) * cos;
  return Point(line.x2 - a1, line.y2 - b1);
}
