import 'dart:async';

import 'package:epic/container.dart';
import 'package:epic/epic.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class InitStateEvent {}

abstract class EpicBloc {
  final List<VoidCallback> _listeners = [];
  final StreamController<dynamic> _innerStreamController = StreamController();
  Stream<dynamic> _events;
  Stream<dynamic> get events => _events;
  bool _cancelled = false;
  final EpicManager manager;

  EpicBloc(this.manager) {
    _events = Rx.merge([
      _innerStreamController.stream,
      manager.events,
    ]);
    listen();
    pushEvent(InitStateEvent());
  }

  void notify() {
    final localListeners = List.from(_listeners);
    for (final listener in localListeners) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void addListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  void pushEvent(dynamic e) {
    _innerStreamController.add(e);
  }

  Future<bool> handle(dynamic event, EpicProvider provider);

  Future<void> listen() async {
    bool initialized = false;
    await for (final e in events) {
      if (e is InitStateEvent) {
        initialized = true;
      }
      if (!initialized) {
        continue;
      }
      final scope = Scope('EpicBloc ($runtimeType). Event handle for ($e)');
      final provider = manager.container.getProvider(scope);
      await runZoned(() async {
        final handled = await handle(e, provider);
        if (handled) notify();
      }).catchError((e, s) => FlutterError.onError(FlutterErrorDetails(
            exception: e,
            stack: s as StackTrace,
          )));
      scope.close();
      if (_cancelled) return;
    }
  }

  Future<void> dispose() async {
    await _innerStreamController.close();
    _cancelled = true;
  }
}
