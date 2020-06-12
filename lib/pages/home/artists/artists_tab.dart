import 'package:flutter/material.dart';

import 'routes.dart';

class ArtistsTab extends StatelessWidget {
  const ArtistsTab([Key key]): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (_, __) => [Routes.chart()],
    );
  }
}
