import 'package:flutter/material.dart';

import 'routes.dart';

class ArtistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (_, __) => [Routes.chart()],
    );
  }
}
