import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

typedef Returner<T> = T Function(T);
typedef Updater<T> = T Function(T Function(T));
typedef Cancelled = bool Function();

typedef Pusher<ST extends EventInfo, TE extends ST, VMT> = 
  void Function<TE extends ST>(TE, Event<VMT, TE>, EventsContext);

typedef Event<T, TEventInfo extends EventInfo> = 
  Future<Returner<T>> Function(
    TEventInfo info, EventConfiguration<T> configuration);

@immutable
abstract class EventInfo { const EventInfo(); }

class RunnedEvent {
  final EventInfo info;
  final void Function() cancel;
  RunnedEvent(this.info, this.cancel);
}

class EventConfiguration<T> {
  final Updater<T> update;
  final Cancelled cancelled;

  final EventsContext context;

  EventConfiguration({
    this.update,
    this.cancelled,
    this.context
  });
}

abstract class Bloc<T, TSuperEventInfo extends EventInfo> {
  List<RunnedEvent> working = [];
  Stream<EventInfo> get completedEvents => _cCompletedEvents.stream;
  final StreamController<EventInfo> _cCompletedEvents 
    = StreamController.broadcast();

  BehaviorSubject<T> get model;
  List<ValueStream<dynamic>> get streams => []; 

  List<Bloc> flatBlocs() => [this]; 

  List<ValueStream<dynamic>> flatModels() {
    final vms = <ValueStream<dynamic>>[];
    vms.add(model.stream);
    for(final bloc in flatBlocs()) {
      if (bloc != this) vms.addAll(bloc.flatModels());
    }
    return vms;
  }
  
  List<ValueStream<dynamic>> flatStreams() {
    final ret = <ValueStream<dynamic>>[];
    ret.addAll(streams);
    for(final bloc in flatBlocs()) {
      if (bloc != this) ret.addAll(bloc.flatStreams());
    }
    return ret;
  }
  
  List<dynamic> flatPushers() {
    final pushers = <dynamic>[];
    pushers.add(push);
    for(final bloc in flatBlocs()) {
      if (bloc != this) pushers.addAll(bloc.flatPushers());
    }
    return pushers;
  }

  void push<TEventInfo extends TSuperEventInfo>(
    TEventInfo info, 
    Event<T, TEventInfo> event,
    EventsContext context
  ) {
    var cancelled = false;
    final runnedEvent = RunnedEvent(info, () => cancelled = true);
    working.add(runnedEvent);
    final remove = () => working.remove(runnedEvent);
    final configuration = EventConfiguration<T>(
      cancelled: () => cancelled,
      update: (a) => model.value = a(model.value),
      context: context
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

class EventsContext {
  final List<dynamic> _pushers;
  final List<ValueStream> _models;
  final List<ValueStream> _streams;
  final List<dynamic> _singletones;

  EventsContext({
    List<dynamic> pushers,
    List<ValueStream> streams,
    List<dynamic> singletones,
    List<ValueStream> models,
  }): 
    _pushers = pushers, 
    _streams = streams,
    _singletones = singletones,
    _models = models;
  
  void push<ST extends EventInfo, TEventInfo extends ST, TVM>(
    TEventInfo eventInfo, Event<TVM, TEventInfo> event, ST Function() fun) {
    for(final p in _pushers) {
      if (p is Pusher<ST, TEventInfo, TVM>) {
        p(eventInfo, event, this);
        return;
      }
    }
    throw Exception('Pusher not found');
  }

  ValueStream<T> subscribe<T>() {
    for(final s in _streams) {
      if (s is ValueStream<T>) {
        return s;
      }
    }
    for(final s in _models) {
      if (s is ValueStream<T>) {
        return s;
      }
    }
    for(final s in _singletones) {
      if (s is T) {
        return Stream.value(s).publishValue();
      }
    }
    throw Exception('Dependency not found');
  }

  T get<T>() {
    for(final s in _streams) {
      if (s is ValueStream<T>) {
        return s.value;
      }
    }
    for(final s in _models) {
      if (s is ValueStream<T>) {
        return s.value;
      }
    }
    for(final s in _singletones) {
      if (s is T) {
        return s;
      }
    }
    throw Exception('Dependency not found');
  }
}