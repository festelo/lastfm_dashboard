import 'package:epic/epic.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'epic_view_model.dart';

class ChartViewModel extends EpicViewModel {
  ChartViewModel(EpicManager manager): super(manager);
  
  Map<DatePeriod, Pair<DateTime>> _bounds = {
    DatePeriod.month: Pair(null, null)
  };
  Map<DatePeriod, Pair<DateTime>> get bounds => _bounds;
  set bounds(value) {
    _bounds = value;
    notify(this);
  }

  DatePeriod _period = DatePeriod.month;
  DatePeriod get period => _period;
  set period(DatePeriod value) {
    _period = value;
    notify(this);
  }
}