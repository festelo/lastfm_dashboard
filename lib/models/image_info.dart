class ImageInfo {
  final String small;
  final String medium;
  final String large;
  final String extraLarge;

  const ImageInfo({this.small, this.medium, this.large, this.extraLarge});

  ImageInfo.fromMap(Map<String, dynamic> map)
      : small = map['small'],
        medium = map['medium'],
        large = map['large'],
        extraLarge = map['extraLarge'];

  Map<String, dynamic> toMap() => {
        'small': small,
        'medium': medium,
        'large': large,
        'extraLarge': extraLarge
      };
}