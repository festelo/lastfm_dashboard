import 'dart:async';

import 'package:epic/container.dart';
import 'package:epic/epic.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

typedef Handler<T> = FutureOr<void> Function(T);
typedef Mapper<T1, T2> = T2 Function(T1);
typedef Checker<T> = bool Function(T event);

class EpicMapper<T1, T2> {
  final Checker<dynamic> typeFits;
  final Mapper<T1, T2> map;
  final Checker<T1> where;
  final Handler<T2> handler;

  EpicMapper({
    this.typeFits,
    this.map,
    this.where,
    this.handler,
  });

  Future<bool> process(dynamic e) async {
    if (e is T1 == false) return false;
    final event = e as T1;
    if (!where(event)) return false;
    final mapped = map(e);
    await handler(mapped);
    return true;
  }
}

abstract class EpicState<T extends StatefulWidget> extends State<T> {
  EpicProvider provider;
  EpicManager epicManager;
  StreamSubscription epicSubscription;
  final Scope scope = Scope();

  final List<EpicMapper> _mappers = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    initEpic();
    final v = onLoad();
    if (v is Future<void>) {
      v.then((_) => afterLoad());
    } else {
      afterLoad();
      loading = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    scope.close();
    epicSubscription.cancel();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void apply() {
    setState(() {});
  }

  void initEpic() {
    epicManager = context.read<EpicManager>();
    provider = epicManager.container.getProvider(scope);
    epicSubscription = epicManager.events.listen(onEvent);
  }

  void afterLoad() {
    setState(() => loading = false);
  }

  void subscribe<T>(
    Handler<T> handler, {
    Checker<T> where,
  }) {
    _mappers.add(EpicMapper<T, T>(
      handler: handler,
      map: (e) => e,
      where: where ?? (e) => true,
      typeFits: (e) => e is T,
    ));
  }

  T1 map<T1, T2>(
    Handler<T2> handler,
    Mapper<T1, T2> mapper, {
    Checker<T1> where,
  }) {
    _mappers.add(EpicMapper<T1, T2>(
      handler: handler,
      map: mapper,
      where: where ?? (e) => true,
      typeFits: (e) => e is T1,
    ));
    return null;
  }

  Future<void> onEvent(dynamic event) async {
    bool handled = false;
    for (final mapper in _mappers) {
      if (await mapper.process(event)) handled = true;
    }
    if (handled) apply();
  }

  FutureOr<void> onLoad();
}
