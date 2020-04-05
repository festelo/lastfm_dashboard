import 'package:lastfm_dashboard/bloc.dart';
import 'package:lastfm_dashboard/models/models.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/watchers/artists_watchers.dart';
import 'package:rxdart/rxdart.dart';

class ArtistWithListenInfo {
 final Artist artist;
 final int scrobbles;
 ArtistWithListenInfo({
   this.artist,
   this.scrobbles
 });
}

class ArtistsViewModel {
  final List<ArtistWithListenInfo> artistsWithListens;
  final List<ArtistSelection> artistSelections;

  const ArtistsViewModel({
    this.artistsWithListens,
    this.artistSelections
  });

  ArtistsViewModel copyWith({
    List<ArtistWithListenInfo> artistsWithListens,
    List<ArtistSelection> artistSelections
  }) => ArtistsViewModel(
    artistsWithListens: artistsWithListens ?? this.artistsWithListens,
    artistSelections: artistSelections ?? this.artistSelections
  );
}

class ArtistsBloc extends Bloc<ArtistsViewModel> 
  with BlocWithInitializationEvent {
  @override
  final BehaviorSubject<ArtistsViewModel> model;

  ArtistsBloc([ArtistsViewModel viewModel = const ArtistsViewModel()]):
    model = BehaviorSubject.seeded(viewModel);
    
  @override
  Stream<Returner<ArtistsViewModel>> initializationEvent(
    void _,
    EventConfiguration<ArtistsViewModel> c
  ) async* {
    final authService = c.context.get<AuthService>();
    await authService.loadUser();

    c.context.push(ArtistsWatcherInfo(), artistsWatcher);
    c.context.push(ArtistSelectionsWatcherInfo(), artistSelectionsWatcher);
  }
}