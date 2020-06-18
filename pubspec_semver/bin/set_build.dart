import 'package:pubspec_semver/pubspec_semver.dart' as pubspec_semver;

import 'shared.dart';

void main(List<String> arguments) {
  var pubspecPath = defaultPubspecPath;
  if (arguments.isEmpty) panic('you must specify build number');
  final number = int.tryParse(arguments[0]);
  if (number == null) panic('build number is not a number');
  if (arguments.length >= 2)  pubspecPath = arguments[1];
  pubspec_semver.setBuildNumber(number, path: pubspecPath);
}