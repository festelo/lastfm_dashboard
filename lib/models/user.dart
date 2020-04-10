import 'package:lastfm_dashboard/extensions.dart';
import 'models.dart';

class UserSetupSync {
  final bool passed;
  final DateTime latestScrobble;

  const UserSetupSync({this.passed = false, this.latestScrobble});

  UserSetupSync.deserialize(Map<String, dynamic> dbMap)
      : passed = (dbMap['passed'] as int).boolean,
        latestScrobble = dbMap['latestScrobble'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(dbMap['latestScrobble']);

  Map<String, dynamic> toDbMap() => {
        'passed': passed.integer,
        'latestScrobble': latestScrobble?.millisecondsSinceEpoch
      };

  UserSetupSync copyWith({bool passed, DateTime latestScrobble}) =>
      UserSetupSync(
        passed: passed ?? this.passed,
        latestScrobble: latestScrobble ?? this.latestScrobble,
      );
}

class User extends DatabaseMappedModel {
  @override
  String get id => username;

  final String username;
  final DateTime lastSync;
  final int playCount;
  final ImageInfo imageInfo;

  final UserSetupSync setupSync;

  User({
    this.username,
    DateTime lastSync,
    this.playCount,
    this.imageInfo,
    this.setupSync = const UserSetupSync(),
  }): lastSync = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0);

  User.deserialize(this.username, Map<String, dynamic> dbMap)
      : playCount = dbMap['playCount'],
        setupSync = UserSetupSync.deserialize(dbMap.unpackDbMap('setupSync')),
        imageInfo = ImageInfo.fromMap(dbMap.unpackDbMap('imageInfo')),
        lastSync = dbMap['lastSync'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(dbMap['lastSync']);

  @override
  Map<String, dynamic> toDbMap() => {
        'lastSync': lastSync?.millisecondsSinceEpoch,
        'setupSync': setupSync.toDbMap(),
        'playCount': playCount,
        'imageInfo': imageInfo?.toMap()
      };

  User copyWith({
    DateTime lastSync,
    String username,
    int playCount,
    ImageInfo imageInfo,
    UserSetupSync setupSync,
  }) =>
      User(
        lastSync: lastSync ?? this.lastSync,
        username: username ?? this.username,
        setupSync: setupSync ?? this.setupSync,
        playCount: playCount ?? this.playCount,
        imageInfo: imageInfo ?? this.imageInfo,
      );
}
