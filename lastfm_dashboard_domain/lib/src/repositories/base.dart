part of 'repositories.dart';

typedef Updater<T> = T Function(T);

abstract class _TranscationableRepository {
  Future<T> transaction<T>(FutureOr<T> Function() action);
}

abstract class _ReadOnlyCollectionRepository<T>
    extends _TranscationableRepository {
  Future<List<T>> getAll();
  Future<T> get(dynamic id);
  FutureOr<void> dispose() {}
}

abstract class _CollectionRepository<T>
    extends _ReadOnlyCollectionRepository<T> {
  Future<void> addOrUpdateAll(List<T> states);
  Future<void> addOrUpdate(T state);
  Future<void> delete(dynamic id);
}
