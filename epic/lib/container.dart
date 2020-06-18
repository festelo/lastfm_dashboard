import 'dart:async';

typedef ScopeListener = void Function();
typedef ValueDisposer<T> = void Function(T);
typedef ValueBuilder<T> = FutureOr<T> Function();
typedef ValueBuilderComplex<T> = FutureOr<T> Function(EpicProvider provider);

class Scope {
  final String _debugLabel;
  final List<ScopeListener> _listeners = [];
  var _closed = false;
  bool get closed => _closed;

  Scope([this._debugLabel]);

  void addListener(ScopeListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ScopeListener listener) {
    _listeners.remove(listener);
  }

  void close() {
    _closed = true;
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

abstract class BaseSingleton<T> {
  final dynamic key;
  T _value;
  BaseSingleton(this.key);

  FutureOr<T> _build(ValueBuilder<T> builder) {
    if (_value == null) {
      final futureOrValue = builder();
      return save(futureOrValue);
    }
    return _value;
  }

  FutureOr<T> save(FutureOr<T> futureOrValue) {
    if (futureOrValue is Future<T>) {
      return Future(() async {
        final value = await futureOrValue;
        _value = value;
        return value;
      });
    } else {
      final value = futureOrValue;
      _value = value;
      return value;
    }
  }
}

abstract class BaseScoped<T> {
  final ValueDisposer<T> _disposer;
  final dynamic key;
  BaseScoped(this._disposer, this.key);

  final Map<Scope, T> _scoped = {};

  FutureOr<T> _build(Scope scope, ValueBuilder<T> builder) {
    if (scope.closed) {
      throw Exception('Scope is closed');
    }
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
        _addOrDispose(value, scope);
        return value;
      });
    } else {
      final value = futureOrValue;
      _scoped[scope] = value;
      return value;
    }
  }

  void _addOrDispose(T val, Scope scope) {
    if (!scope.closed) {
      _scoped[scope] = val;
    } else {
      if (_disposer != null) _disposer(val);
      throw Exception('Scope was closed in time of getting the value');
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

  FutureOr<T> _build(Scope scope, ValueBuilder<T> builder) {
    if (scope.closed) {
      throw Exception('Scope is closed');
    }
    if (!_scoped.containsKey(scope)) {
      _scoped[scope] = [];
      scope.addListener(() => _unregister(scope));
    }
    final futureOrValue = builder();

    if (futureOrValue is Future<T>) {
      return Future(() async {
        final value = await futureOrValue;
        _addOrDispose(value, scope);
        return value;
      });
    } else {
      final value = futureOrValue;
      _scoped[scope].add(value);
      return value;
    }
  }

  void _addOrDispose(T val, Scope scope) {
    if (!scope.closed) {
      _scoped[scope].add(val);
    } else {
      if (_disposer != null) _disposer(val);
      throw Exception('Scope was closed in time of getting the value');
    }
  }

  void _unregister(Scope scope) {
    if (_disposer != null) {
      _scoped[scope]?.forEach(_disposer);
    }
    _scoped.remove(scope);
  }
}

class SingletoneStore<T> extends BaseSingleton<T> implements ValueStore<T> {
  final ValueBuilder<T> builder;
  SingletoneStore(this.builder, {dynamic key}) : super(key);

  @override
  FutureOr<T> build(Scope scope) {
    return _build(builder);
  }
}

class TransientStore<T> extends BaseTransient<T> implements ValueStore<T> {
  final ValueBuilder<T> builder;

  TransientStore(
    this.builder,
    ValueDisposer<T> _disposer, {
    dynamic key,
  }) : super(_disposer, key);

  @override
  FutureOr<T> build(Scope scope) {
    return _build(scope, builder);
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

class SingletoneStoreComplex<T> extends BaseSingleton<T>
    implements ValueStoreComplex<T> {
  final ValueBuilderComplex<T> builder;
  SingletoneStoreComplex(this.builder, {dynamic key}) : super(key);

  @override
  FutureOr<T> build(Scope scope, EpicProvider provider) {
    return _build(() => builder(provider));
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

  void addSingleton<T>(ValueBuilder<T> builder, {dynamic key}) {
    stores.add(SingletoneStore<T>(builder, key: key));
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

  void addSingletonComplex<T>(ValueBuilderComplex<T> builder, {dynamic key}) {
    complexStores.add(SingletoneStoreComplex<T>(builder, key: key));
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

class Key<T> {
  const Key();
}

class EpicProvider {
  final EpicContainer container;
  final Scope scope;
  EpicProvider(this.container, this.scope);

  FutureOr<T> get<T>([Key<T> key]) {
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
