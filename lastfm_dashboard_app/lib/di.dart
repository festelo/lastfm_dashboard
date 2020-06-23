import 'package:epic/container.dart';
import 'package:epic/epic.dart';
import 'package:epic/watcher.dart';
import 'package:lastfm_dashboard/constants.dart';
import 'package:lastfm_dashboard/services/auth/auth_service.dart';
import 'package:lastfm_dashboard/watchers/refresh_config.dart';
import 'package:lastfm_dashboard/watchers/refresh_watcher.dart';
import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:lastfm_dashboard_infrastructure/internal/database_moor/database.dart';
import 'package:lastfm_dashboard_infrastructure/internal/lastfm/lastfm_api.dart';
import 'package:lastfm_dashboard_infrastructure/repositories/repositories.dart';
import 'package:lastfm_dashboard_infrastructure/services/lastfm_service.dart';

import 'config.dart';
import 'db_builder.dart'
  if (dart.library.io) "db_builder_ffi.dart"
  if (dart.library.js) "db_builder_web.dart";
import 'epics/helpers.dart';


void _configureInfrastructure(EpicContainer container) {
  container.addSingleton(() => defaultRefreshConfig);
  container.addSingleton(() => buildDatabase());

  container.addSingletonComplex<ArtistsRepository>(
      (c) async => ArtistsMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<UsersRepository>(
      (c) async => UsersMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<TracksRepository>(
      (c) async => TracksMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<ArtistsRepository>(
      (c) async => ArtistsMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<TrackScrobblesRepository>(
      (c) async => TrackScrobblesMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<ArtistSelectionsRepository>(
      (c) async => ArtistSelectionsMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<ArtistUserInfoRepository>(
      (c) async => ArtistUserInfoMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<TrackScrobblesPerTimeRepository>((c) async =>
      TrackScrobblesPerTimeMoorRepository(await c.get<MoorDatabase>()));

  container.addSingletonComplex<LastFMService>(
    (c) async => LastFMService(
      api: LastFMApi(Config.lastFmKey),
      artists: await c.get<ArtistsRepository>(),
      trackScrobbles: await c.get<TrackScrobblesRepository>(),
      tracks: await c.get<TracksRepository>(),
      users: await c.get<UsersRepository>(),
    ),
  );
}

void _configureApp(EpicContainer container) {
  container.addSingleton<AuthService>(
    () => AuthService.load(),
  );

  container.addWatcher<RefreshWatcher>((p) async {
    final users = await p.get<UsersRepository>();
    final config = await p.get<RefreshConfig>();
    final manager = await p.get<EpicManager>();
    return RefreshWatcher(manager, users, config);
  });
}

EpicContainer configureDependencies(EpicManager manager) {
  final container = EpicContainer();
  _configureInfrastructure(container);
  _configureApp(container);
  defineUserHelpers(container);
  manager.registerContainer(container);
  return container;
}
