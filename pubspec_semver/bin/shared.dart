import 'dart:io';

void panic(String message) {
  print(message);
  exit(1);
}

const defaultPubspecPath = './pubspec.yaml';