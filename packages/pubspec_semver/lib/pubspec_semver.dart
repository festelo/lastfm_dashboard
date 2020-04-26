import 'dart:convert';
import 'dart:io';

import 'package:plain_optional/plain_optional.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

String getVersion({String path = './pubspec.yaml'}) {
  final file = File(path);
  if(!file.existsSync()) throw Exception('File not found');
  final yaml = file.readAsStringSync().toPubspecYaml();
  final fullVersion = yaml.version;
  if (!fullVersion.hasValue) throw Exception('No version found');
  return fullVersion.unsafe.split('+')[0];
}

void setBuildNumber(int number, {String path = './pubspec.yaml'}) {
  final file = File(path);
  if(!file.existsSync()) throw Exception('File not found');
  var yaml = file.readAsStringSync().toPubspecYaml();
  final fullVersion = yaml.version;
  if (!fullVersion.hasValue) throw Exception('No version found');
  final fullVersionSplitted = fullVersion.unsafe.split('+');
  fullVersionSplitted[1] = number.toString();
  print(fullVersionSplitted.join('+'));
  yaml = yaml.copyWith(
    version: Optional<String>(fullVersionSplitted.join('+'))
  );
  file.writeAsStringSync(yaml.toYamlString());
}