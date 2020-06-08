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

abstract class Epic {
  Future<void> call(EpicContext context, Notifier notify);
}

class RunnedEpicBuilder {}

class RunnedEpic {
  final Epic epic;
  final Stream<void> _epicStream;
  final Wrapper<bool> _cancelled;
  RunnedEpic(this.epic, Wrapper<bool> cancelledWrapper, this._epicStream)
      : _cancelled = cancelledWrapper;

  bool get cancelled => _cancelled.value;
  void cancel() {
    _cancelled.value = true;
  }

  Future<void> get completed {
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
}

class EpicEnded {
  final RunnedEpic runned;

  EpicEnded(this.runned);
}

class EpicManager {
  final EpicContainer container;
  final List<RunnedEpic> _runned = [];
  List<RunnedEpic> get runned => [..._runned];

  Stream<dynamic> get events => _controller.stream;
  final StreamController<dynamic> _controller = StreamController.broadcast();

  EpicManager(this.container);

  RunnedEpic start(Epic epic) {
    final cancelled = Wrapper(false);
    final scope = Scope();
    final context = EpicContext(
      manager: this,
      cancelled: cancelled,
      provider: container.getProvider(scope),
    );
    final stream =
        Stream.fromFuture(epic(context, _notify)).asBroadcastStream();
    final runnedEpic = RunnedEpic(
      epic,
      cancelled,
      stream,
    );
    _epicStarted(runnedEpic);
    runnedEpic.completed.whenComplete(() {
      _epicComplete(runnedEpic);
    });
    return runnedEpic;
  }

  void _epicStarted(RunnedEpic runnedEpic) {
    _runned.add(runnedEpic);
    _notify(EpicStarted(runnedEpic));
  }

  void _epicComplete(RunnedEpic runnedEpic) {
    _runned.remove(runnedEpic);
    _notify(EpicEnded(runnedEpic));
  }

  void _notify(dynamic event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> close() async {
    for (final e in runned) {
      e.cancel();
    }
    await _controller.close();
  }
}
