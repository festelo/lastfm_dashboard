import 'package:collection/collection.dart';
import 'package:epic/container.dart';
import 'package:epic/epic.dart';
import 'package:f_charts/f_charts.dart';
import 'package:lastfm_dashboard/epics/artists_epics.dart';
import 'package:lastfm_dashboard/epics/helpers.dart';
import 'package:lastfm_dashboard/epics/users_epics.dart';
import 'package:lastfm_dashboard/epics_ui/epic_bloc.dart';
import 'package:lastfm_dashboard/features/artists_chart/artists_chart_repository.dart';
import 'package:lastfm_dashboard/features/base_chart/chart_bloc.dart';
import 'package:lastfm_dashboard/features/base_chart/chart_repository.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:shared/models.dart';

class ArtistsChartViewModel extends ChartViewModel {
  String userId;

  List<String> get usedArtistIds {
    final artistIds = <String>{};
    final allSeries = [
      previousData?.series,
      currentData?.series,
      nextData?.series,
    ].where((e) => e != null).expand((i) => i);
    artistIds.addAll(allSeries.map((e) => e.name));
    return artistIds.toList();
  }

  DateTime get periodEnd {
    return period.addOffset(periodStart, 1);
  }
}

class ArtistsChartBloc extends ChartBloc {
  @override
  final ArtistsChartViewModel vm;
  ArtistsChartBloc(EpicManager manager)
      : vm = ArtistsChartViewModel()
          ..periodStart = DatePeriod.year.normalize(DateTime.now())
          ..period = DatePeriod.year,
        super(manager);

  @override
  Future<bool> handle(event, provider) async {
    final rep = ArtistsChartRepository(provider, vm);
    if (event is InitStateEvent) {
      final user = await provider.get(currentUserKey);
      vm.userId = user.id;
      await initState(rep);
      return true;
    }
    if (event is UserScrobblesAdded && event.user.id == vm.userId) {
      await wrapInLoading(userScrobblesAdded(event, rep));
      return true;
    }
    if (event is ArtistSelected && event.selection.userId == vm.userId) {
      await wrapInLoading(artistSelected(event, rep));
      return true;
    }
    if (event is ArtistSelectionRemoved && event.userId == vm.userId) {
      await wrapInLoading(artistSelectionRemoved(event, provider, rep));
      return true;
    }
    return await handleBase(event, rep);
  }

  ChartData<DateTime, int> handleScrobbleAdding(
    ChartData<DateTime, int> data,
    Map<String, List<TrackScrobble>> scrobblesPerArtist,
  ) {
    if (data == null) return null;
    final newSeries = [...data.series.map((e) => e.deepCopy())];
    for (final series in newSeries) {
      final scrobbles = scrobblesPerArtist[series.name];
      if (scrobbles == null) continue;
      for (final scrobble in scrobbles) {
        final normalized = vm.interval.normalize(scrobble.date);
        final index = series.entities.indexWhere(
          (s) => s.abscissa == normalized,
        );
        if (index == -1) continue;
        series.entities[index] =
            ChartEntity(normalized, series.entities[index].ordinate + 1);
      }
    }
    return ChartData(newSeries);
  }

  Future<void> userScrobblesAdded(
      UserScrobblesAdded e, ChartRepository rep) async {
    final scrobblesPerArtist =
        groupBy<TrackScrobble, String>(e.newScrobbles, (c) => c.artistId);
    vm.previousData = handleScrobbleAdding(
      vm.previousData,
      scrobblesPerArtist,
    );
    vm.currentData = handleScrobbleAdding(
      vm.currentData,
      scrobblesPerArtist,
    );
    vm.nextData = handleScrobbleAdding(
      vm.nextData,
      scrobblesPerArtist,
    );
    await refreshAllTimeBounds(rep);
  }

  Future<void> artistSelected(ArtistSelected e, ChartRepository rep) async {
    await refreshData(rep);
  }

  ChartData<DateTime, int> handleArtistRemoving(
    ChartData<DateTime, int> data,
    String artistName,
  ) {
    if (data == null) return null;
    final newSeries = [
      ...data.series
          .map((e) => e.deepCopy())
          .where((e) => e.name != artistName),
    ];
    return ChartData(newSeries);
  }

  Future<void> artistSelectionRemoved(
    ArtistSelectionRemoved e,
    EpicProvider provider,
    ChartRepository rep,
  ) async {
    final artists = await provider.get<ArtistsRepository>();
    final artist = await artists.get(e.artistId);
    vm.previousData = handleArtistRemoving(vm.previousData, artist.name);
    vm.currentData = handleArtistRemoving(vm.currentData, artist.name);
    vm.nextData = handleArtistRemoving(vm.nextData, artist.name);
    await refreshAllTimeBounds(rep);
  }
}
