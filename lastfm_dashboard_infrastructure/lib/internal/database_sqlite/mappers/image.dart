import 'package:lastfm_dashboard_domain/domain.dart';

import '../db_mapper.dart';

class ImageInfoMapper extends LiteMapper<ImageInfo> {
  const ImageInfoMapper();
  ImageInfo fromMap(Map<String, dynamic> map) => ImageInfo(
        small: map['small'],
        medium: map['medium'],
        large: map['large'],
        extraLarge: map['extraLarge'],
      );

  Map<String, dynamic> toMap(ImageInfo o) => {
        'small': o.small,
        'medium': o.medium,
        'large': o.large,
        'extraLarge': o.extraLarge
      };
}
