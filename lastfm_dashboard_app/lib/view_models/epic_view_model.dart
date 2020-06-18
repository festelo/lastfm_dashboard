import 'package:epic/epic.dart';

class ViewModelChanged<T> {
  ViewModelChanged(this.viewModel);
  final T viewModel;

  @override
  String toString() => 'ViewModelChanged - [${viewModel.hashCode}] $viewModel';
}

class ViewModelReplaced<T> {
  ViewModelReplaced(this.oldViewModel, this.newViewModel);

  final T oldViewModel;
  final T newViewModel;

  @override
  String toString() =>
      'ViewModelReplaced - [${oldViewModel.hashCode}] '
      '$oldViewModel -> [${newViewModel.hashCode}] $newViewModel';
}

class EpicViewModel {
  final EpicManager _manager;
  EpicViewModel(EpicManager manager) : _manager = manager;

  static T update<T extends EpicViewModel>(T oldVm, T newVm) {
    if (oldVm != null) {
      oldVm._replaced(oldVm, newVm);
      if (oldVm != newVm) {
        newVm.notify(newVm);
      }
    }
    return newVm;
  }

  void notify<T>(T viewModel, [dynamic event]) {
    _manager.notify(ViewModelChanged<T>(viewModel));
    if (event != null) _manager.notify(event);
  }

  void _replaced<T>(T viewModel, T newViewModel) {
    _manager.notify(ViewModelReplaced<T>(viewModel, newViewModel));
  }
}
