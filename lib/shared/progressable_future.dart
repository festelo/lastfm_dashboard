import 'dart:async';

import 'package:rxdart/streams.dart';
import 'package:rxdart/subjects.dart';

class CancelledException implements Exception {}

class Progress<TCounter> {
  final TCounter current;
  final TCounter total;
  Progress(this.current, this.total);
}

typedef SetProgressCallback<TCounter> = 
  void Function(TCounter current, TCounter total);

typedef FutureCallback<T, TCounter> = Future<T> Function(
  SetProgressCallback<TCounter> setProgress,
  ValueStream<bool> cancelled
);

class ProgressableFuture<T, TCounter> implements Future<T> {
  Future<T> _futureSource;
  Future<T> get future => _futureSource;
  // void Function(TCounter current, TCounter total) progressChanged;
  final BehaviorSubject<Progress<TCounter>> _progressChangedController;

  ValueStream<Progress<TCounter>> get progressChanged
    => _progressChangedController.stream;
  
  final BehaviorSubject<bool> _cancelledSubject = BehaviorSubject.seeded(false);
  ValueStream<bool> get cancelled  => _cancelledSubject.stream;

  ProgressableFuture(
    FutureCallback<T, TCounter> future, {
    Progress defaultProgress
  }): _progressChangedController = defaultProgress == null
      ? BehaviorSubject() 
      : BehaviorSubject.seeded(defaultProgress) {
    _futureSource = future(_setProgress, cancelled);
    _futureSource.whenComplete(() => dispose());
  }

  void cancel() {
    _cancelledSubject.add(true);
  }

  void _setProgress(TCounter current, TCounter total) {
    if (_progressChangedController.isClosed) {
      throw Exception('Future is complete');
    }
    _progressChangedController.add(Progress(current, total));
  }

  void chain(
    SetProgressCallback<TCounter> callback,
    ValueStream<bool> cancelled
  ) {
    progressChanged.listen((c) => callback(c.current, c.total));
    cancelled.listen((c) { if(c) cancel(); });
  }

  Future<void> dispose() async {
    await _cancelledSubject.close();
    await _progressChangedController.close();
  }

  @override
  Stream<T> asStream() => future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error) test})
    => future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> onValue(T value), {Function onError})
    => future.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr Function() onTimeout})
    => future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr Function() action)
    => future.whenComplete(action);
}