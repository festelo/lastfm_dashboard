import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home_page/viewmodel.dart';
import 'package:lastfm_dashboard/shared/progressable_future.dart';
import 'package:provider/provider.dart';

class LoadingBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomePageViewModel>(
      builder: (ctx, vm, _) => StreamBuilder<ProgressableFuture<void, int>>(
        stream: vm.currentUpdate,
        builder: (ctx, s) => 
          s.data == null 
            ? Container()
            : Container(
            height: 40,
            width: double.infinity,
            color: Colors.blue,
              child: Row(
                children: [
                  StreamBuilder(
                    stream: s.data.progressChanged,
                    builder: (ctx, s) => s.data == null
                      ? Text('...')
                      : Text(
                        '${s.data.current}/${s.data.total}'
                      ),
                  ),
                  Spacer(),
                ]
              )
            )
          )
    );
  }
}