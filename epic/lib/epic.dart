import 'dart:async';

import 'container.dart';
import 'exceptions.dart';

typedef Notifier = void Function(dynamic event);

class Wrapper<T> {
  T value;
  Wrapper(this.value);
}

class EpicContext {
  final EpicManager manager;
  final EpicProvider provider;
  final Wrapper<bool> _cancelled;
  bool get cancelled => _cancelled.value;

  void throwIfCancelled() {
    if (cancelled) throw CancelledException();
  }

  EpicContext({this.manager, this.provider, Wrapper<bool> cancelled})
      : _cancelled = cancelled;
}

abstract class Epic<T> {
  Future<T> call(EpicContext context, Notifier notify);
}

class RunnedEpicBuilder {}

class EpicChain extends Epic {
  final List<Epic> epics;
  EpicChain(this.epics);

  @override
  Future<void> call(EpicContext context, Notifier notify) async {
    for(final e in epics) {
      final r = context.manager.start(e);
      await r.completed;
    }
  }
}

class RunnedEpic<T> {
  final Epic epic;
  final Stream<T> _epicStream;
  final Wrapper<bool> _cancelled;
  RunnedEpic(this.epic, Wrapper<bool> cancelledWrapper, this._epicStream)
      : _cancelled = cancelledWrapper;

  bool get cancelled => _cancelled.value;
  void cancel() {
    _cancelled.value = true;
  }

  Future<T> get completed {
    return _epicStream.first;
  }
}

class EpicConfiguration<T> {
  bool Function() cancelled;

  final EpicManager manager;

  void throwIfCancelled() {
    if (cancelled()) throw CancelledException();
  }

  EpicConfiguration({this.cancelled, this.manager});
}

class EpicStarted {
  final RunnedEpic runned;

  EpicStarted(this.runned);

  @override
  String toString() {
    return 'EpicStarted - ${runned.epic.runtimeType}';
  }
}

class EpicEnded {
  final RunnedEpic runned;
  final dynamic error;
  bool get succesfully => error == null;

  EpicEnded(this.runned, [this.error]);

  @override
  String toString() {
    if (succesfully) {
      return 'EpicEnded - ${runned.epic.runtimeType}';
    } else {
      return 'EpicEnded - ${runned.epic.runtimeType} with error: $error';
    }
  }
}

class EpicManager {
  EpicContainer _container;
  EpicContainer get container => _container;
  final List<RunnedEpic> _runned = [];
  List<RunnedEpic> get runned => [..._runned];

  Stream<dynamic> get events => _controller.stream;
  final StreamController<dynamic> _controller = StreamController.broadcast();

  EpicManager();

  void registerContainer(EpicContainer container) {
    _container = container;
    _container.addSingleton(() => this);
  }

  RunnedEpic<T> start<T>(Epic<T> epic) {
    final cancelled = Wrapper(false);
    final scope = Scope(epic.toString());
    final context = EpicContext(
      manager: this,
      cancelled: cancelled,
      provider: container.getProvider(scope),
    );
    final stream =
        Stream.fromFuture(epic(context, notify)).asBroadcastStream();
    final runnedEpic = RunnedEpic(
      epic,
      cancelled,
      stream,
    );
    _epicStarted(runnedEpic);
    
    runnedEpic.completed.then(
      (_) => _epicComplete(runnedEpic),
      onError: (e) => _epicComplete(runnedEpic, e),
    ).whenComplete(() => scope.close());

    return runnedEpic;
  }

  Future<T> wait<T>(Epic<T> epic) async {
    final runned = start(epic);
    return await runned.completed;
  }

  void _epicStarted(RunnedEpic runnedEpic) {
    _runned.add(runnedEpic);
    notify(EpicStarted(runnedEpic));
  }

  void _epicComplete(RunnedEpic runnedEpic, [dynamic error]) {
    _runned.remove(runnedEpic);
    notify(EpicEnded(runnedEpic, error));
  }

  void notify(dynamic event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> close() async {
    for (final e in runned) {
      e.cancel();
    }
    await _controller.close();
  }
}
