import 'package:flutter/material.dart';
import 'package:lastfm_dashboard/pages/home_page/artists_tab/artists_tab_content.dart';

class ArtistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cnstr) => ArtistsTabContent(
        height: cnstr.maxHeight,
        width: cnstr.maxWidth,
      ),
    );
  }
}
