import 'package:lastfm_dashboard_domain/domain.dart';

class CancellationTokenSource {
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  void cancel() => _cancelled = true;
  CancellationToken get token => CancellationToken(() => _cancelled);
}

class CancellationToken {
  bool Function() _cancelled;
  bool get cancelled => _cancelled();
  void throwIfCancelled() {
    if (cancelled) throw CancelledException();
  }
  CancellationToken(this._cancelled);
}