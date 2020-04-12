import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/watchers/artists_watchers.dart';
import 'package:rxdart/rxdart.dart';

class ArtistsViewModel {
  final List<UserArtistDetails> artistsDetailed;
  final List<ArtistSelection> artistSelections;
  final int totalCount;

  const ArtistsViewModel({
    this.artistsDetailed,
    this.artistSelections,
    this.totalCount = 0
  });

  ArtistsViewModel copyWith({
    List<UserArtistDetails> artistsDetailed,
    List<ArtistSelection> artistSelections,
    int loadFrom,
    int loadTo,
    int totalCount
  }) {
    return ArtistsViewModel(
      artistsDetailed: artistsDetailed ?? this.artistsDetailed,
      artistSelections: artistSelections ?? this.artistSelections,
      totalCount: totalCount ?? this.totalCount
    );
  }
}

class ArtistsBloc extends Bloc<ArtistsViewModel>
    with BlocWithInitializationEvent {
  @override
  final BehaviorSubject<ArtistsViewModel> model;

  ArtistsBloc([
    ArtistsViewModel viewModel = const ArtistsViewModel(),
  ]) : model = BehaviorSubject.seeded(viewModel);

  @override
  Stream<Returner<ArtistsViewModel>> initializationEvent(
    void _,
    EventConfiguration<ArtistsViewModel> config,
  ) async* {
    final authService = config.context.get<AuthService>();
    await authService.loadUser();

    config.context.push(ArtistsWatcherInfo(), artistsWatcher);
    config.context.push(ArtistSelectionsWatcherInfo(), artistSelectionsWatcher);
  }
}
