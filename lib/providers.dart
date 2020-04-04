import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bloc.dart';
import 'blocs/app_bloc.dart';
import 'blocs/users_bloc.dart';
import 'models/models.dart';

List<Widget> _blocProviders(AppBloc appBloc) {
  return [
    Provider<AppBloc>.value(
      value: appBloc
    ),  
    Provider<UsersBloc>.value(
      value: appBloc.usersBloc
    )
  ];
}

List<Widget> _modelProviders(AppBloc appBloc) {
  return [
    Provider<AppBloc>.value(
      value: appBloc
    ),  
    Provider<UsersBloc>.value(
      value: appBloc.usersBloc
    )
  ];
}

List<Widget> _streamProviders(AppBloc appBloc) {
  return [
    StreamProvider<User>.value(
      value: appBloc.currentUser,
    )
  ];
}

List<Widget> getProviders(AppBloc appBloc, EventsContext eventsContext) {
  final blocProviders = _blocProviders(appBloc);
  assert(blocProviders.length == appBloc.flatBlocs().length);

  final modelProviders = _modelProviders(appBloc);
  assert(blocProviders.length == appBloc.flatBlocs().length);

  final streamProviders = _streamProviders(appBloc);
  assert(blocProviders.length == appBloc.flatBlocs().length);

  return [
      Provider<EventsContext>.value(
        value: eventsContext
      ),
      ...blocProviders,
      ...modelProviders,
      ...streamProviders
  ];
}