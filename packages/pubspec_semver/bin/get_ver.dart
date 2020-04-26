import 'dart:io';

import 'package:pubspec_semver/pubspec_semver.dart' as pubspec_semver;

import 'shared.dart';

void main(List<String> arguments) {
  var pubspecPath = defaultPubspecPath;
  if (arguments.isNotEmpty)  pubspecPath = arguments[2];
  final ver = pubspec_semver.getVersion(path: pubspecPath);
  print(ver);
}
