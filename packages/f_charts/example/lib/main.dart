import 'package:f_charts/f_charts.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var dataIndexes = [0, 0, 0];

  @override
  void initState() {
    super.initState();
  }

  List<ChartData<int, int>> get data => [
        ChartData([
          ChartSeries(color: Colors.red, name: 'First series', entities: [
            ChartEntity(0, 1),
            ChartEntity(1, 2),
            ChartEntity(3, 1),
            ChartEntity(4, 0),
          ]),
          ChartSeries(color: Colors.orange, name: 'Second series', entities: [
            ChartEntity(1, 1),
            ChartEntity(3, 5),
            ChartEntity(4, 10),
          ]),
        ]),
        ChartData([
          ChartSeries(color: Colors.red, name: 'First series', entities: [
            ChartEntity(0, 3),
            ChartEntity(1, 0),
            ChartEntity(4, 5),
          ]),
          ChartSeries(color: Colors.orange, name: 'Second series', entities: [
            ChartEntity(1, 1),
            ChartEntity(2, 3),
            ChartEntity(3, 1),
            ChartEntity(10, 2),
          ]),
        ]),
      ];

  Widget chartWithLabel(
    BuildContext context,
    String title,
    int dataIndexNumber,
    ChartGestureHandlerBuilder gestureHandler,
  ) {
    return Stack(
      children: [
        Chart(
          theme: ChartTheme(),
          mapper: ChartMapper(IntMapper(), IntMapper()),
          markersPointer:
              ChartMarkersPointer(IntMarkersPointer(1), IntMarkersPointer(2)),
          chartData: data[dataIndexes[dataIndexNumber]],
          gestureHandlerBuilder: gestureHandler,
          swiped: (a) {
            setState(() {
              dataIndexes[dataIndexNumber] = (dataIndexes[dataIndexNumber] + 1) % data.length;
            });
            return true;
          },
          pointPressed: (_) => setState(() => dataIndexes[dataIndexNumber] =
              (dataIndexes[dataIndexNumber] + 1) % data.length),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headline6,
              )),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(
          flex: 1,
          child: chartWithLabel(context, 'pointer mode', 0, const PointerHandlerBuilder()),
        ),
        Expanded(
          flex: 1,
          child: chartWithLabel(context, 'gesture mode', 1, const GestureHandlerBuilder()),
        ),
        Expanded(
          flex: 1,
          child: chartWithLabel(context, 'hybrid mode', 2, const HybridHandlerBuilder()),
        ),
      ]),
    );
  }
}
