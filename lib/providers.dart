import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bloc.dart';
import 'blocs/artists_bloc.dart';
import 'blocs/users_bloc.dart';
import 'models/models.dart';

List<Widget> _blocProviders(EventsContext context) {
  return [
    Provider<ArtistsBloc>.value(value: context.get<ArtistsBloc>()),
    Provider<UsersBloc>.value(value: context.get<UsersBloc>())
  ];
}

List<Widget> _modelProviders(EventsContext context) {
  return [
    StreamProvider<ArtistsViewModel>.value(
      value: context.subscribe<ArtistsViewModel>(),
      initialData: context.get<ArtistsViewModel>(),
    ),
    StreamProvider<UsersViewModel>.value(
        value: context.subscribe<UsersViewModel>(),
        initialData: context.get<UsersViewModel>())
  ];
}

List<Widget> _streamProviders(EventsContext context) {
  return [
    StreamProvider<User>.value(
      value: context.subscribe<User>(),
      initialData: context.get<User>(),
      lazy: false,
    )
  ];
}

List<Widget> getProviders(BlocCombiner combiner, EventsContext eventsContext) {
  final blocProviders = _blocProviders(eventsContext);
  assert(blocProviders.length == combiner.flatBlocs().length);

  final modelProviders = _modelProviders(eventsContext);
  assert(modelProviders.length == combiner.flatModels().length);

  final streamProviders = _streamProviders(eventsContext);
  assert(streamProviders.length == combiner.flatStreams().length);

  return [
    Provider<EventsContext>.value(value: eventsContext),
    ...blocProviders,
    ...modelProviders,
    ...streamProviders
  ];
}
