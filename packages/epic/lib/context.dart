import 'container.dart';
import 'epic.dart';

class EpicContext {
  final EpicProvider provider;
  final EpicManager manager;

  EpicContext(this.provider, this.manager);
}