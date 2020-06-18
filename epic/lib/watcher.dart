import 'dart:async';
import 'package:epic/container.dart';

class _WatcherStore<T extends Watcher>
    extends SingletoneStoreComplex<T> {
  _WatcherStore(builder) : super(builder);
}

abstract class Watcher {
  Future<void> start();
}

extension WatchersExtensions on EpicContainer {
  void addWatcher<T extends Watcher>(ValueBuilderComplex<T> builder) {
    complexStores.add(_WatcherStore(builder));
  }

  Future<Scope> startWatchers() async {
    final scope = Scope('watcher');
    final provider = getProvider(scope);

    final watchers = <Watcher>[];

    for (final store in complexStores) {
      if (store is _WatcherStore) {
        final watcher = await store.build(scope, provider);
        watchers.add(watcher);
      }
    }

    await Future.wait(watchers.map((e) => e.start()));

    return scope;
  }
}
