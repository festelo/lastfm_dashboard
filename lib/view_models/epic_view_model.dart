import 'package:epic/epic.dart';

class ViewModelChanged<T> {
  ViewModelChanged(this.viewModel);
  final T viewModel;
}

class EpicViewModel {
  final EpicManager _manager;
  EpicViewModel(EpicManager manager): _manager = manager;

  void notify<T>(T viewModel, [dynamic event]) {
    _manager.notify(ViewModelChanged<T>(viewModel));
    if(event != null) _manager.notify(event);
  }
}