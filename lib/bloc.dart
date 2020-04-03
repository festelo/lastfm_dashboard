import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

typedef Returner<T> = T Function(T);
typedef Updater<T> = T Function(T Function(T));
typedef Cancelled = bool Function();

typedef Event<T, TEventInfo> = 
  Future<Returner<T>> Function(
    TEventInfo info, EventConfiguration<T> configuration);

@immutable
abstract class EventInfo {}

class RunnedEvent {
  final EventInfo info;
  final void Function() cancel;
  RunnedEvent(this.info, this.cancel);
}

class EventConfiguration<T> {
  final Updater<T> update;
  final Cancelled cancelled;

  final Bloc<T> bloc;

  EventConfiguration({
    this.update,
    this.cancelled,
    this.bloc
  });
}

abstract class Bloc<T> {
  List<RunnedEvent> working = [];
  Stream<EventInfo> get completedEvents => _cCompletedEvents.stream;
  final StreamController<EventInfo> _cCompletedEvents 
    = StreamController.broadcast();

  BehaviorSubject<T> get model;

  void push<TEventInfo extends EventInfo>(
    TEventInfo info, 
    Event<T, TEventInfo> event
  ) {
    var cancelled = false;
    final runnedEvent = RunnedEvent(info, () => cancelled = true);
    working.add(runnedEvent);
    final remove = () => working.remove(runnedEvent);
    final configuration = EventConfiguration<T>(
      cancelled: () => cancelled,
      update: (a) => model.value = a(model.value),
      bloc: this
    );
    runZoned(
      () => event(info, configuration)
        .then((modifier) {
          model.value = modifier(model.value);
          remove();
          _cCompletedEvents.add(info);
        })
        .catchError((e) {
          remove();
          _cCompletedEvents.addError(e);
        }),
      onError: (e) { 
        remove(); 
        print('interesting behavior');
      }
    );
  }

  Future<void> close() async {
    await _cCompletedEvents.close();
  }
}

class CancelledException implements Exception {}