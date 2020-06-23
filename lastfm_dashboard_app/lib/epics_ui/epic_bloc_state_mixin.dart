import 'package:flutter/widgets.dart';
import 'package:lastfm_dashboard/epics_ui/epic_bloc.dart';
import 'package:provider/provider.dart';

mixin EpicBlocStateMixin<T extends StatefulWidget, TBloc extends EpicBloc>
    on State<T> {
  TBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = context.read();
    bloc.addListener(() => setState(() {}));
  }
}
