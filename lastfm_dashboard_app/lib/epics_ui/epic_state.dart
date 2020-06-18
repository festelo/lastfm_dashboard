import 'dart:async';

import 'package:epic/container.dart';
import 'package:epic/epic.dart';
import 'package:flutter/cupertino.dart';
import 'package:lastfm_dashboard/view_models/epic_view_model.dart';
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
  final Scope scope = Scope('stated');

  final List<EpicMapper> _mappers = [];
  final Map<Type, dynamic> _vmMap = {};

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

  void _subscribeVM<T>() {
    _vmMap[T] = Provider.of<T>(context, listen: false);
    handle<ViewModelReplaced<T>>(
      (e) => _vmMap[T] = e,
      where: (e) => e.oldViewModel == _vmMap[T],
    );
  }

  void subscribeVM<T>({
    Checker<ViewModelChanged<T>> where,
  }) {
    _subscribeVM<T>();
    subscribe<ViewModelChanged<T>>(
      where: (c) => c.viewModel == _vmMap[T] && (where == null || where(c)),
    );
  }

  void subscribe<T>({
    Checker<T> where,
  }) {
    _mappers.add(EpicMapper<T, T>(
      handler: (_) => apply(),
      map: (e) => e,
      where: where ?? (e) => true,
      typeFits: (e) => e is T,
    ));
  }

  void handleVM<T>(
    Handler<ViewModelChanged<T>> handler, {
    Checker<ViewModelChanged<T>> where,
  }) {
    _subscribeVM<T>();
    handle<ViewModelChanged<T>>(
      handler,
      where: (c) => c.viewModel == _vmMap[T] && (where == null || where(c)),
    );
  }

  void handle<T>(
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

  void mapVM<T1, T2>(
    Handler<T2> handler,
    Mapper<ViewModelChanged<T>, T2> mapper, {
    Checker<ViewModelChanged<T>> where,
  }) {
    _subscribeVM<T>();
    map<ViewModelChanged<T>, T2>(
      handler,
      mapper,
      where: (c) => c.viewModel == _vmMap[T] && (where == null || where(c)),
    );
  }

  void map<T1, T2>(
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
  }

  Future<void> onEvent(dynamic event) async {
    bool handled = false;
    for (final mapper in _mappers) {
      try {
        if (await mapper.process(event)) handled = true;
      } catch (e) {
        if (scope.closed) return;
        rethrow;
      }
    }
    if (handled) apply();
  }

  FutureOr<void> onLoad() {}
}
