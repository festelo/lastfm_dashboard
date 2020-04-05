import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

typedef Returner<T> = T Function(T);
typedef Cancelled = bool Function();

typedef Pusher<TE, VMT> = 
  void Function<TE>(TE, Event<VMT, TE>, EventsContext);

typedef Event<T, TEventInfo> = 
  Stream<Returner<T>> Function(
    TEventInfo info, EventConfiguration<T> configuration);

class RunnedEvent<T> {
  final T info;
  final void Function() cancel;
  final Future<void> future;
  RunnedEvent(this.info, this.cancel, this.future);
}

class EventConfiguration<T> {
  final Cancelled cancelled;

  final EventsContext context;

  void throwIfCancelled() {
    if (cancelled())
      throw CancelledException();
  }

  EventConfiguration({
    this.cancelled,
    this.context
  });
}

mixin BlocWithInitializationEvent<T> on Bloc<T> {
  RunnedEvent<void> pushInitializationEvent(EventsContext context) {
    return context.push(null, initializationEvent);
  }

  Stream<Returner<T>> initializationEvent(
    void _, EventConfiguration<T> c);
}

class BlocCombiner {
  final List<Bloc> _blocs;
  BlocCombiner(this._blocs);
  
  List<Bloc> flatBlocs() {
    final ret = <Bloc>[];
    for(final f in _blocs) {
      ret.addAll(f.flatBlocs());
    } 
    return ret;
  } 

  List<ValueStream<dynamic>> flatModels() {
    final vms = <ValueStream<dynamic>>[];
    for(final bloc in flatBlocs()) {
      vms.addAll(bloc.flatModels());
    }
    return vms;
  }
  
  List<ValueStream<dynamic>> flatStreams() {
    final ret = <ValueStream<dynamic>>[];
    for(final bloc in flatBlocs()) {
      ret.addAll(bloc.flatStreams());
    }
    return ret;
  }
  
  List<dynamic> flatPushers() {
    final pushers = <dynamic>[];
    for(final bloc in flatBlocs()) {
      pushers.addAll(bloc.flatPushers());
    }
    return pushers;
  }
}

abstract class Bloc<T> {
  List<RunnedEvent> working = [];
  Stream<dynamic> get completedEvents => _cCompletedEvents.stream;
  final StreamController<dynamic> _cCompletedEvents 
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

  RunnedEvent<TEventInfo> push<TEventInfo>(
    TEventInfo info, 
    Event<T, TEventInfo> event,
    EventsContext context
  ) {
    var cancelled = false;
    final completer = Completer<void>();
    final runnedEvent = RunnedEvent(info, 
      () => cancelled = true, 
      completer.future);
    StreamSubscription subscription;

    working.add(runnedEvent);
    final remove = ([dynamic error]) {
      subscription.cancel();
      if (completer.isCompleted) return;
      if (error != null) {
        print(error);
        debugPrintStack(stackTrace: StackTrace.current);
        completer.completeError(error);
      } else {
        completer.complete();
      }
      working.remove(runnedEvent);
    };
    final configuration = EventConfiguration<T>(
      cancelled: () => cancelled,
      context: context
    );
    runZoned(
      () => subscription = event(info, configuration)
        .listen((modifier) {
          if (modifier != null)
            model.value = modifier(model.value);
        }, 
        onDone: () {
          remove();
          _cCompletedEvents.add(info);
        },
        onError: (e) {
          remove(e);
          _cCompletedEvents.addError(e);
        }),
      onError: (e) { 
        remove(e); 
        print('interesting behavior');
      }
    );
    return runnedEvent;
  }

  Future<void> close() async {
    await _cCompletedEvents.close();
  }
}

class CancelledException implements Exception {}

class EventsContext {
  final List<dynamic> _blocs;
  final List<ValueStream> _models;
  final List<ValueStream> _streams;
  final List<dynamic> _singletones;

  EventsContext({
    @required List<dynamic> blocs,
    List<ValueStream> streams  = const [],
    List<dynamic> singletones = const [],
    List<ValueStream> models = const [],
  }): 
    _blocs = blocs, 
    _streams = streams,
    _singletones = singletones,
    _models = models;
  
  RunnedEvent<TEventInfo> push<TEventInfo, TVM>(
    TEventInfo eventInfo, Event<TVM, TEventInfo> event) {
    for(final p in _blocs) {
      if (p is Bloc<TVM>) {
        return p.push(eventInfo, event, this);
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
        print('Subscribing to not changing value');
        return Stream.value(s).publishValue();
      }
    }
    for(final s in _blocs) {
      if (s is T) {
        print('Subscribing to not changing value');
        return Stream.value(s).publishValue();
      }
    }
    throw Exception('Dependency not found');
  }

  T get<T>() {
    for(final s in _blocs) {
      if (s is T) {
        return s;
      }
    }
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