import 'dart:async';

typedef ScopeListener = void Function();
typedef ValueDisposer<T> = void Function(T);
typedef ValueBuilder<T> = FutureOr<T> Function();
typedef ValueBuilderComplex<T> = FutureOr<T> Function(EpicProvider provider);

class Scope {
  final List<ScopeListener> _listeners = [];

  Scope();

  void addListener(ScopeListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ScopeListener listener) {
    _listeners.remove(listener);
  }

  void close() {
    for (final l in _listeners) {
      l();
    }
  }
}

abstract class ValueStore<T> {
  final dynamic key;
  ValueStore(this.key);
  FutureOr<T> build(Scope scope);
}

abstract class ValueStoreComplex<T> {
  final dynamic key;
  ValueStoreComplex(this.key);
  FutureOr<T> build(Scope scope, EpicProvider provider);
}

abstract class BaseScoped<T> {
  final ValueDisposer<T> _disposer;
  final dynamic key;
  BaseScoped(this._disposer, this.key);

  final Map<Scope, T> _scoped = {};

  FutureOr<T> _build(Scope scope, ValueBuilder<T> builder) {
    if (!_scoped.containsKey(scope)) {
      final futureOrValue = builder();
      return save(scope, futureOrValue);
    }
    return _scoped[scope];
  }

  FutureOr<T> save(Scope scope, FutureOr<T> futureOrValue) {
    scope.addListener(() => _unregister(scope));
    if (futureOrValue is Future<T>) {
      return Future(() async {
        final value = await futureOrValue;
        _scoped[scope] = value;
        return value;
      });
    } else {
      final value = futureOrValue;
      _scoped[scope] = value;
      return value;
    }
  }

  void _unregister(Scope scope) {
    final o = _scoped.remove(scope);
    if (_disposer != null && o != null) _disposer(o);
  }
}

abstract class BaseTransient<T> {
  final ValueDisposer<T> _disposer;
  final dynamic key;
  BaseTransient(this._disposer, this.key);

  final Map<Scope, List<T>> _scoped = {};

  @override
  FutureOr<T> _build(Scope scope, ValueBuilder<T> builder) {
    if (!_scoped.containsKey(scope)) {
      _scoped[scope] = [];
      scope.addListener(() => _unregister(scope));
    }
    final futureOrValue = builder();

    if (futureOrValue is Future<T>) {
      return Future(() async {
        final value = await futureOrValue;
        _scoped[scope].add(value);
        return value;
      });
    } else {
      final value = futureOrValue;
      _scoped[scope].add(value);
      return value;
    }
  }

  void _unregister(Scope scope) {
    if (_disposer != null) {
      _scoped[scope]?.forEach(_disposer);
    }
    _scoped.remove(scope);
  }
}

class SingletoneStore<T> extends ValueStore<T> {
  final dynamic value;
  SingletoneStore(this.value, {dynamic key}) : super(key);

  @override
  T build(Scope scope) {
    return value;
  }
}

class TransientStore<T> extends ValueStore<T> {
  final ValueBuilder<T> builder;
  final ValueDisposer<T> _disposer;
  TransientStore(this.builder, this._disposer, {dynamic key}) : super(key);

  Map<Scope, List<T>> _scoped;

  @override
  FutureOr<T> build(Scope scope) {
    if (!_scoped.containsKey(scope)) {
      _scoped[scope] = [];
      scope.addListener(() => _unregister(scope));
    }
    final futureOrValue = builder();

    if (futureOrValue is Future<T>) {
      return Future(() async {
        final value = await futureOrValue;
        _scoped[scope].add(value);
        return value;
      });
    } else {
      final value = futureOrValue;
      _scoped[scope].add(value);
      return value;
    }
  }

  void _unregister(Scope scope) {
    if (_disposer != null) {
      _scoped[scope]?.forEach(_disposer);
    }
    _scoped.remove(scope);
  }
}

class ScopedStore<T> extends BaseScoped<T> implements ValueStore<T> {
  final ValueBuilder<T> builder;
  ScopedStore(this.builder, ValueDisposer<T> disposer, {dynamic key})
      : super(disposer, key);

  @override
  FutureOr<T> build(Scope scope) {
    return _build(scope, builder);
  }
}

class ScopedStoreComplex<T> extends BaseScoped<T>
    implements ValueStoreComplex<T> {
  final ValueBuilderComplex<T> builder;

  ScopedStoreComplex(
    this.builder,
    ValueDisposer<T> disposer, {
    dynamic key,
  }) : super(disposer, key);

  @override
  FutureOr<T> build(Scope scope, EpicProvider provider) {
    return _build(scope, () => builder(provider));
  }
}

class TransientStoreComplex<T> extends BaseTransient<T>
    implements ValueStoreComplex<T> {
  final ValueBuilderComplex<T> builder;

  TransientStoreComplex(
    this.builder,
    ValueDisposer<T> disposer, {
    dynamic key,
  }) : super(disposer, key);

  @override
  FutureOr<T> build(Scope scope, EpicProvider provider) {
    return _build(scope, () => builder(provider));
  }
}

class EpicContainer {
  final List<ValueStore> stores = [];
  final List<ValueStoreComplex> complexStores = [];

  EpicContainer();

  void addSingleton<T>(T value, {dynamic key}) {
    stores.add(SingletoneStore<T>(value, key: key));
  }

  void addScoped<T>(
    ValueBuilder<T> builder, {
    ValueDisposer<T> dispose,
    dynamic key,
  }) {
    stores.add(ScopedStore<T>(builder, dispose, key: key));
  }

  void addTransient<T>(
    ValueBuilder<T> builder, {
    ValueDisposer<T> dispose,
    dynamic key,
  }) {
    stores.add(TransientStore<T>(builder, dispose, key: key));
  }

  void addScopedComplex<T>(
    ValueBuilderComplex<T> builder, {
    ValueDisposer<T> dispose,
    dynamic key,
  }) {
    complexStores.add(ScopedStoreComplex<T>(builder, dispose, key: key));
  }

  void addTransientComplex<T>(
    ValueBuilderComplex<T> builder, {
    ValueDisposer<T> dispose,
    dynamic key,
  }) {
    complexStores.add(TransientStoreComplex<T>(builder, dispose, key: key));
  }

  EpicProvider getProvider(Scope scope) {
    return EpicProvider(this, scope);
  }
}

class EpicProvider {
  final EpicContainer container;
  final Scope scope;
  EpicProvider(this.container, this.scope);

  FutureOr<T> get<T>([dynamic key]) {
    for (final s in container.stores) {
      if (s is ValueStore<T> && (key == null || s.key == key)) {
        return s.build(scope);
      }
    }
    for (final s in container.complexStores) {
      if (s is ValueStoreComplex<T> && (key == null || s.key == key)) {
        return s.build(scope, this);
      }
    }
    throw Exception('Value store for $T not found');
  }
}
