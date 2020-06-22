import 'dart:async';

import 'package:epic/container.dart';
import 'package:epic/epic.dart';
import 'package:flutter/cupertino.dart';
import 'package:lastfm_dashboard/view_models/epic_view_model.dart';
import 'package:provider/provider.dart';

typedef Handler<T> = FutureOr<void> Function(T, EpicProvider);
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

  Future<bool> process(dynamic e, EpicProvider p) async {
    if (e is T1 == false) return false;
    final event = e as T1;
    if (!where(event)) return false;
    final mapped = map(event);
    await handler(mapped, p);
    return true;
  }
}

abstract class EpicState<T extends StatefulWidget> extends State<T> {
  EpicManager epicManager;
  StreamSubscription epicSubscription;

  final List<EpicMapper> _mappers = [];
  final Map<Type, dynamic> _vmMap = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    initEpic();
    final Scope scope = Scope('initState $runtimeType');
    final provider = epicManager.container.getProvider(scope);
    final v = onLoad(provider);
    if (v is Future<void>) {
      v.then((_) => afterLoad()).whenComplete(() => scope.close());
    } else {
      afterLoad();
      loading = false;
      scope.close();
    }
  }

  @override
  void dispose() {
    super.dispose();
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
    epicSubscription = epicManager.events.listen(onEvent);
  }

  void afterLoad() {
    setState(() => loading = false);
  }

  void _subscribeVM<T>() {
    _vmMap[T] = Provider.of<T>(context, listen: false);
    handle<ViewModelReplaced<T>>(
      (e, _) => _vmMap[T] = e,
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

  Future<T> gain<T>(FutureOr<T> Function(EpicProvider) fun) async {
    final scope = Scope('Gain $runtimeType');
    try {
      final provider = epicManager.container.getProvider(scope);
      return await fun(provider);
    }
    finally {
      scope.close();
    }
  }
  
  void subscribe<T>({
    Checker<T> where,
  }) {
    _mappers.add(EpicMapper<T, T>(
      handler: (_, __) => apply(),
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
    final scope = Scope('onEvent $event - $runtimeType');
    try {
      final provider = epicManager.container.getProvider(scope);
      for (final mapper in _mappers) {
        if (await mapper.process(event, provider)) handled = true;
      }
      if (handled) apply();
    } finally {
      scope.close();
    }
  }

  FutureOr<void> onLoad(EpicProvider provider) {}
}
